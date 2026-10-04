# MemoryLink 디자인·모션 마스터 아키텍처

> 방향: **Calm Expressive Lavender — 조용한 돌봄, 분명한 반응**
> 기능 계약: `MEMORYLINK_FEATURE_PRESERVATION_CONTRACT.md`
> 현황 감사: `MEMORYLINK_DESIGN_MOTION_AUDIT.md`
> 외부 근거: `MEMORYLINK_DESIGN_RESEARCH_EVIDENCE.md`

## 1. 설계 명제

MemoryLink의 모션 목표는 “강한 움직임”이 아니라 **높은 피드백 커버리지**다.

- 시각 강도: 낮음. 한 화면 hero 1개, 큰 라벤더 면 1개, 반복/자동 움직임 0.
- 반응 커버리지: 높음. 누름·선택·로딩·빈 상태·실패·성공·저장·이동마다 명확한 결과.
- 공간 변화량: 낮음. 8px enter, 0.98 press, data overshoot 0.
- 익숙함: 높음. 5탭, back, Material control, 아이콘+텍스트, 현재 화면 제목 유지.
- 기능 변화: 0. 모든 presentation은 현재 Provider/Service/Repository 계약에 연결.

`DESIGN.md`의 `MOTION_INTENSITY=2`를 유지한다. 풍부함은 intensity를 6으로 올리는 것이 아니라, 일부 화면에만 있는 좋은 피드백을 전 기능 상태에 빠짐없이 적용하는 방식으로 만든다.

## 2. Visual foundation

### 2.1 색

기존 `MLColors`와 `ColorScheme`이 정본이다.

| 역할 | 사용 규칙 |
|---|---|
| primary lavender | 화면의 주 행동, 선택 상태, 한 개 hero |
| surface | 읽기·입력·데이터의 기본 바탕 |
| surfaceContainerHighest | 보조 정보·입력·선택 전 상태 |
| category color | 기능 분류 보조. 한 화면 동시 3개 이하 |
| status surface color | 점·얇은 면·차트. 흰 글자 금지 |
| status text color | 상태 글자·아이콘. 면색과 분리 |

규칙:

1. 한 화면의 dominant accent는 하나다.
2. 라벤더 gradient hero는 화면당 최대 1개다.
3. 건강 상태는 색+아이콘+텍스트를 항상 함께 쓴다.
4. 큰 본문을 gradient/image 위에 올리지 않는다.
5. `Color(0x...)`, `Colors.grey/red/green` 직접 사용은 현재 가드 예외 밖에서 금지한다.
6. 다크 토큰 설계는 P3 별도 트랙이다.

### 2.2 타이포

기존 Pretendard 5굵기를 유지한다.

- display 28/800: 한 화면의 큰 결과나 인사 1개.
- headline 22/800: 화면 또는 핵심 section 제목.
- title 16.5~19/700~800: card/section.
- body 14.5~16/500~600, line height 1.5.
- helper 12~13/500~600: 보조 정보에만.
- 본문 700+ 금지. 모두 굵으면 위계가 사라진다.
- 숫자·시간·점수는 tabular figures.
- 퍼센트·CV·점수에는 반드시 비수치 해석 문구를 제공.
- Korean line은 왼쪽 정렬을 기본으로 하고 긴 중앙 정렬 문단을 금지.

### 2.3 Semantic spacing token

기존 화면 값을 한 번에 바꾸지 않고 의미 이름으로 먼저 고정한다.

| 토큰 | 초기값 | 용도 |
|---|---:|---|
| `screenHorizontal` | 22 | 일반 탭 화면 좌우 |
| `screenHorizontalForm` | 24 | 폼·상세 |
| `screenTop` | 6~8 | AppBar 아래 첫 요소 |
| `controlGap` | 8 | icon-text, 인라인 control |
| `itemGap` | 12 | 같은 section의 item |
| `contentGap` | 16 | card 내부 block |
| `cardGap` | 20 | 연속 card |
| `sectionGap` | 24 | section 간 |
| `heroPadding` | 22 | hero 내부 |
| `bottomSafeContent` | `FloatingPillNav.contentBottomInset` | 탭 마지막 콘텐츠 |

