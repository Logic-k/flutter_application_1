# Stage 2 — 플랫폼 보안·AI·Firestore

- **목표 기간:** 4~6주
- **진입 조건:** Stage 1 데이터 계약·AI ADR·guardian 모델 동결
- **출구 조건:** 권한경계 자동검증, 신뢰 가능한 집계, 플랫폼별 백그라운드 실행과 AI 보호·관측성

### S2-01 Firestore Rules 회귀 테스트 체계
- **구분/목표:** 필수; 규칙의 허용·거부 계약을 emulator에서 자동 검증한다.
- **근거:** Firebase 공식 `@firebase/rules-unit-testing` v9은 `initializeTestEnvironment`, 인증/비인증 context, `assertSucceeds/assertFails`, `clearFirestore`를 제공하며 production을 건드리지 않는다.
- **현재 사실:** guardian 공개 get과 익명 stats write가 핵심 위험이고 규칙 회귀 테스트가 충분하지 않다.
- **영향 파일:** `firestore.rules`, 신규 rules test/package 설정, CI.
- **선행/구현:** collection별 owner/role/capability matrix; test seed는 `withSecurityRulesDisabled`; CRUD/query/list, 교차 사용자, 필드 allowlist, token 만료를 테스트; emulator-only project 강제.
- **제외:** production 데이터 테스트, rules만으로 backend 검증 대체.
- **완료/검증:** 각 collection에 최소 1개 allow와 deny test, guardian/list/cross-user/global-stats 회귀가 CI 필수. `firebase emulators:exec --only firestore "npm test"`.
- **예상 비용/위험/중단·롤백 조건:** 4~6인일; test config 복잡도. test job만 일시 격리할 수 있으나 deny 회귀 실패 상태에서 배포 금지.

### S2-02 Global stats 신뢰 경계 재설계
- **구분/목표:** 필수; 클라이언트가 집단 통계를 임의 조작하지 못하게 한다.
- **근거:** 최소권한·서버 권위 원칙, MASVS AUTH/NETWORK.
- **현재 사실:** 익명 로그인 사용자가 `global_stats/score_stats`를 쓸 수 있다.
- **영향 파일:** rules, stats service/UI, Cloud Functions/Run 또는 집계 제거 migration.
- **선행/구현:** 제품가치·privacy 평가; 선택 A는 개인 raw score를 owner 경로에 쓰고 서버가 익명 집계, 선택 B는 백분위 기능 제거. k-anonymity/최소 표본·재집계 주기·삭제 반영 정의.
- **제외:** 클라이언트 제출 값을 검증 없이 공식 백분위로 사용.
- **완료/검증:** stats 문서 client write deny; 서버 principal만 집계; 비정상 score/중복/삭제 후 재집계 테스트. 비용/latency 관측.
- **예상 비용/위험/중단·롤백 조건:** 5~8인일; 집계 비용·소수집단 재식별. 안전 기준 미충족 시 비교 UI 제거.

### S2-03 Health와 microphone Foreground Service 분리
- **구분/목표:** 필수(백그라운드 FGS를 유지할 경우); 서비스 목적·권한·시작 조건을 분리한다.
- **근거:** Android 14/API 34+는 FGS type, type-specific permission, prerequisite를 요구한다. microphone은 `foregroundServiceType="microphone"`, `FOREGROUND_SERVICE_MICROPHONE`, `RECORD_AUDIO`, while-in-use 제한; health는 health type/permission과 ACTIVITY_RECOGNITION·Health Connect 등 조건이 필요하다.
- **현재 사실:** `background_service.dart`가 여러 책임을 가질 가능성이 있고 targetSdk 36이다. 마이크는 AI/STT에 실제 사용, Health는 read.
- **영향 파일:** AndroidManifest, service 구현, health/gait/STT lifecycle, Play FGS declaration.
- **선행/구현:** 백그라운드 필요성별 decision table; 짧은 작업은 WorkManager/foreground UI로 대체; health/microphone service 분리; background start 금지 경로와 notification channel; 사용자 stop 처리.
- **제외:** 권한만 추가해 결합 서비스를 유지, 마이크를 백그라운드 임의 시작.
- **완료/검증:** Android 14~16 실기기에서 start/stop/거부/background 전환이 예외 없이 동작; manifest와 Play FGS type 동일; `adb shell dumpsys activity services` 증거.
- **예상 비용/위험/중단·롤백 조건:** 6~10인일; OEM 제한. 백그라운드 기능을 비활성화하고 foreground 측정만 유지 가능.

### S2-04 AI gateway와 데이터 보호
- **구분/목표:** 필수(AI 유지 시); 선택한 경로의 인증·quota·삭제·안전 폴백을 완성한다.
- **근거:** Firebase AI Logic/App Check 공식 정책 또는 자체 proxy의 서버 보안 책임, Apple 제3자 AI 명시적 허가, 개인정보 국외이전 검토.
- **현재 사실:** 직접 REST/key 방식은 클라이언트 통제와 삭제·abuse 관측이 부족하다.
- **영향 파일:** AI provider/service/UI, Firebase/Cloud backend, privacy/consent, runbook.
- **선행/구현:** 사용자별 pseudonymous ID; prompt 최소화와 민감정보 redaction; rate/size/model allowlist; timeout/retry/circuit breaker; provider retention/지역/삭제 계약; 안전 응답과 위기 문구 처리.
- **제외:** AI를 의료상담·진단으로 제시, 원문 일기/건강 데이터를 기본 전송.
- **완료/검증:** 동의 철회 후 전송 0건; quota·invalid token·provider 5xx·timeout 테스트; 로그에 prompt/key/전화번호 없음; 삭제 요청 trace.
- **예상 비용/위험/중단·롤백 조건:** 8~15인일; 비용·오탐·서비스 중단. AI off와 로컬 고정 콘텐츠로 degrade.

