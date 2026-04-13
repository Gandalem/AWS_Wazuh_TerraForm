# 최신 Ubuntu 22.04 AMI 이미지를 AWS에서 자동으로 검색해서 가져오는 코드
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu 공식 배포자 ID)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "wazuh_server" {
  # 위에서 자동으로 찾은 최신 우분투 이미지의 ID를 여기에 쏙 넣습니다.
  ami = data.aws_ami.ubuntu.id

  # Wazuh는 메모리 사용량이 많아 t3.medium 이상을 강력히 권장합니다.
  instance_type = "t3.large" #dashboard 배포시 메모리 용량 부족으로 확장

  # 1단계의 퍼블릭 서브넷과 2단계의 보안 그룹을 연결
  subnet_id              = aws_subnet.wazuh_public_subnet.id
  vpc_security_group_ids = [aws_security_group.wazuh_sg.id]

  # ⭐ 방금 만든 키페어 이름을 서버에 등록 (이 줄을 추가하세요!)
  key_name = aws_key_pair.wazuh_keypair.key_name

  # 외부에서 인터넷으로 접속하기 위해 공인 IP 할당을 활성화
  associate_public_ip_address = true

  # 기본값 8기가는 너무 적어서 하드디스크 용량을 50GB로 확장 (추가된 부분!)
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "wazuh-manager-node"
  }
}