숫자 기반 4/8 grid보다 semantic token을 우선한다. 초기 token 값은 현재 UI를 보존하고, 이후 사용자 테스트로 값만 조정한다.

### 2.4 Radius와 elevation

기존 radius 9단을 역할에 맞게 사용한다.

- `rCard`: hero와 최상위 큰 card.
- `rPanel`: 일반 section/data panel.
- `rTile`: list/action tile.
- `rField`: input/inline panel.
- `rBtn`: button.
- `rChip`: filter/status.
- `rPill`: floating nav만.

추가할 elevation 의미 토큰:

| 토큰 | 표현 |
|---|---|
| flat | shadow 없음, outline 사용 |
| raised | 일반 interactive card의 약한 단일 그림자 |
| hero | primary tone shadow, 화면당 1개 |
| floating | nav/sheet 전용, body card에 사용 금지 |

blur/glass/neumorphism은 foundation에 넣지 않는다.

### 2.5 Content width와 responsive

| window | 폭 | shell | content |
|---|---:|---|---|
| compact | `<600` | 현재 FloatingPillNav | 1열, full width |
| medium | `600~839` | 우선 현재 nav 유지 | max 640~720, 선택적 2열 |
| expanded | `>=840` | P3에서 NavigationRail 검토 | max 1200, master-detail/2열 |

- 분기는 기기 종류·orientation이 아니라 `LayoutBuilder.maxWidth`.
- text scale 1.4 이상에서는 폭이 넓어도 form/metric을 1열로 되돌릴 수 있다.
- layout이 바뀌어도 Provider, TextEditingController, ScrollController, PageController를 다시 만들지 않는다.
- 같은 데이터와 action을 다른 layout에서 공유한다. 기능 parity가 깨지는 adaptive UI는 실패다.

## 3. Component architecture

### 3.1 호환 우선 구조

초기에는 import churn을 피한다.

```text
lib/core/
  theme.dart                 # 기존 공개 API 유지
  ml_widgets.dart            # 기존 공개 API 유지/re-export 가능
  motion/                    # 기존 유지
  design_system/             # 신규 내부 분리
    foundations/
      spacing.dart
      elevation.dart
      layout.dart
    components/
      screen_frame.dart
      card.dart
      async_panel.dart
      form_section.dart
      status_banner.dart
      primary_action.dart
    patterns/
      metric_summary.dart
      task_step.dart
      save_feedback.dart
```

안정화 전에는 `theme.dart`와 `ml_widgets.dart` import를 제거하지 않는다. 새 파일로 구현을 옮기더라도 compatibility export를 남긴다.

### 3.2 MLScreenFrame

전 화면의 page frame만 통일하고 route/Scaffold를 숨기지 않는다.

계약:

- 명확한 title과 선택적 subtitle.
- compact/medium/expanded max width.
- tab 화면은 `contentBottomInset` 자동 적용.
- keyboard inset, SafeArea, scroll 여부를 명시.
- loading overlay가 content semantics와 중복되지 않음.
- AppBar/back semantics와 route identity 유지.

### 3.3 MLCard role

```text
hero        : 화면당 0~1, gradient 허용, 핵심 요약
standard    : 일반 정보, flat/outline
interactive : press feedback + 전체 card tap semantics
data         : 숫자+단위+설명, overshoot 금지
support      : 경고/도움/면책, status color+icon+text
```

모든 card를 같은 26 radius와 shadow로 그리지 않는다. role은 시각 위계와 행동을 동시에 설명해야 한다.

### 3.4 MLAsyncPanel

화면 비즈니스 로직을 소유하지 않고 받은 상태만 그린다.

```text
initial/loading → layout-shaped static skeleton
empty           → 이유 + 첫 행동
error           → 쉬운 설명 + retry/continue fallback
content         → 실제 content
refreshing      → 기존 content 유지 + 작은 progress
```

규칙:

