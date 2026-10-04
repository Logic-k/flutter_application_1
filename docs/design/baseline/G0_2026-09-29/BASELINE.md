# G0 Baseline — 2026-09-29

> 핸드오프 `docs/design/CLAUDE_CODE_DESIGN_IMPLEMENTATION_HANDOFF.md` §10 G0의 before bundle.
> 이후 DS/G 패킷의 회귀 판정은 이 폴더의 수치·로그·스크린샷과 비교한다.
> 이 폴더는 **추가 전용**이다. 코드·테스트·설정 파일은 G0에서 한 줄도 바꾸지 않았다.
> HTML 리포트: 같은 폴더 `report.html` · 게시본 https://claude.ai/artifact/MuneJMYvirBKz275iDGZfb (비공개)

## 1. 기준 코드와 환경

| 항목 | 값 |
|---|---|
| 측정일 | 2026-09-29 (KST 21:44~) |
| 브랜치 | `devin/release-hardening` @ `27ca9d3` (origin 대비 ahead 2, 미푸시) |
| 작업 트리 | `lib/`·`test/`·`integration_test/`·`maestro/`·`android/` = HEAD 그대로. 사용자 변경은 아래 §2 |
| Flutter | 3.41.5 stable (framework `2c9eb20739`, engine `c1db59d880`) · Dart 3.11.3 · DevTools 2.54.2 |
| 호스트 | Windows 11 Home 10.0.26200 · RAM 15.6GB (측정 내내 가용 0.6~2.7GB, 작업 세트 트리밍으로 확보) |
| 에뮬레이터 | `QA_Device` → `emulator-5680` · Android 16 / API 36 · `sdk_gphone64_x86_64` · 1440×3120 @560dpi · `-gpu angle_indirect -no-snapshot-load -no-boot-anim -no-audio` · `/data` 7.7G 중 여유 1.8G |
| 앱 빌드 | debug APK `--dart-define=IS_EMULATOR=true` 229.9MB · `versionName 1.0.0` · `minSdk 26` · `targetSdk 36` |
| Maestro | 2.6.0 (`C:\maestro\maestro\bin`) · JAVA_HOME = Android Studio jbr |

핸드오프 §2는 `emulator-5554`로 적혀 있으나 이 PC는 Hyper-V 포트 예약 때문에 `-port 5680`으로 기동한다. 기기 ID만 다르고 AVD·옵션은 이전 실측과 같다.

## 2. 사용자 작업 파일 (G0 시작 시 `git status --short`)

```text
 M CLAUDE.md          디자인·모션 후속 개발 진입점 절 추가(+10), 08 계획 참조 문구 교체
 M DESIGN.md          §1 Maestro 게이팅 정본을 $flows 배열(21)로 명시(+2 −1)
?? .kiro/
?? .research/
?? docs/LAUNCH_AUDIT_2026-09-28.md
?? docs/design/        (핸드오프·MEMORYLINK_* 부록 5종 — 이 baseline 폴더만 G0 산출물)
?? docs/plans/TRACK_D_비회귀계약.md
```

G0는 위 파일을 읽기만 했다. 새로 만든 것은 `docs/design/baseline/G0_2026-09-29/` 한 폴더뿐이다.

## 3. 자동 검증 결과

| 게이트 | 명령 | 결과 | 로그 |
|---|---|---|---|
| analyze | `flutter analyze --no-fatal-infos` | **error 0 · warning 0 · info 4**, exit 0 (160.6s) | `logs/analyze.txt` |
| unit/widget | `flutter test` | **394 / 394 통과**, skip 0, exit 0 (67s) | `logs/flutter_test.txt`, `logs/flutter_test.json` |
| integration | `flutter test integration_test/<file> -d emulator-5680 --dart-define=IS_EMULATOR=true` | **2파일 · 4 / 4 통과** — `training_flow_test` 1/1 (712s), `auth_flow_test` 3/3 (893s) | `logs/integration_*.txt` |
| Maestro 게이팅 | `$flows` 21개, flow별 `maestro test` 종료 코드 | (§4) | `maestro/results.tsv`, `maestro/<flow>.log` |

