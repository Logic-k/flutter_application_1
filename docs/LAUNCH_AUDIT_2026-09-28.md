# MemoryLink Android / Google Play 출시 감사 및 실행 명세

> **감사 기준시각:** 2026-09-28 23:01 KST  
> **대상 저장소:** `E:\Test_Android\flutter_application_1`  
> **대상 패키지:** `com.teammemorylink.memorylink`  
> **대상 앱:** Android 휴대전화용 MemoryLink  
> **독자:** Claude Code, Codex, Kiro 등 저장소를 직접 수정·검증하는 코딩 에이전트와 Play Console 담당자  
> **현재 판정:** **NO-GO — 아래 P0 Gate를 모두 닫기 전 공개 출시 또는 프로덕션 승격 금지**

이 문서는 단순 체크리스트가 아니라 **현재 코드의 결함 근거, 수정 범위, 검증 명령, Play Console 작업과 최종 완료 조건**을 한곳에 고정한 실행 계약이다. 기존 `PLAY_CONSOLE.md`, `RELEASE_CHECKLIST.md`, `DEVELOPMENT_ROADMAP.md`, `docs/plans/*`와 충돌하면 이 문서의 2026-09-28 실측 사실을 우선하되, 코드가 바뀐 뒤에는 다시 측정한다. 정책은 항상 Play Console에 표시되는 현재 요구와 이 문서 §12의 공식 원문을 최종 기준으로 삼는다.

---

## 0. 에이전트 실행 규칙

1. **P0를 순서대로 처리한다.** P1/P2 기능 개선 때문에 P0 출시 안전 작업을 미루지 않는다.
2. 각 항목은 `코드 수정 → 자동 테스트 → release 산출물 검사 → 필요한 실기기/Console 증거`가 모두 있어야 완료다. 코드만 바꾸고 체크하지 않는다.
3. 사용자 데이터 삭제, Firestore 운영 규칙 배포, 키 회전, Play 프로덕션 배포는 비가역 또는 운영 영향이 있으므로 담당자의 명시적 승인 후 실행한다.
4. 키·토큰·실사용자 데이터는 명령행, 커밋, 로그, 스크린샷에 넣지 않는다. 예시는 `<UPLOAD_KEY_PASSWORD>` 같은 placeholder만 쓴다.
5. `android/app/google-services.json`에는 실제 패키지와 일치하는 client가 이미 있다. 첫 번째 legacy client가 `com.example.flutter_application_1`, 두 번째가 `com.teammemorylink.memorylink`다. **“첫 client가 다르다”는 이유만으로 Firebase가 깨졌다고 판정하지 않는다.** 필요하면 legacy client만 Firebase Console에서 정리한다.
6. `SCHEDULE_EXACT_ALARM`과 `USE_EXACT_ALARM`을 혼동하지 않는다. 후자는 Play 허용 용도가 더 제한적이지만, 현재 앱의 일기 리마인더는 어느 exact alarm도 필요하지 않다.
7. 보호자 URL은 현재 “앱 설치 없이 브라우저로 보는 웹 대시보드”다. 이 설계를 유지할 경우 App Link를 고치는 것이 아니라 **앱의 guardian intent-filter를 제거**한다.
8. 완료 증거는 `docs/release/evidence/<versionCode>/` 같은 별도 디렉터리에 명령 원문 출력, 스크린샷, Play pre-review 결과, 실기기 매트릭스로 보존한다. 비밀 값과 실제 건강 데이터는 넣지 않는다.

---

## 1. 2026-09-28 실측 기준선

### 1.1 빌드 식별자

| 항목 | 현재 값 | 근거/판정 |
|---|---:|---|
| applicationId / namespace | `com.teammemorylink.memorylink` | `android/app/build.gradle.kts` |
| 앱 라벨 | `MemoryLink` | release merged manifest |
| 버전 | `1.0.0 (1)` | `pubspec.yaml`, release merged manifest |
| minSdk | 26 (Android 8.0) | release merged manifest |
| compileSdk / targetSdk | 36 / 36 | Flutter 3.41.5 + release APK/merged manifest 실측; 2026-08-31 이후 phone 신규/업데이트 요건 충족 |
| Flutter / Dart | 3.41.5 / 3.11.3 | `flutter --version` |
| AGP / Kotlin / Java target | 8.11.1 / 2.2.20 / 17 | `android/settings.gradle.kts`, app Gradle |
| NDK | 28.2.13676358 | Flutter SDK 기본값 |

> 공식 target API 문서는 필요 시 2026-11-01까지 extension 신청 가능성을 안내하지만, 이 앱은 이미 target 36이므로 연장을 출시 우회 수단으로 사용하지 않는다.

### 1.2 품질·산출물 실측

| 검사 | 2026-09-28 결과 | 판정 |
|---|---|---|
| `flutter analyze` | info 4건, 기본 명령 exit 1 | 기능 오류는 아니나 “기본 명령 green” Gate는 실패. CI는 `--no-fatal-infos`로 우회 중 |
| `flutter test --reporter compact` | exit 0 | 단위/위젯 테스트 통과. hit-test warning 1건은 별도 정리 |
| Android integration | 4개 중 3개 통과 | `auth_flow_test.dart`의 로그인 성공 케이스가 `FloatingPillNav`를 찾지 못해 실패. CI Gate 실패 상태 |
| release AAB | 성공, 70.5MB | `build/app/outputs/bundle/release/app-release.aab` |
| release APK | 성공, 87.0MB | `build/app/outputs/flutter-apk/app-release.apk` |
| release 서명 | 현재 로컬 artifact는 예상 업로드 키로 서명됨 | SHA-1 `6A:9A:38:51:EC:45:A9:E7:FA:76:41:63:3C:A9:CB:A1:E7:02:89:2C` |
| APK signature | v2 검증 성공 | minSdk 26 설치에 유효; Play는 배포 APK를 Play App Signing key로 다시 서명 |
| 64-bit | `arm64-v8a`, `x86_64` 포함; `armeabi-v7a`도 포함 | 64-bit 요건 충족 |
| 16KB ZIP alignment | PASS | `zipalign -c -P 16 -v 4` 성공 |
| 16KB ELF alignment | **FAIL** | `arm64-v8a/libllm_inference_engine_jni.so` 최소 LOAD align `2**12`; 요구값 `2**14` 이상 |
| 배포 privacy URL | HTTP 접근 성공 | `https://memorylink-7af26.web.app/privacy.html` |
| 배포 deletion URL | HTTP 접근 성공 | `https://memorylink-7af26.web.app/delete-account.html` |
| Digital Asset Links | HTTP 200이지만 본문 `[]` | 앱과 연결된 statement가 없으므로 App Link 검증 불가 |

### 1.3 이미 양호한 점

- release merged manifest의 `targetSdkVersion=36`은 현재 phone 앱 요구를 만족한다.
- release AAB/APK 빌드, R8 minify, resource shrink가 성공한다.
- 현재 로컬 RC artifact는 release upload key로 서명됐고 64-bit ABI를 포함한다.
- `RECORD_AUDIO`는 일기/AI 채팅/문장 읽기 STT에서 실제 사용한다. 무조건 삭제할 권한이 아니다.
- 광고 SDK, Analytics, Crashlytics, `AD_ID` 사용은 확인되지 않았다.
- 릴리스 DB에는 admin/demo 계정을 시드하지 않는다(`kReleaseMode` 가드 존재).
- 개인정보처리방침과 삭제 안내 URL은 공개 접근 가능하다. 문제는 **내용과 실제 처리의 불일치**다.
- Firestore의 일반 문의·난이도 문서는 `authorUid`/`ownerUid` 기반 기본 소유권 검사가 있고 마지막 catch-all은 deny다.

---

## 2. 공개 출시 차단 항목 요약