### S2-05 App Check 단계적 강화와 replay 검토
- **구분/목표:** 권장, Firebase AI Logic 선택 시 시한상 필수; 검증되지 않은 앱 트래픽을 관측 후 차단한다.
- **근거:** production provider는 Android Play Integrity, Apple App Attest/DeviceCheck. replay protection의 limited-use token은 요청별 발급으로 지연·비용 증가. 문서상 Flutter 최소 버전은 AI Logic 4.15.0+, App Check 4.10.0+.
- **현재 사실:** App Check 미도입. 일반 Gemini REST 직접 호출은 App Check 보호 대상이 아니다.
- **영향 파일:** Flutter dependencies/init, Firebase console, CI/dev docs.
- **선행/구현:** SDK compatibility spike; debug provider를 로컬/CI에만 분리; valid/invalid metrics; 주요 backend→AI 순으로 enforcement; high-value endpoint만 replay A/B.
- **제외:** debug token commit, 첫날 전면 enforcement, 모든 요청에 replay 일괄 적용.
- **완료/검증:** production debug token 0, legit 기기 성공률/403 baseline과 rollback threshold 승인, invalid attestation deny. Console metrics와 실기기 matrix.
- **예상 비용/위험/중단·롤백 조건:** 4~7인일; 정상 기기 차단. AI Logic의 2026-11-02 이후 enforcement는 해제 불가이므로 사전 호환성 확보; 기타 Firebase는 단계별 unenforce/feature flag.

### S2-06 Secret·로그·관측성 정책
- **구분/목표:** 필수; 민감정보 없는 운영 신호로 장애를 탐지한다.
- **근거:** Apple 1.6/5.1, MASVS STORAGE/NETWORK/PRIVACY.
- **현재 사실:** API key가 평문 저장되고 alert 실패가 silent하며 SLI 계측이 없다.
- **영향 파일:** logging wrapper, crash/reporting 설정, AI/guardian/anomaly/PDF/gait services, secret scan CI.
- **선행/구현:** event taxonomy와 금지 필드; URL query/body redaction; correlation ID; guardian delivery/PDF/gait start/AI 상태 code; retention/access control; repository/binary secret scan.
- **제외:** raw prompt, diary, health values, 전화번호, token을 운영로그에 저장.
- **완료/검증:** synthetic failure가 dashboard/alert에 나타나고 payload inspection에 PII/secret 0; SLI 계산 재현; log retention 자동 삭제.
- **예상 비용/위험/중단·롤백 조건:** 5~8인일; 과도한 logging 비용. sampling/feature flag로 축소하되 안전 실패 지표는 유지.

### S2-07 로컬 인증·세션 보안
- **구분/목표:** 권장; SharedPreferences/SQLite 중심 인증의 위협을 줄이고 클라우드 소유권과 일치시킨다.
- **근거:** MASVS STORAGE/CRYPTO/AUTH; Apple은 얼굴 인증에 가능한 경우 LocalAuthentication 사용을 요구한다.
- **현재 사실:** 로컬 SQLite 계정+Firebase Anonymous Auth 혼합, SharedPreferences 자동 로그인 사용.
- **영향 파일:** auth services, DB/preferences, Android Keystore/iOS Keychain adapter, biometric UI, migration/tests.
- **선행/구현:** 위협모델(분실/백업/루팅/세션 고정); 비밀번호/토큰 평문 여부 확인; secure storage; biometric은 편의 unlock이며 대체 인증 제공; anonymous UID migration/삭제 규칙.
- **제외:** 생체정보 자체 수집, biometric을 유일 복구수단으로 사용.
- **완료/검증:** 민감 token 평문 0, logout/delete 후 token 무효, backup/restore·시간만료·UID 변경 테스트.
- **예상 비용/위험/중단·롤백 조건:** 6~10인일; migration lockout. 버전형 migration과 복구코드/재로그인, 실패 시 cloud 기능 제한 모드.

### S2-08 의존성·공급망 정리
- **구분/목표:** 권장; 사용하지 않는 직접 의존성과 알려진 major 격차를 통제한다.
- **근거:** MASVS CODE/RESILIENCE, 최소 공격면 원칙.
- **현재 사실:** 직접 import 0인 `google_generative_ai`, `google_fonts`, `audioplayers`, `record`가 제거 후보이고 `flutter_gemma`는 사용 중이다. Firebase/Health/Gemma major upgrade 격차가 있다.
- **영향 파일:** `pubspec.yaml`, lockfile, imports/build config, SBOM.
- **선행/구현:** dependency graph/SBOM; 하나씩 제거/upgrade; release size와 기능 회귀 비교; exact version/pinned 정책.
- **제외:** 한 번에 모든 major upgrade, 이름이 유사한 미검증 패키지 도입.
- **완료/검증:** import 0 직접 의존성 제거 또는 유지 사유 기록; analyze/test/AAB/iOS build; SBOM과 취약점 triage.
- **예상 비용/위험/중단·롤백 조건:** 4~8인일; transitive break. 변경별 작은 PR과 lockfile 롤백.

## Stage 2 보안 Gate

OWASP MASVS 체크리스트를 최소 `STORAGE, AUTH, NETWORK, PLATFORM, PRIVACY`에 매핑하고 각 항목에 코드·테스트·설정 증거 링크를 둔다. 미해결 high severity 또는 교차 사용자 접근이 있으면 Stage 3 배포를 중단한다.
