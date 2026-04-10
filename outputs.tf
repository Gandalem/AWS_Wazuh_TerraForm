output "wazuh_dashboard_url" {
  description = "Wazuh 웹 대시보드 접속 주소"
  value       = "https://${aws_instance.wazuh_server.public_ip}"
}

output "wazuh_api_url" {
  description = "Wazuh API 엔드포인트 주소 (테라폼 설정 주입용)"
  value       = "https://${aws_instance.wazuh_server.public_ip}:55000"
}

output "ssh_command" {
  description = "서버 SSH 접속 명령어"
  value       = "ssh -i wazuh-keypair.pem ubuntu@${aws_instance.wazuh_server.public_ip}"
}