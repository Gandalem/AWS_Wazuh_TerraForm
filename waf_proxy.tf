resource "null_resource" "waf_reverse_proxy_setup" {

  #설치가 다 끝날 때까지 기다리라
  depends_on = [null_resource.wazuh_complete_setup]

  # 서버가 생성된 것을 기준으로 실행
  triggers = {
    instance_id = aws_instance.wazuh_server.id
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.wazuh_pk.private_key_pem
    host        = aws_instance.wazuh_server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '=== [1/4] Nginx용 HTTPS 자체 서명 인증서 생성 ==='",
      "sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj '/C=KR/ST=Seoul/L=Seoul/O=Security/OU=IT/CN=wazuh-waf'",

      "echo '=== [2/4] ModSecurity WAF 엔진 스위치 ON ==='",
      "sudo mkdir -p /etc/nginx/modsec",
      "sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf || echo 'No recommended conf found'",
      "sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf",
      "sudo bash -c 'echo \"Include /etc/nginx/modsec/modsecurity.conf\" > /etc/nginx/modsec/main.conf'",

      "echo '=== [3/4] Nginx 리버스 프록시(다리) 설정 작성 ==='",
      "sudo bash -c 'cat << \\EOF > /etc/nginx/conf.d/wazuh-proxy.conf\nserver {\n    listen 443 ssl;\n    server_name _;\n\n    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;\n    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;\n\n    # WAF 엔진 켜기\n    modsecurity on;\n    modsecurity_rules_file /etc/nginx/modsec/main.conf;\n\n    # 정상 트래픽을 내부 8443 포트로 토스!\n    location / {\n        proxy_pass https://127.0.0.1:8443;\n        proxy_set_header Host \\$host;\n        proxy_set_header X-Real-IP \\$remote_addr;\n        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;\n        proxy_ssl_verify off;\n    }\n}\nEOF'",

      "echo '=== [4/4] 기본 웹페이지 제거 및 Nginx 재시작 ==='",
      "sudo rm -f /etc/nginx/sites-enabled/default",
      "sudo systemctl restart nginx",
      "echo '=== WAF 리버스 프록시 구축 완료! ==='"
    ]
  }
}