| ID | 차단점 | 현재 근거 | 출시 위험 |
|---|---|---|---|
| P0-00 | 2026-09-30 Play 패키지 등록 상태 미확인 | 공식 Android developer verification 기한 | 미등록 패키지 Play 제거/배포 차단 가능 |
| P0-01 | 출시 기능 범위가 동결되지 않음 | Health Connect는 선언만, AI/Gemma/Guardian은 정책·보안 미완 | 신고와 바이너리가 계속 어긋남 |
| P0-02 | CI/E2E red | stale Maestro flow + integration 1건 실패 | 회귀를 막지 못하고 프로덕션 준비 답변 불가 |
| P0-03 | 사용자 opt-in 전 재부팅 시 health FGS 자동 시작 가능 | `autoStartOnBoot` 기본값 true, 앱은 값 미지정 | 권한 예외·배터리·백그라운드 정책·신뢰 위반 |
| P0-04 | 알림 선택과 동작이 깨짐 | off preference 무시 재예약, 알림 탭 콜백 미연결 | 사용자의 거부가 무효, “탭하여 문자” 기능 불작동 |
| P0-05 | Guardian 공개 capability 수명/최소수집 미비 | 영구 16자 token, public get, 정상 sync에도 phone/ownerUid 저장 | 링크 유출 후 건강·연락처 무기한 노출 |
| P0-06 | 익명 사용자가 global stats를 임의 쓰기 가능 | `allow write: if isSignedIn()` | 데이터 무결성·남용·비용 위험; 기능은 이미 UI에서 삭제됨 |
| P0-07 | 삭제·백업·익명 UID 수명주기 불완전 | 전체 삭제 없음, `allowBackup` 기본 true, 재설치 시 UID orphan | “로컬 전용/앱 삭제 시 파기/7일 삭제” 약속 불이행 |
| P0-08 | Data safety 및 privacy 답안이 실제 코드와 다름 | 자동 난이도 sync, Firebase Auth, Gemini/HF 경로 누락 | 허위 또는 불완전 신고로 거절/집행 가능 |
| P0-09 | Android Health Connect 신고가 거짓 상태 | READ/WRITE 선언, Android 권한 요청 0건, 실제 Health read는 iOS callback뿐 | 미사용 민감 권한, Health permission 심사 실패 |
| P0-10 | AI 생성 콘텐츠 정책 미충족 | Gemini/Gemma chatbot 있으나 인앱 신고/flag 0건 | AI-Generated Content 정책 위반 |
| P0-11 | 16KB ELF 실패 | `libllm_inference_engine_jni.so` align `2**12` | 16KB 기기 실행 불가; 2027-02-01부터 비호환 업데이트 차단 |
| P0-12 | Android package visibility queries 누락 | STT RecognitionService/TTS_SERVICE query 0건 | Android 11+ 일부 기기에서 STT/TTS 탐색·동작 실패 |
| P0-13 | Guardian App Link 설계가 자기모순 | 웹 링크를 앱이 가로채지만 `/guardian.html` route 없음 | assetlinks를 고치면 오히려 보호자 링크가 앱 오류로 진입 |
| P0-14 | release가 debug signing으로 조용히 폴백 | key 부재 시 `signingConfigs.debug` | 잘못 서명된 “release” artifact를 RC로 오인 |
| P0-15 | 비의료 건강 앱 경계와 공개 문구 불일치 | “예방/임상/의료진용/현재 건강 상태/음성 진단” 잔존 | Health policy·metadata 오인, 의료기기 주장 위험 |
| P0-16 | 스토어 필수 자산/최신성 미완 | feature graphic 없음, root screenshot은 삭제된 social ranking/구 UI | 등록정보 미완 또는 오해 유발 metadata |

**권장 최소 출시 범위:** 첫 공개 RC에서는 (1) Android Health Connect 권한 제거, (2) 규칙 기반 로컬 대화만 유지하고 Gemini/Gemma UI를 feature flag off 또는 제거, (3) Guardian은 보안 재설계를 완료하지 못하면 feature flag off, (4) pedometer는 명시적 사용자 토글 후에만 FGS를 시작한다. 이 범위가 가장 빠르게 정책·16KB·데이터 흐름을 단순화한다.

---

## 3. P0 구현 작업 패키지

### P0-00 — **사람이 즉시 수행:** 개발자 신원 및 패키지 등록 확인

**기한:** 2026-09-30. 코드 작업보다 먼저 Play Console에서 확인한다.

1. Play Console `Home` 또는 `Android developer verification`으로 이동한다.
2. 개발자 identity verification 상태가 완료인지 확인한다.
3. `com.teammemorylink.memorylink`가 **Registered/자동 등록 완료**인지 확인한다.
4. 자동 등록되지 않았으면 Console이 제공하는 key 선택 및 signed APK challenge 절차를 즉시 수행한다.
5. 계정 연락 이메일·전화번호가 verified인지 확인한다.
6. 신규 개인 계정이면 실물 Android 10+ 비루팅 기기에서 Play Console 앱의 device verification도 완료한다.
7. 공식 계정 안내는 Health 앱(예: Medical 또는 Human Subjects Research)을 제공하는 경우 organization 계정을 선택하도록 안내하지만, 모든 비의료 wellness 앱에 일률적으로 강제된다고 단정하지 않는다. 실제 운영 주체와 Play Console prompt를 기준으로 Personal/Organization 및 D-U-N-S 필요 여부를 확정한다.

**증거:** 패키지명과 상태가 함께 보이는 Console 캡처(개발자 PII는 마스킹).

### P0-01 — 출시 범위 ADR 동결

`docs/release/ANDROID_RELEASE_SCOPE.md`를 만들고 다음을 한 줄 선택으로 고정한다.

| 기능 | 권장 첫 RC | 다른 선택의 필수 조건 |
|---|---|---|
| Android Health Connect | OFF; manifest의 `health.READ_STEPS/WRITE_STEPS` 제거 | ON이면 실제 `requestAuthorization`, READ-only 최소권한, 거부 UX, Play permission justification, 실기기 검증 |
| Background step tracking | ON, 사용자 토글 후에만 | FGS 선언 영상과 Android 14~16 검증 필수 |
| Guardian web sharing | 보안 작업 완료 시 ON, 아니면 OFF | TTL/회전/폐기/최소필드/삭제 E2E 필수 |
| Gemini online chat | OFF 권장 | prominent disclosure/consent, secure credential 또는 gateway, Data safety, 신고/moderation 필수 |
| Gemma on-device chat | OFF 권장 | 16KB-compatible native library, ABI gate, 모델 integrity/license/storage 테스트, AI 신고 기능 필수 |
| Local rule-based dialog | ON 가능 | 생성형 AI처럼 광고하지 말고 실제 기능명 사용 |
| “임상/진단/예방” 표현 | OFF | 의료기기 규제 증빙 없이는 활성화 금지 |

선택하지 않은 기능은 버튼만 회색으로 남기지 말고 production UI·route·store screenshot·description에서 숨긴다. “출시 예정”, “정확도 개선 중” 같은 막힌 화면은 리뷰 완성도를 떨어뜨린다.

### P0-02 — CI와 E2E를 실제 제품과 일치시키기

**현재 결함**

- `.github/workflows/maestro.yml`이 삭제된 `maestro/social_ranking_flow.yaml`을 실행한다.
- CI 목록은 로컬 정본 `run_maestro_tests.ps1`과 다르고 `opening_flow`, `dementia_center_flow`가 빠져 있다.
- CI는 저장소 실측에서 불안정했던 `swiftshader_indirect`를 쓴다.
- `integration_test/auth_flow_test.dart` 로그인 성공 케이스가 실제 에뮬레이터에서 `FloatingPillNav`를 찾지 못했다.
- CI에는 release AAB/merged manifest/16KB 검사가 없다.

**수정 파일**

- `.github/workflows/maestro.yml`
- `.github/workflows/test.yml`
- `run_maestro_tests.ps1`
- `integration_test/auth_flow_test.dart`
- 필요 시 공용 `scripts/verified_maestro_flows.*`

**작업**

1. Maestro 게이팅 목록의 단일 source of truth를 만든다. CI와 PowerShell이 같은 목록을 읽게 한다.
2. 존재하지 않는 flow 참조를 0건으로 만든다.
3. integration 성공 단언을 현재 route/onboarding 상태와 실제 위젯 semantics에 맞춘다. 단순히 실패 단언을 삭제하지 않는다.
4. PR Gate를 `analyze → unit/widget → integration → debug Maestro → unsigned/signed release validation` 순으로 분리한다.
5. 에뮬레이터 flaky job은 quarantine을 별도로 두되 핵심 로그인/가입/훈련/권한 거부/삭제는 필수 Gate로 유지한다.
6. API 36 job과 16KB 이미지 job을 추가한다. x86 debug만으로 arm64 native 결함을 검증했다고 표시하지 않는다.

**완료 조건**

```powershell
flutter analyze
flutter test --reporter compact
flutter test --dart-define=IS_EMULATOR=true integration_test/auth_flow_test.dart integration_test/training_flow_test.dart -d <device-id>
.\run_maestro_tests.ps1
flutter build appbundle --release
```

모두 exit 0이고 CI가 존재하는 flow만 실행해야 한다. `flutter analyze --no-fatal-infos`만 통과하고 기본 명령이 실패하는 상태를 최종 green으로 부르지 않는다.

### P0-03 — 사용자 동의 전 boot FGS 자동 시작 차단

**근거**

- `PedometerBackgroundService.initializeService()`는 실제 기기 bootstrap에서 로그인/토글과 무관하게 `configure()`를 호출한다.
- 코드에는 `autoStart: false`만 있다.
- 설치된 `flutter_background_service_platform_interface`의 `AndroidConfiguration.autoStartOnBoot` 기본값은 `true`다.
- 병합 manifest에는 plugin `BootReceiver`와 `WatchdogReceiver`, `RECEIVE_BOOT_COMPLETED`가 존재한다.

**수정**

