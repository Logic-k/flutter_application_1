# Claude Code 실행 핸드오프 — MemoryLink 디자인·모션 후속 개발

> 문서 상태: **실행 가능 정본** · 작성 2026-09-28
> 대상 저장소: `E:\Test_Android\flutter_application_1`
> 목표: 현재 기능·데이터·경로를 변경하지 않고 전 화면 디자인·상태·모션·접근성을 점진 개선한다.
> 사용법: Claude Code 새 세션은 **루트 `CLAUDE.md` 다음으로 이 파일 전체를 읽고**, 한 번에 작업 패킷 하나만 수행한다.

---

## 0. Claude Code에 주는 임무

MemoryLink는 60~80대와 MCI 사용자를 주요 대상으로 하는 Flutter 인지 건강 앱이다. 현재 기능은 이미 충분하고 자동화 방어선도 크다. 이 작업의 목적은 신기능 추가나 전면 재작성보다 다음 네 가지다.

1. 모든 비동기 화면에서 로딩·빈 상태·실패·정상·제출·성공을 분명히 보인다.
2. 라벤더 브랜드를 유지하면서 큰 보라 면과 동일한 둥근 카드 반복을 줄여 위계를 만든다.
3. 모션 강도는 낮게 유지하되 모든 행동에 짧고 일관된 피드백을 제공한다.
4. 44개 경로, 저장 부작용, 센서·권한·AI 폴백·PDF·보호자·관리자 기능을 그대로 보존한다.

**한 줄 방향:** `Calm Expressive Lavender — 조용한 돌봄, 분명한 반응`.

**완료의 의미:** 예쁜 스크린샷이 아니라 기능 parity + 상태 계약 + 접근성 + 모션 3단 + 자동화 + 실기기 성능이 모두 통과한 상태다.

---

## 1. 지시 우선순위와 읽기 순서

### 1.1 충돌 시 우선순위

1. 실제 코드와 통과 테스트
2. 이 문서의 기능 보존 계약
3. 루트 `CLAUDE.md`
4. 루트 `DESIGN.md`
5. `docs/design/MEMORYLINK_DESIGN_MOTION_ARCHITECTURE.md`
6. 화면 시안·스크린샷·과거 계획

코드와 문서가 다르면 코드를 정본으로 확인하고 문서 드리프트를 보고한다. 기능 의미를 문서에 맞추려고 임의 변경하지 않는다.

### 1.2 세션 시작 시 읽을 파일

필수:

```text
CLAUDE.md
이 파일
DESIGN.md
lib/core/theme.dart
lib/core/ml_widgets.dart
lib/core/motion/app_motion.dart
lib/core/motion/motion_settings.dart
lib/core/router.dart
```

해당 작업 파일과 테스트를 추가로 읽는다. 전체 연구의 세부 근거가 필요할 때만 아래 부록을 연다.

- `MEMORYLINK_FEATURE_PRESERVATION_CONTRACT.md` — 44경로·데이터 상세
- `MEMORYLINK_DESIGN_MOTION_AUDIT.md` — 화면별 현황
- `MEMORYLINK_DESIGN_RESEARCH_EVIDENCE.md` — 외부 근거 등급
- `MEMORYLINK_DESIGN_MOTION_ARCHITECTURE.md` — 토큰·컴포넌트 상세
- `MEMORYLINK_DESIGN_MOTION_MASTER_PLAN.md` — 전체 계획 원문

과거 `docs/plans/08_MOTION_SYSTEM_GLOBAL.md`는 현재 모션 시스템의 형성 기록이다. 이미 완료된 패킷과 낡은 수치가 섞여 있으므로 **새 작업 순서는 이 문서의 G0~G12를 따른다.**

---

## 2. 현재 검증 기준선

> **2026-10-05 메모 — 이 문서 작성(9/28) 뒤 출시 감사로 바뀐 사실.** 코드가 정본이다(§1.1).
> - AI 대화는 `Gemini(개발 빌드, 키가 있을 때) > LocalFallback` 두 단계다. 온디바이스 Gemma는 16KB 페이지 기기
>   비호환으로 제거됐다(LAUNCH_AUDIT P0-11). 아래 §3-10의 Gemma는 지난 사실이다.
> - 보호자 링크는 v2다: 128비트 토큰, 30일 만료, 이름·걸음·점수만 공개(§4.4의 '16자 token'은 v1).
> - 출시 범위의 정본은 `docs/release/ADR-001_first_release_scope.md`, 수치 정본은 `DEVELOPMENT_ROADMAP.md` §1이다.
>   Maestro 게이팅 목록은 `maestro/gating_flows.txt`(23개)이고, 하단 탭은 좌표가 아니라 탭 이름으로 누른다.
> - `/voice_assessment` 화면 이름은 '말하기 기록'이다(감사 P0-15 비의료 표현). 중지 화면 자체는 그대로다.

| 항목 | 현재 정본 | 주의 |
|---|---:|---|
| GoRouter | **44경로** | `router.dart`의 `GoRoute(` 직접 계산 |
| 메인 탭 | **5개** | 홈·인지훈련·생활습관·리포트·내정보 |
| 훈련 활동 | **8개** | 점수형 7 + 참여형 일상 회상 |
| SQLite v9 | **10테이블** | 디자인 PR에서 schema 변경 금지 |
| 일반 테스트 파일 | **53개** | `test/**/*_test.dart`만 계산, `test/helpers/*.dart` 제외, 감소 금지 |
| `flutter test` | **394/394 통과** | 2026-09-28 실측 |
| integration | **2파일·4/4 통과** | `emulator-5554`, `IS_EMULATOR=true` |
| analyze | error 0·warning 0·info 4 | `--no-fatal-infos`에서 exit 0 |
| Maestro 게이팅 | **21개** | `$flows` 배열 정본, 이 핸드오프 작성 중 재실행하지 않음 |
| 대표 PNG | 14개 | 2026-07 화면이라 현재 코드보다 낡음 |

