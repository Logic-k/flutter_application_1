# MemoryLink × AWS — 활용 설계 및 권한 요청서 v3

> 작성 2026-09-16 · v2 대비 변경: 사무국 추가 불가 통보(Parameter Store · CloudWatch · Bedrock · Transcribe · Polly Neural · SNS · SQS · Rekognition) 반영
> 리전 ap-northeast-2 · 기간 2026-09-22 ~ 10-31 · 예산 90만 원(월 45만) · 집행률 상한 50% · 환율 가정 1,400원/USD

**설계 원칙 변경**: 관리형 AI·알림·모니터링 서비스를 전부 뺀다. **EC2 한 대에 STT·모니터링·알림을 자체 호스팅**하고, AWS는 컴퓨팅(EC2)과 배포(S3+CloudFront)만 담당한다. 신청 서비스 4개.

---

## A. 양식 붙여넣기 텍스트 (4칸)

### ① 제공받은 IAM User ID
```
(사무국 발급 IAM User ID 기입)
```

### ② 필요한 AWS 서비스
```
[리전: ap-northeast-2 서울 / 기간: 2026-09 ~ 10 / 월 예산 45만 원 중 50% 이내 운용]

1. Amazon EC2 — t4g.medium 1대(Graviton, 2vCPU/4GiB), Amazon Linux 2023, Elastic IP 1개, 보안그룹 인바운드 22·80·443
   → FastAPI 분석 서버 + 자체 호스팅 STT(whisper.cpp, CPU) + 모니터링(Uptime Kuma) + 알림(Gmail SMTP·FCM)을 한 대에서 운영
   → S3 읽기/쓰기 권한이 있는 인스턴스 역할(Instance Profile) 연결을 사무국에 요청 (IAM 콘솔 권한은 요청하지 않음)

2. Amazon EBS — gp3 40GB (EC2 루트 볼륨)
   → 서버 OS, whisper 모델 파일(0.5~1.5GB), 음성 임시 저장, 로그

3. Amazon S3 — 버킷 1개(퍼블릭 차단, 라이프사이클 7일)
   → 온디바이스 Gemma 모델 파일(0.5GB) 원본, 테스트 APK, 리포트 PDF, 음성 파일 임시 보관

4. Amazon CloudFront — 배포 2개(S3 오리진 / EC2 오리진), 기본 *.cloudfront.net 도메인만 사용
   → HTTPS API 엔드포인트, 모델 파일·APK 다운로드 (Route 53·ACM 미사용)

※ IAM · Route 53 · ACM · Secrets Manager · Parameter Store · ElastiCache · CloudWatch · Bedrock · Transcribe · Polly · SNS · SQS · Rekognition · SES · Budgets · Backup · t3.large 이상/GPU 인스턴스는 신청하지 않습니다.
```

### ③ 추가 설명
```
MemoryLink는 초기 인지저하 고위험 고령자를 위한 Flutter 앱(한이음드림업)입니다. 현재 인증·데이터는 Firebase, AI 대화는 Gemini API, 음성 인지평가는 서버가 없어 차단 화면 상태입니다. AWS는 앱에 없는 "서버 컴퓨팅"과 "파일 배포"만 맡고, 관리형 AI·알림·모니터링 서비스는 사용하지 않습니다.

[구조] 앱 → CloudFront(기본 도메인, HTTPS) → EC2 t4g.medium(FastAPI, Docker). AWS 자격증명은 EC2 인스턴스 역할(S3 한정)만 사용하고 앱에는 AWS 키를 넣지 않습니다. 환경변수는 EC2 내 .env로 관리(Git 커밋 금지), 세션·멀티턴 상태는 FastAPI 인메모리(dict/lru_cache)로 처리합니다.

[EC2 용도]
- 음성 인지평가: 앱이 올린 음성을 whisper.cpp(오픈소스, CPU 추론)로 한국어 전사 → 발화속도(WPM)·어휘다양성(TTR)·휴지 비율 산출 → Firestore 저장. 관리형 STT 대신 EC2 안에서 자체 처리합니다.
- AI 대화 프록시: 앱 바이너리에 포함된 Gemini 키를 서버 .env로 옮겨 키 노출을 막습니다.
- 보호자 이상감지: 앱 2곳에 흩어진 판정 로직을 서버 1곳으로 통합하고, 알림은 FCM 푸시와 Gmail SMTP 메일로 보냅니다.
- 모니터링: Uptime Kuma를 같은 인스턴스에 띄워 서버 상태·응답시간을 확인하고, 장애 시 이메일로 통보받습니다.

[S3+CloudFront 용도] 온디바이스 Gemma 모델(0.5GB)을 자체 배포해 현재 필수인 HuggingFace 토큰·약관 동의 절차를 없애고, 테스트 APK·리포트 PDF를 같은 경로로 배포합니다.

[비용] 월 약 $42(≈6만 원, 45만 원의 13%). 고정비는 EC2·EBS·EIP(≈$37)뿐이고 사용량 과금은 S3·CloudFront 전송료뿐입니다. 모델 파일 다운로드는 앱 인증 사용자에게만 허용해 전송량을 통제합니다.

[일정] 9월 4주 EC2·CloudFront·Docker 배포 → 10월 1~2주 whisper 음성평가 파이프라인 → 10월 3~4주 이상감지 통합·Gemma 모델 배포·최종 시연.
```