- error를 empty로 바꾸지 않는다.
- content가 있으면 refresh 중 사라지거나 위치가 크게 바뀌지 않는다.
- 상태 변화는 `Semantics(liveRegion: true)`로 한 번 알린다.
- raw exception과 stack trace는 사용자에게 표시하지 않는다.
- retry는 같은 service call을 다시 호출하며 데이터 의미를 변경하지 않는다.

### 3.5 MLFormSection

- visible title/description.
- field label이 입력 후 사라지지 않음.
- 필수/선택을 텍스트로 표시.
- invalid field 바로 아래 오류와 수정 방법.
- submitting 중 CTA disable + 진행 문구.
- back/resize/background에서 controller 보존.
- section enter만 허용, field별 stagger 금지.

### 3.6 MLStatusBanner / MLMetricSummary

- status = icon + label + short meaning.
- metric = label + value + unit + interpretation + measured time/source.
- null → “측정되지 않음/기록 부족”, zero → 실제 0.
- 의료 상태처럼 보이는 값은 면책과 근거 범위를 같은 viewport에 둔다.
- chart에는 한 줄 textual summary와 semantics value를 제공.

### 3.7 Stable test identity

- 기존 visible text selector를 불필요하게 변경하지 않는다.
- 시각 문구 변경이 필요한 component에는 안정적인 `Key`와 Semantics label을 추가한다.
- 테스트를 통과시키기 위해 접근성 label을 숨기거나 `excludeSemantics`를 남발하지 않는다.
- key는 route/feature 의미로 명명하고 레이아웃 구현명을 넣지 않는다.

## 4. State contract

모든 비동기/입력 화면은 다음 중 필요한 상태를 명세서에 선언한다.

| 상태 | 사용자에게 보여야 하는 것 | 모션 |
|---|---|---|
| loading | 무엇을 불러오는지 + skeleton | none/fade |
| empty | 값이 없는 이유 + 첫 행동 | fade |
| error | 쉬운 원인 + retry/대안 | fade, live region |
| content | 실제 데이터 | 첫 진입만 screen policy |
| editing | visible label, 변경 중임 | press/color |
| submitting | CTA disable, 진행 문구 | progress only |
| success | 방금 끝난 행동과 다음 단계 | fade/one-shot |
| disabled | 이유와 활성화 방법 | none |

상태 전환은 Provider/Service API를 바꾸지 않는다. 필요하면 화면 전용 immutable UI state/ViewModel을 추가해 기존 결과를 mapping한다.

## 5. Motion grammar

### 5.1 정본 값

| token | 시간/값 | 허용 용도 |
|---|---:|---|
| press | 100ms | button/card down/up |
| fade | 150ms | color, opacity, state switch |
| enter | 200ms | local element enter/exit |
| route | 300ms | 기존 page/control transition |
| stagger | 60ms | 최대 4 group, 총 400ms 이하 |
| translate | 8px | screen section enter |
| pressScale | 0.98 | full only |
| burst | 600ms | 정답·저장 1회 |
| celebrateMax | 2.5s | 훈련 결과/오프닝 상한 |

신규 milliseconds literal을 만들지 않는다.

### 5.2 MotionLevel mapping

| pattern | full | fadeOnly | none |
|---|---|---|---|
| press | 0.98 scale+opacity | opacity | 즉시 상태 |
| screen enter | 8px+fade, 4 group | 동시 fade | 최종 상태 |
| state switch | 150ms fade | 150ms fade | 즉시 |
| chart/value | 200ms linear/ease-out | 즉시 | 즉시 |
| message insert | size+fade | fade | 즉시 |
| error shake | 작은 translate | 없음, 색+텍스트 | 즉시 텍스트 |
| particle/confetti | 1회 | 없음 | 없음 |
| route | 플랫폼 기본 | 플랫폼 설정 | 플랫폼 설정 |

fadeOnly에서 정보가 사라지면 안 된다. none은 애니메이션만 없고 success/error feedback은 즉시 표시한다.

### 5.3 화면별 motion policy

