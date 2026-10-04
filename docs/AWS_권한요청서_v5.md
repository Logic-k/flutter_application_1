# MemoryLink × AWS v5 — EC2 1대 구성안

> 작성 2026-09-21 · v4 대비 변경: **EC2 1대 제약** 반영, v4 수치 오류 2건 정정(하단 G)
> 리전 ap-northeast-2 · 기간 2026-09-22 ~ 10-31 · 예산 월 45만 원 · 집행률 상한 50% · 환율 1,400원/USD · 단가는 서울 온디맨드(2026-09 조회)

---

## 1. 결론

**t4g.medium 1대로 신청하고, 성능 실측 후 "같은 인스턴스의 타입 변경"으로 키운다.**

- 사무국 스스로 "단일 EC2로 구성되는 MVP 단계"라고 썼다(Secrets Manager 불가 사유). t4g.medium은 그 기준에 정확히 맞아 승인이 거의 확실하다.
- API·STT·LLM을 한 대에 Docker Compose로 올린다. 4GB에 맞추려고 서버 LLM은 **Gemma 3 1B**, STT는 **whisper base/small**로 제한한다. 무거운 대화는 기기 쪽 온디바이스 Gemma가 1순위로 처리하므로 서버는 폴백 역할이면 충분하다.
- 인스턴스 타입 변경(정지 → 타입 변경 → 시작)은 **대수가 늘지 않고** IP·EBS·설정이 그대로 유지된다. 10월 실측에서 1B가 품질이 부족하면 그때 c7g.xlarge로 변경을 요청한다. 거절돼도 기능은 그대로 동작한다.

## 2. 후보 비교 (24시간 운영, EBS 30GB·EIP·S3/CloudFront 포함)

| 인스턴스 | 사양 | 시간당 | 월 합계 | 45만 대비 | 서버 LLM | 승인 가능성 |
|---|---|---|---|---|---|---|
| **t4g.medium** | 2vCPU(버스트)/4GB | $0.0416 | **$40** | **13%** | Gemma 3 1B | **높음** — MVP 기준 부합 |
| c7g.large | 2vCPU/4GB | $0.0816 | $70 | 22% | Gemma 3 1B | 중간 — 메모리 같은데 2배 가격, 이점 적음 |
| t4g.large | 2vCPU(버스트)/8GB | $0.0832 | $71 | 22% | Gemma 3 4B | **낮음** — 불허된 t3.large의 ARM판 |
| m7g.large | 2vCPU/8GB | $0.1003 | $84 | 26% | Gemma 3 4B | 낮음 — t3.large와 가격대 동일 |
| c7g.xlarge | 4vCPU/8GB | $0.1632 | $131 | 41% | Gemma 3 4B, 가장 빠름 | 낮음 — 2단계 타입 변경 후보로만 |

## 3. 한 대 안의 구성 (t4g.medium, 4GB)

| 컨테이너 | 내용 | 메모리(추정) |
|---|---|---|
| FastAPI | `/chat`, `/analyze/voice`, `/anomaly`, 인메모리 세션(dict/lru_cache) | 0.3GB |
| llama.cpp server | Gemma 3 1B Q4, 컨텍스트 2k, OpenAI 호환 API | 1.0GB |
| whisper.cpp | base(기본) / small(정확도 필요 시), 비동기 배치 | 0.3~1.0GB |
| Uptime Kuma | 자체 모니터링 | 0.1GB |
| OS·Docker | Amazon Linux 2023 | 0.6GB |
| **합계** | + 스왑 2GB 설정 | **≈2.3~3.0GB** |

동시성 규칙: whisper와 llama가 동시에 CPU를 쓰면 대화 응답이 느려지므로, **전사는 큐 1개로 직렬 처리**하고 대화 요청을 우선한다(FastAPI 내부 `asyncio.Semaphore`).

```
[Flutter 앱]
  ├─ 대화: 기기 Gemma(1순위) → 서버 /chat(llama.cpp 1B) → 규칙 폴백
  ├─ 음성평가: 녹음 업로드 → 서버 /analyze/voice(whisper) → WPM·TTR·휴지 → Firestore
  └─ 모델 다운로드: CloudFront → S3 (Gemma 3 1B .litertlm, 0.5GB)
       │
       ▼ HTTPS (*.cloudfront.net)
[EC2 t4g.medium 1대 — Docker Compose: FastAPI · llama.cpp · whisper.cpp · Uptime Kuma]
       └─ S3 (인스턴스 역할, 버킷 1개 한정)
```