analyze info 4개 위치(기존과 동일, 전부 스타일 힌트):

```text
lib/core/ml_widgets.dart:197:7   use_null_aware_elements
lib/core/ml_widgets.dart:248:7   use_null_aware_elements
lib/core/theme.dart:121:24       unnecessary_nullable_for_final_variable_declarations
lib/features/training/games/shape_match_game.dart:223:7   use_null_aware_elements
```

integration은 메모리 압박(Gradle `-Xmx8G` + 에뮬레이터 4.5GB) 때문에 핸드오프의 디렉터리 단위 명령 대신
파일 단위로 나눠 돌렸다. 대상 테스트 집합은 같다. 케이스마다 약 4분 20초가 걸렸다(원인은 조사하지
않음 — 이후 패킷에서 integration 소요가 크게 늘면 이 값과 비교). `training_flow_test` 로그의
"Some possible finders for the widgets at Offset(210.6, 472.8)" 5줄은 실패 경고가 아니라 live 테스트
바인딩이 기기 쪽 포인터 입력 1건을 받았을 때 출력하는 안내이며, 그 지점 최상단은 `MemoryOpening`이었다.
테스트 종료 시 flutter가 앱을 제거하므로 Maestro 전에 일반 debug APK를 다시 설치했다.

## 4. Maestro 게이팅

**1차 연속 실행 20 / 21** (22:24~22:57, 약 33분, 한 프로세스로 21개를 끝까지 실행 — 이전 기록은 모두 분할 실행이었다).
실패 1건 `cs_center_flow`는 곧바로 단독 재실행해 **PASS**(88s) → 결정적 결함이 아니라 **불안정 flow**다.

| # | flow | 1차 | 초 |
|---:|---|---|---:|
| 1 | login_flow | PASS | 88 |
| 2 | login_fail_flow | PASS | 85 |
| 3 | register_flow | PASS | 115 |
| 4 | navigation_flow | PASS | 100 |
| 5 | training_hub_flow | PASS | 95 |
| 6 | profile_flow | PASS | 98 |
| 7 | cs_center_flow | **FAIL** → 재실행 PASS | 87 / 88 |
| 8 | reports_flow | PASS | 87 |
| 9 | voice_assessment_flow | PASS | 91 |
| 10 | guardian_link_flow | PASS | 79 |
| 11 | home_detail_flow | PASS | 76 |
| 12 | ai_chat_flow | PASS | 76 |
| 13 | memory_garden_flow | PASS | 69 |
| 14 | training_game_flow | PASS | 103 |
| 15 | edit_profile_flow | PASS | 60 |
| 16 | clinical_report_flow | PASS | 58 |
| 17 | training_progression_flow | PASS | 102 |
| 18 | training_persistence_flow | PASS | 203 |
| 19 | training_accessibility_flow | PASS | 95 |
| 20 | dementia_center_flow | PASS | 77 |
| 21 | opening_flow | PASS | 118 |

`cs_center_flow` 실패 분석(`maestro/cs_center_flow_FAIL.png`, `cs_center_flow_maestro.log`):
`scrollUntilVisible`이 고객센터 카드가 `FloatingPillNav` 알약 **뒤에 가려진 위치**에서 멈췄고, 이어진
`tapOn`이 카드 대신 '내정보' 탭에 떨어져 고객센터 화면이 열리지 않았다(5초 대기 후 "공지사항" 카드 미발견).
2026-08-21 `profile_flow`가 같은 원인으로 실패해 `centerElement: true`로 고친 전례가 있고,
`cs_center_flow`에는 그 옵션이 없다. **제품 기능 결함이 아니라 flow의 스크롤 정지 위치 의존**이다.
CLAUDE.md 규칙 6에 따라 yaml은 고치지 않았다(셀렉터 변경은 아니지만 보고 후 별도 판단).