검증 명령:

```powershell
flutter analyze --no-fatal-infos
flutter test
flutter test integration_test -d <device-id> --dart-define=IS_EMULATOR=true
.\run_maestro_tests.ps1
```

`flutter analyze` 기본 실행은 기존 info 4개 때문에 이 환경에서 종료 코드 1이 될 수 있다. info를 숨기지 말고 위치와 개수가 4 이하인지 보고한다.

---

## 3. 절대 금지선

위반이 필요해 보이면 구현을 중단하고 이유와 대안을 보고한다.

### 기능·데이터

1. 44개 route 삭제·경로 변경·병합 금지.
2. 5탭 순서·라벨·`IndexedStack`·`FloatingPillNav` 의미 변경 금지.
3. 로그인·온보딩·admin redirect 변경 금지.
4. `onboardingRoutes`에서 `/dementia_centers` 제거 금지.
5. `trainingCatalog` ID/route/category/prerequisite/initial unlock 변경 금지.
6. SQLite schema/migration/CRUD/reset 범위 변경 금지.
7. Firestore collection/field/`ownerUid`/guardian token/payload 변경 금지.
8. 센서 샘플링·보행 계산·`StepAnomalyPolicy` 변경 금지.
9. 점수·XP·streak·난이도·잠금 알고리즘 변경 금지.
10. AI 우선순위 `Gemma local > Gemini > LocalFallback` 변경 금지.
11. AI 대화 자동 영구 저장 금지. 사용자가 저장할 때만 `voice` score를 쓴다.
12. gait session DB 저장 신설 금지. 현재는 메모리 요약만 제공한다.
13. PDF 데이터 의미·의료 면책·점수 밴드 변경 금지.
14. `/voice_assessment` 중지 화면 활성화·삭제 금지.
15. admin release gate 완화 금지.

### 기술·디자인

16. `pubspec.yaml` dependency 추가·변경 금지.
17. Provider/go_router를 다른 프레임워크로 교체 금지.
18. `material_ui` migration을 리디자인과 동시 수행 금지.
19. `ThemeMode.light`를 이번 범위에서 해제 금지.
20. 화면 코드의 `Duration(milliseconds:)` 직접 사용 금지.
21. raw `Color(0x...)`, Material 원색, 임의 radius 사용 금지.
22. 반복/자동재생/shimmer/parallax/marquee/blur 진입 금지.
23. `CustomTransitionPage`·`pageTransitionsTheme` 추가 금지.
24. 기존 Maestro selector·테스트 assertion 삭제·약화 금지.
25. `dart format` 전체 실행 금지. 저장소 압축 스타일을 보존한다.
26. 사용자 작업 파일을 덮어쓰거나 관련 없는 파일을 stage/commit하지 않는다.

---

## 4. 기능 보존 지도

### 4.1 44개 route

```text
Core (11)
/  /login  /register  /consent  /onboarding
/assessment  /cognitive_tasks  /assessment_result
/report_options  /training_hub  /training_history

Training (8)
/game/comparison  /game/sequence  /game/sudoku  /game/multiplication
/game/shape_match  /game/categorization  /game/reading  /training/recall

User features (11)
/memory_garden  /diary_book  /guardian_link  /voice_assessment
/dementia_centers  /ai_chat  /walking_dashboard  /profile
/ondevice-ai  /settings  /health_input

CS (7)
/cs_center  /cs/notices  /cs/notice_detail/:id  /cs/faq
/cs/inquiry_submit  /cs/my_inquiries  /cs/inquiry_detail/:id

Admin (7)
/admin_login  /admin/dashboard  /admin/user_detail/:userId
/admin/cs_management  /admin/notice_edit  /admin/faq_edit
/admin/inquiry_detail/:id
```

### 4.2 Redirect 불변조건

- 미로그인 일반 경로 → `/login`.
- 로그인 상태에서 auth 경로 → 미온보딩 `/consent`, 완료 `/`.
- 미온보딩은 consent/onboarding/assessment/cognitive/result/center만 접근.
- admin portal disabled 빌드의 모든 `/admin*` → `/` 또는 `/login`.
- admin 세션 없는 admin 상세 → `/admin_login`.

### 4.3 GoRouter 밖에서 반드시 보존할 UI

- `MemoryOpening` overlay/skip/reduce motion.
- `EditProfileScreen` MaterialPageRoute와 camera/gallery/remove sheet.
- PDF preview MaterialPageRoute, print, share.
- Training result bottom sheet.
- API key dialog/editor.
- reset/logout/model delete dialog.
- license page.
- privacy/AI Studio/HuggingFace/map external URL.
- guardian/center/anomaly tel·sms.
- guardian link·PDF system sharesheet.

### 4.4 데이터 계약

