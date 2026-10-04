# MemoryLink 전 화면 디자인·모션 마스터 플랜

> 작성: 2026-09-28 · 상태: 실행 준비안
> 목표: 현재 기능·데이터·경로를 하나도 잃지 않고 MemoryLink를 더 세련되고 일관되며 반응이 풍부한 Flutter 앱으로 개선한다.

## 0. 함께 읽을 정본

1. [기능 보존·비회귀 계약](MEMORYLINK_FEATURE_PRESERVATION_CONTRACT.md)
2. [전 화면 디자인·모션 감사](MEMORYLINK_DESIGN_MOTION_AUDIT.md)
3. [2차 리서치 근거 장부](MEMORYLINK_DESIGN_RESEARCH_EVIDENCE.md)
4. [디자인·모션 마스터 아키텍처](MEMORYLINK_DESIGN_MOTION_ARCHITECTURE.md)
5. 저장소 루트 [DESIGN.md](../../DESIGN.md)

충돌 시 우선순위는 **코드/테스트 계약 → 기능 보존 계약 → DESIGN.md → 마스터 아키텍처 → 화면 시안**이다.

## 1. Executive decision

채택할 방향은 **Calm Expressive Lavender — 조용한 돌봄, 분명한 반응**이다.

- 라벤더 브랜드, Pretendard, 5탭, 큰 타깃, 익숙한 Material control은 유지한다.
- 큰 라벤더 면·같은 둥근 카드의 반복을 줄여 정보 위계를 만든다.
- 모션 강도는 `DESIGN.md`의 2를 유지하고 action feedback coverage를 높인다.
- opening/login/onboarding/training/data chart의 기존 모션은 재사용한다.
- 신규 핵심 모션은 AI bubble, diary save, 명확한 async state에 집중한다.
- 모든 화면에 stagger를 넣지 않는다. 평가·대화·관리 화면은 fadeOnly/상태 피드백 중심이다.
- Provider, go_router, SQLite/Firestore/SharedPreferences 계약은 유지한다.
- `material_ui` 전환, dark mode 복구, 상태관리 교체는 이번 리디자인과 분리한다.

## 2. 완료 성공 기준

리디자인 완료는 다음이 모두 참일 때만 선언한다.

### 기능

- GoRouter **44/44** 경로와 5탭 기능 parity.
- 비라우트 표면(EditProfile, PDF preview, result sheet, dialog, external URL/tel/sms/share) parity.
- SQLite v9의 schema, migration, row 의미, reset 삭제 범위 동일.
- AI provider 우선순위와 “명시적 결과 저장” 시점 동일.
- 보행 권한·background service·anomaly fallback 동일.
- Firestore ownerUid/token/collection/payload 의미 동일.
- PDF option/preview/print/share와 관리자 release gate 동일.

### 시각·상태

- 핵심 async 화면의 loading/empty/error/content 100% 구분.
- 입력 화면의 editing/submitting/error/success 상태 구분.
- 한 화면 hero 최대 1개, dominant accent 1개.
- 동일 역할 component의 색·radius·spacing·feedback 일관.
- null과 0, offline과 error, disabled와 unavailable을 시각·텍스트로 구분.

### 모션

- 모든 action에 즉시 press/state feedback.
- 일반 choreography 400ms 이하, 4 group 이하.
- 자동 반복·shimmer·parallax·marquee 0.
- full/fadeOnly/none에서 정보·결과 동일.
- hidden tab ticker 0, 숫자 overshoot 0.

### 접근성·성능

- Android 48dp 하한, 주요 CTA 56dp, floating nav 48dp 예외.
- text 4.5:1, 큰 글자·필수 graphic/control 3:1.
- 320/360/600/840dp와 text scale 1.0/1.3/1.6/2.0에서 핵심 기능 손실 0.
- TalkBack/VoiceOver/Voice Access로 핵심 task 완료.
- predictive back/background/lock/orientation에서 의도치 않은 데이터 손실 0.
- 최저 사양 실제 기기 profile에서 60Hz p95 UI/raster frame이 16ms 예산 안; 초과 frame 원인 기록.

### 자동화