## 4. 양식 붙여넣기 텍스트

### ① 제공받은 IAM User ID
```
(사무국 발급 IAM User ID 기입)
```

### ② 필요한 AWS 서비스
```
[리전: ap-northeast-2 서울 / 기간: 2026-09 ~ 10 / 월 예산 45만 원 중 50% 이내 운용]

1. Amazon EC2 — t4g.medium 1대(2vCPU/4GiB, Graviton), Amazon Linux 2023, Elastic IP 1개, 보안그룹 인바운드 22·80·443
   → API 서버와 오픈소스 로컬 AI(llama.cpp·whisper.cpp, CPU 추론)를 한 대에서 Docker로 운영
   → S3 버킷 1개 읽기/쓰기 권한의 인스턴스 역할 연결을 사무국에 요청 (IAM 콘솔 권한은 요청하지 않음)

2. Amazon EBS — gp3 30GB (EC2 루트 볼륨)
   → OS, 모델 파일(Gemma 3 1B·whisper, 약 1.5GB), 음성 임시 저장, 로그

3. Amazon S3 — 버킷 1개(퍼블릭 차단, 라이프사이클 7일)
   → 온디바이스 AI 모델 파일(0.5GB) 원본, 테스트 APK, 리포트 PDF, 음성 파일 임시 보관

4. Amazon CloudFront — 배포 2개(S3 오리진 / EC2 오리진), 기본 *.cloudfront.net 도메인만 사용
   → HTTPS API 엔드포인트, 모델 파일·APK 다운로드 (Route 53·ACM 미사용)

※ 추가 인스턴스 · GPU · IAM · Route 53 · ACM · Secrets Manager · Parameter Store · ElastiCache · CloudWatch · Bedrock · Transcribe · Polly · SNS · SQS · Rekognition · SES · Budgets · Backup은 신청하지 않습니다.
```

### ③ 추가 설명
```
MemoryLink는 초기 인지저하 고위험 고령자를 위한 Flutter 앱(한이음드림업)입니다. 현재 인증·데이터는 Firebase, AI 대화는 Gemini API, 음성 인지평가는 서버가 없어 차단 화면 상태입니다. 관리형 AI 서비스 없이, 오픈소스 모델을 EC2 한 대의 CPU에서 직접 실행하는 MVP 구성입니다.

[구조] 앱 → CloudFront(HTTPS) → EC2 t4g.medium 1대. 한 대 안에서 Docker로 FastAPI(API), llama.cpp(Gemma 3 1B, 대화), whisper.cpp(한국어 STT), Uptime Kuma(모니터링)를 함께 운영합니다. AWS 자격증명은 인스턴스 역할(S3 한정)만 사용하고 앱에는 키를 넣지 않으며, 환경변수는 EC2 내 .env(Git 커밋 금지), 세션 상태는 FastAPI 인메모리로 처리합니다.

[용도]
- 음성 인지평가: 앱이 올린 음성을 whisper.cpp로 전사해 발화속도·어휘다양성·휴지 비율을 산출하고 Firestore에 저장합니다.
- AI 회상대화: 기기 내 온디바이스 모델이 1순위, EC2의 llama.cpp가 저사양 기기용 폴백을 맡습니다. 앱 바이너리에 포함된 Gemini 키도 서버로 옮겨 노출을 막습니다.
- 보호자 이상감지: 앱 2곳에 흩어진 판정 로직을 서버 한 곳으로 통합하고 FCM 푸시로 알립니다.
- S3+CloudFront: 온디바이스 모델(0.5GB)을 자체 배포해 HuggingFace 토큰·약관 절차를 없애고, APK·리포트 PDF를 배포합니다.

[비용] 24시간 운영 기준 EC2 $31 + EBS·EIP $6 + S3·CloudFront $3 = 월 약 $40(≈5.6만 원, 45만 원의 13%). 고정비 중심 구성이라 사용량 급증에 따른 과금 위험이 거의 없습니다.

[확장] 10월 초 성능 실측 결과 응답 품질이 부족할 경우, 인스턴스를 추가하지 않고 동일 인스턴스의 타입 변경만 별도로 요청드리겠습니다.

[일정] 9월 4주 EC2·CloudFront·Docker 배포 → 10월 1~2주 whisper 음성평가·llama.cpp 대화 연동·성능 실측 → 10월 3~4주 이상감지 통합·온디바이스 모델 배포·최종 시연.
```