1. `lib/core/services/background_service.dart`의 Android config에 `autoStartOnBoot: false`를 명시한다.
2. 추적 ON 성공 후에만 `setAutoStartOnBootMode(true)`를 호출할지 제품 결정을 한다. 권장 첫 RC는 재부팅 후 자동 시작도 false이며 사용자가 앱을 다시 열 때 이전 opt-in과 권한을 확인해 재개한다.
3. 추적 OFF·로그아웃·전체 데이터 삭제 시 `setAutoStartOnBootMode(false)`와 `stopService` 완료를 await한다.
4. source manifest에는 plugin receiver 선언이 없으므로 제거를 결정했다면 `tools:node="remove"` receiver override를 **추가**한다. plugin watchdog/restart 동작을 release 실기기에서 검증하고, grep만 보고 receiver가 없다고 가정하지 않는다.
5. FGS 시작 전에 `ACTIVITY_RECOGNITION` granted와 사용자의 persisted opt-in을 모두 확인한다.
6. 알림에는 “안전 모니터링”처럼 구조를 보장하는 표현 대신 “걸음 측정 중”을 사용한다.

**테스트**

- fresh install, 로그인 전 재부팅: service/ongoing notification 없음.
- 추적 OFF 후 재부팅: service 없음.
- 추적 ON → 권한 허용 → foreground/background: 서비스와 ongoing notification 정상.
- 권한 거부/취소/설정에서 회수 후 재부팅: 크래시·service 없음.
- 로그아웃 후 다른 로컬 계정 로그인: 걸음 데이터 교차 저장 없음.

```powershell
adb shell dumpsys activity services com.teammemorylink.memorylink
adb shell cmd appops get com.teammemorylink.memorylink ACTIVITY_RECOGNITION
```

### P0-04 — 알림 opt-in, 예약, 탭 동작 수정

**현재 결함**

- `main.dart::_prepareNotifications()`가 `diary_reminder_enabled=false`를 읽지 않고 매 시작마다 일기 알림을 다시 예약한다.
- fresh install에서 사용자 맥락 없이 notification permission을 자동 요청하고 기본 ON으로 예약한다.
- `PedometerManager.handleNotificationTap()`은 정의만 있고 `onDidReceiveNotificationResponse` 연결이 0건이다. “탭하여 보호자에게 문자를 보내세요”가 작동하지 않는다.
- 일기 알림은 exact alarm이 필요한 기능이 아닌데 `exactAllowWhileIdle`을 먼저 시도한다.

**수정**

1. 최초 기본값을 OFF로 하고, 만보기 토글이 아니라 **설정의 일기 알림 토글을 처음 켤 때** 알림 권한을 요청한다. 만보기를 사용하지 않는 사용자도 일기 알림을 독립적으로 켤 수 있어야 한다.
2. bootstrap은 preference가 true인 경우에만 재예약한다.
3. 일기 알림은 `inexactAllowWhileIdle`만 사용하고 manifest의 `SCHEDULE_EXACT_ALARM`을 제거한다.
4. notifications plugin 초기화에 foreground/background response callback을 연결한다.
5. SMS payload를 바로 실행하기 전에 화면에서 대상 번호와 메시지를 보여주고 사용자가 전송 앱 열기를 확인하게 한다.
6. payload에 전화번호를 넣는 현재 방식이 시스템/로그에 노출될 수 있으므로 notification ID만 넣고 앱 내부에서 현재 사용자 데이터를 조회하는 방식을 우선한다.

**완료 조건**

- 알림 OFF → 앱 종료/재실행/재부팅 후 pending request 0.
- 알림 ON → 대략 19시 발송, exact alarm special access 불필요.
- Guardian notification tap → SMS compose 화면 진입; 번호가 없는 경우 명확한 안내.
- 권한 거부 후 앱 핵심 기능 정상.

### P0-05 — Guardian capability와 데이터 최소화 재설계

**현재 사실**

- `guardian_views/{token}`은 인증 없이 단일 `get` 허용, `list`만 거부한다.
- token은 `Random.secure()`의 base36 16자(약 83bit)지만 만료·회전·폐기 UI가 없다.
- 정상 sync에도 `emergency_contact`를 항상 저장하며 주석의 “이상일 때만”과 다르다.
- 공개 document에 `ownerUid`, token, username, steps, scores, phone이 함께 있다.
- Firebase anonymous UID가 재설치/앱 데이터 삭제로 바뀌면 기존 문서 삭제 권한을 잃고 링크가 orphan될 수 있다.
- UI의 “실시간” 표현과 달리 정상 데이터는 사용자의 수동 sync 위주다.

**권장 설계**

1. 가능하면 보호자도 인증하고 owner가 초대를 승인하는 모델로 전환한다.
2. capability URL을 유지하면 최소 128bit(권장 32 random bytes base64url) token, `createdAt`, `expiresAt`, `revokedAt`, `schemaVersion`을 둔다.
3. 화면에 `공유 시작`, `링크 재발급`, `공유 중지`, `만료일`을 제공한다. 재발급은 구 token 문서를 즉시 삭제/폐기한다.
4. 기본 공개 필드는 별도 allowlist DTO로 제한한다. 전화번호는 별도 명시적 opt-in이고, 필요하면 이상 상태에서만 제공한다.
5. 소유권 메타데이터와 공개 view를 분리해 `ownerUid`가 public response에 포함되지 않게 한다. Rules만으로 field-level read를 숨길 수 없음을 고려한다.
6. token을 analytics/log/crash report/email 본문에 기록하지 않는다.
7. account/data deletion이 모든 active/revoked token 문서를 제거하도록 index를 만든다.
8. “응급/안전 보장/실시간” 표현을 삭제하고 “사용자가 동기화한 활동 요약”으로 정확히 표기한다.

**Rules 테스트 필수 사례**

- list/query deny, 임의 token deny/not-found.
- 소유자 외 create/update/delete deny.
- 만료·폐기 token get deny.
- 허용되지 않은 field write deny.
- phone 미동의 문서에 field 자체가 없음.
- token rotation 후 구 URL 무효.

운영 rules 배포는 emulator 테스트 후 담당자 승인으로만 수행한다.

### P0-06 — 죽은 global stats 쓰기 제거 또는 서버 권위 집계

UI의 social ranking은 삭제됐지만 `GuardianSyncService.syncToFirestore()`는 여전히 `_updateGlobalStats()`를 호출하고, `firestore.rules`는 모든 익명 로그인 사용자의 write를 허용한다.

**권장 첫 RC:**

- `_updateGlobalStats` 호출과 메서드 삭제.
- `global_stats/score_stats` client write/read 규칙 삭제 또는 deny.
- 관련 stale 문서·스크린샷·설명 삭제.
- 기존 운영 문서는 별도 승인 후 백업/삭제한다.

기능을 되살리려면 client raw input을 owner path에 쓰고 trusted backend가 최소 표본·중복방지·삭제 반영을 적용해 집계해야 한다. client EMA 값을 공식 비교치로 사용하지 않는다.

### P0-07 — 삭제, backup, 익명 identity 수명주기 완성

**정책 판정 주의:** Google은 완전히 offline으로 생성·운영되는 계정을 “app account” 삭제 의무에서 예외로 설명한다. 현재 사용자명/비밀번호 계정은 SQLite local-only여서 이 예외에 해당할 여지가 있다. 그러나 MemoryLink는 Firebase 익명 ID와 사용자 데이터를 클라우드에 저장하며 배포 페이지가 7일 내 삭제를 약속한다. 따라서 예외를 근거로 삭제 구현을 생략하지 않는다.

**현재 결함**

- 앱에는 로그아웃과 일부 측정 데이터 초기화만 있다. 일기, 프로필, 로컬 계정, preferences/cache/model, Firebase Auth, 문의, 난이도, Guardian 전체 삭제가 없다.
- `android:allowBackup` 미지정이라 Android 기본값 true다. SQLite/SharedPreferences 복원이 “앱 삭제 시 즉시 파기” 고지와 충돌할 수 있다.
- 한 Firebase UID 아래 여러 로컬 사용자가 존재할 수 있어 UID 단위 삭제는 다른 로컬 계정 데이터까지 지울 수 있다.
- 삭제 웹 페이지는 username만으로 요청하게 하지만 서버 ownership은 anonymous UID 중심이다. 재설치 후 UID를 잃으면 정확한 매핑/삭제가 어렵다.

**수정**

