# MemoryLink × AWS v4 — 서버 측 로컬 AI 컴퓨팅 설계

> 작성 2026-09-21 · v3 대비 변경: "EC2에서 로컬 LLM/STT를 실제로 돌리는" 컴퓨팅 구성 추가 · 신청 서비스는 여전히 EC2·EBS·S3·CloudFront 4개
> 전제: 관리형 AI(Bedrock·Transcribe·Polly) 불가, t3.large 불가 → **GPU·상시 대형 인스턴스도 불가로 간주**. 단가는 서울 리전 온디맨드(2026-09 조회), 환율 1,400원/USD

---

## 1. 결론 먼저

**가능하다. 단, GPU가 아니라 Graviton(ARM) CPU 추론이고, "상시 소형 + 필요할 때만 켜는 중형" 2단 구성이어야 승인·예산 둘 다 맞는다.**

| 역할 | 인스턴스 | 사양 | 단가(서울) | 운용 | 월 비용 |
|---|---|---|---|---|---|
| A. API 서버(상시) | **t4g.medium** | 2vCPU / 4GB | $0.0416/h | 24시간 | $30 |
| B. AI 워커(필요 시) | **c7g.xlarge** | 4vCPU Graviton3 / 8GB | $0.1632/h | 하루 4~6시간 start/stop | $20~30 |
| EBS gp3 | 40GB + 30GB | — | ≈$0.09/GB | — | $6 |
| Elastic IP | 1개 | — | $0.005/h | — | $4 |
| **합계** | | | | | **≈$60~70 (8.4~9.8만, 45만의 19~22%)** |

B를 24시간 켜면 $119(26%)로 예산은 되지만, t3.large($76)를 불허한 사무국 기준으론 거절 가능성이 높다. 그래서 **"시연·평가 세션 때만 기동"** 을 명시한다.

## 2. 왜 이 구성인가 — 검토한 대안

| 대안 | 서울 단가 | 판정 |
|---|---|---|
| g4dn.xlarge (T4 GPU 16GB) | $0.647/h → 24시간 $472(66%) / 스팟 $0.32/h | **불가.** GPU 쿼터 신청(Service Quotas)도 사무국 권한, 예산 초과 |
| c7g.xlarge 24시간 | $119/월 | 예산 내(26%)지만 t3.large 불허 선례상 거절 가능성 ↑ → start/stop 조건부로만 |
| c7g.large 24시간 (2vCPU/8GB) | ≈$0.082/h → $60/월 | 한 대로 통합 가능하나 2vCPU라 4B 모델 3~4 tok/s → 대화용 부족 |
| c7g.xlarge **스팟** | $0.0445/h → 24시간 $32/월 | 가성비 최고. 중단 10~15%라 시연엔 위험, **2차 요청 후보** |
| Lightsail (고정 $24~44/월) | — | 별도 서비스라 권한 목록 밖. 미신청 |
| Lambda + 컨테이너(10GB) | 요청당 과금 | 산발적 대화엔 싸지만 콜드스타트 10~20초, ECR·Lambda 권한 추가 필요 → 미신청 |
| Fargate | $0.04/vCPU-h + 메모리 | 상시 4vCPU면 EC2보다 비쌈. 미신청 |

## 3. AI 워커(c7g.xlarge)에서 실제로 돌리는 것

| 구성 요소 | 모델 | 크기(Q4) | 기대 성능(4vCPU Graviton3, **추정·실측 필요**) | 앱 연동 |
|---|---|---|---|---|
| llama.cpp server | **Gemma 3 4B** 또는 **EXAONE 3.5 2.4B**(한국어 강점) | 2.5GB / 1.6GB | 6~10 tok/s, 첫 토큰 1~2초 | OpenAI 호환 `/v1/chat/completions` → FastAPI 프록시 → 앱 `AiProviderInterface` 구현체 추가 |
| llama.cpp server (경량) | Gemma 3 1B | 0.7GB | 20~30 tok/s | 저사양 기기 폴백 |
| whisper.cpp | `small` (ko) | 0.5GB | 30초 음성 ≈ 15~30초 처리 | `/analyze/voice` 비동기 배치 |
| 메모리 합 | 4B + whisper small | ≈4GB | 8GB 안에서 동시 상주 가능 | — |

참고 벤치: 12코어 x86(i7-12700)에서 Gemma 4 E2B 15 tok/s, Phi-4 mini(3.8B) 12 tok/s. Graviton3 4vCPU는 그 절반 이하로 잡았다. **고령 사용자 회상대화(짧은 턴, 1:1)** 에는 6 tok/s면 체감상 충분하다.

## 4. 앱 연동 방식 (코드 기준)

