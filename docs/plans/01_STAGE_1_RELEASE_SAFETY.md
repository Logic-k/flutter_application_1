# Stage 1 — 출시 안전·규제·개인정보

- **목표 기간:** 3~5주
- **진입 조건:** [Gate 0](00_MASTER_EXECUTION_PLAN.md#3-gate-0-계획-동결) 승인
- **출구 조건:** 보안·개인정보·스토어 정책상 치명 위험 제거, RC 핵심 경로 증거 확보

## 우선순위

`S1-01 CI → S1-02 주장 → S1-03 guardian → S1-04 삭제 → S1-05 이상감지 → S1-06 권한/스토어 → S1-07 AI 조건부 → S1-08 RC`

### S1-01 CI와 자동화 기준선 복구
- **구분/목표:** 필수; 실패가 제품 회귀를 실제로 탐지하는 CI로 복구한다.
- **공식/연구 근거:** Apple은 제출 전 실기기 안정성과 완성도를 요구한다. 프로젝트 Gate는 analyze/test/build green을 요구한다.
- **현재 코드 사실:** `.github/workflows/maestro.yml`이 삭제된 `maestro/social_ranking_flow.yaml`과 부적절한 GPU 설정을 사용하고, `integration_test/auth_flow_test.dart`는 현재 UI의 `FloatingPillNav` 대신 없는 `BottomNavigationBar`를 단언한다.
- **영향 파일:** `.github/workflows/test.yml`, `.github/workflows/maestro.yml`, `run_maestro_tests.ps1`, `integration_test/auth_flow_test.dart`, 관련 flow.
- **선행조건/구현 작업:** 실제 flow inventory 작성; stale 참조 수정; 통합 테스트를 의미 기반 finder/실제 widget으로 갱신; unit/widget/integration/Maestro를 필수·실기기 job으로 분리; artifact 보존.
- **제외 범위:** 신규 기능 테스트 확대, 전면 프레임워크 교체.
- **완료 조건:** 기본 브랜치 PR에서 analyze/unit/widget/build가 green이고, Maestro job이 존재하는 flow만 실행하며 실패 artifact를 남긴다.
- **검증:** `flutter analyze`; `flutter test --reporter compact`; `flutter test integration_test/`; `maestro test <검증된-flow>`; workflow dry-run/실제 CI 링크.
- **예상 비용/위험/중단·롤백 조건:** 3~5인일; emulator flaky 위험. 2회 이상 비결정 실패면 필수 gate와 quarantine을 분리하고 원인 이슈를 연결한다. workflow 이전 버전으로 롤백 가능.

### S1-02 비의료 주장과 개인정보 고지 정합화
- **구분/목표:** 필수; 앱·PDF·보호자·스토어·웹의 표현과 실제 데이터 처리를 일치시킨다.
- **근거:** Apple 1.4.1은 건강 측정 정확도 주장의 검증을 요구하고 2.3은 정확한 metadata를 요구한다. SUPERBRAIN-MEET과 CCT 연구는 MemoryLink 단독 효과를 입증하지 않는다.
- **현재 사실:** README의 예방·정상/경고/고위험·치매 전조 표현, `임상 리포트` 명칭, 검증 전 CV 외부 노출 가능성이 제품 경계를 넘는다. `site/privacy.html`과 `landing/privacy.html`은 canonical 외 내용이 같다.
- **영향 파일:** 앱 문자열/리포트/PDF, `README.md`, `GAIT_ANALYSIS.md`, `site/privacy.html`, `landing/privacy.html`, Play/App Store metadata.
- **선행/구현:** G0 주장표 승인; 허용 문구 사전 작성; “생활습관 기록/인지 활동/참고 정보”로 교체; AI 제3자 전송·guardian 공유·보존/삭제를 고지; 두 privacy 원본의 source-of-truth 운영 규칙 결정.
- **제외:** 의료기기 효능 주장, 연구결과를 광고 문구로 전환.
- **완료/검증:** 금지 표현과 검증 전 CV 위험판정 공개 노출 0건; 앱/웹/스토어 Data Safety·App Privacy 응답의 필드 단위 대조표 승인. `rg` 또는 `Select-String`으로 문구 검사, 화면/PDF snapshot 검토.
- **예상 비용/위험/중단·롤백 조건:** 4~7인일; 검색 노출 감소 가능. 안전 문구로 즉시 롤백하되 근거 없는 원문 복원 금지.

### S1-03 Guardian 최소수집과 capability token 수명주기
- **구분/목표:** 필수; 비인증 capability URL의 노출 반경을 제한하고 전화번호 상시 저장을 제거한다.
- **근거:** 개인정보 최소화, 접근통제, Apple 1.6/5.1; OWASP MASVS AUTH/PRIVACY/STORAGE.
- **현재 사실:** rules의 `guardian_views/{token}`에 `allow get: if true`, list만 차단. 일반 sync가 `'emergency_contact': emergencyContact ?? ''`를 항상 저장하고 token 만료·회전·폐기가 없다.
- **영향 파일:** `firestore.rules`, `lib/core/services/guardian_sync_service.dart`, guardian link/view UI, 데이터 migration/테스트.
- **선행/구현:** 공유 필드 allowlist; 전화번호 별도 opt-in/기본 미수집; 128-bit 이상 난수 token, `expiresAt`, `revokedAt`, `createdBy`, schema/version; 재연결 시 rotation; 로그/analytics에 token 금지; 가능한 경우 인증 보호자 모델로 이행.
- **제외:** 보호자 의료 판단·실시간 응급서비스 제공.
- **완료/검증:** 만료/폐기/회전 token deny, 새 token만 최소 필드 get, list/query deny, 전화번호 미동의 문서에 필드 없음. Firestore emulator allow/deny 테스트와 유출 token 폐기 E2E.
- **예상 비용/위험/중단·롤백 조건:** 5~8인일; 기존 링크 단절. grace period를 두되 구 token은 짧은 TTL 후 폐기. 문제 시 guardian 공유 기능 플래그 off.

### S1-04 계정 및 데이터 삭제 완결성
- **구분/목표:** 필수; 인앱 삭제와 재설치 없는 웹 요청 경로를 제공하고 실제 삭제를 증명한다.
- **근거:** Google Play는 앱에서 계정 생성 시 인앱 삭제와 웹 삭제 요청 URL을 요구한다. Apple 5.1.1(v)는 인앱 계정 삭제를 요구한다. 개인정보보호법 제21조. Firestore TTL은 완료 보장이 아니다.
- **현재 사실:** 로컬 SQLite 계정과 Firebase Anonymous Auth/Firestore가 혼재하며 로컬·클라우드·guardian 전체 삭제 경로가 없다.
- **영향 파일:** 인증/설정 UI, DB helper, Firestore/Storage/Cloud backend, guardian service, privacy/web delete page, 테스트.
- **선행/구현:** 데이터 지도 승인; 재인증/오조작 방지; 로컬 DB·preferences·cache, Auth, Firestore top-level/subcollections, Storage, token, processor 요청을 idempotent job으로 삭제; 상태/실패 재시도; 합법 보존 항목은 범위·기간·근거 고지.
- **제외:** TTL만으로 완료 처리, 단순 로그아웃을 삭제로 표시.
- **완료/검증:** 삭제 요청 후 재로그인/재설치에도 사용자 데이터가 복원되지 않고 guardian token deny. 성공·부분실패·재시도 E2E, emulator inventory diff, 웹 URL 비로그인 제출 시험.
- **예상 비용/위험/중단·롤백 조건:** 8~12인일; 비가역 데이터 손실. preview/확인/backup 제외 정책을 명확히 하고 production destructive test는 전용 계정에서만 수행. 삭제 실패 시 “완료” 표시 금지.

### S1-05 이상감지 정책 단일화와 신뢰성
- **구분/목표:** 필수; 중복 임계값을 하나의 버전 정책으로 통합하고 알림 실패를 관측·재시도한다.
- **근거:** 안전 관련 기능은 예측 가능성·추적성 필요; MASVS CODE/NETWORK/PRIVACY.
- **현재 사실:** `pedometer_manager.dart`, `anomaly_monitor_service.dart`, guardian 경로에 정책이 중복되고 임계값이 다르다. `GuardianSyncService().syncAnomalyAlert(...)`를 await하지 않고 `catch (_)`로 실패를 숨긴다.
- **영향 파일:** 위 서비스들과 정책 model/test, local queue/logging.
- **선행/구현:** 제품 경계상 “이상/위험” 대신 “평소 활동과 차이” 문구 검토; 순수 함수 정책+version; 최소 표본/결측/시간대 정의; await 또는 durable outbox; 지수 backoff·중복방지·사용자 확인.
- **제외:** 임상 위험 예측, 긴급 구조 보장.
- **완료/검증:** 모든 호출이 단일 정책을 사용하고 silent catch 0건; offline→online 재전송, 중복 전송 방지, 실패 지표/사용자 상태 표시 테스트.
- **예상 비용/위험/중단·롤백 조건:** 5~8인일; 알림 과다/누락. shadow evaluation 후 전환하고 feature flag로 기존 정책 복귀 가능.

### S1-06 최소 권한·알람·Health 선언
- **구분/목표:** 필수; 실제 기능에 필요한 권한만 요청하고 Play 선언과 일치시킨다.
- **근거:** Android는 대부분의 일반 알림에 inexact alarm을 권장하며 exact alarm은 정시 동작이 핵심인 알람/캘린더 등에 제한한다. Health Connect는 최소 data type과 상세 정당화, Data Safety, Health Apps form을 요구한다.
- **현재 사실:** Health 접근은 `[HealthDataAccess.READ]`; `WRITE_STEPS`와 iOS `health-records` entitlement는 제거 후보. 일기 알림이 `exactAllowWhileIdle`을 쓰지만 `inexactAllowWhileIdle` fallback이 있다. `RECORD_AUDIO`는 실제 STT 기능에 사용된다.
- **영향 파일:** Android manifest, iOS Info.plist/entitlements, `diary_notification_service.dart`, health/STT UI, Play declarations.
- **선행/구현:** 기능-권한 표; WRITE/medical entitlement 제거 검증; 일기 알림을 inexact 기본으로 전환; microphone은 사용 직전 요청·대체 입력 제공; Health privacy link와 앱 내 policy 동일화.
- **제외:** 사용 중인 마이크 권한 제거, exact 시각 보장 약속.
- **완료/검증:** release manifest/entitlements에 미사용 권한 0개; 권한 거부 시 핵심 앱 사용 가능; Play Health form의 data type이 런타임 요청과 동일. clean install 실기기 테스트.
- **예상 비용/위험/중단·롤백 조건:** 3~5인일; OEM 알림 지연. UX로 “대략 이 시간” 고지; 기능 회귀 시 사용자 선택형 exact 요구가 정당한지 재심사.

### S1-07 AI 출시 경로 이행과 App Check 시한
- **구분/목표:** G0-03에서 AI 포함 결정 시 필수; 클라이언트 키 노출을 없애고 abuse/삭제/동의를 갖춘다.
- **근거:** Firebase AI Logic은 2026-11-02부터 App Check enforcement가 자동·필수이며 해제 불가. Apple 5.1.2는 제3자 AI 공유를 명시하고 명시적 허가를 요구한다.
- **현재 사실:** key가 SharedPreferences 평문이고 `?key=` URL query로 전송된다.
- **영향 파일:** `lib/core/ai/ai_key_service.dart`, `gemini_provider.dart`, AI consent/UI, Firebase 또는 자체 backend, dependencies.
- **선행/구현:** ADR 선택. Firebase 경로면 지원 SDK 버전·Play Integrity/App Attest·debug token 분리·metrics 후 enforcement. 자체 프록시면 Secret Manager, 사용자 quota, payload 최소화, 삭제/retention, moderation, timeout/circuit breaker, audit를 구현.
- **제외:** App Check가 일반 REST를 보호한다고 가정, production debug provider, 사용자 key 평문 유지.
- **완료/검증:** 바이너리/로그/URL에 API key 없음; 미승인 AI 전송 차단; invalid attestation/초과 quota deny; provider 장애 시 안전 폴백. proxy/SDK 통합 테스트와 secret scan.
- **예상 비용/위험/중단·롤백 조건:** 8~15인일; 비용·모델 호환성. AI feature flag off 및 로컬 비AI 안내로 롤백.

### S1-08 Release Candidate 증거 패키지
- **구분/목표:** 필수; 스토어 제출 판단을 재현 가능한 증거로 만든다.
- **근거:** Play target API/Health declaration, Apple review completeness/privacy/health accuracy, 내부 Gate.
- **현재 사실:** merged manifest target 36과 테스트 기준선은 확인됐지만 최신 AAB 업로드/사전검사와 전체 실기기 시나리오는 미확인.
- **영향 파일:** release artifact/checklist/스토어 콘솔(제품 파일 수정과 분리).
- **선행/구현:** S1-01~07; signed AAB/IPA, SBOM/secret scan, 정책 대조표, 삭제/guardian/PDF/걷기 시작/알림/STT 실기기 matrix, SLI baseline 수집.
- **제외:** 보행 CV 임상 검증 통과 주장.
- **완료/검증:** targetSdk 36 AAB가 Play pre-review를 통과하고 주요 경로 P0/P1 결함 0; Apple review용 demo/설명; rollout 중단 기준 승인.
- **예상 비용/위험/중단·롤백 조건:** 5~8인일; 스토어 정책 재검토 가능. staged rollout 중단, 기능 플래그 off, 이전 안정 버전 유지.

## Stage 1 최종 체크

- [ ] 공개 PII/capability token에 만료·폐기·최소 필드가 적용됨
- [ ] 계정 삭제가 로컬·Auth·Firestore subcollection·Storage·guardian·processor를 포함함
- [ ] AI key·debug token이 앱/로그/저장소에 없음
- [ ] 건강·인지·보행 문구가 비의료 경계와 일치함
- [ ] Health/마이크/알람 권한과 스토어 선언이 실제 호출과 일치함
- [ ] CI와 RC 실기기 증거가 존재함
