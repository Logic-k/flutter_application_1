# MemoryLink 전 화면 디자인·모션 심층 감사

> 작성: 2026-09-28 · 기준: 현재 `lib/` 코드, 루트 PNG 14개, `DESIGN.md`.
> 이 문서는 기능 변경안이 아니라 표현 계층 감사다. 기능 불변조건은 `MEMORYLINK_FEATURE_PRESERVATION_CONTRACT.md`를 따른다.

## 1. 정적 감사 결과

`lib/features/**/*.dart` 중 `Scaffold`를 직접 만드는 파일을 기준으로 계산했다.

| 항목 | 직접 사용하는 화면 파일 | 해석 |
|---|---:|---|
| Scaffold 화면 | **44** | 라우트와 비라우트 화면 포함 |
| StaggeredColumn/Scope | **12** | 홈·데이터·목록 일부에 편중 |
| 직접 Semantics | **12** | Material 기본 semantics는 별도이므로 접근성 총량이 아님 |
| MLCard | **8** | 프로필·설정·데이터 화면 중심 |
| MLLoadSwitcher | **8** | 로딩 상태 패턴이 일부 화면에만 적용 |
| MLErrorState | **7** | CS와 훈련 기록 중심; 핵심 데이터 화면은 오류를 빈 상태로 바꾸는 곳이 있음 |

직접 스타일 표현(`fontSize`, `EdgeInsets`, `BoxDecoration`)은 54개 feature 파일에서 513회 발견됐다. PDF 생성기 106회를 빼도 화면 코드에 상당히 남아 있다. 색과 radius는 비교적 중앙화됐지만 **spacing, elevation, icon size, content width, responsive breakpoint 토큰이 없다.**

## 2. 이미 잘 설계된 기반

### 2.1 시각 시스템

- `theme.dart`: Material 3, Pretendard 400/500/600/700/800, 의미색, 상태 면색/글자색 분리.
- radius 9단(`rBar`~`rPill`)과 주요 CTA 56dp 토큰.
- 라이트 surface/text/outline을 `ColorScheme`으로 사용하고 화면의 raw `Color(0x...)`를 가드.
- 대비비를 계산하는 `theme_contrast_test.dart`와 raw palette guard가 존재.
- `MLCard`, `MLHeroCard`, `MLIconTile`, `MLStatusPill`, `MLMetricCard`, `MLListRow`, skeleton/error/chart/count 위젯이 존재.

### 2.2 모션 시스템

- `AppMotion`: press 100, fade 150, enter 200, route 300ms.
- `MotionLevel`: full / fadeOnly / none.
- OS Android disableAnimations, iOS reduceMotion, 앱 설정을 함께 반영.
- `StaggeredColumn`: 8px, 최대 4 slot, 전체 400ms 이하, 실행당 1회.
- `PressableScale`: full에서 0.98 scale, fadeOnly에서는 opacity.
- `MLChart`, `MLCountUp`, progress/ring: 데이터 변화를 과장하지 않는 200ms 보간.
- `GameTemplate`: badge, burst, shake, Hero. 결과 sheet는 stars/confetti/particle.
- `MemoryOpening`: 2.4초 이내, skip, 로딩과 겹침, reduce motion.
- `motion_token_guard_test.dart`: feature 화면의 직접 `Duration(milliseconds:)`를 차단.

이 기반은 새 animation package를 도입하는 것보다 확장·정리하는 편이 안전하다.

## 3. 현재 모션 지도

| 사용자 순간 | 현재 구현 | 평가 |
|---|---|---|
| cold start | MemoryOpening 1회 | 완성도 높음; 길이 증가 금지 |
| 로그인 성공 | logo flight/Hero 성격 전환 | 브랜드 연결 좋음 |
| 온보딩 선택 | press + color + stagger | 적절함 |
| 설문 페이지 | 300ms PageView, reduce 시 jump | 적절함; 질문 자체에 장식 추가 금지 |
| 훈련 허브→게임 | CourseNode/GameTemplate Hero | 공간 연속성의 좋은 사용 |
| 정답/오답 | badge + shake/burst + sound/haptic | 앱의 핵심 피드백, 유지 |
| 훈련 완료 | result sheet + stars/confetti | 1회성 성취, 유지 |
| 홈·walking·reports·settings | first-entry stagger | 적용 완료 |
| 차트·걸음·XP | MLChart/MLCountUp | 적용 완료 |
| 일기 키보드 | calendar AnimatedSize | 기능적 모션, 유지 |
| 일기 저장 | snackbar만 | 작은 1회성 정원 성취 모션 후보 |
| AI 새 메시지 | 목록 즉시 삽입 + 300ms scroll | bubble 자체의 상태 전환과 실패 상태 부족 |
| PDF 4단계 | PageView slide/jump | 적절함 |
| 모델 다운로드 | progress | 적절함; 반복 장식 불필요 |
| CS 목록 | 일부 stagger + load/error | 비교적 성숙 |
| 관리자 | 기본 Material 전환 중심 | 생산성 화면이므로 과한 안무 불필요 |

