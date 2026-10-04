# MemoryLink × AWS — 활용 설계 및 권한 요청서 v2

> 작성 2026-09-16 · 리전 ap-northeast-2(서울) · 기간 2026-09-22 ~ 10-31 · 예산 90만 원(월 45만) · **계획 집행률 상한 50%**
> 근거: 저장소 `E:\Test_Android\flutter_application_1` 실제 코드(2026-09-16 기준) + AWS 요금 페이지(2026-09 조회)
> 환율 가정 1 USD = 1,400원(보수적)

---

## A. 양식 붙여넣기 텍스트 (4칸)

### ① 제공받은 IAM User ID
```
(사무국 발급 IAM User ID 기입)
```
※ 미발급 상태면: `계정 미보유 — 신규 발급 요청 (팀 MemoryLink / 요청자 ML / teammemorylink@gmail.com)`

### ② 필요한 AWS 서비스
```
[리전: ap-northeast-2 서울 / 기간: 2026-09 ~ 10 / 월 예산 45만 원 중 50% 이내 운용]

1. Amazon EC2 — t4g.medium 1대(Graviton, 2vCPU/4GiB), Amazon Linux 2023, EBS gp3 30GB, Elastic IP 1개, 보안그룹 인바운드 22·80·443
   → FastAPI 분석/AI 프록시 서버 (backend/analysis_server) 상시 운영
   → 위 서비스 호출 권한이 있는 인스턴스 역할(Instance Profile) 연결을 사무국에 요청 (IAM 콘솔 권한은 요청하지 않음)

2. Amazon Transcribe — 배치 전사, 언어 ko-KR, 입력 S3
   → 음성 인지평가 STT: 전사 텍스트로 발화속도(WPM)·어휘다양성(TTR)·휴지 비율 산출

3. Amazon Polly — Neural 엔진, 한국어 음성(Seoyeon)
   → 고령 사용자용 안내/회상대화 음성 합성, S3에 캐시 후 앱 재생

4. Amazon S3 — 버킷 1개(퍼블릭 차단, 라이프사이클 7일)
   → Transcribe 입력 음성 임시 저장, Polly 캐시, 온디바이스 Gemma 모델 파일(0.5~3GB) 미러, 테스트 APK 배포

5. Amazon CloudFront — 배포 2개(S3 오리진 / EC2 오리진), 기본 *.cloudfront.net 도메인만 사용
   → HTTPS API 엔드포인트 및 모델 파일 다운로드 (Route 53·ACM 미사용)

6. Amazon CloudWatch — Logs, Metrics, 알람 5개 이내
   → 서버 로그, EC2/Transcribe/CloudFront 사용량 알람(예산 30·40·50% 단계 경보)

7. Amazon SNS — 이메일 구독 토픽 1개(SMS 미사용)
   → CloudWatch 알람 수신, 보호자 이상감지 이메일 알림 시범

8. Amazon DynamoDB — 온디맨드 테이블 2개(voice_analysis, anomaly_events)
   → 분석 결과·이상감지 이벤트 저장 (고정 과금 없음)

9. (선택) Amazon Bedrock — InvokeModel/Converse, Amazon Nova Lite 또는 Claude Haiku, APAC 교차 리전 추론 프로파일
   → AI 회상대화의 서버측 생성. 서울 리전 in-region 모델이 없어 교차 리전 필요. 정책상 불가 시 본 항목만 제외해 주시면 됩니다(현재 Gemini API로 대체 운용 중).

※ IAM · Route 53 · ACM · Secrets Manager/Parameter Store · ElastiCache · SES · Budgets · Backup · GPU/t3.large 이상 인스턴스는 신청하지 않습니다.
```