| 영역 | 현재 쓰기 | 보존해야 할 의미 |
|---|---|---|
| auth | users + random session token | password hash/salt와 legacy migration |
| scores | `training_scores` | category·0~100 의미와 명시적 저장 시점 |
| gamification | attempts/progress/unlocks | idempotent attempt, XP, streak, prerequisite |
| steps | `daily_steps` | 사용자·날짜 분리, 거리·칼로리 |
| diary | `diary_entries` | 하루 1건 upsert, 3년 보관, 오늘만 편집 |
| health | `health_logs` | 하루 1건, nullable vitals, 14일 추세 |
| guardian | `guardian_views/{token}` | ownerUid, 16자 token, anomaly fallback |
| CS | notices/faqs/inquiries/replies | 사용자·관리자 read/write/reply |
| settings | SharedPreferences | 기존 key 이름과 기본값 |

Reset은 다음 7테이블만 삭제한다.

```text
training_attempts
training_user_progress
training_activity_progress
training_unlocks
training_scores
daily_steps
health_logs
```

`users`, `diary_entries`, `daily_active_users`, guardian token, 설정은 보존한다.

---

## 5. 디자인 정본

### 5.1 North star

- 차분한 건강 관리 제품이며 게임 앱이나 AI 데모처럼 보이지 않는다.
- 사용자는 3초 안에 “이 화면이 무엇이고 다음에 무엇을 누르는지” 알아야 한다.
- 접근성이 미학보다 우선한다.
- 한 화면 주 행동 1개, main choice 최대 5개를 목표로 한다.
- 익숙한 위치·라벨·아이콘·back을 유지한다.
- 숫자에는 비수치 설명을 함께 제공한다.

### 5.2 색·타입·형태

- primary `#6C5CE7` 유지.
- 화면당 dominant accent 1개, 큰 gradient hero 0~1개.
- category 색 동시 3개 이하, 텍스트·아이콘 동반.
- 건강 status는 면색과 글자색을 분리하고 색만으로 전달하지 않는다.
- Pretendard 400/500/600/700/800 외 굵기 금지.
- 화면 본문 15~16sp, 보조 12~13sp, 주요 수치·행동 16sp 이상.
- 데이터 숫자는 `FontFeature.tabularFigures()`.
- 모든 card를 26 radius+shadow로 만들지 않는다.

Card role:

```text
hero        화면 핵심 요약, 0~1개, gradient 허용
standard    일반 정보, flat/outline
interactive 전체 card tap + press feedback
data        값+단위+해석, overshoot 금지
support     오류·경고·도움·면책, icon+text
```

### 5.3 추가할 semantic token

기존 값으로 시작해 먼저 이름만 만든다.

```text
screenHorizontal = 22
screenHorizontalForm = 24
screenTop = 6~8
controlGap = 8
itemGap = 12
contentGap = 16
cardGap = 20
sectionGap = 24
heroPadding = 22
bottomSafeContent = FloatingPillNav.contentBottomInset
```

추가 elevation role: `flat`, `raised`, `hero`, `floating`.

Responsive:

```text
compact  <600  : 현 5탭 floating nav, 1열
medium   600~839: 현 nav 우선 유지, max-width 640~720
expanded >=840 : P3에서 NavigationRail 검토, max-width 1200
```

text scale 1.4 이상에서는 넓은 화면도 form/metric을 1열로 되돌릴 수 있다.

---

## 6. 상태 컴포넌트 계약

### 6.1 모든 비동기 화면

```text
loading    무엇을 불러오는지 + layout-shaped static skeleton
empty      값이 없는 이유 + 첫 행동
error      쉬운 설명 + retry 또는 fallback
content    실제 데이터
refreshing 기존 content 유지 + 작은 progress
```

### 6.2 입력·제출 화면

```text
editing         visible label과 변경 상태
validationError field 가까운 오류 + 수정 방법
submitting      CTA disabled + 진행 문구
submitError     입력 보존 + retry
success         방금 끝난 행동 + 다음 단계
```

규칙:

- error를 empty로 바꾸지 않는다.
- null을 0으로 바꾸지 않는다.
- raw exception을 사용자에게 노출하지 않는다.
- refresh 중 기존 content 위치를 움직이지 않는다.
- 상태 메시지는 필요할 때 `Semantics(liveRegion: true)`로 한 번 알린다.
- state widget은 비즈니스 로직을 갖지 않고 전달받은 상태만 그린다.

추가할 공통 컴포넌트:

```text
MLScreenFrame
MLCardRole / role-aware MLCard
MLAsyncPanel
MLFormSection
MLStatusBanner
MLMetricSummary
MLPrimaryAction
```

기존 `theme.dart`와 `ml_widgets.dart` API는 안정화 전까지 유지하거나 re-export한다.

---

## 7. 모션 정본

### 7.1 철학

`MOTION_INTENSITY=2`를 유지한다. 모션 개수를 늘리는 대신 **행동 피드백이 빠진 상태를 없앤다.**

### 7.2 값

| token | 값 | 용도 |
|---|---:|---|
| `AppMotion.press` | 100ms | 누름 |
| `AppMotion.fade` | 150ms | 색·불투명도·상태 |
| `AppMotion.enter` | 200ms | 화면 내 진입·퇴장 |
| `AppMotion.route` | 300ms | 기존 page/control transition |
| `AppMotion.stagger` | 60ms | 자식 간 간격 |
| choreography | ≤400ms | 최대 4 group |
| translate | 8px | section enter |
| press scale | 0.98 | full only |
| burst | 600ms | 1회성 정답·저장 |
| celebrate | ≤2.5s | 훈련 결과·오프닝 예외 |

### 7.3 MotionLevel