## 4. 상태 설계 감사

### 4.1 모범

- CS 목록/상세: Firestore 오류와 빈 상태 구분.
- Training history: loading/error/empty/content.
- Model download: idle/downloading/done/error.
- Guardian sync: syncing/success/error/anomaly를 사용자에게 표시.
- Diary main: skeleton→content, saving disabled.
- Walking/Reports: skeleton→content.

### 4.2 보강 필요

| 화면 | 현재 위험 | 목표 상태 계약 |
|---|---|---|
| AI chat | `AiChatService.chat` 예외를 화면에서 catch하지 않아 loading 해제·재시도 계약이 없음 | starting/ready/sending/error/ended/resultSaving |
| Walking | DB 실패를 빈 주간 데이터로 바꿈 | loading/empty/error/content + 추적권한 상태 별도 |
| Reports | DB 실패를 빈 점수처럼 표시 | loading/empty/error/content, 0과 데이터 없음 구분 |
| Health | DB 실패를 빈 폼으로 위장 | loading/loadError/ready/saving/saveError/saved |
| Diary | 초기 load 예외 시 `_loaded`가 false로 남을 수 있음 | loading/error/ready/saving/saved |
| Guardian | token 생성 실패 시 QR spinner가 계속될 수 있음 | tokenLoading/tokenError/ready/syncing/syncError |
| Register | 제출 중 disabled 상태 없음 | editing/submitting/validationError/serverError/success |
| Assessment | task 진행은 있으나 interruption/restart 설명 부족 | ready/inProgress/feedback/completed; 타이머의 의미 명시 |
| Admin dashboard | 일부 async 실패 표현이 빈 값과 혼동 가능 | loading/error/empty/content |

디자인 개편에서는 오류를 숨기지 말되, 서비스·DB 동작 자체는 변경하지 않는다.

## 5. 화면군별 감사와 목표

### 5.1 Opening / Login

**유지:** 로고 위치 연속성, skip, 자동 로그인 대기, 입력 2개와 단일 CTA.

**개선:** 로그인 화면에서는 장식보다 오류·진행·autofill·password manager 호환을 우선한다. 현재 로고 flight 외 진입 안무를 늘리지 않는다.

**금지:** 2.4초 초과, 반복 logo loop, 로그인 폼을 carousel로 변경.

### 5.2 Register / Consent / Onboarding

**현황:** Onboarding은 공통 모션 체계가 잘 적용됐다. Register는 333줄, 40dp padding, 2열 나이/체중, 선택 정보 ExpansionTile, 직접 spacing이 많다. Consent는 단순하지만 필수/선택의 시각 구분이 약하다.

**목표:**
- 가입을 `계정 → 기본 정보 → 선택 정보` 시각 section으로 나누되 실제 한 화면과 제출 계약은 유지.
- 큰 글자에서는 나이/체중을 1열로 전환.
- 필수·선택과 제출 결과를 텍스트로 유지.
- 진입 안무는 각 field가 아니라 section 3개에만 적용.

### 5.3 Assessment

**현황:** 설문은 큰 2개 버튼과 PageView가 명확하다. CognitiveTasks는 `TextStyle(fontSize:)`와 즉석 Column/Row/Grid가 많고, 단어 노출이 `Future.delayed(5초)`로 고정된다. 결과는 큰 원형 %가 시선을 지배한다.

**목표:**
- 한 화면 한 과제, 제목·지시·상호작용·진행의 위치를 모든 단계에서 고정.
- task 교체는 150ms fadeThrough 성격으로 하고 이동 안무를 넣지 않는다.
- 5초 노출은 현재 점수 의미의 일부이므로 디자인 작업에서 임의로 변경하지 않는다. `준비 후 시작`, 남은 시간, 다시 안내를 추가할 수 있다.
- 시간이 접근성 규범상 조정되어야 한다면 “기존 점수 모드”와 “연습/접근성 모드”를 구분하는 별도 제품 결정이 필요하다. 같은 score category에 조용히 섞지 않는다.
- 결과는 %만 보여주지 말고 `양호/주의 관찰/변화가 관찰됨` 설명을 먼저 읽을 수 있게 한다. 의료 면책은 유지.

