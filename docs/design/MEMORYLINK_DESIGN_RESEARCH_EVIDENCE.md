# MemoryLink 디자인·모션 2차 리서치 근거 장부

> 확인일: 2026-09-28. 출처의 법적·기술적 성격을 구분한다. 연구 주장이나 showcase를 규범처럼 사용하지 않는다.

## 1. 근거 등급

| 등급 | 의미 | 계획에서의 사용 |
|---|---|---|
| A — 규범/플랫폼 품질 기준 | WCAG 2.2, Android core quality | 반드시 통과할 acceptance criterion |
| B — Flutter 공식 기술 가이드 | Flutter docs/API/codelab | 구현 방식과 테스트 선택의 기본값 |
| C — 공식 디자인 연구·보충 지침 | M3 Expressive research, W3C COGA Note | 방향과 사용자 가설; 실제 사용자 검증 필요 |
| D — 공식 사례·제작사 사례 | Flutter showcase, Wonderous source | 패턴 참고; 그대로 복제 금지 |

## 2. 공식 근거와 MemoryLink 적용

### A. WCAG 2.2

- URL: https://www.w3.org/TR/WCAG22/
- 성격: W3C Recommendation, 규범 기준.
- 적용:
  - 텍스트 대비 4.5:1, 큰 텍스트 3:1.
  - 필수 비텍스트/컨트롤 상태 3:1.
  - 색을 유일한 정보 수단으로 사용 금지.
  - text resize 200%에서 기능·정보 손실 금지.
  - target minimum 24×24 CSS px는 규범 하한이며 MemoryLink 목표가 아니다.
  - 시간 제한 조절, 자동 이동 제어, 점멸 제한, 접근 가능한 인증, 오류 식별·제안.

### A/B. Android Core App Quality (2026-09-21 갱신)

- URL: https://developer.android.com/docs/quality-guidelines/core-app-quality
- 성격: Android 공식 앱 품질 기준과 수동 테스트 목록.
- 확인 내용:
  - 모든 screen/dialog/settings/user flow를 탐색해 일관성 검증.
  - touch target 최소 48dp.
  - 작은 글자 4.5:1, 큰 글자·그래픽 3:1.
  - standard back/gesture back, foreground/background/lock/orientation state 보존.
  - startup이 2초보다 길면 사용자에게 진행 피드백.
  - 16ms 이하 frame으로 60fps 목표.
  - runtime permission은 기능 요청 시점에 설명과 함께 요청하고 거부 시 graceful degradation.
  - system sharesheet 사용.
- MemoryLink 적용: 44 route뿐 아니라 dialog/sheet/PDF/share/권한까지 보존 계약에 포함하고, profile mode와 실제 기기 검증을 release gate로 둔다.

### B. Flutter Material 3

- URL: https://docs.flutter.dev/ui/widgets/material
- 성격: Flutter 3.47 공식 widget catalog.
- 확인: Material 3는 Flutter 3.16부터 기본이며 visual/behavioral/motion-rich widget과 NavigationBar/Rail, dialog, sheet, card, selection, progress를 제공한다.
- 적용: 커스텀 canvas보다 표준 Material control을 기본으로 하고 MemoryLink token을 Theme/component wrapper에서 적용한다.

### B. Flutter animations

- URL: https://docs.flutter.dev/ui/animations
- 성격: Flutter 공식 구현 가이드.
- 적용: implicit AnimatedX 우선, 제어가 필요할 때 controller, 동일 요소 연결은 Hero, 물리 의미가 있을 때만 spring. 기존 AppMotion을 유지한다.

### B. Flutter performance

- URL: https://docs.flutter.dev/perf/best-practices
- URL: https://docs.flutter.dev/perf/ui-performance
- 성격: Flutter 공식 성능 가이드.
- 적용:
  - 큰 build와 상위 setState를 변화 단위 widget으로 분리.
  - const와 builder/lazy list 사용.
  - Opacity/clip/saveLayer/shadow/RepaintBoundary는 측정 후 사용.
  - debug/emulator가 아닌 최저 사양 실기기 profile mode로 UI/raster frame 측정.

### B. Flutter accessibility testing

- URL: https://docs.flutter.dev/ui/accessibility/accessibility-testing
- URL: https://docs.flutter.dev/ui/accessibility/assistive-technologies
- 성격: Flutter 3.47 공식 테스트 가이드.
- 확인:
  - Android 48×48, iOS 44×44, tap label, text contrast guideline API.
  - Android Accessibility Scanner, Xcode Accessibility Inspector.
  - TalkBack/VoiceOver뿐 아니라 Switch Access, Voice Access, Switch Control, Voice Control, AssistiveTouch.
- 적용: 현재 training 중심 guideline test를 전 화면 shell·폼·chat·settings로 확장한다.

### B. Flutter predictive back

- URL: https://docs.flutter.dev/platform-integration/android/predictive-back
- 성격: Flutter 3.47 공식 플랫폼 가이드.
- 확인: Android 14부터 지원되는 predictive back을 기본 page route가 지원하고, custom pop interception은 `PopScope`를 사용한다.
- 적용: 전역 custom route transition을 만들지 않는다. 폼 이탈 확인이 필요하면 `WillPopScope`가 아니라 `PopScope`와 상태 보존을 함께 검증한다.

### B. Flutter adaptive Material 3 codelab

- URL: https://codelabs.developers.google.com/codelabs/flutter-animated-responsive-layout
- 성격: Google 공식 샘플.
- 확인: 좁은 화면 NavigationBar ↔ 넓은 화면 NavigationRail, list-detail, layout transition을 하나의 상태와 controller로 연결한다.
- 적용: 600/840 폭 검토 근거는 되지만, 5탭 셸 전환은 P3에서 상태 보존을 먼저 증명한 뒤 적용한다. 샘플의 1000ms+ 안무를 MemoryLink에 그대로 쓰지 않는다.