- `flutter analyze`: error/warning 0, 기존 info 증가 0.
- 기존 test file/case 감소 0, 전체 pass.
- integration 2파일 pass.
- Maestro 게이팅 21/21 pass.
- route/data/component 신규 contract test pass.

## 3. 화면군별 마스터 변경표

| 화면군 | 절대 보존 | 디자인 변경 | 모션 정책 | 필수 검증 |
|---|---|---|---|---|
| Opening | loading 병렬, skip, reduce motion | 로고·시간 유지, 추가 장식 없음 | brand full 1회 | opening widget+Maestro |
| Login | SQLite auth, session token, 오류 | 입력/CTA/오류 hierarchy 정리 | 기존 logo flight만 | auth unit/widget/integration/Maestro |
| Register | 필드·validation·goal code·초기 unlock | 3 section, 큰 글자에서 2열→1열 | section 3group | 가입 row/unlock + 320/2.0 |
| Consent | 필수 2·선택 1, 다음 조건 | 필수/선택 status 명료화 | fade state only | register flow, semantics |
| Onboarding | goal enum·assessment 이동 | 현재 card 유지, copy 정리 | 기존 full | widget + reduce motion |
| Assessment survey | 10문항·answer·auto advance | 제목/진행/질문/답 위치 고정 | page slide/fade | score/route/back |
| Cognitive tasks | 단어·방해·회상·주의 채점 | task frame 통일, 준비/시간 안내 | fadeOnly | 5초 계약, score fixture, 2.0 |
| Assessment result | risk 계산·면책·센터·complete | 숫자보다 해석 우선 | result fade | redirect whitelist, disclaimer |
| MainNav | 5탭 순서·IndexedStack·TickerMode | compact shell 유지 | 조건부 150ms fade | shell integration, 309dp, state |
| Home | 모든 진입·오늘 데이터·recommendation | 주 행동 1개, hero 1개, section 분리 | 기존 first-entry | Maestro detail/navigation, Selector |
| Training hub | 8활동·잠금·목표·기록 | today 3 우선, course 전체 유지 | 기존 full | catalog/unit/Maestro |
| 7 scored games | 문제·난이도·score·XP·unlock | GameTemplate 위계만 미세 조정 | action feedback full, entry none | 모든 game widget/E2E |
| Daily recall | always unlocked·participation XP | score처럼 보이지 않게 유지 | save/complete one-shot | completion test |
| Training history | filter·attempt rows | async/empty refinement | first-entry full | persistence/widget |
| Walking/Gait | permission·tracking·steps·gait memory | 추적→오늘→session→trend 순 | chart/count 기존 | deny/revoke/service/anomaly |
| Diary | 오늘 edit·과거 read-only·STT·3년 | 상태 pill, error, save feedback | 600ms garden one-shot | DB row, STT off, reduce motion |
| Diary book | 내림차순·empty·back | skeleton, card meaning 명료화 | fadeOnly | list/empty/back |
| AI Chat | memory-only messages·10턴·STT·provider·explicit save | 추천 주제≤3, error/fallback, 56dp send | bubble size+fade | provider/error/save timing |
| Reports | 4 score·summary·PDF entry | no-data/error, 실제 date/series | chart/value 기존 | fixture chart, PDF CTA |
| PDF options/preview | 4단계·risk·caregiver·preview/share/print | step summary·back/data retention | 기존 page slide | file bytes/page/Share |
| Profile | 모든 hub entry | section hierarchy, 항목 삭제 금지 | section fadeOnly | profile Maestro/routes |
| Edit profile | image source·field update | form section/visible errors | state fade | camera/gallery/save/back |
| Settings | font/voice/haptic/sound/motion/reminder/AI/reset/license/logout | section/component 통일 | 기존 first-entry | prefs/reset exact scope |
| On-device AI | HF token·1.5GB·progress·delete/provider | state panel 통일 | progress only | file/token/provider/error |
| Health | day upsert·14일·nullable metrics | load/save error, numeric explanation | chart+save state | DB fixture, input formats |
| Guardian | token/QR/sync/payload/tel/sms/share | token error, critical CTA above fold | state fade | Firestore fake, external actions |
| Dementia center | CSV/filter/1899-9988/call/map | hotline 항상 노출, result state | fadeOnly | asset/repository/Maestro |
| CS user | 4 hub entry·Firestore CRUD/read | 기존 async pattern 전체 통일 | list first-entry/fade | CS Maestro + error fixtures |
| Admin 7 routes | release gate·CRUD·extra payload | desktop density·standard Material | state/chart only | router guard + admin E2E |
| Voice blocked | 중지 상태·안내 | 유지 | none | blocked widget/Maestro |