```
[Flutter] ──HTTPS──▶ CloudFront ──▶ t4g.medium FastAPI
                                        ├─ /chat      → (워커 ON) http://<워커 사설IP>:8080/v1/chat/completions
                                        │              → (워커 OFF) Gemini 프록시 또는 규칙 폴백
                                        ├─ /analyze/voice → S3 업로드 → 워커 whisper.cpp 큐
                                        └─ /worker/start|stop → ec2:StartInstances/StopInstances (인스턴스 역할)
[Flutter] ──HTTPS──▶ CloudFront ──▶ S3 : Gemma 3 1B(.litertlm) 온디바이스 배포
```
- `ai_chat_service.dart` 우선순위(Gemma 기기 > 원격 > 규칙)는 그대로. 원격 자리에 `ServerLlmProvider`(FastAPI `/chat`)를 넣는다.
- 워커 기동은 앱이 아니라 **운영자(팀)** 가 한다: FastAPI 관리자 엔드포인트 또는 EC2 콘솔. 하루 종료 시 자동 정지(cron `shutdown -h 23:00`)로 켜둔 채 잊는 사고 방지.
- 워커는 퍼블릭 IP 없이 사설 서브넷, 보안그룹은 t4g.medium에서만 8080 허용.

## 5. 양식 텍스트 (v3 ②·③ 교체분)

### ② 필요한 AWS 서비스
```
[리전: ap-northeast-2 서울 / 기간: 2026-09 ~ 10 / 월 예산 45만 원 중 50% 이내 운용]

1. Amazon EC2 — 2대
   (A) t4g.medium 1대(2vCPU/4GiB, Graviton), Amazon Linux 2023, Elastic IP 1개, 보안그룹 인바운드 22·80·443 — FastAPI API 서버, 24시간 운영
   (B) c7g.xlarge 1대(4vCPU/8GiB, Graviton3), 퍼블릭 IP 없음(사설 서브넷) — 오픈소스 로컬 AI 추론 워커(llama.cpp·whisper.cpp, CPU). 시연·평가 세션 시에만 기동, 하루 4~6시간, 매일 23시 자동 정지
   → (A)에 S3 읽기/쓰기 + (B) Start/Stop만 가능한 인스턴스 역할 연결을 사무국에 요청 (IAM 콘솔 권한은 요청하지 않음)

2. Amazon EBS — gp3 40GB(A) + 30GB(B)
   → OS, 모델 파일(Gemma 3 4B·whisper small, 약 3GB), 음성 임시 저장, 로그

3. Amazon S3 — 버킷 1개(퍼블릭 차단, 라이프사이클 7일)
   → 온디바이스 Gemma 모델 파일(0.5GB) 원본, 테스트 APK, 리포트 PDF, 음성 파일 임시 보관

4. Amazon CloudFront — 배포 2개(S3 오리진 / EC2 오리진), 기본 *.cloudfront.net 도메인만 사용
   → HTTPS API 엔드포인트, 모델 파일·APK 다운로드 (Route 53·ACM 미사용)

※ GPU 인스턴스 · IAM · Route 53 · ACM · Secrets Manager · Parameter Store · ElastiCache · CloudWatch · Bedrock · Transcribe · Polly · SNS · SQS · Rekognition · SES · Budgets · Backup은 신청하지 않습니다.
```

### ③ 추가 설명
```
MemoryLink는 초기 인지저하 고위험 고령자를 위한 Flutter 앱(한이음드림업)입니다. 현재 인증·데이터는 Firebase, AI 대화는 Gemini API, 음성 인지평가는 서버가 없어 차단 화면 상태입니다. 관리형 AI 서비스 대신 오픈소스 모델을 EC2 CPU에서 직접 실행하는 구성으로, AWS에는 EC2·EBS·S3·CloudFront만 사용합니다.

[구조] 앱 → CloudFront(HTTPS) → EC2 (A) t4g.medium FastAPI(24시간). AI 추론은 EC2 (B) c7g.xlarge에서 llama.cpp(Gemma 3 4B, Q4 양자화)와 whisper.cpp(small, 한국어 STT)를 CPU로 실행하고, (A)가 사설망으로 호출합니다. (B)는 시연·평가 시에만 켜고 23시에 자동 정지되며, 꺼져 있을 때는 (A)가 Gemini 프록시 또는 규칙 기반으로 폴백합니다. AWS 자격증명은 인스턴스 역할만 사용하고 앱에는 키를 넣지 않습니다. 환경변수는 .env(Git 커밋 금지), 세션 상태는 FastAPI 인메모리로 처리합니다.

[용도]
- 음성 인지평가: 앱이 올린 음성을 (B) whisper.cpp로 전사 → 발화속도·어휘다양성·휴지 비율 산출 → Firestore 저장.
- AI 회상대화: (B) llama.cpp가 OpenAI 호환 API로 응답, (A)가 프록시. 앱 바이너리의 Gemini 키 노출 문제도 함께 해소.
- 보호자 이상감지: 앱 2곳의 판정 로직을 (A) 한 곳으로 통합, FCM 푸시·Gmail SMTP로 알림.
- S3+CloudFront: 온디바이스 Gemma 모델(0.5GB) 자체 배포로 HuggingFace 토큰·약관 절차 제거, APK·리포트 PDF 배포.
- 모니터링: (A)에 Uptime Kuma 자체 호스팅.

[비용] (A) $30 + (B) 하루 5시간 기준 $25 + EBS·EIP $10 = 월 약 $65(≈9만 원, 45만 원의 20%). (B)를 켜둔 채 방치해도 24시간 $119(26%)로 50% 상한 이내이며, 자동 정지로 그 경우를 막습니다. 사용량 과금은 S3·CloudFront 전송료뿐입니다.

[일정] 9월 4주 (A) 배포·CloudFront → 10월 1~2주 (B) 모델 적재·STT 파이프라인·성능 실측 → 10월 3~4주 이상감지 통합·온디바이스 모델 배포·최종 시연.
```