1. 하나의 canonical user/cloud identity 모델을 ADR로 정한다. 최소한 local user ↔ cloud document index를 서버가 검증 가능하게 만든다.
2. 설정에 `내 계정 및 모든 데이터 삭제`를 추가한다. 재확인, 진행 상태, 부분 실패, 재시도를 제공한다.
3. 삭제 순서: FGS/알림 중지 → guardian revoke/delete → 문의/replies → difficulty → 기타 owner 문서 → Firebase anonymous user → model/token/preferences/cache → local FK transaction user delete.
4. cloud 삭제 완료 전 local mapping을 먼저 지우지 않는다. idempotent하게 재실행 가능해야 한다.
5. 첫 RC에서 backup이 불필요하면 `<application android:allowBackup="false" ...>`로 명시한다. 필요하면 Android 12+ `dataExtractionRules`와 legacy `fullBackupContent`로 health DB, auth/session/API tokens, guardian token, model을 제외하고 고지한다.
6. `site/delete-account.html`의 7일 약속을 처리할 운영 SOP(`docs/release/DATA_DELETION_RUNBOOK.md`)와 담당자/대체 담당자/감사 로그로 뒷받침한다.
7. 웹 요청에 guardian secret URL 전체를 이메일로 보내도록 권하지 않는다. 별도 deletion request ID 또는 최소 식별 절차를 설계한다.
8. 배포 privacy/deletion 페이지와 앱 내 문구를 실제 삭제 범위·보존기간·backup 정책에 맞춘다.

**E2E 완료 조건**

- 일반 성공, offline 부분 실패 후 재시도, 중복 요청, UID 변경, guardian token, inquiry subcollection을 테스트한다.
- 삭제 후 재가입/재설치에서 예전 데이터가 복원되지 않는다.
- 구 guardian URL은 더 이상 데이터를 반환하지 않는다.
- 이메일 삭제 요청 1건을 test data로 7일 SLA보다 빠르게 end-to-end 리허설한다.

### P0-08 — 실제 데이터 지도와 Data safety/privacy 정합화

현재 `PLAY_CONSOLE.md`의 “remote 수집은 전부 Guardian 선택사항”은 틀리다.

#### 현재 네트워크 데이터 지도

| 경로 | 시점/선택성 | 기기 밖으로 나가는 값 | 수신자 |
|---|---|---|---|
| Firebase Anonymous Auth | 실제 기기 앱 bootstrap 시 자동 | Firebase Auth user ID, IP/user-agent 등 SDK 데이터 | Google Firebase |
| Firestore difficulty read/write | 로그인 후 load; 레벨 변경 시 자동 write | UID, local username, category levels, timestamp | Google Firebase |
| Guardian sync | 사용자가 sync/이상감지 경로 사용 | token, UID, username, steps, weekly dates, cognitive scores, phone, anomaly message | Google Firebase + token 보유 브라우저 |
| CS inquiry | 사용자가 제출 | UID, username, title, body, status, timestamp | Google Firebase |
| Gemini | 사용자가 API key를 넣고 chat | API key, system prompt, current+history messages; fixed Seoul weather context | Google Gemini API |
| wttr.in | Gemini mode에서 weather fetch | request metadata/IP; 위치 query는 고정 Seoul | wttr.in |
| HuggingFace | 사용자가 model download | bearer access token, request metadata/IP | HuggingFace |
| OS SpeechRecognizer | 사용자가 STT 실행 | 구현 공급자에 따라 음성이 on-device 또는 원격 처리될 수 있음; 앱은 text 결과만 받음 | Android/OEM speech service |
| PDF/share | 사용자 share action | 사용자가 선택한 외부 앱으로 PDF 전달 | 사용자 선택 recipient app |

#### 로컬 전용(현재 코드 기준)

로컬 계정 비밀번호 hash/salt, 이름·나이·몸무게·혈액형·약물, 일기, health logs, 상세 training attempts, profile image는 Guardian/Gemini/CS 경로에 명시적으로 넣지 않는 한 앱 서버로 전송되지 않는다. 단, Android backup을 허용하면 “기기만”이라는 설명이 달라질 수 있으므로 P0-07을 먼저 결정한다.

#### Data safety 초안 — 범위 동결 후 다시 확정

| Play 데이터 유형 | 현재 신고 방향 | 필수/선택 | 목적/주의 |
|---|---|---|---|
| Personal info > User IDs | **수집** | Firebase Auth는 자동; difficulty username도 현재 opt-out 없음 | app functionality/account management. Firebase Auth UID는 pseudonymous여도 신고 대상 |
| Device or other IDs | Firebase native dependency와 최종 SDK guidance 재확인 | 자동 수집 SDK가 있으면 필수 | Firebase App ID 자체를 사용자 device ID로 임의 분류하지 말고 Firebase 공식 disclosure와 dependency tree로 판정 |
| Personal info > Name | Guardian가 실제 display name을 보내도록 고치면 수집 | 선택 | 현재 코드는 display name이 아니라 username을 보냄. 문서와 코드 중 하나를 통일 |
| Personal info > Phone number | Guardian 사용 시 수집 | 선택 | 기본 미수집/별도 opt-in으로 변경 권장 |
| Health & fitness > Fitness info | Guardian에 steps 전송 시 수집 | 선택 | app functionality |
| Health & fitness > Health info | cognitive score를 건강 지표/보호자 리포트로 전송하므로 보수적으로 수집 | 선택 또는 해당 기능 필수 | 단순 “app activity”로만 축소 신고하지 말 것 |
| App activity > Other actions/interactions | training level/score를 서버로 보낼 경우 수집 | 현재 difficulty는 사실상 필수 | personalization/app functionality |
| App activity > Other user-generated content | CS title/body | 선택 | developer communications/app functionality |
| Messages > Other in-app messages | Gemini prompt/history | 선택 | app functionality; ephemeral 여부는 provider 계약/retention을 확인한 뒤 답변 |
| Audio > Voice/sound recordings | 앱이 raw audio를 받거나 저장하지 않으면 앱 수집은 아님 | 해당 없음 가능 | privacy에는 OS speech service가 원격 처리할 수 있음을 정확히 고지 |
| Photos | profile photo local only이면 수집 아님 | 해당 없음 | cloud upload 추가 시 즉시 갱신 |
| Health logs/Diary | local only이면 수집 아님 | 해당 없음 | Guardian/AI prompt에 넣지 않는 회귀 테스트 필요 |

공통 답변은 실제 구현이 모두 TLS인지, 모든 수집 데이터의 삭제 요청이 가능한지 확인한 뒤 작성한다. Firebase가 service provider라면 “sharing 아님” 예외가 가능하지만, Gemini/HuggingFace/OS provider의 user-initiated transfer와 계약은 별도 판정한다. 추정으로 전부 “공유 아님”을 선택하지 않는다.

#### privacy 문서의 현재 오류

`site/privacy.html`과 `landing/privacy.html`은 다음을 고쳐야 한다.

- 존재하지 않는 “음성 진단 녹음 저장” 대신 OS STT 처리와 앱의 raw audio 미저장을 설명한다.
- Gemini는 키가 있을 때 prompt/history가 Google로 전송됨을 명시하고 동의/철회 방법을 적는다.
- HuggingFace token/model 다운로드 경로를 기능 유지 시 추가한다.
- Guardian의 정확한 field, 공개 capability 방식, 수신자, 만료, 삭제를 적는다.
- 감정 일기가 Guardian cloud로 나가는 것처럼 읽히는 표를 분리한다.
- Firebase Auth UID/difficulty의 자동 수집을 적는다.
- `deleteOldDiaries()`의 최대 3년 로컬 보관과 실제 실행 시점을 검증해 고지한다. 주석만 있고 호출되지 않으면 “자동 삭제”로 약속하지 않는다.
- 측정 데이터 초기화가 local account/diary/profile/cloud까지 지우는 것처럼 쓰지 않는다.
- backup 정책, 보존기간, 국외 처리, 담당자, 시행일을 갱신한다.
- canonical source 한 곳에서 `site/`와 `landing/`을 생성하거나 consistency test를 추가한다.

### P0-09 — Health, FGS, exact alarm, Android 권한 최소화

#### Android Health Connect

현재 Android에서 `Health.requestAuthorization()` 호출은 0건이다. `health` 사용은 `onIosBackground`의 iOS READ 경로뿐이다. 따라서 `READ_STEPS`/`WRITE_STEPS`를 선언하고 Play 답안을 “Health Connect read/write”로 쓰는 것은 잘못이다.

**권장 RC 수정**

- `android.permission.health.READ_STEPS`와 `WRITE_STEPS`를 manifest에서 제거한다.
- Android 기능이 없다면 Play Health Connect permission request를 제출하지 않는다.
- `health` Flutter plugin이 Android merged manifest에 `HealthDataSdkService`를 남기는 점을 확인한다. Play scanner 혼동을 피해야 하면 iOS 전용 구현을 분리하거나 첫 Android RC에서 dependency를 제거한다.
- Health Connect를 실제 구현한다면 WRITE는 사용하지 말고 READ_STEPS만 요청하며, 사용자-facing benefit, runtime consent, revoke/delete, privacy, 실제 기기 테스트를 완성한다.

#### Health apps declaration

Health Connect 사용 여부와 무관하게 **모든 published app은 Health apps declaration을 작성**한다. MemoryLink는 최소 다음 기능을 정확히 선택한다.

- Activity and Fitness
- Stress Management, Relaxation, Mental Acuity
- Sleep Management(수면 기록 유지 시)
- Nutrition and Weight Management(식이/체중 기록 유지 시)