### 5.4 Home / Main navigation

**현황:** Home은 520줄, 4개 Provider 구독, hero·AI·diary·walking·recommendation·brain health가 한 파일에 있다. 시각적으로 큰 라벤더 hero와 walking hero가 한 화면에 반복된다. Floating nav는 309dp와 48dp 가드를 갖는다.

**목표:**
- 첫 viewport의 주 행동은 하나: `오늘 훈련 시작/이어하기`.
- hero는 화면당 하나. walking은 surface metric row로 낮춘다.
- 5탭 순서와 활성 label은 유지.
- 탭 변경은 새 slide가 아니라 150ms fadeOnly를 조건부 검토. state가 초기화되면 도입하지 않는다.
- Home을 section widget으로 분리하고 각 section만 Selector로 구독.

### 5.5 Training hub / Games / History

**현황:** 앱에서 가장 성숙한 시스템. 8활동 catalog, course path, 잠금, 목표, XP, Hero, feedback, 결과 sheet, persistence test가 있다.

**목표:**
- UI 구조와 모션 grammar를 다른 기능이 참고한다.
- 허브에서 오늘 3개와 전체 course의 정보 위계를 더 분명히 하되 activity ID/순서/잠금은 유지.
- 게임 중에는 진입 stagger, 배경 parallax, 반복 particle을 추가하지 않는다.
- 정답/오답 효과는 full에서만, fadeOnly는 색+텍스트, none은 즉시 텍스트.
- 잠금 설명·결과·계속하기 semantics 유지.

### 5.6 Walking / Gait

**현황:** 추적 상태, gait session, ring, 4 metric, weekly chart가 한 긴 화면에 있다. chart/count motion은 구현됨. 권한·service·anomaly 안전 흐름이 복잡하다.

**목표:**
- 상단은 추적 상태와 토글, 다음은 오늘 걸음, 세션 분석은 명시적 시작/중지 card로 유지.
- “0”과 측정 안 됨을 분리.
- metric 2열은 text scale이 크면 1열 또는 2×2의 높이 자동 확장.
- gait live update 영역에 RepaintBoundary를 측정 후 적용; 전체 화면을 25Hz rebuild하지 않도록 유지.
- tracking switch 이동·권한 dialog·background service 의미를 바꾸지 않는다.

### 5.7 Diary / Diary Book

**현황:** 달력, 오늘 편집, 과거 read-only, STT, 3년 보관, skeleton이 있다. Memory Garden 이름에 비해 저장 성취의 정서 표현이 약하다.

**목표:**
- 오늘/과거 편집 가능 여부를 날짜 제목 옆 상태 pill로 명시.
- 저장 성공 시 600ms 이하 1회성 잎/꽃 모션을 기존 CustomPainter/Burst 계열로 구현 가능.
- fadeOnly에서는 체크 아이콘+snackbar, none에서는 즉시 확인.
- Diary Book는 spinner를 skeleton으로, card tap의 “해당 날짜로 돌아가기” 의미를 명확히 한다.

### 5.8 AI Chat

**현황:** 569줄, in-memory 메시지, 10턴, STT, provider 설정 dialog, 종료 분석, 명시적 voice score 저장. bubble 삽입은 즉시이고 초기에는 공백이 크다. 전송 원형 버튼은 정적 크기 검증이 필요하다.

**목표:**
- 대화 기록이 영구 저장되는 것처럼 보이는 UI를 만들지 않는다.
- 초기에는 추천 회상 주제 3개 이하를 표시하고 첫 입력 후 제거.
- 새 bubble은 `AnimatedSize + 150ms fade`, 이동은 최소화.
- AI thinking은 반복 점 3개가 아니라 spinner+텍스트 또는 정적 progress.
- provider 실패는 retry와 “기본 대화로 계속”을 제공.
- 종료 분석과 저장을 명확히 분리. 저장 전 자동 기록 금지.

### 5.9 Reports / PDF

**현황:** summary, 4영역, chart, AI 요약, PDF CTA. DB 접근과 화면 계산이 State에 혼합. 차트는 최근 score 행을 영역 구분 없이 선 하나로 연결하고 월~일 라벨을 고정한다.