### ③ 추가 설명
```
MemoryLink는 초기 인지저하 고위험 고령자를 위한 Flutter 앱(한이음드림업)입니다. 현재 인증·데이터는 Firebase, AI 대화는 앱에서 Gemini API를 직접 호출하며, 음성 인지평가는 서버가 없어 차단 화면 상태입니다. AWS는 앱에 없는 "서버 측 분석·음성·배포 계층"을 맡습니다.

[구조] 앱 → CloudFront(기본 도메인, HTTPS) → EC2 t4g.medium(FastAPI, Docker) → Transcribe/Polly/S3/DynamoDB 호출. AWS 자격증명은 EC2 인스턴스 역할만 사용하고, 앱에는 어떤 AWS 키도 넣지 않습니다. 환경변수는 EC2 내 .env로 관리(Git 커밋 금지).

[용도]
- EC2: 유일한 상시 자원. 음성 파일 수신 → Transcribe 전사 → 지표 산출 → DynamoDB 저장 → 이상 시 SNS 이메일. 보호자 안심알림 판정도 앱 2곳에 분산된 로직을 서버 1곳으로 통합합니다.
- Transcribe(ko-KR): 자체 Whisper 서버는 GPU가 필요해 예산·정책상 불가하므로 관리형 STT로 대체.
- Polly: 기기 내장 TTS 품질 편차가 커서 고령자용 안내 음성을 서버에서 합성, S3 캐시로 반복 비용 억제.
- S3+CloudFront: 온디바이스 Gemma 모델 파일을 자체 배포해 현재 필수인 HuggingFace 토큰·약관 동의 절차를 제거하고, 테스트 APK와 리포트 PDF를 같은 경로로 배포합니다.
- CloudWatch+SNS: 사용량 알람으로 예산 초과를 사전 차단(Budgets 대체).
- Bedrock(선택): 앱 바이너리에 포함된 Gemini 키 노출 위험을 서버 프록시로 해소하기 위한 용도이며, 교차 리전이 불가하면 제외해도 나머지 설계는 그대로 동작합니다.

[비용] 기본 시나리오 월 약 $104(≈15만 원, 45만 원의 32%), 2개월 합계 예산의 50% 이내로 CloudWatch 사용량 알람에서 차단. 고정 과금은 EC2·EBS·EIP(월 약 $37)뿐이고 나머지는 사용량 과금입니다.

[일정] 9월 4주 EC2·CloudFront·CloudWatch 구성 → 10월 1~2주 Transcribe 음성평가 파이프라인 → 10월 3~4주 이상감지 통합·SNS·최종 시연.
```

### ④ 권한 오류 메시지
```
해당 없음 — 최초 권한 신청입니다. 계정 발급 후 AccessDenied 발생 시 서비스명·API명·오류 전문을 첨부해 추가 요청하겠습니다.
```

---

## B. 폴더 분석 결과 → AWS가 해결하는 것

| 코드 근거 (실제 확인) | 현재 상태 | AWS 역할 |
|---|---|---|
| `backend/analysis_server/main.py` 58줄 | `random.uniform` 반환 스텁, Whisper 전제 | EC2 + Transcribe(ko-KR)로 실제 STT·지표 산출 |
| `lib/features/voice_assessment/voice_assessment_blocked_screen.dart` | 서버 부재로 기능 차단 | 서버 생기면 차단 해제 |
| `lib/core/ai/gemini_provider.dart`, `app_config.dart` | Gemini 키가 `--dart-define`으로 바이너리 포함 | (선택) EC2 프록시 + Bedrock으로 키 제거 |
| `lib/core/ai/model_download_service.dart` | `gemma-1.1-2b-it-gpu-int4.bin`을 HF에서 직접 다운로드, **HF 토큰 + 약관 동의 필수**(`model_download_screen.dart` 185행) | S3+CloudFront 미러로 토큰 절차 제거 |
| `lib/core/local_ai_service.dart` | 규칙 기반(TTR/WPM/필러어) 온디바이스 분석, TFLite 보류 | 서버 STT 텍스트를 같은 규칙 엔진에 넣어 일관 지표 |
| `pedometer_manager.dart` · `guardian_sync_service` (로드맵 §7) | 이상감지 임계값 2곳 상이, `catch(_)`로 실패 삼킴 | 서버 단일 판정 + DynamoDB 기록 + SNS 이메일 |
| `maestro/` 12개 플로우 | 로컬 PS 스크립트로만 실행 | EC2에서는 **불가**(에뮬레이터에 KVM 필요 → 베어메탈만 지원, 예산 외). 로컬 유지 |

## C. 온디바이스 AI — 가능 여부 판단

**결론: 가능하며, AWS의 역할은 "추론"이 아니라 "모델 배포 + 폴백"이다.**