Medical Device Apps는 선택하지 않는다. 앱 설명에는 §7의 비의료 면책을 넣는다. 질병 관리/임상 의사결정처럼 읽히는 기능명은 제거한다.

#### Foreground service declaration

`foregroundServiceType="health"`를 유지하면 Play App content의 FGS form에 다음을 제출한다.

- 기능: 사용자가 생활습관 화면에서 스위치를 켠 동안 걸음 수를 지속 측정.
- 지연/중단 영향: 일부 걸음 기록이 누락될 수 있으나 응급·안전 기능을 보장하지 않음.
- 영상: fresh install → 사용자 toggle → ACTIVITY_RECOGNITION/notification permission → ongoing notification → step update → toggle off 및 notification 종료.
- 시작 조건: 사용자 action 이후만. boot 무단 시작 장면이 없어야 한다.

#### 나머지 권한

- `SCHEDULE_EXACT_ALARM`: 제거하고 inexact daily reminder 사용.
- `HIGH_SAMPLING_RATE_SENSORS`: background `update_gait_data` event를 소비하는 코드가 0건이다. 불필요 가속도 subscription과 함께 제거 권장.
- `RECEIVE_BOOT_COMPLETED`/`WAKE_LOCK`: plugin receiver/watchdog 실제 동작 때문에 grep만 보고 삭제하지 않는다. autoStartOnBoot false와 manifest override를 실기기 검증 후 결정한다.
- `POST_NOTIFICATIONS`: 알림 기능 유지 시 필요, 사용 시점에 요청한다.
- `RECORD_AUDIO`: STT 유지 시 필요. 사용자가 microphone 버튼을 누를 때 설명 후 요청하고 text 대체 입력을 유지한다.

최종 AAB merged manifest와 Play 선언의 permission/type가 1:1이어야 한다.

### P0-10 — 생성형 AI 안전·신고·credential

Gemini 및 Gemma text chatbot은 Google Play AI-Generated Content 정책 대상이다. 현재 인앱 offensive-content 신고/flagging이 없으므로 그대로 출시할 수 없다.

**가장 빠른 해결:** 첫 RC에서 Gemini/Gemma route와 설정을 숨기고 `LocalFallbackProvider`만 사용한다. 규칙 기반 응답을 “생성형 AI”로 광고하지 않는다. `flutter_gemma`, model download, HF token 코드를 제거하면 P0-11 16KB 실패도 함께 해소될 가능성이 높다.

**AI를 유지할 경우 전부 구현**

1. 각 AI 응답에 인앱 신고 버튼, 신고 category, Firebase/backend 접수, 처리 상태와 moderation 운영 runbook.
2. restricted content 방지, 건강/진단/처방 답변 금지, 위기 상황 안전 안내, prompt injection/긴 output/timeout 테스트.
3. 전송 직전 Gemini third-party prominent disclosure와 별도 opt-in. settings에서 철회/키 삭제.
4. 사용자 Gemini/HF token을 SharedPreferences 평문에서 Android Keystore 기반 secure storage로 이전한다.
5. Gemini API key를 query string 대신 지원되는 인증 header 또는 안전한 gateway로 전환한다. 앱 소유 공용 key를 binary에 넣지 않는다.
6. prompt/history, token, phone, health 값이 log/URL/analytics에 들어가지 않게 redaction test.
7. Gemma model은 SHA-256/서명, expected size, atomic download, Wi-Fi/저장공간 안내, 취소/resume, 삭제 후 provider 재선택을 구현한다.
8. 현재 `deleteModel()` 후 `AiChatService.initialize()`는 `_initialized` 때문에 provider를 재선택하지 않을 수 있다. 명시적 reinitialize를 테스트한다.
9. 지원 ABI/기기에서만 local model UI를 보여주고 1.5GB 저장 요구를 store/app에 고지한다.
10. Data safety와 privacy를 prompt/history/token 처리에 맞춘다.

### P0-11 — 16KB native library 호환

**현재 실패 파일:** `arm64-v8a/libllm_inference_engine_jni.so`, LOAD alignment `2**12`.

1. 어느 dependency가 파일을 제공하는지 Gradle dependency/APK Analyzer로 확정한다. 현재 가장 유력한 경로는 `flutter_gemma`/MediaPipe LLM이다.
2. 권장 첫 RC는 미완 온디바이스 모델 기능과 `flutter_gemma` dependency를 제거한다.
3. 기능 유지 시 16KB-compatible prebuilt SDK 버전으로 올리거나 16KB ELF alignment로 재빌드한다. 단순 `zipalign` 성공만으로 완료 처리하지 않는다.
4. 모든 `arm64-v8a`와 `x86_64` `.so`의 LOAD align이 `2**14` 이상이어야 한다.
5. 16KB Android 15/16 image에서 설치·cold start·AI init·SQLite·PDF·background tracking을 실행한다.

현재 공식 문서는 target 35+ 앱이 16KB를 지원해야 하며 **2027-02-01부터 비호환 update release가 차단**된다고 명시한다. 기한 전이라도 실제 16KB 기기 호환 결함이므로 첫 공개 RC Gate로 다룬다.

### P0-12 — STT/TTS package visibility

release merged manifest의 `<queries>`에는 `PROCESS_TEXT`만 있다. 설치된 plugin 문서는 target SDK 30+에서 다음을 요구한다.

```xml
<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
    <intent>
        <action android:name="android.intent.action.TTS_SERVICE" />
    </intent>
</queries>
```

`android/app/src/main/AndroidManifest.xml`에 추가하고 Android 11, 14, 16에서 다음을 검사한다.

- STT engine 있음/없음, microphone 허용/거부/영구 거부.
- network speech service와 offline engine.
- TTS engine 있음/없음, voice guidance ON/OFF.
- Bluetooth headset을 공식 지원하지 않으면 Bluetooth 권한을 무작정 추가하지 않는다.

### P0-13 — Guardian web URL과 App Link 결정

현재 공유 문구는 “앱 설치 없이” 웹 대시보드를 여는 설계다. 그런데 Android manifest가 같은 `https://memorylink-7af26.web.app/guardian.html`을 autoVerify App Link로 가로채고 앱에는 `/guardian.html` route가 없다. 배포 `assetlinks.json`은 현재 `[]`라 우연히 브라우저로 남아 있다.

**권장 수정:** guardian https intent-filter를 manifest에서 제거하고 링크를 브라우저 전용으로 유지한다. 제거 후 QR, Kakao/SMS/share, 앱 설치 여부 두 경우를 시험한다.

인앱 guardian viewer를 새로 만들기로 결정한 경우에만 `/guardian.html` route, token validation, auth/secure view, Play App Signing certificate fingerprint를 갖춘 `assetlinks.json`을 구현한다. assetlinks만 채우는 것은 금지한다.

### P0-14 — release signing fail-closed

`android/app/build.gradle.kts`는 `key.properties`가 없으면 release를 debug key로 서명한다. 현재 머신에는 gitignored `android/key.properties`와 JKS가 존재해 이번 로컬 artifact는 올바른 upload key로 서명됐고, 두 파일은 현재 git 추적 대상이 아니다. 그러나 다른 agent/CI에서는 조용히 잘못된 artifact가 만들어질 수 있으며 로컬 key.properties의 평문 비밀번호를 절대 커밋하면 안 된다.

1. production `release`는 upload key가 없으면 Gradle configuration을 실패시킨다.
2. PR에서 release optimization만 검사하려면 명시적 `ciRelease`/unsigned 검증 경로를 따로 둔다. “release” 이름으로 debug-signed artifact를 만들지 않는다.
3. key password는 repo 밖 secret store/CI secret로 제공한다. keystore와 key.properties가 git 추적되지 않는지 검사한다.
4. Play App Signing을 활성화하고 upload key와 app signing key를 구분한다.
5. Firebase/API provider와 App Links를 쓸 경우 로컬 upload SHA가 아니라 Play app signing certificate fingerprint도 등록한다.
6. versionCode는 업로드마다 증가한다. 최초 `1`은 가능하지만 같은 code 재업로드는 거부된다.

### P0-15 — 비의료 표현과 실제 지표 의미 정리

다음 표현을 public app/store/privacy/README/PDF/Guardian에서 제거 또는 비의료 표현으로 바꾼다.

| 현재 표현 예 | 권장 표현 |
|---|---|
| 치매 예방, 조기 발견/선별 | 인지 활동, 생활습관 기록, 자가 모니터링 |
| 임상 리포트, 의료진용 | 활동 기록 리포트, 상담 시 참고용 |
| 현재의 건강 상태 | 최근 게임 수행 기록 |
| 정상/경고/고위험, 치매·낙상 위험 전조 | 측정값/표본 수/변화만 표시; 진단적 판정 없음 |
| 음성 진단 | 음성 입력 또는 기능 자체 production에서 숨김 |
| 보호자 실시간 모니터링/안전 | 사용자가 동기화한 활동 요약 공유 |
| AI 분석(실제 rule-based) | 자동 요약 또는 규칙 기반 요약 |