| pattern | full | fadeOnly | none |
|---|---|---|---|
| press | scale+opacity | opacity | 즉시 상태 |
| screen enter | 8px+fade | 동시 fade | 최종 상태 |
| state switch | fade | fade | 즉시 |
| chart/value | 200ms | 즉시 | 즉시 |
| message | size+fade | fade | 즉시 |
| shake | 작게 | 없음 | 없음 |
| particles | 1회 | 없음 | 없음 |
| route | 플랫폼 기본 | 플랫폼 설정 | 플랫폼 설정 |

### 7.4 화면 정책

```text
Opening/Login       brand full, 1회
Onboarding          section full
Assessment          fadeOnly
Training hub/history first-entry full
Games               entry none, action feedback full
Home                first-entry full
Walking/Reports     first-entry + chart/value only
Diary               functional calendar + save one-shot
AI Chat             bubble fade/size, page stagger 없음
Profile/Settings    section 최대 3group
Guardian/CS         state/section fade
Admin               state fade + chart only
Blocked/legal/error none/fade
```

금지: 반복 pulse/bounce/confetti/shimmer, autoplay, parallax, animated blur, scroll 장식, 데이터 spring overshoot, 재진입 stagger, 전역 custom route.

---

## 8. 현재 화면별 변경 계약

| 화면군 | 보존 | 개선 | 모션 | 핵심 테스트 |
|---|---|---|---|---|
| Opening | skip/loading/reduce | 추가 장식 없음 | 기존 1회 | opening widget/Maestro |
| Login | auth/session/error | hierarchy/autofill | logo flight만 | auth 전체 |
| Register | fields/goal/unlock | 3 section, 2열→1열 | section≤3 | row/unlock/320×2.0 |
| Consent | 필수2/선택1 | 필수·선택 명료화 | state fade | register flow |
| Onboarding | goal/route | 기존 card 정리 | 기존 | widget/reduce |
| Assessment | 10문항/채점 | task frame·시간 안내 | fadeOnly | score/5초/back |
| Result | risk/disclaimer/center | 해석 우선 | fade | redirect/disclaimer |
| MainNav | 5탭/state/TickerMode | 셸 유지 | fade 조건부 | shell/309dp/state |
| Home | 데이터·모든 진입 | 주 행동1, hero1, 분리 | 기존 | navigation/home/profile |
| Training | 8활동·잠금·XP | hub 위계만 | 기존 | unit/integration/Maestro |
| Games | 문제·score·난이도 | GameTemplate 미세 정합 | feedback full | 모든 game test |
| Walking | permission/service/steps/gait | 상태·null·순서 | chart/count | deny/anomaly/profile |
| Diary | today/past/STT/3년 | error+save feedback | garden 600ms | DB/reduce/keyboard |
| AI Chat | memory-only/10턴/fallback/save | 추천≤3/error/send target | bubble fade | provider/save timing |
| Reports | scores/summary/PDF | no-data/error/date/series | chart | fixture/PDF CTA |
| PDF | 4step/preview/share/print | summary/data retention | 기존 | bytes/share |
| Profile/Edit | 모든 link/update/image | section/form | fade | routes/camera/back |
| Settings/Model | prefs/reset/provider/download | state component | progress | exact reset/token/file |
| Health | upsert/14일/null | error+numeric explanation | chart/state | DB/input |
| Guardian | token/QR/payload/tel/sms/share | token error/CTA | state fade | fake Firestore/external |
| Center/CS | hotline/CSV/4 CS 기능 | async 통일 | fade/list | repository/Maestro |
| Admin | gate/7route/CRUD | desktop density | state/chart | guard/admin E2E |
| Voice blocked | 중지 안내 | 그대로 | none | blocked test |

---

## 9. 알려진 현재 결함과 우선순위

### Must fix first

1. AI Chat의 `AiChatService.chat` 예외 처리 부재: loading 고정 가능.
2. Walking·Reports·Health가 일부 오류를 빈 데이터처럼 처리.
3. Diary 초기 load 실패 시 loading 고정 가능.
4. Guardian token 생성 실패 시 QR loading 고정 가능.
5. Reports chart의 series/date 의미 불일치와 no-data 0선.
6. AI send/custom control의 48/56dp 실측 필요.
7. 320dp × text scale 2.0 전 화면 matrix 부재.
8. route/redirect/admin 계약 test 부재.
9. MainNav 전체 shell test 부족.
10. PDF bytes와 guardian payload contract test 부재.
11. `AndroidManifest.xml`에 predictive-back opt-in 없음. 별도 플랫폼 PR 필요.
12. admin 7경로 E2E 게이팅 부재.

### Documentation drift

- README Lottie 배지와 현재 pubspec 불일치.
- README/PROJECT_DOCS 화면·의존성·폰트·죽은 기능 정보가 과거 상태.
- DEVELOPMENT_ROADMAP의 320건/44파일은 과거 기준선.
- 루트 PNG는 2026-07 화면.
- social ranking UI는 삭제됐지만 guardian의 global stats update는 남아 있음.

문서 drift를 이유로 기능 코드를 삭제하지 않는다.

---

## 10. 실행 순서 G0~G12

### G0 Baseline capture

- `git status --short`로 사용자 변경 확인.
- analyze/test/integration/Maestro를 실행하고 SDK/device/date 기록.
- 44 route, test file, Maestro flow를 재계산.
- 현재 UI·상태 screenshot.
- SQLite/Provider/Firestore fake fixture.
- 최저 사양 profile trace와 startup.
- predictive-back manifest 부재를 별도 issue로 기록.

**Exit:** 재현 가능한 before bundle.

### G1 Characterization/contract tests

신규 목표와 담당 issue:

| 계약 테스트 | 담당 issue | 범위 |
|---|---|---|
| `router_contract_test` | DS-001 | 44 route + redirect 5조건 + admin gate |
| `main_nav_shell_test` | DS-002 | 5탭·overlay·state·309dp |
| `data_preservation_test` | DS-003 | reset 7테이블·보존 데이터 |
| `ai_provider_contract_test` | DS-010 | provider 우선순위·명시적 save |
| `guardian_sync_contract_test` | DS-013 | payload·성공/실패 fallback |
| `clinical_pdf_smoke_test` | DS-012 | `%PDF`·page/data marker |
| `all_screen_accessibility_test` | DS-007 | label·48/56dp·contrast |
| `large_text_layout_test` | DS-007 | 320dp×2.0 critical screens |
| `motion_level_contract_test` | DS-005~011 관련 화면 | 3단 정보 동등성 |
| `state_restoration_smoke_test` | DS-016 | back/background/rotation |

DS-001은 `test/widget/core/router_contract_test.dart` 한 파일을 우선 사용한다. 실제 `GoRouter`를 pump해 등록 경로와 redirect를 검증하며 DS-002의 MainNav 셸 렌더 검증을 섞지 않는다. admin-disabled 분기는 일반 테스트에서 `kReleaseMode=false`라 현재 코드 그대로는 도달할 수 없으므로 test seam 없이 해당 assertion을 완료할 수 없다. `createAppRouter`에 기본값이 기존 `AppConfig.isAdminPortalEnabled`인 optional boolean test seam을 최소 추가한다. 기본 호출의 production 동작이 같다는 테스트를 동반하고, 다른 AppConfig 동작은 바꾸지 않는다.

현재 결함 test는 assertion을 약화하지 말고 명시적 backlog로 둔다.

**Exit:** 44개 route 등록 assertion과 §4.2 redirect 5조건이 각각 통과하고, admin enabled/disabled·admin session 유무를 모두 재현한다. route 개수만 맞으면 완료가 아니다.

### G2 Foundation tokens

spacing/elevation/layout/content-width token을 **현재 값 그대로** 도입한다. 초기 PR은 시각 diff가 없어야 한다.

**Exit:** token test/guard, 전체 green.

### G3 Shared components

MLScreenFrame/CardRole/AsyncPanel/FormSection/StatusBanner/MetricSummary를 독립 component demo/test에서 구현한다.

**Exit:** 모든 state×MotionLevel×a11y test, 기존 화면 영향 0.

### G4 Critical state/accessibility

순서: `AI Chat → Reports → Walking → Health → Diary → Guardian → Register`.

먼저 state를 올바르게 보이고 나중에 레이아웃을 바꾼다.

**Exit:** error가 empty로 보이는 핵심 경로 0, retry/fallback, raw exception 0.

### G5 Main shell + Home

Home section/Selector, 주 행동1, hero1. Floating nav와 5탭 의미는 유지. 탭 fade는 state/frame test를 통과할 때만.

### G6 Training presentation lock

Hub/history만 정합. GameTemplate·score·XP·unlock·Hero·result sheet 의미는 변경하지 않는다.

### G7 Diary + AI Chat polish

- Diary: 저장 one-shot garden feedback.
- Chat: bubble insert, 추천 주제, provider error/fallback.

저장 시점과 데이터는 동일해야 한다.

### G8 Walking + Reports + Health data language

null/0, actual date/series, source/time, textual summary. PDF 의미는 변경하지 않는다.

### G9 Secondary user screens

Register/Consent → Assessment → Profile/Edit → Settings/Model → Guardian/Center → CS.

### G10 Admin

공통 token/state만 적용. 소비자용 hero/stagger/confetti 금지. 7 route E2E를 추가한다.

### G11 Adaptive + dark, separate PRs

- Adaptive: 기능 parity와 state preservation 먼저.
- Dark: semantic text 4색과 dark contrast test 먼저.
- 둘을 한 PR에 섞지 않는다.

### G12 `material_ui` evaluation, separate branch

Flutter 3.47 opt-in migration이다. dependency public type 호환과 bridge를 조사하고 전체 gate를 다시 실행한다. 사용자 가치가 없으면 formal deprecation까지 보류한다.

---

## 11. 구현 issue 목록

### P0/P1 — 먼저 수행

| ID | 작업 | 주요 파일 | Exit |
|---|---|---|---|
| DS-001 | route/redirect/admin test | `lib/core/router.dart`, `test/widget/core/router_contract_test.dart` | 44 route 등록 + redirect 5조건 + admin enabled/disabled/session assertion |
| DS-002 | MainNav shell test | `lib/features/navigation/main_nav_screen.dart`, `test/widget/core/main_nav_shell_test.dart` | 5탭/state/309dp |
| DS-003 | data reset fixture | DB/UserProvider test | 7 delete·보존 확인 |
| DS-004 | semantic tokens | theme/design_system | visual diff 없음 |
| DS-005 | shared components | ml_widgets/design_system | state×motion×a11y |
| DS-006 | critical async states | chat/report/walk/health/diary/guardian | empty≠error |
| DS-007 | large text matrix | critical screen tests | 320×2.0 |
| DS-008 | Home hierarchy | home/main nav | 주 행동1·hero1·state |
| DS-009 | Reports semantics | reports/analyzer | actual series/date/no-data |
| DS-010 | Chat contract | ai_chat/ai providers | error/fallback/save timing |
| DS-011 | Diary feedback | diary/motion | row 동일·3단 |
| DS-012 | PDF smoke | report generator/options | `%PDF`/preview/share |
| DS-013 | Guardian contract | guardian sync/screen | payload/failure/external |