게이팅이 놓치는 것 — `guardian_link_flow`는 내 정보 탭의 카드 텍스트만 확인하고 보호자 연결 **화면에
들어가지 않는다**. 아래 §9-1의 적색 오류 화면을 이 게이트는 잡을 수 없다.

## 5. 화면·성능 기준선

### 스크린샷 (`screenshots/`, 1440×3120 원본 PNG 28장)

| 폴더 | 만든 flow (비게이팅 촬영용) | 장수 | 결과 |
|---|---|---:|---|
| `tour/` | `hanium_screens.yaml` → 00~12, `hanium_screens2.yaml` → 13~15 | 15 | 앞 flow는 13단계에서 exit 1 — 음성 진단 카드 부제가 "인지 건강 초기 진단 재실행"에서 "정확도 개선을 위해 현재 사용 중지"로 바뀐 뒤 갱신되지 않은 낡은 셀렉터. 13~15는 뒤 flow가 찍었다 |
| `design_review/` | `design_review_shots.yaml` | 12 | exit 0. 로그인·홈 2·허브·게임·정답 배지 2·결과 시트·생활습관·리포트·내 정보·설정 |
| 루트 | `opening_flow`(게이팅) 부산물 | 1 | `gating_opening_hold.png` — flow가 저장소 루트에 남긴 파일을 옮김 |

상태 화면(loading·empty·error·submitting)은 기존 flow로 재현할 수 없어 **찍지 못했다**.
단, 투어 중 보호자 연결 화면이 실제 error 상태(적색 오류 화면)로 찍혔다 — §9-1.

### 시작 성능

| 측정 | 조건 | 값 | 이전 |
|---|---|---:|---|
| `am start -W` TotalTime run1 | debug APK, `pm clear` 직후 (ROADMAP §1과 같은 방법) | **7,889ms** | 7,456ms (09-20) |
| run2 | force-stop 후 재시작, 데이터 유지 | 9,202ms | 4.35s (09-20 "2회차") |
| run3 | 같음 | 7,628ms | |
| profile `--trace-startup` | profile APK, x86_64 에뮬레이터 | 첫 프레임 **3,055ms** · 래스터 3,243ms · 프레임워크 초기화 634ms | 없음 (첫 측정) |

이번 측정 동안 호스트 가용 메모리가 0.6~2.3GB였고(09-20 조건은 기록 없음) 09-27에 `MemoryOpening`이
추가됐다. 재시작 값이 09-20보다 크지만 조건이 달라 **회귀로 판정하지 않는다**. 로그: `logs/cold_start.txt`,
`logs/profile_start_up_info.json`, `logs/profile_trace_startup.txt`.

**저사양 실기기 profile trace는 하지 못했다** — 연결된 실기기가 없다(`adb devices`는 에뮬레이터 1대).
위 profile 값은 x86_64 에뮬레이터 대체값이며 핸드오프 §15의 "60Hz p95 ≤16ms on low-end device" 판정에는 쓸 수 없다.

## 6. 재계산한 구조 수치 (`fixtures/recount.txt`)

| 항목 | 재계산 | 핸드오프 §2 | 비고 |
|---|---:|---:|---|
| `GoRoute(` | **44** (경로 파싱 44, 중복 0) | 44 | 핸드오프 §4.1 목록과 경로 **집합이 정확히 일치**(diff 0) |
| 훈련 활동 route | 8 | 8 | `trainingActivityById(id).route` 7개 + `/training/recall` |
| 일반 테스트 파일 | **53** (`test/**/*_test.dart`, helpers 2개 제외) | 53 | |
| 테스트 case | **394** | 394 | |
| integration 파일 | 2 | 2 | |
| Maestro 게이팅 | **21** (`$flows`) | 21 | |
| Maestro 최상위 YAML | **28** = 게이팅 21 + 비게이팅 7 | 28 | 비게이팅: demo_recording ×3, screenshot_tour, design_review_shots, hanium_screens, hanium_screens2 |
| SQLite | `user_version=9`, **10테이블** | v9·10 | `fixtures/sqlite_schema_v9.txt` |

