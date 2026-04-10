terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # 최신 AWS 프로바이더 버전
    }
  }
}

# AWS 서울 리전(ap-northeast-2) 사용
provider "aws" {
  region = "ap-northeast-2"

  # 인텔리제이 터미널에서 aws configure를 통해
  # 자격 증명을 세팅했다면 access_key는 안 적어도 됩니다.
}