**DS-001 최소 읽기 세트:** 루트 `CLAUDE.md`, 이 문서 §2·§3·§4.1~4.2·§10 G0/G1·§11·§12, `lib/core/router.dart`, `lib/core/app_config.dart`, `lib/core/user_provider.dart`, `lib/core/admin_provider.dart`와 기존 test helper. 디자인·모션 §5~§8은 DS-001이 presentation을 변경하지 않으므로 첫 test 작성에는 선택 사항이다.

### P2

| ID | 작업 |
|---|---|
| DS-014 | Register/FormSection responsive |
| DS-015 | Assessment task frame/time policy |
| DS-016 | Walking permission/revoke/restoration |
| DS-017 | Profile/Edit/Settings/Model pass |
| DS-018 | Center/CS support pass |
| DS-019 | Admin route/CRUD E2E |
| DS-020 | current screenshot/demo regeneration |

### P3 — 별도

| ID | 작업 |
|---|---|
| DS-021 | medium/expanded shell |
| DS-022 | dark semantic colors |
| DS-023 | material_ui compatibility spike |
| DS-024 | optional focal Rive research; 기본 결정은 dependency 없음 |

---

## 12. Claude Code 세션 실행 프로토콜

### 12.1 Boot

1. `git status --short` 실행.
2. `CLAUDE.md`와 이 파일을 읽음.
3. 선택된 DS/G 패킷 관련 코드·테스트만 읽음.
4. 사용자 변경 파일과 이번 작업 파일을 구분.
5. 코딩 전에 아래를 출력:
   - 작업 패킷
   - preserve 목록
   - 변경 파일 예상
   - 추가/실행할 테스트
   - rollback

### 12.2 Characterize

1. 현재 동작을 코드와 테스트로 설명.
2. 저장/route/permission/fallback side effect를 목록화.
3. 빠진 test를 먼저 작성하거나 기존 test로 잠겼음을 증명.
4. 현재 결함이면 test를 억지로 green으로 만들지 않고 기대 동작을 명시.

### 12.3 Implement

1. 한 화면 또는 한 token 묶음만 수정.
2. 기능 로직과 presentation을 같은 PR에 섞지 않음.
3. 기존 Provider/Service를 그대로 연결.
4. 모든 state와 MotionLevel 구현.
5. stable Key/Semantics를 사용하고 기존 Maestro 의미를 보존.

### 12.4 Validate

가벼운 것부터 실패 즉시 수정한다.

```powershell
# 변경 파일 관련 targeted test
flutter test test/<target>.dart

# 정적 분석
flutter analyze --no-fatal-infos

# 전체 unit/widget
flutter test

# 실제 main/DB/router 흐름
# `flutter devices`로 실제 ID를 확인. 현재 검증 예시: emulator-5554
flutter test integration_test -d emulator-5554 --dart-define=IS_EMULATOR=true

# 사용자 E2E
.\run_maestro_tests.ps1
```

추가 수동 검증:

- 320/360/600/840dp.
- text scale 1.0/1.3/1.6/2.0.
- full/fadeOnly/none.
- TalkBack/VoiceOver/Voice Access.
- predictive back/background/lock/orientation.
- permission grant/deny/revoke.
- 최저 사양 profile frame.

### 12.5 Report

완료 보고에 반드시 포함:

```text
패킷/issue:
변경 파일:
보존한 기능·데이터:
구현한 상태:
모션 full/fadeOnly/none:
추가·수정 테스트:
analyze 결과:
test 결과:
integration 결과:
Maestro 결과:
실기기/접근성/성능 결과:
못 한 검증과 이유:
rollback:
다음 패킷:
```

검증하지 않은 항목을 “문제 없음”으로 보고하지 않는다.

---

## 13. Git·PR 규칙

- 작업 시작 전 status 확인.
- 관련 파일만 stage.
- `git add .`, force/reset/clean 금지.
- 요청 없이 commit/push/PR 생성 금지.
- 커밋이 필요하면 화면 1개 또는 token 1묶음 단위.
- 한글 commit message는 파일+`git commit -F`.
- 기존 test를 지우거나 skip해서 green 만들지 않는다.
- PR description에 before/after screenshot, DB/payload diff, 테스트, rollback을 붙인다.

### PR 체크리스트

```text
[ ] 해당 route와 비라우트 surface 보존
[ ] DB/Firestore/SharedPreferences side effect 동일
[ ] loading/empty/error/content 및 제출 상태
[ ] full/fadeOnly/none 동일 정보
[ ] Android 48dp / 주요 CTA 56dp
[ ] contrast와 color 외 단서
[ ] 320dp×2.0, 600/840dp
[ ] back/state/keyboard/permission
[ ] targeted + analyze + full test
[ ] integration + Maestro 또는 미실행 이유
[ ] profile trace 또는 성능 비영향 근거
[ ] rollback 가능
```

---

## 14. Rollback 전략

- PR 단위 revert가 기본.
- DB migration, route, service 변경을 만들지 않아 rollback이 데이터에 영향을 주면 안 된다.
- pure token/accessibility 수정은 flag 없이 적용.
- Home/Reports/AI처럼 큰 화면은 필요할 때만 compile-time `ML_UI_V2`를 **새로 제안**할 수 있다. 현재 flag가 존재한다고 가정하지 않는다.
- 새/구 view는 동일 Provider/ViewModel instance를 사용.
- remote flag는 오프라인-first 복잡도 때문에 도입하지 않는다.
- 접근성·보안·데이터 안전 수정은 구 UI와 함께 롤백하지 않는다.
- 게이트 실패 시 다음 화면으로 진행하지 않는다.

