# MemoryLink 마스터 실행계획

- **기준일:** 2026-08-30
- **예상 기간:** Gate 0 포함 14~22주(출시 안전 3~5주, 플랫폼 4~6주, 제품 가치 3~5주, 보행 파일럿 4~6주). 연구 수준 외부 검증은 별도 3~6개월 이상.
- **제품 경계:** 비의료 생활습관 지원·인지 활동·기록·자가 모니터링

## 1. 현재 기준선

| 영역 | 확인된 사실 | 계획상 의미 |
|---|---|---|
| 도구/품질 | Flutter 3.41.5, Dart 3.11.3; analyze error·warning 0; 테스트 307/307 | 신규 작업은 이 기준을 후퇴시키지 않는다. info 4는 별도 정리 가능 |
| Android | release merged manifest targetSdk 36 | 2026-08-31 Play의 새 앱/업데이트 API 36 요구에 기술적으로 부합. 실제 AAB/Play 사전검사는 별도 Gate |
| 보호자 | `guardian_views/{token}` 비인증 단일 get, token 만료·회전·폐기 없음, 일반 sync에 `emergency_contact` 저장 | 공개 capability URL의 수명·범위·PII를 Stage 1에서 재설계 |
| Firestore | 익명 사용자도 `global_stats/score_stats` 쓰기 가능 | 클라이언트 집계를 신뢰하지 않고 서버 집계 또는 제거 |
| 이상감지 | 정책 3곳 중복·임계값 불일치, 알림 await 없음, 실패 숨김 | 단일 정책·재시도·관측성 필요 |
| AI | Gemini key를 SharedPreferences 평문 저장, URL query로 직접 전송 | 출시 전 경로 결정. Firebase AI Logic 또는 자체 프록시로 분기 |
| 삭제 | 로컬·클라우드 계정/데이터 삭제 경로 불완전 | Google Play/Apple 요구와 개인정보 삭제 의무를 Stage 1 Gate로 처리 |
| 보행 | CV 실행 경로는 있으나 세션 저장·실기기 검증 없음 | 검증 전 외부 표시 금지; Stage 4에서 프로토콜·준거 대조 |
| 제품 | 리포트 날짜·영역·빈 상태 문제, `gaitStability`가 목표 달성률 | 기존 데이터 의미를 바로잡은 뒤 가치 화면화 |
| CI | stale Maestro flow/GPU 설정, 통합 테스트가 없는 `BottomNavigationBar` 단언 | CI 복구가 Stage 1 첫 구현 작업 |
| 권한 | Health는 READ만 사용, 단순 일기 알림에 exact alarm 사용 | 최소 권한·inexact alarm으로 축소 검토 |

## 2. 실행 흐름과 종속성

```text
Gate 0 (1~3일)
  ├─ 제품 주장/출시 범위 동결
  ├─ 데이터·권한·AI 경로 ADR
  └─ 기준선 재현
       ↓
Stage 1 출시 안전 (3~5주)
  CI → 주장 정리 → guardian/삭제/이상감지 → 권한/스토어 선언 → RC 증거
       ↓
Stage 2 플랫폼 강화 (4~6주)
  Rules 테스트 → 서버 집계 → FGS 분리 → AI/App Check/관측성 → 인증 강화
       ↓
Stage 3 기존 데이터 가치 (3~5주)
  데이터 의미 사전 → 타임라인/추세/리포트 → 오류 UX → 접근성
       ↓
Stage 4 보행 검증·연구 (4~6주 파일럿 + 외부 검증)
  세션 모델 → 프로토콜 → 파일럿 → 준거 대조 → 승격 심사
```

Stage 1 완료 전 공개 출시를 진행하지 않는다. Stage 2는 Stage 1과 일부 개발 병렬화가 가능하지만, Firestore/AI/삭제 계약을 먼저 동결한다. Stage 3은 데이터 정의가 확정된 뒤 시작한다. Stage 4 결과가 나오기 전 보행 CV를 위험 신호로 승격하지 않는다.

## 3. Gate 0: 계획 동결

### G0-01 주장·표면 목록
- **구분/목표:** 필수; 앱, README, 스토어, 개인정보처리방침, PDF, 보호자 화면의 모든 건강·인지·보행 주장을 한 표로 만든다.
- **근거/현재 사실:** Apple 1.4.1은 건강 측정 정확도 주장 근거를 요구한다. 현재 README에는 “예방”, “정상/경고/고위험”, “치매·낙상 위험 전조”가 있으나 MemoryLink CV 검증은 없다.
- **영향 파일:** `README.md`, `GAIT_ANALYSIS.md`, 앱 문자열, 리포트/PDF, 스토어 메타데이터(이 단계에서는 목록만 작성).
- **선행조건/구현:** 제품 책임자 지정; 각 문구를 `허용/수정/삭제/연구 전용`으로 분류하고 증거 소유자·기한 지정.
- **제외 범위:** 의료기기 허가 전략, 진단 성능 주장.
- **완료 조건/검증:** 사용자 노출 표면 100% 목록화, “치매 예방/진단/선별/조기 발견/고위험 판정” 공개 문구 0건을 목표로 승인. 문자열/문서 grep 결과 첨부.
- **예상 비용/위험/중단·롤백 조건:** 1~2인일; 마케팅 약화 우려. 근거 없는 문구는 보류가 기본이며 원문은 버전관리로 복구 가능.