### B. Flutter 3.47 standalone design packages

- URL: https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui
- 성격: Flutter 3.47 breaking change guide.
- 확인:
  - `material_ui`/`cupertino_ui` 1.0은 opt-in.
  - in-framework Material은 향후 stable에서 deprecation 예정.
  - bridge가 public API type mismatch를 해결하지 못할 수 있어 dependency 호환 위험이 있다.
- 결정: 리디자인과 동시에 마이그레이션하지 않는다. 별도 브랜치·별도 회귀 캠페인으로 분리한다.

### C. Material 3 Expressive UX research

- URL: https://design.google/library/expressive-material-design-google-research
- 성격: Google Design의 UX 연구 주장, 규범·임상 근거 아님.
- 확인: color/shape/size/motion/containment로 핵심 요소를 강조하고, 10개 앱 실험에서 일부 핵심 UI를 최대 4배 빨리 발견했다고 보고한다. 45세 이상 fixation time 차이 감소도 보고한다. 동시에 익숙한 패턴·텍스트 label 제거 시 usability가 하락했고 calmer design 선호 집단이 있음을 명시한다.
- 적용: “표현적”을 색·모션 양이 아니라 중요한 행동의 발견 가능성으로 해석한다. 60~80대 효과는 MemoryLink 사용자 테스트로 재검증한다.

### C. W3C COGA Making Content Usable

- URL: https://www.w3.org/TR/coga-usable/
- 성격: 2021 Working Group Note, WCAG 적합성 요구가 아닌 보충 지침.
- 확인:
  - familiar hierarchy, consistent visual design, clear steps/controls.
  - 가장 중요한 행동을 스크롤 없이 찾게 함.
  - 움직임·내용 변화는 사용자 통제.
  - 오류 예방·되돌리기·입력 보존·즉시 성공 피드백.
  - 한 화면 main choice 5개 이하 권고 패턴.
  - chart/숫자에 텍스트 설명 제공.
  - 인지장애 당사자와 실제 task usability test를 자동 검사와 병행.
- 적용: 5탭과 기존 위치는 유지하고, 한 화면의 주 행동을 하나로 만든다. 모션은 feedback와 orientation을 위해서만 쓴다.

### 참고 제한 — Apple HIG

Apple HIG motion/accessibility 페이지는 현재 도구에서 JavaScript 요구로 본문을 추출하지 못했다. URL은 참고 링크로만 남기고, 이번 계획의 구체 acceptance 수치는 WCAG·Flutter·Android에서 검증된 값으로 고정한다.

- https://developer.apple.com/design/human-interface-guidelines/motion
- https://developer.apple.com/design/human-interface-guidelines/accessibility

## 3. 검증된 Flutter 사례 비교

| 사례 | 1차 근거 | 확인 가능한 사실 | MemoryLink가 배울 것 | 복제 금지 |
|---|---|---|---|---|
| Wonderous | https://flutter.dev/blog/wonderous-explore-the-world-with-flutter · https://github.com/gskinnerTeam/flutter-wonderous-app | Flutter팀+gskinner 오픈소스 reference, custom transition/scroll, familiar behavior, accessibility와 benchmark 목적 | motion token, shared element, custom UI와 접근성 병행 | 영화적 scroll/parallax와 고밀도 효과 |
| SoFi | https://flutter.dev/showcase/sofi | custom animation/motion, package architecture, 점진 Add-to-app, 변경 package 대상 test/screenshot test | 기능별 독립 개발·검증, 점진 migration | 금융 super-app 정보 밀도 |
| Tonal | https://flutter.dev/showcase/tonal | 건강·fitness 앱, custom branded UI, custom chart, Rive animation, 긴 목록 | 건강 데이터에 선택적 branded motion | 운동 앱의 강한 에너지와 전역 Rive |
| Rive Editor | https://flutter.dev/showcase/rive | editor 전체 Flutter, interactive graphics, fluid layout, 대규모 test | 한 개 focal state machine의 design-dev workflow | 일반 UI를 custom canvas로 교체 |
| Reflectly | https://flutter.dev/showcase/reflectly | Flutter 제작 mental-health journal, 양 플랫폼 개발 | diary 도메인의 정서적 tone 참고 | official page가 세부 motion 기법을 제공하지 않으므로 기술 추정 금지 |
| Superlist | https://flutter.dev/showcase/superlist | Flutter로 task/project management 앱 제작 | 매일 쓰는 앱의 제품 polish를 관찰 기준으로 활용 | 공식 페이지가 구현 세부를 제공하지 않으므로 package/architecture 추정 금지 |

## 4. 2차 리서치로 바뀐 결정

1. 전 화면에 motion을 추가하지 않는다. 평가·대화·관리 화면은 주의 분산을 막기 위해 fadeOnly/상태 feedback 중심이다.
2. 5탭을 줄이거나 위치를 바꾸지 않는다. COGA의 familiar interface와 현재 사용자 muscle memory를 우선한다.
3. 디자인 feature flag는 rollout/rollback을 위해 제안할 수 있지만 현재 구현으로 오인하지 않는다.
4. Material 3 Expressive는 원칙을 채택하되 standalone `material_ui` migration은 분리한다.
5. Golden image만으로 합격시키지 않는다. 44 route 기능 parity, state restoration, permission denial, screen reader 실제 검증이 필요하다.
6. “모션이 많음”의 성공 지표는 animation count가 아니라 action feedback coverage, disorientation 0, frame jank 0이다.