| 화면군 | 정책 | 이유 |
|---|---|---|
| opening/login | brand full, 1회 | 첫인상·공간 연결 |
| onboarding | section full | 선택 가능한 3항목 orientation |
| assessment | fadeOnly | 집중과 점수 의미 보호 |
| training hub/history | full first-entry | 경로와 진행 발견 |
| games | action feedback full, entry none | 문제 집중, 정답 인과 |
| home | full first-entry | daily overview orientation |
| walking/reports/health | chart/value only + first-entry group | 데이터 변화 설명 |
| diary | calendar functional + save one-shot | 기록 완료 기억 |
| AI chat | bubble fade/size, no page stagger | 대화 흐름 보존 |
| profile/settings/guardian/CS | section fade/full 최대 3group | 정보 구조 orientation |
| admin | state fade, chart only | 생산성·밀도 우선 |
| blocked/error/legal | none/fade | 내용 읽기가 우선 |

### 5.4 금지 모션

- 반복 pulse/bounce/shimmer/confetti.
- 자동 carousel, marquee, parallax.
- blur/backdrop filter 진입.
- scroll 위치에 묶인 장식 fade-up.
- 수치를 실제 범위 밖으로 넘기는 spring.
- control 위치를 바꾸는 loading/content transition.
- 같은 화면 재진입마다 stagger replay.
- 서로 다른 정보 card 사이 Hero.
- 전역 custom route transition.
- hidden tab에서 ticker 실행.

## 6. Presentation architecture

### 6.1 유지

- Provider/ChangeNotifier.
- go_router 44개.
- feature-first 구조.
- training domain/application/data 분리.
- SQLite/Firestore/SharedPreferences/Service API.

### 6.2 점진 분리 우선순위

1. **Reports**: DB read, trend/status 계산, chart series를 `ReportsViewModel`/repository adapter로 이동. 저장 의미는 유지.
2. **Home**: section widget + `Selector`로 User/Pedometer/Training/Diary 구독 분리.
3. **AI chat**: session state(starting/ready/sending/error/ended/saving)를 화면 전용 model로 묶되 message는 여전히 memory-only.
4. **Walking**: weekly load error와 tracking permission state를 분리; PedometerManager API 유지.
5. **Health**: load/save 상태와 form controller 분리; upsert 계약 유지.
6. **Guardian**: token/sync state 분리; payload와 token API 유지.

한 화면에서 비즈니스 refactor와 visual redesign을 같은 PR에 하지 않는다. 먼저 characterization test, 다음 state adapter, 마지막 view 교체 순서다.

### 6.3 Rebuild boundary

- 상위 화면의 `context.watch<T>()`를 section-level `Selector`로 이동.
- selector는 화면이 사용하는 immutable scalar/record만 반환.
- 100Hz sensor stream은 현재처럼 notify를 제한하고 live graph만 repaint.
- AnimatedBuilder의 변하지 않는 subtree는 child로 전달.
- RepaintBoundary는 DevTools raster/profile에서 효과를 확인한 곳에만.

## 7. Rollout architecture

### 7.1 변경 단위

- PR 1개 = token 묶음 1개 또는 화면 1개.
- 각 화면 PR은 characterization test → UI state test → visual change → Maestro selector 확인 순서.
- 기능 코드 수정이 필요하면 별도 PR로 분리.

### 7.2 Flag 전략

현재 `redesign2026` flag는 존재하지 않는다. 필요 시 아래처럼 **제안**한다.

- pure token/accessibility 수정: flag 없이 적용.
- Home/MainNav, Reports, AI Chat처럼 고위험 큰 화면: compile-time `ML_UI_V2` 또는 화면별 임시 builder flag.
- 두 view는 같은 Provider/ViewModel instance를 사용.
- 출시 후 안정화되면 구 view와 flag를 제거.
- remote flag 의존은 오프라인-first 앱에 추가 운영 복잡도를 만들므로 사용하지 않는다.

### 7.3 롤백

- UI flag off 또는 해당 화면 PR revert.
- DB migration/route/service가 없으므로 롤백이 데이터에 영향을 주지 않아야 한다.
- 접근성·보안·데이터 안전 수정은 구 UI 롤백과 함께 되돌리지 않는다.
- test assertion 약화로 롤백하지 않는다.