문서 드리프트(수정하지 않고 기록만):

- `DEVELOPMENT_ROADMAP.md` §1은 "데모·스크린샷 **4**"라 적지만 실제 비게이팅 YAML은 **7**개다
  (`design_review_shots`·`hanium_screens`·`hanium_screens2`가 빠져 있음). 같은 절의 320건/44파일은
  핸드오프 §9가 이미 지적한 과거 기준선이다.
- 핸드오프 §17·§10 G12는 Flutter 3.47을 전제로 적지만 이 PC의 SDK는 **3.41.5**다. G12(material_ui) 전에 확인 필요.

## 7. 데이터 픽스처 스냅샷 (`fixtures/`)

| 파일 | 내용 | 만든 방법 |
|---|---|---|
| `sqlite_schema_v9.txt` | fresh `onCreate` DB의 DDL 전체, 테이블 10개, debug 시드 직후 행 수 | 스크래치 테스트로 in-memory DB를 열어 `sqlite_master` 덤프. 원본 `build/g0_scratch/`는 analyze에 잡혀(warning 2) DS-001 중 삭제했고 사본은 `fixtures/schema_dump_test.dart.txt` — 다시 쓸 때 `build/` 아래로 복사해 `flutter test <path>` |
| `firestore_write_contract.txt` | `guardian_views`·`global_stats`·`notices`·`faqs`·`inquiries/replies`·`training_difficulty` 쓰기 지점과 필드 | 소스 추출 |
| `shared_preferences_keys.txt` | SharedPreferences 키와 기본값 읽기 지점 | 소스 추출 |
| `recount.txt` | 44경로 목록, 테스트 파일 53개, `$flows` 21개, 비게이팅 7개 | 스크립트 재계산 |

debug 시드 직후 행 수: users 3 · training_scores 240 · daily_steps 60 · daily_active_users 25 ·
diary_entries 20 · training_unlocks 15 · training_user_progress 3 · 나머지 3테이블 0.

현재 테스트 대역 현황(이후 DS-003·DS-013이 채울 공백):

- **SQLite**: `sqflite_common_ffi` + `DatabaseHelper.resetForTest()` in-memory 격리가 이미 있다(`database_helper_test`, `database_v9_migration_test`).
- **Provider**: `test/helpers/test_helpers.dart`의 `pumpWithProviders`(User·Difficulty·TrainingProgress·Settings 4종)와 `mock_definitions.dart`의 mocktail mock 6종 + `FakeSettingsProvider`. 앱 본체 `main.dart`는 Provider 8종(User·Gait·Pedometer·Settings·Admin·Diary·Difficulty·TrainingProgress)을 쓴다.
- **SharedPreferences**: `setMockInitialValues` 사용 테스트 4개.
- **Firestore**: 테스트 대역이 **없다**. `fake_cloud_firestore` 미의존이고 `FirebaseService.setAvailableForTest(false)` 가드만 있다. pubspec 변경 금지이므로 DS-013은 수제 fake나 seam이 필요하다.

## 8. 별도 이슈 — predictive back opt-in 부재 (플랫폼 PR 대상, G0에서는 수정하지 않음)

- `android/app/src/main/AndroidManifest.xml`의 `<application>`·`<activity>` 어디에도
  `android:enableOnBackInvokedCallback`이 없다.
- 설치 APK의 `targetSdk`는 **36**이다(Flutter 3.41.5 `FlutterExtension.targetSdkVersion = 36`).
  Android 16 동작 변경 문서에 따르면 targetSdk 36 앱은 **Android 16 이상 기기에서는 플래그 없이도**
  시스템 predictive back 애니메이션(back-to-home·cross-task·cross-activity)이 기본 켜진다.
  → 플래그 부재의 실제 영향 범위는 **Android 13~15 기기**(opt-in 필요)다. 핸드오프 §9-11의
  "opt-in 없음"은 이 범위로 좁혀 읽어야 한다.