## 4. 실행 DAG와 우선순위

### P0 — 계약과 기반: G0~G3

#### G0. Baseline capture

**진입:** 현재 branch가 실행 가능.

**작업:**

1. `flutter analyze`, `flutter test`, integration 2개, Maestro 21개 결과를 날짜·SDK·device와 기록.
2. router GoRoute count=44, test file=53, Maestro=21을 script로 재계산.
3. 현재 빌드로 14개 대표 화면과 추가 상태 화면을 재촬영.
4. 주요 task의 SQLite/Provider/Firestore fake payload fixture를 저장.
5. 최저 사양 profile trace와 cold/warm start 기록.
6. 현재 `AndroidManifest.xml`에 `android:enableOnBackInvokedCallback="true"`가 없음을 기록하고, 별도 플랫폼 호환 PR에서 opt-in한 뒤 Android 13~최신 버전의 back preview/cancel/complete를 검증한다. 디자인 전환과 같은 PR에 섞지 않는다.

**종료:** 재현 가능한 baseline bundle 존재.

**롤백:** 변경 없음.

#### G1. Characterization/contract tests

**의존:** G0.

**신규 방어선:**

- `router_contract_test`: 44 route path + redirect matrix + admin gate.
- `main_nav_shell_test`: 5탭, 309dp, nav overlay, tab state.
- `data_preservation_test`: reset exact table scope, diary/setting/user 보존.
- `ai_provider_contract_test`: local model/Gemini/fallback, explicit voice save.
- `guardian_sync_contract_test`: success/failure payload와 anomaly fallback.
- `clinical_pdf_smoke_test`: `%PDF` bytes, non-empty pages/data markers.
- `all_screen_accessibility_test`: critical controls label/48dp.
- `large_text_layout_test`: 320dp × 2.0 critical screens.
- `motion_level_contract_test`: full/fadeOnly/none result equality.
- `state_restoration_smoke_test`: back/background/rotation form state.

**종료:** 현재 UI에서 가능한 test는 green, 현재 결함을 표현하는 test는 명시적 expected-fail backlog로 분리. 테스트를 억지로 green 처리하지 않음.

**롤백:** test-only revert 가능. 단 발견한 실제 결함은 issue로 보존.

#### G2. Foundation token 확장

**의존:** G1.

**작업:** semantic spacing/elevation/layout/content width token 추가. 기존 값으로 시작해 visual diff를 만들지 않는다. `theme.dart`/`ml_widgets.dart` compatibility API 유지.

**종료:** raw spacing/elevation 신규 사용을 막는 lint/test, 기존 screenshot 변화 최소, 전체 test green.

**롤백:** token PR revert. 색·radius 기존값 무변경.

#### G3. Shared component/state patterns

**의존:** G2.

**작업:** MLScreenFrame, MLCard role, MLAsyncPanel, MLFormSection, MLStatusBanner, MLMetricSummary. Story/demo page에서 모든 state와 MotionLevel을 먼저 검증.

**종료:** component widget/golden/a11y test, 기존 화면에 아직 영향 없음.

**롤백:** 신규 component 삭제 가능.

### P1 — 핵심 사용자 여정: G4~G8

#### G4. Async·오류·접근성 우선 보강

**의존:** G3.

**순서:** AI Chat → Reports → Walking → Health → Diary → Guardian → Register.

각 화면에서 먼저 error/empty/loading/submitting/success를 분리한다. 배치와 색을 바꾸기 전에 기능 결과가 같은지 characterization fixture로 확인한다.

**종료:** 오류가 빈 데이터로 보이는 핵심 경로 0, raw exception 0, retry/fallback 존재, live status semantics.