## 8. 성능 예산

| 항목 | 합격 기준 |
|---|---|
| 60Hz frame | target 최저 사양 profile에서 UI/raster p95가 16ms 예산 안, 초과 frame 원인 기록 |
| 120Hz | 지원 기기 관찰 지표; 60Hz 합격을 먼저 |
| screen choreography | 400ms 이하, 최대 4 group |
| simultaneous full-screen animation | 1개 이하 |
| repeating animation | 0 |
| hidden tab ticker | 0 |
| cold start | 기존 사용자 피드백/오프닝보다 늦어지지 않음 |
| memory | 탭을 반복해도 controller/subscription 증가 없음 |
| dependency | 리디자인으로 runtime package 0개 추가 |

성능 수치가 없으면 “부드럽다”고 완료 처리하지 않는다. 실제 기기 profile trace를 저장한다.

## 9. 접근성·인지 acceptance

### 자동

- Android tap target 48dp; primary CTA 56dp.
- text 4.5:1, large/essential graphics 3:1.
- labeled tap target.
- palette/motion/radius/font guard.
- 320dp × text scale 2.0 overflow.
- full/fadeOnly/none 동일 정보.

### 실기기

- TalkBack, VoiceOver: 이름·역할·값·순서·live status.
- Voice Access/Switch Access: 모든 핵심 action 도달.
- Android predictive back: preview/cancel/complete와 form state.
- permission deny/revoke: 걷기·마이크·카메라가 앱 전체를 막지 않음.
- background/lock/orientation: 현재 task와 입력 복원.

### 사용자 task

60~80대·MCI 특성이 있는 참여자와 보호자를 포함하고 다음을 관찰한다.

1. 홈에서 오늘 할 행동을 도움 없이 찾는가.
2. 훈련을 시작·완료하고 결과를 이해하는가.
3. 일기를 음성/텍스트로 저장하고 저장 여부를 확신하는가.
4. 걸음 추적 권한 거부 후 다음 행동을 이해하는가.
5. 리포트의 숫자와 비수치 해석을 구분하는가.
6. 보호자 연결을 공유하고 실패 시 대안을 찾는가.
7. 중간에 1분 방해 후 현재 단계와 다음 행동을 다시 찾는가.

성공률, 오탭, 도움 요청, 완료시간, 중단, 모션 불편을 기록한다. 참여자는 언제든 중단할 수 있고 본인과 필요한 경우 보호자의 informed consent를 받는다.

## 10. 의존성 DAG

```text
G0 Baseline capture
 └─ G1 Characterization / contract tests
     └─ G2 Foundation tokens
         └─ G3 Shared component / state patterns
             └─ G4 Async·오류·접근성 보강
                 ├─ G5 Main shell + Home
                 ├─ G6 Training presentation lock
                 ├─ G7 Diary + AI Chat
                 └─ G8 Walking + Reports + Health

G5+G6+G7+G8 green
 └─ G9 Auth/onboarding/profile/settings/support
     └─ G10 Admin
         └─ G11 Adaptive expanded + dark mode (서로 다른 PR)
             └─ G12 material_ui migration evaluation (별도 branch)
```

한 gate가 실패하면 downstream 화면을 시작하지 않는다.

## 11. Done의 정의

화면이 예뻐졌거나 스크린샷이 승인됐다는 이유만으로 완료하지 않는다.

- 44 route와 비라우트 surface 기능 parity.
- 데이터 row/payload/PDF 의미 동일.
- loading/empty/error/content와 필요한 edit/submit/success 상태.
- 320/360/600/840 폭, text scale 1.0/1.3/1.6/2.0.
- full/fadeOnly/none.
- TalkBack/VoiceOver와 predictive back.
- flutter analyze/test/integration/Maestro gate.
- 최저 사양 profile 성능.
- before/after screenshot과 사용자 task 결과.
- 롤백 경로 확인.

이 기준을 모두 통과한 화면만 “리디자인 완료”로 표시한다.
