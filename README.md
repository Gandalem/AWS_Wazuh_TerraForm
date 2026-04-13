![aws_Wazuh.png](aws_Wazuh.png)
# 🛡️ Wazuh AWS 인프라 자동 구축 프로비저닝 (Terraform)

이 프로젝트는 오픈소스 보안 모니터링 플랫폼인 **Wazuh**를 운영하기 위한 AWS 클라우드 인프라(네트워크, 방화벽, 컴퓨팅)를 Terraform을 통해 코드로 안전하고 빠르게 구축(IaC)하는 템플릿입니다.

기존의 복잡한 오픈소스 코드를 복사하지 않고, AWS 공식 모범 사례(Clean Room 설계)를 바탕으로 처음부터 작성되어 라이선스 제약 없이 자유롭게 사용 및 수정이 가능합니다.

---

## 🏗️ 아키텍처 구성 요소

이 코드를 실행하면 AWS 서울 리전(`ap-northeast-2`)에 다음 자원들이 자동으로 생성됩니다.

1. **Network (`network.tf`)**
    * VPC (10.0.0.0/16) 및 퍼블릭 서브넷 (10.0.1.0/24)
    * 인터넷 게이트웨이(IGW) 및 라우팅 테이블
2. **Security (`security.tf`)**
    * 외부 통신을 제어하는 보안 그룹(Security Group)
    * 개방 포트: `22` (SSH), `443` (Dashboard), `1514` (Agent Log), `1515` (Agent Enrollment), `55000` (API)
3. **Compute (`compute.tf`)**
    * 최신 Ubuntu 22.04 LTS (자동 검색 적용)
    * `t3.medium` 인스턴스 (Wazuh 권장 최소 사양) 및 공인 IP 자동 할당

---

## 📋 사전 준비 사항 (Prerequisites)

이 프로젝트를 실행하기 전에 본인의 PC에 다음 도구들이 설치되어 있어야 합니다.

* [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.0.0 이상)
* [AWS CLI](https://aws.amazon.com/ko/cli/)
* AWS IAM 계정 (Access Key 및 Secret Key)

**AWS 자격 증명 설정:**
터미널을 열고 아래 명령어를 통해 AWS 접속 정보를 로컬 환경에 세팅합니다.
```bash
aws configure
# Access Key, Secret Key, region(ap-northeast-2), format(json) 입력
```

---

## 🚀 실행 가이드 (Quick Start)

1. **초기화 및 실행 계획 확인**
   ```bash
   terraform init
   terraform plan
   ```
2. **인프라 셋업 및 프로비저닝 (Wazuh & WAF 자동 설치)**
   ```bash
   terraform apply
   ```
   > ⏳ **참고:** EC2 인스턴스가 생성된 후 `remote-exec` 쉘 스크립트를 통해 Wazuh 통합 패키지와 Nginx ModSecurity(WAF)가 순차적으로 다운로드 및 설치됩니다. 이 과정은 약 5~10분 정도 소요됩니다.

3. **접속 주소 확인**
   설치가 완료되면 터미널 출력(Outputs)에 대시보드 접근 주소와 API 주소가 표시됩니다.
   ```bash
   Apply complete! ...
   Outputs:
   wazuh_dashboard_url = "https://<서버의_공인IP>"
   ```

---

## 🆘 트러블슈팅 가이드 (Troubleshooting)

프로비저닝 도중 SSH 접속이 끊기거나 패키지 다운로드 에러로 설치 로직(`remote-exec`)이 실패했을 경우, 엄격한 하네스 룰(`set -e`)에 의해 스크립트가 즉시 중단됩니다. 

이 경우 오염된 좀비 상태의 서버에서 재시도하기보다는, 사이드 이펙트를 차단하기 위해 **해당 인스턴스를 파괴하고 처음부터 깨끗하게 다시 설치(Clean Room 방식)** 하는 것을 강력히 권장합니다.

**설치 에러 발생 시 초기화 및 재구축 명령어:**
```bash
# 1. 꼬여버린 기존 EC2 인스턴스를 날리고 새 서버에서 스크립트를 재시작
terraform apply -replace="aws_instance.wazuh_server"

# 2. 모든 자원을 완전히 삭제하고 싶을 때
terraform destroy
```