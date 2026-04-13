# Wazuh 설치 및 WAF 설정을 담당하는 통합 프로비저닝 리소스
resource "null_resource" "wazuh_complete_setup" {

  # 서버가 새로 생성될 때마다 실행되도록 인스턴스 ID와 연결
  triggers = {
    instance_id = aws_instance.wazuh_server.id
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.wazuh_pk.private_key_pem
    host        = aws_instance.wazuh_server.public_ip
  }

  # [STEP 1] Wazuh 통합 설치 (All-in-one)
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '=== [1/3] Wazuh 설치를 시작합니다 (약 5~10분 소요) ==='",
      "curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh",
      "sudo bash ./wazuh-install.sh -a",
      "echo '=== Wazuh 설치 완료! ==='"
    ]
  }

  # [STEP 2] Wazuh 대시보드 내부 격리 (Port 443 -> 8443)
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '=== [2/3] 대시보드 포트 격리 및 설정 변경 ==='",
      "sudo sed -i 's/server.port: 443/server.port: 8443/g' /etc/wazuh-dashboard/opensearch_dashboards.yml",
      "sudo sed -i 's/server.host: \"0.0.0.0\"/server.host: \"127.0.0.1\"/g' /etc/wazuh-dashboard/opensearch_dashboards.yml",
      "sudo systemctl restart wazuh-dashboard",
      "echo '=== 대시보드 내부 격리 완료 ==='"
    ]
  }

  # [STEP 3] 수문장(WAF) Nginx + ModSecurity 설치
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '=== [3/3] Nginx 및 ModSecurity 설치 ==='",
      "sudo apt-get update -y",
      "curl -fsSL https://modsecurity.digitalwave.hu/archive.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/digitalwave-modsecurity.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/digitalwave-modsecurity.gpg] http://modsecurity.digitalwave.hu/ubuntu/ jammy main\" | sudo tee /etc/apt/sources.list.d/dwmodsec.list",
      "echo \"deb [signed-by=/usr/share/keyrings/digitalwave-modsecurity.gpg] http://modsecurity.digitalwave.hu/ubuntu/ jammy-backports main\" | sudo tee -a /etc/apt/sources.list.d/dwmodsec.list",
      "sudo bash -c 'echo -e \"Package: *nginx*\\nPin: origin modsecurity.digitalwave.hu\\nPin-Priority: 900\" > /etc/apt/preferences.d/99-digitalwave'",
      "sudo bash -c 'echo -e \"Package: *modsecurity*\\nPin: origin modsecurity.digitalwave.hu\\nPin-Priority: 900\" >> /etc/apt/preferences.d/99-digitalwave'",
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx libnginx-mod-http-modsecurity",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "echo '=== WAF 엔진 설치 완료! 모든 설정이 끝났습니다. ==='"
    ]
  }
}