### ④ 권한 오류 메시지
```
해당 없음 — 최초 권한 신청입니다. 계정 발급 후 AccessDenied 발생 시 서비스명·API명·오류 전문을 첨부해 추가 요청하겠습니다.
```

---

## B. 불가 서비스 → 자체 호스팅 대체표

| 불가 서비스 | v2 용도 | v3 대체 (EC2 내부) | 비용 |
|---|---|---|---|
| Transcribe | 한국어 STT | **whisper.cpp** `small` 또는 `base` 모델, CPU 추론, 큐는 FastAPI BackgroundTasks | 0 |
| Polly Neural | 안내 음성 TTS | 기기 내장 TTS 유지(현행) | 0 |
| Bedrock | AI 대화 생성 | Gemini API를 EC2 프록시 경유(키 서버 보관) + 온디바이스 Gemma 3 1B | Gemini 무료 티어 |
| CloudWatch | 로그·알람 | **Uptime Kuma**(도커) + `journalctl`/파일 로그 + `logrotate` | 0 |
| SNS | 이메일 알림 | **FCM 푸시**(Firebase 이미 사용) + Gmail SMTP(앱 비밀번호) | 0 |
| SQS | 작업 큐 | FastAPI BackgroundTasks / 인메모리 큐(단일 서버라 충분) | 0 |
| Parameter Store | 시크릿 | EC2 `.env` (사무국 지침) | 0 |
| DynamoDB (v2 신청분) | 분석 결과 저장 | **Firestore**(firebase-admin으로 EC2에서 기록) — 서비스 수 최소화를 위해 자진 제외 | 0 |
| Rekognition | (미사용) | — | — |

## C. 온디바이스 AI — 판단 유지

v2 결론 그대로. 관리형 AI가 막힌 지금 **온디바이스 Gemma가 AI 대화의 1순위 경로**가 된다.
- `flutter_gemma` 0.2.0 → 1.8.3 업그레이드 후 `fromNetwork()`로 CloudFront URL에서 **Gemma 3 1B(0.5GB, HF 토큰 불필요)** 다운로드. `model_download_screen.dart`의 토큰 입력 UI 제거.
- 폴백 순서(`ai_chat_service.dart` 88행 그대로): Gemma(기기) → EC2 프록시 Gemini → 규칙 기반.
- 음성 STT는 온디바이스 불가(flutter_gemma 파이프라인에 한국어 STT 없음) → EC2 whisper.cpp.
- 실험(선택): EC2에 `llama.cpp` 서버로 Gemma 3 1B를 띄워 기기 미지원 사용자용 폴백. 2 vCPU Graviton에서 수 tok/s 수준이라 시연용에 한정.

## D. 아키텍처

```
[Flutter 앱] ─HTTPS─▶ CloudFront(*.cloudfront.net) ─▶ EC2 t4g.medium (Docker Compose)
                                                       ├─ FastAPI: /analyze/voice, /chat(Gemini 프록시), /anomaly
                                                       ├─ whisper.cpp small (ko) — CPU 배치 전사
                                                       ├─ firebase-admin → Firestore 기록, FCM 푸시
                                                       ├─ Uptime Kuma :3001 (내부) → Gmail SMTP 장애 통보
                                                       └─ .env (GEMINI_API_KEY, FIREBASE_SA, SMTP)
[Flutter 앱] ─HTTPS─▶ CloudFront ─▶ S3 : Gemma 3 1B(.litertlm) · APK · 리포트 PDF
EC2 → S3: 인스턴스 역할(S3 한정)
```