우선 검색 대상:

- `README.md`, `PROJECT_DOCS.md`, `GAIT_ANALYSIS.md`
- `lib/features/reports/*`, `lib/features/voice_assessment/*`
- `lib/features/profile/*`, `lib/core/cs_service.dart`
- `site/*.html`, `landing/*.html`
- 모든 Maestro/demo/screenshot metadata

금지 문자열만 grep해서 끝내지 말고 스크린샷/PDF text extraction/실제 Guardian 페이지도 검토한다.

### P0-16 — 스토어 자산 최신화

**현재 상태**

- `assets/icon/app_icon.png`는 고해상도 원본 후보이고 `site/icons/Icon-512.png`도 있으나 Play icon export 검증이 필요하다.
- 1024×500 feature graphic이 저장소에 없다.
- root `01_*.png`~`14_*.png`는 구 UI를 포함한다. 특히 `08_social_ranking.png`와 `07_reports.png`는 삭제된 social ranking/잘못된 percentile을 보여준다.
- 중지된 voice assessment 화면을 스토어 주요 기능처럼 보여주면 안 된다.

**산출물 구조 권장**

```text
docs/store-assets/ko-KR/
  icon-512.png
  feature-graphic-1024x500.png
  phone/
    01-home.png
    02-training.png
    03-walking.png
    04-diary.png
    05-report.png
    06-guardian.png        # 기능을 출시할 때만
  listing.md
  alt-text.md
```

**요건**

- icon: 512×512, 32-bit PNG with alpha, ≤1024KB.
- feature graphic: 1024×500, JPEG 또는 24-bit PNG, alpha 없음.
- phone screenshots: 최소 2장; JPEG/24-bit PNG, 각 변 320~3840px, 긴 변은 짧은 변의 2배 이하. 추천 노출을 위해 portrait 1080×1920 이상 4장 권장.
- 실제 release build와 동일한 UI/기능만 표시하고 demo PII/notification/debug banner를 제거한다.
- 각 자산에 140자 이하 alt text를 작성한다.
- AI로 만든/편집한 시각 자산이면 Play Console content creation flow의 AI asset self-declaration 적용 여부를 각각 답한다.

---

## 4. P1 — 출시 전 고쳐야 할 제품·보안 결함

P0가 끝난 뒤 첫 production 전에 닫는다.

| ID | 결함 | 파일/작업 | 완료 조건 |
|---|---|---|---|
| P1-01 | Reports DB 오류를 빈 데이터로 위장 | `lib/features/reports/reports_screen.dart` | 오류 상태+재시도, 빈 상태와 분리 |
| P1-02 | 4개 인지 영역을 한 선에 섞고 x축을 월~일로 고정 | reports screen/data model | 영역별 series 또는 선택 filter, 실제 날짜, 신규 사용자 empty state |
| P1-03 | Gemma 삭제 후 provider stale 가능 | AI/model services | model 삭제 즉시 LocalFallback/Gemini 재선택 테스트 |
| P1-04 | API/HF token 평문 SharedPreferences | AI/model services | secure storage migration, logout/delete cleanup, backup 제외 |
| P1-05 | Firebase anonymous identity에 App Check 없음 | Firebase init/Console | metrics 관찰 후 Play Integrity enforcement; debug token production 0 |
| P1-06 | 로컬 password KDF가 salt+single SHA-256 | database/auth | PBKDF2/Argon2/bcrypt 등 versioned migration; 기존 로그인 유지 |
| P1-07 | 앱 표시 버전 하드코딩 | settings/version label | build metadata에서 읽고 `pubspec`과 자동 일치 테스트 |
| P1-08 | fixed Seoul weather를 모든 사용자에게 현재 날씨처럼 사용 | Gemini provider | 삭제 또는 명시적 지역 선택/consent; third-party flow 신고 |
| P1-09 | 1.5GB 모델 다운로드에 checksum/resume/network/storage 방어 부족 | model download | checksum, 공간/Wi-Fi 확인, cancel/resume, corrupted file test |
| P1-10 | Guardian sync 오류에 raw exception 문자열 노출 | guardian UI | 사용자용 오류 code/message, secret/endpoint 미노출 |
| P1-11 | background accelerometer output 소비자 0건 | background service | subscription/permission 제거 또는 저장·표시 목적 구현 |
| P1-12 | 익명 UID 상실 시 cloud orphan | auth/cloud model | stable deletion identity 또는 server-side deletion index |
| P1-13 | 동의 checkbox가 상세 내용/저장 없이 장식적 | consent flow | versioned consent record, separate optional controls, withdraw path |
| P1-14 | 가입이 health consent보다 먼저 name/age/weight를 저장 | register/consent | 수집 전 고지·동의 또는 최소 가입 후 별도 선택 입력 |
| P1-15 | 앱의 건강 권고가 근거/한계 없이 규칙값으로 표시될 수 있음 | ReportAnalyzer/health UI | 비의료 문구, 근거 없는 개인 건강 권고 제거, 테스트 |
| P1-16 | dependency/SBOM 문서 stale | `pubspec.lock`, `sbom.json`, notices | RC lock 기준 재생성, license/SDK Index review |

---

## 5. Play Console 전체 등록 Runbook

Console UI 이름은 바뀔 수 있다. 화면 위치보다 **제출해야 하는 사실**을 따른다.

### 5.1 개발자 계정

- [ ] identity verification 완료.
- [ ] contact email/phone verified.
- [ ] public developer name과 운영 주체 일치.
- [ ] 운영 주체와 Console prompt에 맞는 Personal/Organization account type 확인. Medical/Human Subjects Research 등 organization 대상이면 D-U-N-S와 조직 정보 완료; 비의료 wellness라는 이유만으로 어느 유형도 추정하지 않음.
- [ ] 2-Step Verification, 최소권한 사용자, 비상 복구 owner 설정.
- [ ] `com.teammemorylink.memorylink` package registration 완료(2026-09-30 기한 확인).
- [ ] 신규 개인 계정이면 Android 10+ 비루팅 실물 기기 verification 완료.

### 5.2 앱 생성

- Default language: Korean (`ko-KR`).
- App or game: App.
- Free or paid: 현재 결제 기능이 없으므로 Free. 무료 앱을 나중에 유료 앱으로 직접 전환할 수 없는 제약을 Console에서 다시 확인한다.
- App name: `MemoryLink`.
- Support email: 실제 운영 가능한 주소. 현재 문서는 `teammemorylink@gmail.com`.
- Developer Program Policies, US export laws, Play App Signing 약관 확인.
- package name은 첫 artifact 후 영구·재사용 불가이므로 철자를 재확인한다.

### 5.3 Main store listing 초안

P0 기능 범위와 문구 정리 후만 사용한다.

**앱 이름(30자 이하)**

```text
MemoryLink
```

**짧은 설명(80자 이하)**

```text
인지 활동, 걸음·생활 기록, 감정 일기와 보호자 공유를 한곳에서 관리하세요
```

Guardian를 첫 RC에서 끄면 마지막 구절을 삭제한다.

**전체 설명 초안(4000자 이하)**

```text
MemoryLink는 고령 사용자와 가족이 일상 인지 활동과 생활습관 기록을 정리하도록 돕는 비의료 웰니스 앱입니다.

주요 기능
• 여러 종류의 인지 활동과 최근 수행 기록
• 사용자가 켠 동안의 걸음 수와 주간 활동 기록
• 수면, 혈압, 혈당, 식이 등 사용자가 직접 입력하는 생활 기록
• 감정 일기와 PDF 활동 기록 리포트
• 전국 치매안심센터 정보 안내
• 사용자가 명시적으로 활성화한 경우의 보호자 활동 요약 공유

데이터 처리
대부분의 계정·일기·건강 기록은 기기 안에 저장됩니다. 보호자 공유, 고객 문의 또는 선택한 온라인 기능을 사용할 때에는 해당 화면에 안내된 데이터만 네트워크로 전송됩니다. 자세한 내용과 삭제 방법은 개인정보처리방침을 확인해 주세요.

의료 면책
MemoryLink는 의료기기가 아니며 어떠한 질환도 진단, 치료, 치유 또는 예방하지 않습니다. 앱의 기록과 점수는 의료적 판단을 대신하지 않습니다. 의학적 조언, 진단 또는 치료가 필요하면 의료 전문가와 상담하세요.

기기 요구사항
Android 8.0 이상이 필요합니다. 걸음 측정은 기기의 센서 지원과 사용자가 허용한 권한에 따라 일부 기기에서 제한될 수 있습니다.
```

온라인 생성형 AI를 출시 범위에 넣을 때만 AI 기능·제3자 전송·사용자 신고 방법을 정확히 추가한다.

**분류 권장:** Health & Fitness. 태그는 실제 기능만 선택한다. `Medical` category/medical device 표기를 사용하지 않는다.