**롤백:** 화면별 1 PR revert. Service API 불변.

#### G5. Main shell + Home

**의존:** G4, main_nav_shell_test.

**작업:** Home section 분리, Selector 경계, hero 1개, first viewport 주 행동 1개. Floating nav 자체는 유지. 탭 fade는 상태/프레임 test를 통과할 때만.

**종료:** 5탭 상태 parity, navigation/home Maestro, 320~840, profile p95.

**롤백:** `ML_UI_V2` 임시 compile-time flag 또는 screen builder revert.

#### G6. Training presentation lock

**의존:** G3, G5 shell.

**작업:** hub/history의 component 정합만 수행. GameTemplate 로직/feedback/Hero/result sheet는 보존하고 토큰 우회만 회수.

**종료:** catalog/progression/persistence/accessibility/game tests + integration + Maestro 전부 green. XP/score/unlock DB fixture 동일.

**롤백:** hub/history presentation만 revert.

#### G7. Diary + AI Chat 정서적 완성

**의존:** G4.

**Diary:** 저장 성공 one-shot garden feedback. **Chat:** bubble insert, 추천 주제, provider error/fallback. 둘 다 장식 loop 없음.

**종료:** 저장 timing/row 동일, chat memory-only 유지, full/fadeOnly/none, STT off/on, keyboard open layout.

**롤백:** animation wrapper만 제거 가능. 데이터/상태 component 유지.

#### G8. Walking + Reports + Health 데이터 언어

**의존:** G4.

**작업:** metric summary, null/0, 실제 date/series, 추적·측정 source/time, textual chart summary. PDF content 의미는 변경하지 않음.

**종료:** fixture 기반 값 parity, chart semantics, permission denial, anomaly, PDF entry, 16ms profile.

**롤백:** view mapper/presentation revert. DB·policy 불변.

### P2 — 전체 일관성: G9~G10

#### G9. Auth/onboarding/profile/settings/support screens

**의존:** G5~G8 green.

**순서:** Register/Consent → Assessment → Profile/Edit → Settings/Model → Guardian/Center → CS.

**종료:** 모든 route와 MaterialPageRoute, dialog/sheet/external action parity; form state/back/large text/a11y.

#### G10. Admin

**의존:** router/admin contract tests, G9.

**작업:** 공통 token과 async state만 적용. 소비자용 hero·stagger·celebration은 사용하지 않는다. admin 7 route 게이팅 E2E 추가.

**종료:** release-disabled deep link, debug admin login, CRUD/reply/delete confirmation pass.

### P3 — 별도 기술 트랙: G11~G12

#### G11. Adaptive expanded + dark mode

- Medium/expanded layout은 기능 parity/state preservation부터.
- NavigationRail 전환은 compact 5탭 순서와 label을 유지.
- Dark mode는 `goodText/warnText/badText/calc` 대응과 dark contrast test가 먼저.
- adaptive와 dark를 같은 PR에서 하지 않는다.

#### G12. standalone material_ui 평가

- Flutter 3.47에서는 opt-in이므로 release 리디자인과 분리.
- 모든 dependency public type compatibility 조사.
- 전용 branch에서 `dart fix`, bridge 필요성, 44 route/test/Maestro를 재실행.
- 사용자 가치가 없고 유지보수 위험만 크면 formal deprecation 시점까지 보류.

## 5. 화면 PR 표준 절차

모든 화면은 다음 11단계를 동일하게 따른다.

1. 기능/route/data invariant를 보존 계약에서 복사.
2. 현재 normal/loading/empty/error/disabled/success 상태를 캡처.
3. 현재 동작 characterization test 작성.
4. 기존 비즈니스 로직을 변경하지 않고 UI state adapter 작성.
5. 새 공통 component로 normal state 구현.
6. 나머지 상태 구현.
7. MotionLevel 세 단계 구현.
8. 320/360/600/840 × text scale matrix 실행.
9. screen reader/back/keyboard/permission 검증.
10. unit/widget/integration/Maestro/profile 실행.
11. before/after, payload/DB diff, rollback 방법을 PR에 첨부.

한 단계가 실패하면 다음 화면으로 진행하지 않는다.

