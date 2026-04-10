resource "aws_security_group" "wazuh_sg" {
  name        = "wazuh-security-group"
  description = "Security group for Wazuh Server"
  vpc_id      = aws_vpc.wazuh_vpc.id # 1단계에서 만든 VPC에 연결

  # 1. SSH 접속 (서버 관리용)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 2. Wazuh Dashboard (웹 UI 접속용)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 3. 에이전트 통신 및 로그 수집용
  ingress {
    from_port   = 1514
    to_port     = 1514
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 4. 에이전트 신규 등록용
  ingress {
    from_port   = 1515
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 5. Wazuh API (테라폼 2단계 연동용)
  ingress {
    from_port   = 55000
    to_port     = 55000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 (서버가 외부로 나가는 통신은 모두 허용)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wazuh-sg"
  }
}