---

## 15. 성능·접근성 예산

### 성능

```text
60Hz p95 UI/raster frame <= 16ms on target low-end profile device
screen choreography <= 400ms
stagger groups <= 4
simultaneous full-screen animation <= 1
repeating animation = 0
hidden tab ticker = 0
redesign runtime dependency addition = 0
```

RepaintBoundary, lazy tab, clip/shadow 제거는 추측으로 적용하지 않고 DevTools 전후 수치가 좋아질 때만 유지한다.

### 접근성

- Android 48dp, iOS 참고 44pt, MemoryLink 주요 CTA 56dp.
- 일반 text 4.5:1, 큰 text·필수 control/graphic 3:1.
- 색만으로 상태 전달 금지.
- 200% text에서 정보·기능 손실 금지.
- 아이콘 단독 핵심 action 금지; visible label 우선.
- 오류·성공·진행을 시각 및 programmatic status로 제공.
- 사용자가 움직임과 알림을 통제.
- back으로 작업을 잃지 않음.

---

## 16. 사용자 검증

자동 테스트는 인지 이해를 증명하지 않는다. prototype, P1 종료, release candidate에서 60~80대·MCI 특성 사용자와 보호자를 포함해 같은 fixture로 before/after를 비교한다.

Task:

1. 홈에서 오늘 할 훈련 찾기.
2. 훈련 완료 후 결과와 다음 행동 설명.
3. 일기 저장 여부 확인.
4. 보행 권한 거부 후 복구.
5. 리포트 숫자와 해석 설명.
6. PDF preview/share.
7. guardian 공유·실패 대안.
8. 건강 기록·추세 찾기.
9. 1분 방해 후 현재 단계 복귀.
10. reduce motion 선호·불편.

기록: 성공/중단, 오탭, back, 도움 요청, 완료시간, 확신, 의미 재설명, 모션 불편. 소규모 결과를 임상 효과로 표현하지 않는다.

---

## 17. 외부 리서치 요약

- WCAG 2.2: 규범 acceptance.
- Android Core App Quality 2026-09: 모든 screen/dialog/flow, 48dp, 16ms, state preservation, lazy permission.
- Flutter 3.47: Material 3 기본, 공식 accessibility test, predictive back, profile mode.
- W3C COGA: familiar design, clear step, 중요한 행동 우선, 오류 복구, memory 부담 감소. Working Group Note이며 WCAG 규범은 아님.
- M3 Expressive: color/shape/size/motion/containment로 핵심 행동 발견을 돕는 연구 방향. Google UX 연구 주장이지 임상 근거가 아님.
- Wonderous: custom motion+accessibility reference.
- SoFi: package/점진 migration/test.
- Tonal: health custom chart+선택적 Rive.
- Rive Editor: focal stateful graphics 가능성.
- Reflectly/Superlist: Flutter 제작만 공식 확인; 구현 세부는 추정하지 않음.
- Flutter 3.47 `material_ui`: opt-in 이행 단계, 별도 branch에서만 평가.

주요 URL은 `MEMORYLINK_DESIGN_RESEARCH_EVIDENCE.md`에 있다.

---

## 18. 재사용 프롬프트

### 18.1 세션 시작 프롬프트

```text
너는 MemoryLink Flutter 디자인·모션 후속 개발 담당이다.
먼저 루트 CLAUDE.md와 docs/design/CLAUDE_CODE_DESIGN_IMPLEMENTATION_HANDOFF.md 전체를 읽어라.
그 다음 git status --short를 실행하고 사용자 미커밋 파일을 구분하라.

이번 세션은 [DS-XXX 또는 G-X] 하나만 수행한다.
코딩 전에 다음을 보고하라:
1. 해당 기능·route·데이터 불변조건
2. 현재 동작과 기존 테스트
3. 변경할 파일
4. state와 full/fadeOnly/none 설계
5. 320dp×textScale2.0 전략
6. 실행할 검증과 rollback

기능 로직·route·DB·Provider·Service·dependency를 바꾸지 마라.
테스트 assertion과 Maestro selector를 약화하지 마라.
계획과 코드가 다르면 코드가 정본이며 차이를 보고한 뒤 멈춰라.
```

### 18.2 화면 구현 프롬프트

```text
[DS-XXX: 화면명]만 구현하라.
핸드오프 §3 금지선과 §4 데이터 계약을 먼저 인용하라.
현재 화면의 normal/loading/empty/error/editing/submitting/success/disabled 중 해당 상태를 표로 만들고,
MLScreenFrame/MLCard role/MLAsyncPanel/MLFormSection/MLStatusBanner/MLMetricSummary를 우선 재사용하라.

모션은 AppMotion 토큰과 MotionSettings full/fadeOnly/none만 사용한다.
반복·자동재생·blur·parallax·전역 route transition·새 패키지는 금지다.
기존 Provider/Service 결과와 저장 시점을 그대로 유지한다.

characterization test를 먼저 작성하고 화면을 구현한 뒤 targeted test, analyze, full test를 실행하라.
기기 기능이면 integration/Maestro/profile 결과까지 보고하라.
```

### 18.3 테스트 선행 프롬프트

```text
[DS-001/002/003 등 contract test]만 수행하라.
현재 구현을 characterization하되 현재 결함을 원하는 동작으로 고정하지 마라.
route count, redirect, DB row, payload, save timing처럼 사용자에게 보이지 않는 계약을 fixture로 잠가라.
테스트를 통과시키기 위한 production code 변경은 하지 말고, seam이 정말 필요하면 최소 제안만 보고하라.
기존 테스트 삭제·skip·assertion 완화 금지.
```