1. 현재 코드는 `flutter_gemma ^0.2.0` + Gemma 1.1 2B `.bin`(MediaPipe). 최신 `flutter_gemma 1.8.3`은 `.litertlm` 포맷과 `fromNetwork()` 커스텀 URL을 지원하므로, **S3+CloudFront에 올린 모델을 앱이 직접 받는 구조**가 성립한다. HF 토큰 화면(`model_download_screen.dart`)을 제거할 수 있다.
2. 모델 선택(고령자 보급형 기기 기준):
   - **Gemma 3 1B (0.5GB)** — 회상대화 정도의 텍스트 생성엔 충분, 4GB RAM 기기 안전. **1순위**
   - Gemma 3n E2B (3.1GB) / Gemma 4 E2B (2.4GB) — 오디오 입력까지 되지만 저사양 기기 OOM 위험. 2순위(고사양 기기 한정)
3. 하이브리드 우선순위는 이미 코드에 있다(`ai_chat_service.dart` 88행: Gemma > Gemini > 규칙 폴백). Gemini 자리를 EC2 프록시(Bedrock 또는 현행 Gemini)로 바꾸면 끝.
4. 음성 인지평가 STT는 **서버(Transcribe) 유지**가 맞다. 온디바이스 한국어 STT는 flutter_gemma 파이프라인에 없고, 평가 재현성(동일 엔진)이 근거 확보에 중요하다.
5. 주의: Gemma 모델 재배포 시 Gemma Terms of Use 고지 문구를 앱 내 유지(현재 `model_download_screen.dart` 268행에 이미 있음). 모델 다운로드 트래픽이 CloudFront 비용의 주 변수 → 알람 필수.

## D. 아키텍처

```
[Flutter 앱] ─HTTPS─▶ CloudFront(*.cloudfront.net) ─▶ EC2 t4g.medium (FastAPI/Docker, 인스턴스 역할)
                                                       ├─ Transcribe(ko-KR) ◀─ S3 음성(7일 삭제)
                                                       ├─ Polly(Seoyeon) ─▶ S3 캐시
                                                       ├─ DynamoDB(voice_analysis, anomaly_events)
                                                       ├─ CloudWatch Logs/Alarm ─▶ SNS 이메일
                                                       └─ (선택) Bedrock Nova Lite/Haiku, APAC 프로파일
[Flutter 앱] ─HTTPS─▶ CloudFront ─▶ S3 : Gemma 3 1B(.litertlm) · APK · 리포트 PDF
인증: Firebase ID 토큰 → EC2 검증. 시크릿: EC2 .env. 세션/멀티턴: FastAPI 인메모리(dict/lru_cache).
```

## E. 비용 시뮬레이션 (서울, USD, 2026-09 조회 단가)

| 항목 | 단가 | 9월(9/22~30, 셋업) | 10월 기본(테스터 30명) | 10월 최대(테스터 60명) |
|---|---|---|---|---|
| EC2 t4g.medium | $0.0416/h | 9.0 | 30.4 | 30.4 |
| EBS gp3 30GB | ≈$0.09/GB | 0.8 | 2.7 | 2.7 |
| Elastic IP | $0.005/h | 1.1 | 3.7 | 3.7 |
| Transcribe ko-KR 배치 | $0.024/분(보수) | 200분 4.8 | 1,500분 36.0 | 3,000분 72.0 |
| Polly Neural | $16/100만자 | 1.6 | 60만자 9.6 | 120만자 19.2 |
| S3 | ≈$0.025/GB | 0.5 | 1.0 | 1.5 |
| CloudFront 전송 | ≈$0.12/GB(APAC) | 10회×0.5GB 0.6 | 30회×0.5GB 1.8 | 60회×3.1GB 22.3 |
| CloudWatch | — | 1.0 | 3.0 | 4.0 |
| DynamoDB 온디맨드 | — | 0.2 | 1.0 | 2.0 |
| SNS 이메일 | 무료 | 0 | 0 | 0 |
| (선택) Bedrock | Nova Lite $0.06/$0.24 per M · Haiku 4.5 $1/$5 per M | 5.0 | 15.0 | 40.0 |
| **합계** | | **≈$25 (3.5만)** | **≈$104 (14.6만, 32%)** | **≈$198 (27.7만, 62%)** |