- 앱 내부 route의 predictive back 전환(`PredictiveBackPageTransitionsBuilder`)은 `pageTransitionsTheme`
  추가 금지 규칙(CLAUDE.md 모션 규칙 5)과 얽혀 있어 같은 플랫폼 PR에서 따로 판단해야 한다.
- 근거: https://developer.android.com/about/versions/16/behavior-changes-16 (2026-09-29 확인)

## 9. G0에서 새로 드러난 기존 결함 (수정하지 않음, 별도 이슈 후보)

1. **보호자 연결 화면 적색 오류 — `IS_EMULATOR=true` 빌드에서 항상 재현** (`screenshots/tour/12_guardian_link.png`)
   - 화면: `[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()`
   - 경로: `lib/main.dart:100` `if (isEmulator) return;`이 에뮬레이터 QA 빌드에서 Dart 쪽
     `FirebaseService.initialize()`(= `Firebase.initializeApp()`)를 의도적으로 건너뛴다(네이티브
     `FirebaseInitProvider`는 logcat상 성공). 그런데 `lib/features/profile/guardian_link_screen.dart:20`이
     필드 초기화에서 `GuardianSyncService()`를 만들고, `guardian_sync_service.dart:32`가 즉시
     `FirebaseFirestore.instance`를 읽어 State 생성 시점에 예외가 난다. `FirebaseService.isAvailable` 확인이 없다.
   - 영향: 에뮬레이터 QA·시연 빌드에서 보호자 연결 화면 전체 사용 불가(debug 적색, release라면 회색 박스).
     실기기에서도 `Firebase.initializeApp()`이 실패하면(`FirebaseService`가 "로컬 전용 모드로 계속"을 약속하는 경로)
     같은 예외가 날 구조다 — 실기기 재현은 하지 않았다.
   - 게이트 공백: `guardian_link_flow`는 카드 텍스트만 확인하고 화면에 진입하지 않는다.
   - 핸드오프 §9 must-fix 4("Guardian token 생성 실패 시 QR loading 고정")보다 앞단의 결함이다. DS-013/G4 Guardian 작업의 첫 확인 대상.
2. **`cs_center_flow` 불안정** — §4. `centerElement: true` 추가 여부는 사용자 판단(Maestro yaml 변경 보고 규칙).
3. **`hanium_screens.yaml` 낡은 셀렉터** — §5. 비게이팅 촬영용이라 품질 게이트에는 영향 없음.

## 10. 보존해야 할 불변조건 (이후 패킷의 판정 기준 요약)

- **Route 44개** — 경로 집합은 `fixtures/recount.txt`, 핸드오프 §4.1과 diff 0.
- **Redirect 5조건** (`lib/core/router.dart:59-101`): ① 미로그인 일반 경로 → `/login` ② 로그인 상태의 `/login`·`/register` →
  미온보딩 `/consent`, 완료 `/` ③ 미온보딩은 `/consent`·`/onboarding`·`/assessment`·`/cognitive_tasks`·`/assessment_result`·`/dementia_centers`만
  ④ `AppConfig.isAdminPortalEnabled == false`면 모든 `/admin*` → 로그인 `/`, 미로그인 `/login` ⑤ admin 세션 없는 `/admin/*`(`/admin_login` 제외) → `/admin_login`.
  `isAdminPortalEnabled = !kReleaseMode || ADMIN_CODE_SHA256 주입` — 일반 테스트에서는 항상 true라 ④는 현재 코드로 도달 불가(핸드오프 G1이 seam을 예고).