## 6. 테스트 피라미드

| 계층 | 무엇을 잠그는가 | 실행 시점 |
|---|---|---|
| unit | score, policy, formatter, repository, payload, provider selection | 모든 PR |
| component widget | state, target, semantics, MotionLevel | component/screen PR |
| screen widget | layout, input state, error/retry, 320×2.0 | 모든 screen PR |
| shell widget | 5탭, overlay, state preservation | shell/주 화면 PR |
| golden | token/component visual regression | foundation/component PR |
| integration | 실제 main/provider/router/DB 주요 흐름 | P0 이후 모든 wave 종료 |
| Maestro | 사용자 관점 21 gate + 신규 admin/state flow | 모든 wave 종료 |
| profile/manual | frame, startup, permission, sensor, sharesheet, TalkBack | 기기 기능·wave 종료 |
| user task | 이해·오탭·도움·중단·불편 | prototype, P1, release candidate |

Golden은 기능 테스트를 대체하지 않는다. Emulator는 센서·permission·sharesheet·성능의 최종 증거가 아니다.

## 7. 사용자 검증 계획

### 참여자

- 60~80대 중심.
- 기억·주의·시각·운동 어려움의 다양성을 포함.
- 보호자 역할 참여자 별도.
- 본인과 필요한 경우 보호자의 이해 가능한 동의.
- 조용한 환경, 쉬는 시간, 언제든 중단.

### 비교 방식

현재 UI와 후보 UI를 같은 fixture·task로 비교한다. 절대 시간보다 before/after 차이와 오류 위치를 본다.

### 필수 task

1. 로그인 후 오늘 할 훈련 찾기.
2. 훈련 완료 후 결과와 다음 행동 설명.
3. 오늘 일기 작성·저장 여부 확인.
4. 걸음 측정 켜기, 권한 거부 뒤 복구.
5. 리포트에서 현재 상태와 변화 설명.
6. PDF 미리보기·공유.
7. 보호자 QR/링크 공유, 실패 시 전화/문자 대안.
8. 건강 기록 저장과 최근 추세 찾기.
9. 1분 방해 뒤 중단한 단계로 복귀.
10. 움직임 줄이기 on/off 선호와 불편 보고.

### 기록

- task success/critical failure.
- 잘못 누른 횟수, back 횟수, 도움 요청.
- 완료시간과 멈춘 구간.
- 저장·전송·완료 확신 여부.
- 화면 목적과 수치 의미 재설명.
- 모션으로 인한 어지러움·주의 분산·기다림.

소규모 형성평가 결과를 통계적 임상 효과로 표현하지 않는다.

## 8. 위험 등록부

| 위험 | 가능성/영향 | 예방 | 롤백 |
|---|---|---|---|
| route/guard 유실 | 중/치명 | 44 route snapshot+redirect tests | router 변경 revert |
| DB 저장 시점 변경 | 중/치명 | row fixture before/after | view adapter revert |
| error를 empty로 오인 | 높음/높음 | AsyncPanel state contract | 화면 PR revert |
| large text overflow | 높음/높음 | 320×2.0 matrix | responsive layout revert |
| nav overlay/팽창 | 중/높음 | shell integration+Maestro | nav 변경 즉시 revert |
| hidden tab animation/state reset | 중/높음 | TickerMode+tab state test | transition 제거 |
| 과도한 모션 | 높음/높음 | policy table, reduce motion, 사용자 test | animation wrapper 제거 |
| performance jank | 중/높음 | profile p95, 4group/400ms | effect 제거/경계 축소 |
| PDF 의미 변경 | 낮음/치명 | data model/bytes snapshot | PDF PR 분리/revert |
| guardian safety failure | 중/치명 | fake Firestore success/failure | presentation revert |
| admin release exposure | 낮음/치명 | release gate/deep link test | admin PR revert |
| 문서·코드 drift | 높음/중 | 자동 수치 script, 정본 link | 문서 즉시 정정 |
| material_ui 동시 migration | 중/높음 | G12 분리 | migration branch 폐기 |

## 9. 문서 드리프트 정리 백로그

디자인 구현 전에 또는 같은 문서 PR에서 정리한다.