### G0-02 데이터·권한 처리 지도
- **구분/목표:** 필수; 데이터 항목별 수집, 로컬/클라우드 저장, 공유, 보존, 삭제, 법적 성격을 연결한다.
- **근거/현재 사실:** 개인정보보호법 제21조(파기), 제23조(민감정보), Apple 5.1, Play Data Safety/Health Apps 선언; guardian 전화번호와 AI 대화가 외부 전송될 수 있다.
- **영향 파일:** DB schema/service, `firestore.rules`, manifests/entitlements, privacy 원본(목록화만).
- **선행조건/구현:** 데이터 owner 지정; training, diary, health, gait, voice, guardian, AI prompt/response, logs를 행 단위로 기록.
- **제외 범위:** 신규 analytics 도입.
- **완료 조건/검증:** 모든 네트워크 endpoint와 민감정보 흐름에 보존기간·삭제 방법·동의 근거가 존재. 미상 항목 0개 또는 명시적 출시 차단.
- **예상 비용/위험/중단·롤백 조건:** 2~3인일; 누락 시 삭제/정책 선언 불일치. 문서 작업이라 롤백 불필요.

### G0-03 AI 경로 ADR
- **구분/목표:** 필수; `Firebase AI Logic` 또는 `자체 서버 프록시` 중 출시 경로를 선택한다.
- **근거/현재 사실:** 현재 일반 Gemini REST 직접 호출은 사용자 키를 평문·URL query로 사용한다. Firebase AI Logic의 App Check 강제는 2026-11-02부터 적용되며 일반 REST 직접 호출을 자동 보호하지 않는다.
- **영향 파일:** `lib/core/ai/*`, `pubspec.yaml`, Firebase/서버 설정(후속 Stage).
- **선행조건/구현:** 비용, 지원 모델, 지역, 데이터 처리, 키 소유, 삭제, 쿼터, abuse, 장애 폴백 비교; 입력 데이터 최소화·제3자 AI 동의 설계.
- **제외 범위:** 두 경로를 production에서 동시에 유지.
- **완료 조건/검증:** 보안·개인정보·비용 책임자가 서명한 ADR, 위협모델, 마이그레이션/롤백 경로.
- **예상 비용/위험/중단·롤백 조건:** 2~4인일; 결정 지연은 AI 포함 출시를 차단. 미결 시 AI 기능을 출시 범위에서 제거.

### G0-04 출시 범위·SLI 동결
- **구분/목표:** 필수; 기능 플래그와 출시 품질 지표를 고정한다.
- **근거/현재 사실:** 보행/guardian/AI가 각각 별도 안전 위험을 갖고 CI에도 stale 경로가 있다.
- **영향 파일:** 릴리스 이슈/대시보드; 코드 변경 없음.
- **선행조건/구현:** 기능별 `출시/제한/비활성/연구` 상태 지정; 크래시프리 사용자·세션, 걸음 측정 시작 성공률, PDF 생성 성공률의 수집 방법과 목표를 정한다.
- **제외 범위:** 근거 없는 목표 수치 확정. 첫 RC에서 baseline을 측정한 뒤 목표를 승인한다.
- **완료 조건/검증:** 기능 플래그 표, owner, on-call/중단 기준, SLI 분모·분자·샘플링 정의.
- **예상 비용/위험/중단·롤백 조건:** 1~2인일; 계측 자체가 개인정보를 늘리지 않도록 집계 중심 설계. 기능 플래그로 롤백.

## 4. 단계별 Go/No-Go

| Gate | Go 조건 | No-Go/중단 조건 |
|---|---|---|
| Gate 0 | 주장표·데이터 지도·AI ADR·출시 범위 승인 | AI 경로/삭제 책임/guardian 공개 범위 미결 |
| Stage 1 | CI green, 계정/데이터 삭제 E2E, guardian token 수명/폐기, 최소 권한, 정책·스토어 선언 일치 | 공개 PII, 재현되지 않는 삭제, 고위험 건강 주장, RC 주요 경로 실패 |
| Stage 2 | Rules emulator deny/allow 회귀, stats 비신뢰 쓰기 제거, FGS/AI 위협모델·관측성, App Check 단계적 enforcement | 익명 교차 사용자 접근, 클라이언트 집계 신뢰, production debug token/키 노출 |
| Stage 3 | 데이터 정의·빈/오류 상태·접근성 기준 충족, PDF/차트 날짜 정확 | 오해 가능한 지표명, 건강 수치 해석/진단 권고, 접근성 핵심 경로 실패 |
| Stage 4 | 고정 프로토콜, 원시/파생 데이터 추적성, 사전 정의된 검출·재현성·결측 기준 통과 | 특정 기기/위치 편향, CV 임계값 미검증, 중대한 안전사건 또는 동의/IRB 부재 |

## 5. 릴리스 운영 규칙

- RC는 작은 내부 트랙 → 제한 베타 → 단계적 rollout 순으로 배포한다. 중대한 개인정보/보안/데이터 손상은 즉시 중단한다.
- App Check는 metrics-only/모니터링 후 enforcement하며, debug provider/token은 production 및 공개 저장소에 포함하지 않는다.
- 계정 삭제 완료는 Auth, Firestore 문서/하위 컬렉션, Storage, guardian token, 외부 AI/processor 요청, 로컬 DB/cache 각각의 결과로 증명한다.
- 연구·측정 알고리즘 변경은 앱 버전, 알고리즘 버전, 기기/OS, 센서 위치와 함께 저장한다.

## 재현 명령

PowerShell 기준이며 각 RC에서 원문 출력을 보존한다.

```powershell
flutter --version
flutter pub get
flutter analyze
flutter test --reporter compact
flutter test integration_test/
flutter build appbundle --release
Select-String -Path "build\app\intermediates\merged_manifests\release\processReleaseManifest\AndroidManifest.xml" -Pattern "targetSdkVersion"
git diff --check
git status --short
```

Maestro는 Stage 1에서 stale flow를 제거한 뒤 실제 flow 목록을 기준으로 실행한다. iOS archive/실기기 검증은 macOS/Xcode runner에서 별도 증거를 남긴다.