- **5탭** 홈·인지훈련·생활습관·리포트·내정보, `IndexedStack` + `FloatingPillNav`.
- **훈련 8활동** id/route/prerequisite — `training_catalog.dart`.
- **SQLite v9 10테이블**, reset 7테이블(`resetUserMeasurementData`: training_attempts·training_activity_progress·training_unlocks·training_user_progress·training_scores·daily_steps·health_logs). users·diary_entries·daily_active_users 보존.
- **Firestore** collection/field — `fixtures/firestore_write_contract.txt`. **SharedPreferences** 키·기본값 — `fixtures/shared_preferences_keys.txt`.
- **AI** `Gemma local > Gemini > LocalFallback`(이번 에뮬레이터 빌드 로그: "API 키 없음 → LocalFallback 사용").

## 11. 검증하지 않은 것 (통과로 보고하지 않음)

- 저사양 **실기기** profile trace·frame p95 — 실기기 없음.
- 상태 화면(loading·empty·error·submitting) 스크린샷 — 기존 flow로 재현 불가. 보호자 연결 error만 우연히 포착.
- 320/360/600/840dp × text scale 1.0~2.0 매트릭스, TalkBack·Voice Access, 권한 grant/deny/revoke, predictive back 제스처 — G0 범위의 자동 실행 대상이 아니었다.
- `.\run_maestro_tests.ps1` 스크립트 자체 — 백그라운드 PowerShell 러너가 중간에 죽은 전례 때문에 같은 판정(flow별 `maestro test` 종료 코드)을 Bash 루프로 돌렸다. flow 목록·순서는 `$flows`와 동일.
- integration 디렉터리 단위 1회 실행 — 파일 단위로 나눠 실행했다.

## 12. 재현 방법

```powershell
# 에뮬레이터 (포트 예약 회피 + angle_indirect)
D:\Android\SDK\emulator\emulator.exe -avd QA_Device -port 5680 -no-snapshot-load -no-boot-anim -no-audio -gpu angle_indirect
flutter analyze --no-fatal-infos
flutter test
flutter test integration_test/training_flow_test.dart -d emulator-5680 --dart-define=IS_EMULATOR=true
flutter test integration_test/auth_flow_test.dart -d emulator-5680 --dart-define=IS_EMULATOR=true
flutter build apk --debug --dart-define=IS_EMULATOR=true ; adb -s emulator-5680 install -r build\app\outputs\flutter-apk\app-debug.apk
.\run_maestro_tests.ps1        # 또는 flow별 maestro test maestro/<flow>.yaml
# 스크린샷: 출력 폴더로 이동 후 maestro test <repo>/maestro/design_review_shots.yaml (hanium_screens*.yaml 동일)
adb -s emulator-5680 shell pm clear com.teammemorylink.memorylink ; adb -s emulator-5680 shell am start -W -n com.teammemorylink.memorylink/.MainActivity
flutter run --profile --trace-startup -d emulator-5680 --dart-define=IS_EMULATOR=true   # → build/start_up_info.json
```

## 13. Rollback

G0는 코드·테스트·설정·Maestro yaml을 바꾸지 않았다. 되돌릴 것은 이 폴더 하나다.

- 기준선 폐기: `docs/design/baseline/G0_2026-09-29/` 삭제(미추적 파일, 커밋·스테이징 안 함).
- 핸드오프 §19 표의 G0 한 행을 이번에 갱신했다 — 되돌리려면 그 행을 `not started`로 복원.
- 스크래치 `build/g0_scratch/`는 삭제했다(사본 `fixtures/schema_dump_test.dart.txt`).
- 에뮬레이터에는 IS_EMULATOR debug APK가 다시 설치돼 있다(게이팅 상태). 기기 상태 되돌리기는 불필요.

## 14. 다음 패킷

G0 종료. **DS-001(route/redirect/admin contract test)은 시작하지 않았다** — 사용자 지시("먼저 G0만")에 따라
다음 프롬프트를 기다린다. DS-001 착수 시 이 폴더의 394/394·info 4·route 44 diff 0이 비교 기준이다.