①·④는 v3와 동일.

## 6. 비용 시뮬레이션 (USD)

| 항목 | 9월(9/22~30) | 10월 기본(B 5h/일) | 10월 최대(B 24h) |
|---|---|---|---|
| (A) t4g.medium | 9.0 | 30.4 | 30.4 |
| (B) c7g.xlarge | 45h 7.3 | 155h 25.3 | 744h 121.4 |
| EBS 70GB | 1.9 | 6.3 | 6.3 |
| EIP | 1.1 | 3.7 | 3.7 |
| S3 + CloudFront | 0.9 | 2.8 | 23.8 |
| **합계** | **≈$20 (2.8만)** | **≈$69 (9.6만, 21%)** | **≈$186 (26만, 58%)** |

2개월: 기본 ≈$89(12.4만, **14%**), 최대 ≈$206(28.8만, 32%). 10월 단독 최대가 58%이므로 **(B) 24시간 + 3.1GB 모델 배포 동시 채택 금지** — 23시 자동 정지로 구조적으로 차단.

## 7. 자체 검증

| 점검 | 결과 |
|---|---|
| c7g.xlarge가 "t3.large 불허" 기준에 걸리나 | 시간당 단가는 t3.large($0.104)보다 높음. **거절 가능성 있음** → start/stop·자동정지·월 $25 근거를 ②③에 명시. 거절 시 폴백: c7g.large 24h($60) 또는 c7g.xlarge 스팟($32) 2차 요청 |
| 인스턴스 역할에 ec2:Start/Stop 포함 요청 | IAM 정책 작성은 사무국 몫. 사무국이 거부하면 EC2 콘솔에서 수동 기동으로 대체(기능 동일) |
| CPU 추론 성능 수치 | **전부 추정.** 근거는 x86 12코어 벤치(Gemma 4 E2B 15 tok/s)의 절반 이하 가정. 10월 1주에 `llama-bench`로 실측하고 4B가 5 tok/s 미만이면 EXAONE 2.4B 또는 Gemma 1B로 강등 |
| 8GB에 4B Q4 + whisper small 동시 상주 | 2.5 + 0.5 + OS/런타임 ≈ 4GB. 여유 있음. KV 캐시는 컨텍스트 4k로 제한 |
| 사설 서브넷 워커의 모델 다운로드 | 퍼블릭 IP 없음 → HuggingFace 직접 다운로드 불가. **S3에 모델 올린 뒤 인스턴스 역할로 받거나, NAT 없이 (A)를 경유** — S3 VPC 게이트웨이 엔드포인트(무료) 사용 권장 |
| 비용 합산 | 10월 기본 30.4+25.3+6.3+3.7+2.8=68.5 ✔ / 최대 30.4+121.4+6.3+3.7+23.8=185.6 ✔ |
| EXAONE 3.5 라이선스 | 연구·비상업 조건(EXAONE AI Model License) — 한이음 시연은 해당되나 상용 전환 시 재검토. Gemma는 Gemma Terms 고지 유지 |
| 단가 출처 | t4g.medium·c7g.xlarge·g4dn.xlarge 서울 단가는 조회값. c7g.large는 xlarge의 1/2로 **추정** |

## 8. 범위 밖 발견 (수정 안 함)
- v2·v3와 동일(GaitScreen 도달 불가, CI SDK 불일치, HF 토큰 평문 저장).
- `backend/analysis_server/main.py`는 `time.sleep(2)` 동기 호출 — 실제 STT 연결 시 `BackgroundTasks`로 바꿔야 API가 블로킹되지 않음(구현 단계 작업).