### 5.4 App content 필수 항목

| 항목 | MemoryLink 제출 방향 |
|---|---|
| Privacy policy | `https://memorylink-7af26.web.app/privacy.html`; P0-08 수정·재배포 후 제출 |
| Data safety | §3 P0-08 지도를 코드/SDK와 다시 대조한 최종 CSV 제출 |
| Data deletion | local-only account 예외 판단을 기록하되 공개 URL `https://memorylink-7af26.web.app/delete-account.html`과 실제 cloud 삭제 SOP를 제공 |
| Ads | No. 광고 SDK/house ad 추가 시 갱신 |
| Advertising ID | 사용하지 않음; final merged manifest에서 `AD_ID` 재확인 |
| App access / Sign-in details | 아래 reviewer 절차 제공 |
| Target audience | 실제 고령 성인 대상. 18+ 연령대만 선택하는 방향; 어린이 대상 아님 |
| Content rating | questionnaire 사실대로 완료. 폭력/성/도박/공개 UGC/구매 없음; AI chat 유지 시 AI 출력 위험 고려 |
| Health apps | Activity & Fitness, Mental Acuity, Sleep, Nutrition/Weight 등 실제 기능 모두 선언; non-medical disclaimer |
| Health permissions | 권장 RC는 Health Connect 미사용. 구현할 때만 READ_STEPS 최소 요청과 상세 justification |
| Foreground service | health FGS 설명, 지연/중단 영향, 사용자 시작/종료 영상 제출 |
| AI-generated content policy | chatbot 유지 시 인앱 신고 기능 필수. Store visual asset이 AI 생성/편집이면 asset별 self-declaration |
| News/Magazine | No |
| Government | No; 공공데이터 출처 안내가 정부 앱을 뜻하지 않음 |
| Financial features | No |
| COVID/contact tracing | No |

### 5.5 Reviewer 접근 안내 초안

release build에는 고정 demo account가 없다. “이미 존재하는 reviewer 계정”이라고 쓰지 말고 local 가입 절차를 제공한다.

```text
MemoryLink의 사용자 계정은 리뷰 기기 내부에 생성되는 로컬 계정입니다.
서버에 미리 생성된 테스트 계정은 없습니다.

1. 첫 화면에서 “처음이신가요? 회원가입”을 선택합니다.
2. 예시 입력: 아이디 reviewer / 이름 Review User / 비밀번호 review1234 / 나이 68 / 체중 60.
3. 선택 건강정보는 비워도 됩니다.
4. 가입 후 개인정보·건강정보 안내를 확인하고 필수 항목에 동의합니다.
5. 온보딩과 초기 활동을 완료하면 전체 앱 화면에 접근할 수 있습니다.
6. 걸음 측정은 생활습관 화면의 스위치를 켠 후 Android 권한을 허용해야 시작됩니다.
7. 보호자 공유가 출시 범위에 포함된 빌드에서는 보호자 연결 화면의 “지금 동기화” 후 QR 링크를 브라우저로 확인합니다.

결제, 초대 코드, OTP, 위치 제한은 없습니다.
```

실제 release candidate에서 이 절차를 fresh install로 녹화한다. Health/FGS review video는 별도 제출한다.

### 5.6 테스트 트랙과 프로덕션

1. Internal testing: signing/install/upgrade/permission smoke test.
2. Closed testing: 개인정보·Guardian·AI·FGS·PDF·삭제를 실제 타깃 사용자에 가깝게 검증.
3. 2023-11-13 이후 생성된 Personal developer account라면 **최소 12명이 14일 연속 opt-in** 상태를 유지해야 production access 신청 가능하다.
4. production access 신청에는 tester engagement, feedback, 수정사항, 준비 판단을 구체적으로 작성한다.
5. Pre-launch report의 crash, ANR, accessibility, security, screenshot issue를 0 또는 승인된 예외로 만든다.
6. 첫 production은 managed publishing + 작은 staged rollout로 시작한다. 건강/데이터 삭제/Guardian P0 발생 시 rollout 중단 기준을 미리 둔다.

---

## 6. 실기기 QA 매트릭스

최소 다음 조합을 기록한다.

| 축 | 필수 케이스 |
|---|---|
| Android | 10(API29), 11(API30), 13(API33), 14(API34), 16/API36; 가능하면 제조사 2종 |
| ABI | arm64-v8a 64-bit-only, x86_64 emulator; 16KB page-size 환경 |
| 설치 | fresh install, upgrade from previous RC, uninstall/reinstall, backup restore 정책 |
| 권한 | 허용, 1회 거부, 영구 거부, 설정에서 회수, notification denied |
| 네트워크 | online, offline first launch, 중간 끊김, 느린 네트워크 |
| 계정 | 신규 가입, 로그인 실패, 로그아웃, 로컬 A→B→A 전환, 전체 삭제 |
| 보행 | 센서 있음/없음, toggle on/off, background, force-stop, reboot, 날짜 변경 |
| 알림 | reminder on/off/restart/reboot, tap callback, no phone number |
| Guardian | sync, expired/revoked token, rotation, offline failure, old URL deny |
| STT/TTS | engine 있음/없음, network/offline recognition, mic denied, voice guidance off |
| PDF/share | 생성, Korean font, cancel share, target app 없음, 민감 데이터 확인 |
| AI(유지 시) | consent, report offensive response, restricted prompt, timeout, bad key/token, model corruption/delete |
| 접근성 | TalkBack, 200% text, display size, contrast, touch target, reduce motion |

각 RC에서 “테스트하지 못함”을 통과로 표시하지 않는다. 장비가 없으면 Play pre-launch/Test Lab 결과와 남은 위험을 명시한다.

---

## 7. Windows PowerShell 재현 명령

### 7.1 기본 Gate

```powershell
flutter --version
flutter pub get
flutter analyze
flutter test --reporter compact
adb devices -l
flutter test --dart-define=IS_EMULATOR=true integration_test/auth_flow_test.dart integration_test/training_flow_test.dart -d <device-id>
.\run_maestro_tests.ps1
flutter build appbundle --release
flutter build apk --release
```

### 7.2 merged manifest와 artifact

```powershell
$manifest = 'build\app\intermediates\merged_manifests\release\processReleaseManifest\AndroidManifest.xml'
Select-String $manifest -Pattern 'targetSdkVersion|uses-permission|foregroundServiceType|android:exported|allowBackup'

$bt = 'D:\Android\SDK\build-tools\36.1.0'
$apk = 'build\app\outputs\flutter-apk\app-release.apk'
& "$bt\aapt2.exe" dump badging $apk |
  Select-String -Pattern '^package:|^sdkVersion:|^targetSdkVersion:|^native-code:'
& "$bt\apksigner.bat" verify --verbose --print-certs $apk
& "$bt\zipalign.exe" -c -P 16 -v 4 $apk
```

Build Tools 경로는 머신마다 다르므로 SDK Manager의 최신 설치 버전으로 바꾼다.

### 7.3 ELF 16KB alignment — ZIP 성공과 별도 검사

```powershell
$apk = Resolve-Path 'build\app\outputs\flutter-apk\app-release.apk'
$out = 'build\tmp\release-apk-16k-audit'
$zip = 'build\tmp\release-apk-16k-audit.zip'
Remove-Item $out,$zip -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item $apk $zip
Expand-Archive $zip $out

$objdump = 'D:\Android\SDK\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-objdump.exe'
$bad = @()
Get-ChildItem "$out\lib" -Recurse -Filter *.so | ForEach-Object {
  $aligns = @(& $objdump -p $_.FullName |
    Select-String '^\s*LOAD ' |
    ForEach-Object {
      if ($_.Line -match 'align 2\*\*(\d+)') { [int]$Matches[1] }
    })
  $min = ($aligns | Measure-Object -Minimum).Minimum
  if ($min -lt 14) { $bad += "$($_.FullName): min=2**$min" }
}
if ($bad.Count) { $bad; throw '16KB ELF alignment failed' }
'16KB ELF alignment PASS'
```

### 7.4 manifest 금지/필수 항목

```powershell
# 권장 RC에서는 결과 0건이어야 함
Select-String $manifest -Pattern 'health\.READ_STEPS|health\.WRITE_STEPS|SCHEDULE_EXACT_ALARM|AD_ID'

# 기능 유지 시 있어야 함
Select-String $manifest -Pattern 'ACTIVITY_RECOGNITION|FOREGROUND_SERVICE_HEALTH|POST_NOTIFICATIONS|RECORD_AUDIO'
Select-String $manifest -Pattern 'android\.speech\.RecognitionService|android\.intent\.action\.TTS_SERVICE'
```

### 7.5 문서/코드 일관성 검색

```powershell
$patterns = @(
  '치매.*예방','조기.*(발견|선별)','임상 리포트','의료진용',
  '음성 진단','고위험','치매.*전조','social_ranking'
)
Get-ChildItem lib,site,landing,maestro -Recurse -File |
  Select-String -Pattern $patterns

Select-String -Path '.github\workflows\maestro.yml','run_maestro_tests.ps1' -Pattern 'maestro/.+\.yaml'
git diff --check
git status --short
```