## E. 비용 (서울, USD)

| 항목 | 단가 | 9월(9/22~30) | 10월 기본 | 10월 최대(테스터 60명, 3.1GB 모델) |
|---|---|---|---|---|
| EC2 t4g.medium | $0.0416/h | 9.0 | 30.4 | 30.4 |
| EBS gp3 40GB | ≈$0.09/GB | 1.1 | 3.6 | 3.6 |
| Elastic IP | $0.005/h | 1.1 | 3.7 | 3.7 |
| S3 | ≈$0.025/GB | 0.3 | 1.0 | 1.5 |
| CloudFront 전송 | ≈$0.12/GB(APAC) | 0.6 | 30회×0.5GB 1.8 | 60회×3.1GB 22.3 |
| **합계** | | **≈$12 (1.7만)** | **≈$41 (5.7만, 13%)** | **≈$62 (8.6만, 19%)** |

- 2개월 합계 기본 ≈$53(7.4만, **8%**), 최대 ≈$74(10.3만, 11%). 50% 상한과 거리가 크다.
- **남는 예산의 합리적 사용처(2차 요청 후보, 우선순위순)**: ① whisper `small`이 느리면 STT 워커용 **t4g.medium 1대 추가**(+$30, 총 20%) — API 응답과 전사 배치를 분리 ② 서버 측 Gemma 폴백을 쓸 경우 메모리 여유용 t4g.large(사무국이 t3.large를 불허했으므로 사전 문의 필요). GPU·관리형 AI는 어떤 경우에도 신청하지 않는다.
- 폭탄 경로는 CloudFront 모델 다운로드 하나뿐 → Firebase ID 토큰 검증 후 EC2가 서명 없는 단기 URL을 발급하는 대신, **모델 다운로드를 EC2 프록시 경유로만 허용**(사용자당 1회). CloudWatch가 없으므로 전송량은 사무국 청구서 + Uptime Kuma 카운트로 확인.

## F. 자체 검증

| 점검 | 결과 |
|---|---|
| 불가 목록 대조 (1차 5개 + 2차 8개) | ②·③에 13개 전부 "신청하지 않음" 명시. 신청분 EC2·EBS·S3·CloudFront는 어느 목록에도 없음. **통과** |
| DynamoDB·Polly Standard | 불가 목록에 없으나 "주체관리 불명확" 기준에 걸릴 여지 → 자진 제외. Polly Standard 필요 시 2차 요청 |
| whisper.cpp 한국어 CPU 성능 | **미검증.** 2 vCPU Graviton2에서 `small` 모델은 30초 음성에 수십 초 소요 예상. 배치(비동기) 처리라 허용 가능하나 실측 필요. 느리면 `base`로 강등 또는 워커 인스턴스 추가 |
| CloudWatch 없이 EC2 상태 확인 | EC2 콘솔 "모니터링" 탭도 CloudWatch 권한 필요 → Uptime Kuma + `htop`/`docker stats`로 대체. **청구 알람 불가**라 고정비 중심 설계로 위험 자체를 제거 |
| Gmail SMTP | Google 계정 앱 비밀번호 필요(팀 계정 teammemorylink@gmail.com에 2단계 인증 설정). 일 500통 제한 — 시범 규모엔 충분 |
| 비용 합산 | 10월 기본 30.4+3.6+3.7+1.0+1.8=40.5 ✔ / 최대 30.4+3.6+3.7+1.5+22.3=61.5 ✔ |
| 인스턴스 역할 범위 | S3 한 버킷 읽기/쓰기만 요청 → 사무국이 붙이기 쉬운 최소 권한 |
| v2 문서와의 모순 | v2는 폐기. 프로젝트에 v2·v3 모두 남기되 v3가 제출본 |

## G. 범위 밖 발견 (v2와 동일, 수정 안 함)
- `GaitProvider`~`GaitScreen` 730줄 도달 불가(로드맵 §6).
- CI Flutter 3.32.0 고정 vs SDK 3.41.5 불일치, Maestro CI 누락 flow 2개.
- `model_download_service.dart` HF 토큰 `SharedPreferences` 평문 — 온디바이스 전환 시 자연 소멸.