### 18.4 리뷰 프롬프트

```text
현재 diff를 MemoryLink 기능 보존 관점에서 독립 리뷰하라.
CLAUDE.md와 핸드오프를 읽고 다음을 파일:줄로 확인하라:
- route/redirect/DB/payload/save timing 변화
- Provider/Service/algorithm 변경 혼입
- raw color/radius/duration 및 dependency
- 빠진 async state와 null/0 혼동
- full/fadeOnly/none 정보 차이
- 반복 모션/400ms/4group 위반
- 48/56dp, contrast, semantics, 320×2.0
- back/state/permission/predictive back
- 테스트·Maestro assertion 약화
- rollback 가능성

BLOCKER/HIGH/MEDIUM/LOW로 보고하고, 문제가 없을 때만 PASS라고 하라.
```

### 18.5 실패 복구 프롬프트

```text
검증 실패를 숨기지 말고 최초 실패부터 원인을 분리하라.
1. 변경 전에도 실패했는지 baseline과 비교
2. 기능 회귀인지 selector/layout 회귀인지 분류
3. 가장 작은 관련 diff만 수정
4. 같은 targeted test 재실행
5. 통과 후 상위 test로 확장

테스트를 삭제·skip하거나 assertion을 약화하지 마라.
기능 로직 수정이 필요하면 현재 디자인 PR을 중단하고 별도 issue로 분리하라.
해결 불가 시 해당 화면 PR을 revert할 정확한 파일 목록을 보고하라.
```

---

## 19. 작업 상태 기록 양식

Claude Code는 패킷 완료 때 아래 표의 해당 행만 갱신하거나 별도 status 문서가 이미 생겼다면 그 문서를 갱신한다. 완료 증거 없는 `done` 금지.

| Gate | 상태 | 증거 | 다음 |
|---|---|---|---|
| G0 Baseline | done 2026-09-29 (저사양 실기기 profile 제외) | `docs/design/baseline/G0_2026-09-29/BASELINE.md` — test 394/394·analyze info 4·integration 4/4·Maestro 1차 20/21(cs_center flaky, 재실행 PASS)·스크린샷 28·보호자 화면 기존 결함 발견 | DS-001 |
| G1 Contract tests | done 2026-09-29 (미커밋) | `docs/design/baseline/G3_2026-09-29/report_G1-G3.html` — router_contract·main_nav_shell·data_preservation, router.dart seam, Maestro 라우팅 5/5, backlog skip 2(라우터 온보딩 우회·309dp 탭 overflow) | DS-004 |
| G2 Foundation | done 2026-09-29 (미커밋) | `lib/core/design_system/foundations/` 현재 값 그대로·미연결, design_tokens_test | DS-005 |
| G3 Components | done 2026-09-30 (미커밋) | components 6 + patterns 1 미연결, design_system_components_test, 독립 리뷰 PASS, 최종 test 454/454·skip 2·analyze info 4 | DS-006 (사용자 확인 후) |
| G4 Critical states | not started | — | DS-006~007 |
| G5 Home/Nav | not started | — | DS-008 |
| G6 Training | not started | — | regression lock |
| G7 Diary/Chat | not started | — | DS-010~011 |
| G8 Data screens | not started | — | DS-009/012/013 |
| G9 Secondary | not started | — | DS-014~018 |
| G10 Admin | not started | — | DS-019 |
| G11 Adaptive/Dark | separate | — | DS-021/022 |
| G12 material_ui | separate | — | DS-023 |

---

## 20. Claude Code가 먼저 수행할 권장 작업

새 디자인 구현부터 시작하지 않는다. 다음 순서가 안전하다. **DS-001은 test-only지만 G0 기준선 기록이 끝난 뒤 시작하며 병행하지 않는다.** 그래야 새 테스트가 드러낸 결함과 기존 기준선 실패를 구분할 수 있다.

1. **G0**: 현재 branch·tests·screenshots·profile 기준선.
2. **DS-001**: 44 route/redirect/admin contract test.
3. **DS-002**: MainNav 5탭 shell/overlay/state test.
4. **DS-003**: reset 7테이블과 보존 데이터 fixture.
5. **DS-004**: visual diff 없는 semantic tokens.
6. **DS-005**: 기존 화면에 연결하지 않은 shared component test bed.
7. **DS-006**: AI Chat error/loading부터 핵심 async state 개선.

첫 구현 후보는 AI Chat이지만, **G0~G3 없이 화면부터 바꾸지 않는다.**

---

## 21. 최종 Definition of Done

한 화면 또는 패킷이 완료되려면:

```text
[ ] preserve/change가 명시됨
[ ] route·데이터·권한·외부 action parity
[ ] 필요한 모든 상태 구현
[ ] full/fadeOnly/none 동일 정보
[ ] 320/360/600/840 및 1.0/1.3/1.6/2.0
[ ] 48dp/56dp·대비·색 외 단서·semantics
[ ] back/keyboard/background/permission
[ ] targeted/analyze/full test
[ ] integration/Maestro 또는 구체적 미실행 사유
[ ] profile 성능 또는 비영향 증거
[ ] before/after와 fixture diff
[ ] 독립 리뷰 PASS
[ ] 정확한 rollback
```

모든 화면이 위 조건을 통과하고, 44 route·394+ tests·integration·Maestro·실기기 task가 유지될 때 전체 리디자인을 완료한다.