검색 결과에는 연구 문서/테스트의 금지어 guard가 있을 수 있으므로 모든 hit를 무조건 지우지 말고 사용자 노출 여부를 판정한다.

---

## 8. Definition of Done — 공개 출시 Go Gate

다음이 모두 true일 때만 **GO**다.

### 코드·artifact

- [ ] `flutter analyze`, unit/widget, integration, 검증된 Maestro Gate 전부 exit 0.
- [ ] release AAB가 fail-closed upload key로 서명되고 versionCode가 이전 업로드보다 큼.
- [ ] targetSdk 36, 64-bit, 모든 native ELF 16KB align 통과.
- [ ] release merged manifest에 미사용 Health/exact/high-sampling 권한이 없음.
- [ ] STT/TTS queries 존재하고 API 30+ 실기기에서 동작.
- [ ] fresh install에서 사용자 action 전 FGS/notification permission/일기 예약이 시작되지 않음.
- [ ] 알림 OFF가 restart/reboot 후 유지되고 Guardian notification tap이 작동.
- [ ] Guardian를 켠 경우 token TTL/rotation/revoke/minimal fields/delete E2E 통과.
- [ ] client global stats write 0.
- [ ] account/data deletion과 backup 정책 E2E 통과.
- [ ] 생성형 AI를 켠 경우 신고/moderation/consent/secure credential/Data safety 완료; 아니면 production UI에서 완전히 off.

### 정책·문서·스토어

- [ ] Play developer identity/contact/package registration 완료.
- [ ] privacy, Data safety, Health form, FGS form, 앱 실제 동작의 field/permission/type가 일치.
- [ ] 비의료 disclaimer가 full description과 앱 내 적절한 위치에 있음.
- [ ] “예방/진단/선별/임상/실시간 안전 보장” 오인 표현 0.
- [ ] 계정 삭제 예외를 택하더라도 cloud data deletion URL/SOP/실측이 존재.
- [ ] reviewer fresh-install 절차로 모든 출시 기능 접근 가능.
- [ ] 512 icon, 1024×500 feature graphic, 최신 phone screenshot 최소 2장(권장 4장+)과 alt text 완료.
- [ ] stale social ranking/voice blocked/구 UI screenshot 미사용.
- [ ] content rating, target audience, ads, Health apps, AI asset declarations 완료.
- [ ] 신규 개인 계정이면 12명/14일 closed test와 production access 승인 완료.
- [ ] Pre-launch report의 blocking issue 0, staged rollout/rollback 담당자와 기준 승인.

---

## 9. 기존 문서에서 그대로 믿으면 안 되는 항목

- `PLAY_CONSOLE.md`의 “Health Connect read/write” — Android 실제 권한 요청 없음.
- `PLAY_CONSOLE.md`의 “클라우드 수집은 모두 Guardian 선택사항” — difficulty username/level과 Firebase Auth는 자동 경로가 있음.
- `PLAY_CONSOLE.md`의 “AI 대화 내용 미수집” — 사용자가 key를 넣을 수 있는 production UI가 있으므로 Gemini prompt/history 전송 경로가 존재함.
- `RELEASE_CHECKLIST.md`의 AAB 150MB 상한 — 현재 공식 앱 생성 안내는 app bundle로 생성되는 **기기별 압축 APK 다운로드 200MB**를 설명한다. Console 계산값을 최종 기준으로 쓴다.
- `RELEASE_CHECKLIST.md`의 `MemoryLink(beta)` 라벨 — 현재 release 라벨은 `MemoryLink`.
- 과거 117/307/320 테스트 수치 — 매 RC에서 직접 실행한다.
- “App Link assetlinks만 추가하면 해결” — 현재 웹 전용 Guardian 설계에서는 intent-filter 제거가 정답이다.
- “RECEIVE_BOOT_COMPLETED receiver가 없다” — release merged manifest에는 plugin receiver가 있다.
- “google-services.json 첫 package가 달라 Firebase 불가” — 실제 package와 맞는 두 번째 client가 존재한다.
- “16KB zipalign 통과 = 16KB 지원” — ELF LOAD alignment도 별도로 확인해야 한다.

---

## 10. 운영 후 모니터링

- Play Android vitals의 crash/ANR/excessive wakeup/foreground service 문제를 daily 확인한다.
- release 첫 주는 작은 staged rollout을 유지한다.
- 즉시 중단 조건: 교차 사용자/Guardian 데이터 노출, 삭제 실패를 성공으로 표시, background 무단 시작, 건강 오인/유해 AI 응답, 데이터 손상, crash/ANR 급증.
- 기능 flag off 순서: 생성형 AI → Guardian → background gait/step. local diary/training은 가능한 유지한다.
- policy/Data safety/privacy는 SDK나 네트워크 field가 바뀌는 같은 PR에서 갱신한다.
- Firebase rules 변경은 emulator deny/allow suite와 rollback ruleset ID를 남긴다.

---

## 11. 권장 구현 순서와 예상 종속성

```text
사람: P0-00 package/identity 즉시 확인
  ↓
P0-01 release scope ADR
  ├─ AI/Gemma OFF 결정 → P0-10 단순화 + P0-11 해결
  ├─ Health Connect OFF 결정 → P0-09 단순화
  └─ Guardian OFF/ON 결정 → P0-05 범위 확정
  ↓
P0-02 CI baseline 복구
  ↓
P0-03 FGS + P0-04 notifications + P0-12 queries + P0-13 App Link
  ↓
P0-05 Guardian + P0-06 Firestore + P0-07 deletion/backup
  ↓
P0-08 data map/privacy/Data safety + P0-15 claims
  ↓
P0-14 signing + P0-16 store assets
  ↓
전체 release artifact/실기기 matrix/Play pre-launch
  ↓
Closed test → production access → staged production
```

Guardian/AI/Health를 ON으로 선택하면 해당 보안·정책 작업은 생략할 수 없다. 일정이 부족하면 기능을 release에서 제거하는 것이 “문서상 완료”로 속이는 것보다 안전하다.

---

## 12. 공식 근거 — 2026-09-28 확인

정책 요약보다 링크 원문과 Play Console의 현재 상태가 우선한다.

### 계정·등록·테스트

- [Registering Play package names — 2026-09-30](https://support.google.com/googleplay/android-developer/answer/16984799?hl=en)
- [Contact information requirements](https://support.google.com/googleplay/android-developer/answer/10840893?hl=en)
- [Device verification for new accounts](https://support.google.com/googleplay/android-developer/answer/14316361?hl=en)
- [12 testers / 14 days for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- [Create and set up an app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)

### 빌드·배포

- [Target API level requirement — API 36 from 2026-08-31](https://developer.android.com/google/play/requirements/target-sdk)
- [Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en)
- [64-bit requirement](https://developer.android.com/google/play/requirements/64-bit)
- [16KB page sizes — current 2027-02-01 enforcement text](https://developer.android.com/guide/practices/page-sizes)
- [Store listing and app bundle size/version information](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)

### 개인정보·앱 콘텐츠

- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Firebase Android data disclosure](https://firebase.google.com/docs/android/play-data-disclosure)
- [Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
- [Prepare app for review / privacy / access / audience / rating](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)
- [Preview asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en)

### 건강·권한·AI

- [Health Content and Services](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en)
- [Health apps declaration](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en)
- [Android Health Permissions guidance](https://support.google.com/googleplay/android-developer/answer/12991134?hl=en)
- [FGS declaration and video requirements](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en)
- [Android exact vs inexact alarms](https://developer.android.com/develop/background-work/services/alarms/schedule)
- [AI-Generated Content policy / in-app reporting](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en)
- [AI-created visual asset declaration](https://support.google.com/googleplay/android-developer/answer/17262077?hl=en)

---

## 13. 이 감사가 확인하지 못한 외부 상태

저장소 밖이므로 담당자가 Console에서 증거를 추가해야 한다.

- Play developer 계정 생성일·Personal/Organization 유형·신원/기기 검증 상태.
- `com.teammemorylink.memorylink` package registration 실제 상태.
- Play App Signing 활성화와 Google-held signing certificate fingerprints.
- 현재 Play Data safety/Health/FGS/content rating 제출·승인 상태.
- Firebase 운영 rules가 저장소 `firestore.rules`와 동일한지 여부.
- Firebase App Check, budget alert, API restriction, anonymous auth abuse quota 상태.
- 삭제 이메일의 실제 운영 담당자와 7일 이내 처리 이력.
- Play pre-launch report, 12명/14일 closed test, production access 승인 상태.
- 16KB ARM64 실기기/에뮬레이터의 실제 전체 기능 실행 결과.

이 항목은 “코드에서 보이지 않음”을 “미설정”으로 단정하지 말고, Console 캡처나 export로 확인한다.
