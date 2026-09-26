# MemoryLink EC2 생성 + 소형 AI 모델 가이드 (t3.small)

> 2026-09-21 · 근거: 사무국 설명서 PDF(인스턴스 t3.small 이하, gp3 50GiB 이하, 기존 보안 그룹 선택, SafeInstanceProfile) · 모델: ggml-org/gemma-3-1b-it-GGUF (Q4_K_M 806MB)

## 1. 인스턴스 생성 설정

| 단계 | 입력값 | 이유 |
|---|---|---|
| 이름 | `{IAM사용자명}-memorylink` | 설명서 규칙: IAM 사용자명이 접두사 |
| AMI | Ubuntu Server 24.04 LTS, 아키텍처 64비트(x86) | llama.cpp·whisper.cpp 빌드 자료가 가장 많음, EC2 Instance Connect 기본 탑재 |
| 인스턴스 유형 | **t3.small** (2vCPU / 2GiB) | 허용 최대 사양. t3.micro(1GiB)는 모델 적재 불가 |
| 키 페어 | 새로 생성, RSA, **.pem** | Windows 11 기본 ssh로 사용 가능(.ppk는 PuTTY 전용) |
| 네트워크 | Default VPC, 퍼블릭 서브넷, 퍼블릭 IP 자동 할당 **활성화** | 외부 접속 필요 |
| 보안 그룹 | **기존 보안 그룹 선택** → 앞서 만든 그룹 | "새 보안 그룹 생성" 금지 |
| 스토리지 | **30GiB, gp3** | 모델·스왑 4GB·Docker 여유. 50GiB 이하 |
| 고급 → IAM 인스턴스 프로파일 | `SafeInstanceProrile-{IAM사용자명}` | 설명서 지정 |
| 고급 → 크레딧 사양 | **Standard** | Unlimited는 CPU 과다 사용 시 추가 과금. 운영 중에도 변경 가능 |

## 2. 접속 (Windows PowerShell)

```powershell
icacls C:\keys\memorylink.pem /inheritance:r /grant:r "$($env:USERNAME):R"
ssh -i C:\keys\memorylink.pem ubuntu@<퍼블릭 IPv4>
```

## 3. 스왑 + llama.cpp + Gemma 3 1B

```bash
# 스왑 4GB (2GiB 메모리 보완, 필수)
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 빌드 도구
sudo apt update && sudo apt install -y build-essential cmake git libcurl4-openssl-dev

# llama.cpp 빌드 (10~20분)
git clone https://github.com/ggml-org/llama.cpp && cd llama.cpp
cmake -B build -DLLAMA_CURL=ON && cmake --build build --config Release -j2 --target llama-server llama-cli

# 대화 테스트
./build/bin/llama-cli -hf ggml-org/gemma-3-1b-it-GGUF:Q4_K_M -t 2 -c 2048 -p "어릴 적 살던 동네 이야기를 해 주세요."

# API 서버 (외부 비공개, 127.0.0.1 바인딩)
./build/bin/llama-server -hf ggml-org/gemma-3-1b-it-GGUF:Q4_K_M -t 2 -c 2048 --host 127.0.0.1 --port 8080
```

## 4. 기대치와 제약 (추정, 실측 필요)
- 2GiB 메모리 기준: OS 0.4 + Gemma 1B 1.1 + FastAPI 0.2 ≈ 1.7GB. whisper는 LLM과 동시에 올리지 말고 필요할 때만 실행.
- 속도: 2vCPU x86에서 1B Q4 약 5~10 tok/s 예상. Standard 크레딧이면 크레딧 소진 후 기준성능 20%로 떨어짐 → 연속 사용 시 느려짐.
- 모델 품질 부족 시 대안: Qwen2.5 0.5B(더 빠름, 한국어 약함) / 온디바이스 Gemma를 1순위로 두고 서버는 폴백 유지.
- 인스턴스 정지 후 시작하면 퍼블릭 IP가 바뀜 → CloudFront 오리진 재설정 필요. 가능하면 정지하지 말 것.