### ④ 권한 오류 메시지
```
해당 없음 — 최초 권한 신청입니다. 계정 발급 후 AccessDenied 발생 시 서비스명·API명·오류 전문을 첨부해 추가 요청하겠습니다.
```

## 5. 비용 (USD)

| 시나리오 | 9월(9/22~30) | 10월 | 10월 비율 | 2개월 비율(90만 대비) |
|---|---|---|---|---|
| t4g.medium 유지 | $12 | $40 | 13% | **8%** |
| 10월에 c7g.xlarge로 타입 변경 | $12 | $131 | 41% | 22% |

어느 경우든 50% 상한 이내. 사용량 과금은 S3·CloudFront 전송료뿐이며, 모델 다운로드는 Firebase 인증 사용자에게 1회만 허용한다.

## 6. 10월 1주 실측 기준 (타입 변경 판단)

| 지표 | 유지 | 타입 변경 요청 |
|---|---|---|
| Gemma 3 1B 생성 속도 | ≥ 8 tok/s | < 5 tok/s |
| 30초 음성 전사 시간(whisper base) | ≤ 30초 | > 60초 |
| 회상대화 한국어 품질(팀 10문항 평가) | 7/10 이상 자연스러움 | 5/10 이하 |
| 메모리 | 스왑 사용 < 500MB | OOM 발생 |

측정: `llama-bench`, `whisper-cli` 처리 시간, `docker stats`, `free -m`.

## 7. 검증

| 점검 | 결과 |
|---|---|
| "1대" 조건 | EC2 1대, 추가 인스턴스 미신청 명시. 타입 변경은 대수 불변. **통과** |
| t4g.medium 버스트 크레딧 | 기준 성능 vCPU당 20%, 시간당 24크레딧 적립, 최대 576. 가득 찬 상태에서 2vCPU 100% 연속 약 6시간 가능. 산발적 대화·전사 트래픽엔 충분. 기본 Unlimited 모드라 초과 시 스로틀 대신 소액 과금(vCPU-시간당 약 $0.04) — 시범 규모에선 월 $1 미만 예상 |
| 4GB 메모리 | 합계 약 2.3~3.0GB + 스왑 2GB. whisper small과 llama 동시 적재 시 빠듯 → 기본은 base, 필요 시에만 small |
| 1B 모델 품질 | **미검증.** 짧은 회상대화 턴에 맞춰 프롬프트를 제한. 부족하면 6절 기준으로 타입 변경 |
| CPU 성능 수치 | 전부 추정. 6절 실측으로 확정 |
| 금지 서비스 | 1·2차 불가 목록 전부 미신청 명시 |
| 비용 계산 | t4g.medium 744h $31.0 + EBS 30GB $2.7 + EIP $3.7 + S3·CF $2.8 = $40.2 ✔ / c7g.xlarge $121.4 + $9.2 = $130.6 ✔ |

## 8. v4 오류 정정 (v4 문서는 수정하지 않고 여기 기록)

| v4 위치 | v4 내용 | 정정 |
|---|---|---|
| 1절 본문, ③ [비용] | c7g.xlarge 24시간 $119 = **26%** | 45만 원 대비 **38%** (121.4 × 1,400 ÷ 450,000). A와 합치면 58%로 6절 표와는 일치했으나 본문·양식 문구가 틀렸음 |
| 2절 대안표 | c7g.large = 2vCPU / **8GB**, 약 $60 | c7g.large는 2vCPU / **4GB**, $0.0816/h (조회값). 8GB 2vCPU는 t4g.large·m7g.large |

v4 양식 텍스트를 제출했다면 ③의 "(B)를 켜둔 채 방치해도 24시간 $119(26%)" 문장만 틀린 수치입니다. 아직 제출하지 않았다면 v5를 사용하세요.
