# 1. VPC 생성 (가장 큰 사설 네트워크 울타리)
resource "aws_vpc" "wazuh_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "wazuh-vpc"
  }
}

# 2. 퍼블릭 서브넷 생성 (VPC 내부의 인터넷 가능 구역)
resource "aws_subnet" "wazuh_public_subnet" {
  vpc_id                  = aws_vpc.wazuh_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # 여기에 띄우는 서버는 자동으로 공인 IP 부여
  availability_zone       = "ap-northeast-2a" # 서울 리전의 a 가용 영역

  tags = {
    Name = "wazuh-public-subnet"
  }
}

# 3. 인터넷 게이트웨이 생성 (외부 인터넷으로 나가는 대문)
resource "aws_internet_gateway" "wazuh_igw" {
  vpc_id = aws_vpc.wazuh_vpc.id

  tags = {
    Name = "wazuh-igw"
  }
}

# 4. 라우팅 테이블 생성 및 연결 (모든 트래픽을 대문으로 안내하는 표지판)
resource "aws_route_table" "wazuh_public_rt" {
  vpc_id = aws_vpc.wazuh_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # 모든 목적지
    gateway_id = aws_internet_gateway.wazuh_igw.id
  }

  tags = {
    Name = "wazuh-public-rt"
  }
}

# 5. 서브넷과 라우팅 테이블 묶어주기
resource "aws_route_table_association" "wazuh_public_rt_assoc" {
  subnet_id      = aws_subnet.wazuh_public_subnet.id
  route_table_id = aws_route_table.wazuh_public_rt.id
}