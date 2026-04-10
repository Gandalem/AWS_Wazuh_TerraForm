# 1. RSA 알고리즘으로 안전한 프라이빗 키 생성
resource "tls_private_key" "wazuh_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. 생성된 키를 AWS EC2 키페어로 등록
resource "aws_key_pair" "wazuh_keypair" {
  key_name   = "wazuh-keypair"
  public_key = tls_private_key.wazuh_pk.public_key_openssh
}

# 3. 내 컴퓨터(현재 테라폼 폴더)에 .pem 파일로 자동 저장
resource "local_file" "wazuh_pem" {
  filename        = "${path.module}/wazuh-keypair.pem"
  content         = tls_private_key.wazuh_pk.private_key_pem
  file_permission = "0400" # 보안을 위해 나만 읽을 수 있게 권한 설정
}