**목표:**
- 앱 화면 순서: `이번 주 요약 → 영역별 상태 → 추세 → 권고 → PDF`.
- chart는 실제 날짜와 series 의미를 일치시키되 기존 저장 데이터·점수는 변경하지 않는다.
- no data를 0선으로 그리지 않는다.
- PDF 생성 내용·4단계 options·preview/print/share는 보존.
- PDF 자체는 화면 디자인 토큰과 분리된 인쇄 디자인 시스템으로 유지.

### 5.10 Profile / Edit / Settings / Health

**현황:** Profile/Settings는 MLCard/MLListRow를 많이 사용해 일관성이 높다. Edit/Health/Model 화면은 직접 레이아웃이 많다. 설정은 539줄이나 섹션 구조와 상태가 명확하다.

**목표:**
- Profile은 entry hub로 유지하고 항목 삭제·병합 금지.
- Edit form은 visible label, 입력 format, camera/gallery sheet, save 성공을 유지.
- Settings의 접근성 토글과 AI provider 상태는 다른 UI보다 우선 보존.
- Health는 저장/로드 실패를 빈 상태와 분리하고 수치에는 텍스트 해석을 동반.
- 모델 1.5GB 다운로드는 용량·progress·중단/오류를 계속 명시.

### 5.11 Guardian / Dementia Center / CS

**현황:** 실제 외부 행동과 실패가 중요한 안전·지원 화면이다. CS 목록은 상태 패턴이 성숙하다.

**목표:**
- guardian token/QR 실패를 무한 spinner로 두지 않는다.
- 전화·문자·공유 CTA는 접히거나 숨지 않게 한다.
- 치매상담콜센터 1899-9988은 검색 결과와 무관하게 항상 보인다.
- CS 네 기능은 hub 첫 화면에서 계속 한 번에 보인다.
- 위험/실패는 색+아이콘+텍스트로 표시한다.

### 5.12 Admin

**현황:** 7개 별도 route, 표/차트/CRUD 중심, release build gate가 있다. 공통 ML 컴포넌트 적용은 낮다.

**목표:**
- 소비자 앱의 감성 모션을 복제하지 않는다.
- density와 keyboard/mouse 생산성을 우선한다.
- 차트 200ms, CRUD 상태 150ms fade 외 진입 choreography는 최소화.
- 관리자 route·gate·extra payload와 삭제 confirmation을 보존.

## 6. 우선순위별 디자인 부채

### P0 — 기능 오해·접근성 위험

1. AI chat, walking, reports, health, diary, guardian의 오류/빈 상태 분리.
2. 320dp × text scale 2.0에서 Register 2열, Assessment row/grid, Health 2열, PDF option 확인.
3. AI send, custom chips, icon-only control의 실제 48/56dp 측정.
4. Assessment 5초 task의 준비/시간 의미와 접근성 예외 정책 결정.
5. report 차트의 series/date 의미 오류 제거.

### P1 — 전 앱 시각 일관성

1. spacing/elevation/icon/content-width/breakpoint 토큰 신설.
2. MLCard role variant.
3. standard screen scaffold/content max width.
4. form section, async state, status banner 공통 컴포넌트.
5. Home/Reports/Chat/Settings 대형 State 분리.

### P2 — 목적 기반 모션 확장

1. chat bubble insert.
2. diary save garden feedback.
3. section-level form entry.
4. 탭 fade는 상태·성능 검증 후 조건부.
5. admin은 chart/state 외 확대하지 않음.

### P3 — adaptive·다크·고급 자산

1. 600/840 breakpoint shell.
2. 상태 보존과 함께 NavigationRail 검토.
3. 다크 semantic text 대비를 별도 작업으로 복구.
4. 사용자 테스트로 가치가 입증된 focal illustration에만 Rive 검토.
5. Flutter 3.47 standalone `material_ui` opt-in 마이그레이션은 이번 리디자인과 분리.

## 7. 감사 결론

현재 문제는 “모션 부족”이 아니라 **적용 편중과 상태 표현의 불균형**이다. 훈련·홈·리포트는 이미 충분히 움직이며, 핵심 개선 대상은 AI/평가/건강/보호자의 실패·진행·완료를 같은 문법으로 보이게 하는 것이다.

전 화면에 `StaggeredColumn`을 기계적으로 넣지 않는다. 사용자가 콘텐츠를 읽고 결정해야 하는 평가·대화·관리 화면은 fadeOnly 또는 상태 피드백만 사용한다. 풍부함은 애니메이션 개수가 아니라 “누르면 즉시 반응하고, 기다리면 이유를 알려주고, 끝나면 결과를 기억시켜 주는가”로 평가한다.