- 2개월 합계: 기본 ≈$129(18만, **20%**), 최대 ≈$223(31만, 35%). **50% 상한(45만)은 최대 시나리오에서도 남는다.** 10월 단독 최대 시나리오는 62%이므로 Transcribe 3,000분·모델 3.1GB 동시 채택은 금지(알람 40%에서 테스터 확대 중단).
- 고정비는 EC2+EBS+EIP ≈ $37/월뿐. 나머지는 사용량 과금 → "폭탄" 경로는 (a) CloudFront 모델 다운로드 무제한 공개 (b) Transcribe 반복 제출 두 가지. 대응: CloudFront `BytesDownloaded` 알람, 서버에서 사용자당 일 3회 전사 제한.
- Transcribe 단가: AWS 요금 페이지는 us-east-1 기준 $0.006/분으로 인하 표기, 서울 리전은 미확인 → **$0.024로 보수 계상**. 실제는 더 낮을 가능성 큼.
- 신규 계정(2025-07-15 이후)은 12개월 프리티어 대신 크레딧 방식 → 프리티어 미반영.

## F. 사무국 불가 항목 대응

| 불가 | 대안(본 설계) |
|---|---|
| IAM | 신청 없음. EC2 인스턴스 역할 연결만 사무국에 요청 |
| Route 53 / ACM | CloudFront 기본 도메인(관리형 인증서) |
| Secrets Manager / Parameter Store | EC2 `.env` + 인스턴스 역할 |
| ElastiCache | FastAPI 인메모리 `dict`/`lru_cache` |
| SES / Budgets / Backup | SNS 이메일 / CloudWatch 알람 / Firestore 이중 보관 |
| t3.large · GPU | t4g.medium + 관리형 Transcribe |

## G. 자체 검증 (Adversarial-Verify)

| 점검 | 결과 |
|---|---|
| 금지 서비스 포함 여부 | ②·③ 텍스트에서 IAM/Route53/ACM/Secrets/ElastiCache/SES/Budgets/Backup/t3.large 모두 미신청 명시. **통과** |
| Bedrock 교차 리전 = 정책 위반? | 사무국 불가 목록에 Bedrock 없음. 다만 "주체 관리 불가 서비스" 해석 여지 → **선택 항목으로 분리**해 단독 제외 가능하게 함 |
| 비용 합산 재계산 | 10월 기본: 30.4+2.7+3.7+36+9.6+1+1.8+3+1+15 = 104.2 ✔ / 최대: 30.4+2.7+3.7+72+19.2+1.5+22.3+4+2+40 = 197.8 ✔ |
| "50% 집행률" 해석 | 계획 지출을 50%에 맞추면 낭비. **50%를 상한**으로 두고 기본 32%·최대 62%(10월 단독)로 설계, 40% 알람에서 확대 중단 |
| EC2에서 Maestro CI 가능? | Android 에뮬레이터는 KVM 필요 → EC2 베어메탈(수십만 원/일)만 가능. **불가로 명시**, 로컬 유지 |
| CloudWatch 청구 알람 | `AWS/Billing` 지표는 us-east-1 + 계정 설정 "결제 알림 수신" 활성화 필요(사무국 권한). 불가 시 서비스별 사용량 알람으로 대체 — ③에 "사용량 알람"으로만 기재 |
| flutter_gemma 0.2.0 → 1.8.3 업그레이드 리스크 | API 변경 큼(`FlutterGemmaPlugin.instance.init` → 모델 매니저 방식). 온디바이스 채택 시 `gemma_local_provider.dart` 재작성 필요 — **범위 외 작업으로 플래그** |
| Polly 한국어 Neural 음성 | Seoyeon Neural 확인. Jihye는 v1 문서 기재였으나 미검증 → ②에서 제외 |
| EIP 과금 | 2024-02부터 연결 상태여도 $0.005/h → 계상함 |

## H. 범위 밖 발견 (수정하지 않음, 보고만)
- `DEVELOPMENT_ROADMAP.md §6`: `GaitProvider`~`GaitScreen` 730줄 도달 불가 상태 — AWS와 무관하나 심사 리스크.
- `.omo/drafts`: CI Flutter 3.32.0 고정 vs SDK 3.41.5 불일치, Maestro CI가 없는 flow 2개 참조.
- `lib/core/ai/model_download_service.dart` HF 토큰 저장이 `SharedPreferences` 평문.