1. README의 Lottie 배지와 현재 pubspec 불일치.
2. README의 화면/경로 목록과 44 GoRoute 불일치.
3. PROJECT_DOCS의 NanumGothic/Lottie/record/vibration/checklist/social ranking 등 과거 내용.
4. DEVELOPMENT_ROADMAP의 테스트 파일·case 수 과거 snapshot.
5. 2026-07 루트 PNG와 현재 8~9월 UI 불일치.
6. `global_stats` 업데이트는 남고 social ranking UI는 삭제된 현재 상태 설명.
7. integration test가 게이팅이 아닌 정책과 실제 실행 결과.

수치는 복사하지 않고 script/정본 section을 링크한다.

## 10. 구현 issue 목록

### Must — P0/P1

- DS-001 Route/redirect/admin contract tests.
- DS-002 MainNav shell/overlay/state test.
- DS-003 DB reset/data preservation fixtures.
- DS-004 Semantic spacing/elevation/layout tokens.
- DS-005 MLScreenFrame/CardRole/AsyncPanel/FormSection.
- DS-006 Critical async states: Chat/Report/Walking/Health/Diary/Guardian.
- DS-007 320dp×2.0 + 48/56dp critical matrix.
- DS-008 Home hierarchy + Selector split.
- DS-009 Reports date/series/no-data semantics.
- DS-010 Chat bubble/error/fallback + explicit save contract.
- DS-011 Diary save one-shot feedback.
- DS-012 PDF bytes/preview/share smoke.
- DS-013 Guardian payload/error/external actions test.

### Should — P2

- DS-014 Register/FormSection responsive.
- DS-015 Assessment task frame/time policy.
- DS-016 Walking permission/revoke/state restoration.
- DS-017 Profile/Edit/Settings/Model component pass.
- DS-018 Dementia center/CS support pass.
- DS-019 Admin route/CRUD E2E.
- DS-020 current screenshots/demo regeneration.

### Separate — P3

- DS-021 medium/expanded shell.
- DS-022 dark semantic colors and contrast.
- DS-023 `material_ui` compatibility spike.
- DS-024 optional focal Rive research only after user evidence; default is no dependency.

## 11. Claude/Kiro 구현 프롬프트 계약

화면 구현을 AI에게 맡길 때 다음을 그대로 제공한다.

```text
MemoryLink [화면/issue]만 수정한다.
먼저 MEMORYLINK_FEATURE_PRESERVATION_CONTRACT.md에서 해당 route, 데이터 read/write,
권한, 외부 action, 테스트 불변조건을 인용하라.
DESIGN.md와 MEMORYLINK_DESIGN_MOTION_ARCHITECTURE.md가 시각·모션 정본이다.

금지:
- route/Provider/Service/DB schema/algorithm 변경
- raw color/radius/duration 및 새 dependency
- 반복/장식 모션과 전역 custom route transition
- 기존 테스트 삭제·assertion 약화

코드 전에 제출:
1. preserve/change 목록
2. loading/empty/error/content/editing/submitting/success 상태표
3. full/fadeOnly/none 모션표
4. 320dp×textScale2.0 전략
5. 영향 테스트와 rollback

한 화면만 구현하고 모든 검증을 실행하라.
```

## 12. 최종 권고

가장 큰 품질 상승은 모션 패키지를 추가하거나 모든 화면을 다시 그리는 데서 나오지 않는다.

1. 현재 기능을 테스트로 먼저 잠근다.
2. 토큰과 상태 component를 만든다.
3. 실패·대기·완료가 불명확한 핵심 화면부터 고친다.
4. 홈·리포트·대화·일기의 정보 위계와 목적 기반 모션을 완성한다.
5. 전체 화면에 같은 문법을 적용하되, 집중 화면은 덜 움직인다.
6. 실제 고령 사용자와 최저 사양 기기에서 이해·오탭·프레임을 검증한다.
7. dark/adaptive/material_ui는 안정화 뒤 독립 트랙으로 진행한다.

이 순서가 MemoryLink의 현재 기능과 방어선을 유지하면서 Flutter로 만들 수 있는 가장 높은 완성도에 도달하는 최소 위험 경로다.
