# MemoryLink Flutter 디자인·모션 리서치 최종 보고서

> 완료: 2026-09-28 · 범위: 현재 코드/14개 대표 캡처 진단, Flutter 3.47 공식 문서, Material 3 Expressive, WCAG 2.2 모바일·인지 접근성, 검증 가능한 Flutter 앱 사례

## 1. 결론부터

MemoryLink는 전면 재디자인이 필요한 앱이 아니다. 이미 `Material 3`, Pretendard 5굵기, 의미색과 반경 토큰, 버튼용 56dp 기본 터치 토큰과 48dp 플로팅 내비 예외, `full/fadeOnly/none` 모션 감소, 정적 스켈레톤, 차트·숫자 모션과 관련 회귀 테스트를 갖췄다. 일반적인 Flutter 프로토타입보다 기반이 훨씬 성숙하다.

최적의 다음 방향은 **Calm Expressive Lavender**다.

- 현재 라벤더 `#6C5CE7`과 “조용한 돌봄, 보이는 기록”은 유지한다.
- M3 Expressive의 color·shape·size·motion·containment는 **핵심 행동 발견과 상태 이해**에만 사용한다.
- “모션을 많이”는 반복 장식이 아니라 **누름, 진입, 상태 변경, 수치 변화, 이동, 성취, 기록 완료**의 일곱 순간에서 항상 반응하는 것으로 재정의한다.
- Provider·go_router·feature 구조는 유지한다. 상태관리 교체보다 `home`과 `reports`의 UI/data 분리 및 구독 범위 축소가 우선이다.
- `flutter_animate`, Lottie, Rive를 한꺼번에 넣지 않는다. 현재 native 모션 시스템으로 대부분 충분하며, Rive는 사용자 가치가 입증된 하나의 focal animation에만 조건부 검토한다.

가장 먼저 할 일은 ① 현재 빌드로 대표 화면 재캡처, ② AI 대화 빈 상태와 리포트 차트/하단 가림 검증, ③ 카드와 라벤더 큰 면의 반복 축소, ④ `home` 섹션 분리와 `reports` ViewModel화다.

## 2. 무엇을 확인했는가

### 로컬 프로젝트

- `pubspec.yaml`
- `lib/core/theme.dart`, `lib/core/ml_widgets.dart`
- `lib/core/motion/*`, `lib/main.dart`, `lib/core/router.dart`
- `home`, `navigation`, `training`, `walking`, `reports`, `diary`, `ai_chat`, `profile` 주요 구현
- 루트의 `01_home.png`부터 `14_cs_center.png`까지 14개 캡처
- 디자인·모션·접근성 관련 테스트 9개
- 기존 `DESIGN.md`와 `.research/flutter-design-2026` 연구 기록

### 주의할 점

루트 캡처는 화면에 2026년 7월 날짜가 보이고, 현재 코드와 `DESIGN.md`에는 8~9월 개선이 반영되어 있다. 예를 들어 현재 코드는 하단 네비게이션 가림 방지 inset, MotionLevel 3단, 스켈레톤, 진입 안무를 갖고 있다. 따라서 캡처는 **시각 방향 진단 자료**로 사용했으며, 현재 동작의 최종 증거로 보지 않았다. P0에서 재캡처해야 한다.

또한 README에는 Lottie 배지가 있지만 현재 `pubspec.yaml`에는 `lottie`, `rive`, `flutter_animate`가 없다. 문서와 구현이 불일치한다.

## 3. 현재 디자인 진단

| 영역 | 잘된 점 | 개선점 |
|---|---|---|
| 색 | 일관된 라벤더 브랜드, 민트·앰버·핑크 의미색, 글자용 상태색 분리 | 캡처에서 큰 라벤더 면과 연보라 배경이 반복되어 계층이 평평하고 AI 템플릿 같은 인상이 날 수 있음 |
| 타이포 | Pretendard 400~800 실제 자산, 큰 제목·본문 위계, 12sp 하한 | 핵심 측정값과 행동 문구는 16sp 이상을 더 엄격히 보장하고 숫자에 tabular figures 적용 필요 |
| 형태 | 큰 타깃, 친근한 둥근 모서리, 일관된 pill nav | 거의 모든 카드가 크고 둥글어 중요도 차이가 약함. hero/standard/data/list의 형태 차이를 더 분명히 해야 함 |
| 정보 구조 | 홈→훈련/생활/리포트/내정보가 이해하기 쉬움 | 홈·리포트가 긴 카드 스택이며 한 화면의 “지금 할 한 가지”가 덜 분명함 |
| AI 대화 | 진행률과 입력 구조가 단순하고 글자가 큼 | 첫 메시지만 있을 때 화면 대부분이 공백. 추천 답변·회상 주제·음성 안내가 필요 |
| 일기 | 달력, 큰 입력 영역, 음성 입력이 명확 | “Memory Garden”이라는 이름과 실제 시각 경험 연결이 약함 |
| 훈련 | 큰 선택지, 즉각 피드백, 결과 효과와 적응형 난이도 | 카테고리 사이 여백과 긴 탐색을 줄이고 오늘 할 훈련 3개를 우선해야 함 |
| 리포트 | 상태 텍스트·막대·차트로 이해가 쉬움 | 차트 데이터가 7개 미만이어도 월~일 라벨을 고정 표시할 수 있고, DB/계산/UI가 한 State에 섞임 |
| 접근성 | 버튼·주요 행동 56dp 기본 토큰, 플로팅 내비 48dp, AA 대비 계산, text scale 2.0 상한, Semantics, 축소 모션 | 56dp 정책의 전 컴포넌트 적용 여부, 시간 제한 조절, 실제 TalkBack/VoiceOver 순서, 색 외 단서의 전 화면 검증이 남음 |

## 4. 추천 디자인: Calm Expressive Lavender

Google의 M3 Expressive 연구는 표현적 디자인의 기본 요소를 **색, 형태, 크기, 모션, 컨테인먼트**로 설명한다. 연구 글은 핵심 UI 발견이 일부 실험에서 최대 4배 빨랐고, 45세 이상 사용자의 탐색 시간 차이가 줄었다고 보고한다. 다만 이는 Google의 UX 연구 결과이지 MemoryLink의 임상적 유효성을 입증하는 수치가 아니다. 같은 글은 익숙한 패턴과 텍스트 라벨을 제거하면 사용성이 떨어지고, 차분한 버전을 선호하는 사용자도 있으므로 기능과 사용자 요구를 우선하라고 경고한다.

MemoryLink 적용 규칙은 다음과 같다.

### 4.1 색

1. 라벤더는 유지하되 **한 화면에 큰 라벤더 면은 최대 하나**로 둔다.
2. hero 아래 일반 콘텐츠는 흰 surface, 약한 경계선, 6~12% category tint를 사용한다.
3. 카테고리색은 한 화면에 동시에 세 개 이하로 제한하고 아이콘·라벨을 함께 둔다.
4. 그라디언트는 홈 hero, 오프닝 등 브랜드 순간에만 사용한다. 모든 CTA와 카드에 반복하지 않는다.
5. 다크 모드는 당장 P0가 아니다. `DESIGN.md`의 현재 결정대로 고대비 라이트를 완성한 뒤 상태 텍스트 4색의 다크 대비를 해결하고 별도 검증한다.

### 4.2 타이포

- 기존 Pretendard와 TextTheme를 유지한다.
- 행동 버튼, 건강 상태, 주요 수치는 16sp 이상, 본문은 15~16sp, 12~13sp는 보조 라벨에만 쓴다.
- 한 화면에서 굵기 단계는 세 개 이하로 제한한다.
- 걸음 수·점수·백분율에는 `FontFeature.tabularFigures()`를 적용한다.
- 고정 높이로 큰 글자를 끼워 맞추지 말고 text scale이 커지면 2열→1열, 가로 Row→세로 Column으로 바뀌게 한다.

### 4.3 형태와 깊이

현재 반경 토큰은 유지하되 역할을 나눈다.

- `rCard/rSheet`: hero, 큰 dialog, bottom sheet
- `rPanel`: 일반 정보 카드와 데이터 패널
- `rTile`: 리스트 타일과 아이콘 배경
- `rBtn`: 버튼
- `rChip`: 상태·필터

즉, 새 반경을 만들지 말고 `MLCard`에 `hero`, `standard`, `data`, `interactive` variant를 추가한다. 일반 카드에는 경계선과 최소 그림자, hero와 floating nav에만 브랜드 톤 그림자를 사용한다. blur, glassmorphism, neumorphism은 대비와 렌더 비용 때문에 이 제품의 기본 언어로 적합하지 않다.

### 4.4 화면별 핵심 변경

**홈**: 가장 큰 요소는 “오늘 지금 할 행동” 하나여야 한다. 인사 hero 안에 상태를 모두 넣기보다 오늘 훈련 시작 또는 오늘 기록 중 하나를 주 CTA로 둔다. AI·일기·걸음은 동등한 큰 카드 세 장이 아니라 우선순위가 다른 surface 타일로 정리한다.

**AI 대화**: 빈 공간을 장식 애니메이션으로 채우지 않는다. `오늘 기분 이야기하기`, `어릴 적 추억 떠올리기`, `음성으로 답하기` 같은 56dp 추천 선택지 2~3개를 제공한다. 메시지 삽입은 fade+size로만 처리한다.

**Memory Garden**: 저장 성공 순간에만 작은 잎이나 꽃이 한 번 자라게 한다. 날짜마다 기록이 쌓이는 모습은 정적인 정원 상태로 보여주고 반복 흔들림·반짝임은 쓰지 않는다.

**훈련**: 오늘 목표를 맨 위에, 추천 3개를 다음에, 전체 훈련은 그 아래 둔다. 정답은 색+아이콘+텍스트+필요 시 햅틱으로 확인시키고, 오답 shake는 작고 짧게 하며 reduce motion에서는 제거한다.

**보행/리포트**: 화면 순서를 `한 줄 결론 → 근거 수치 → 추세 → 다음 행동`으로 고정한다. 의료적 확정처럼 보이는 표현은 피하고, 정상/경고/고위험은 색만이 아니라 텍스트와 아이콘을 유지한다.

## 5. Flutter로 “모션이 풍부하지만 깔끔한” 앱을 만드는 법

### 5.1 모션의 목적

많은 모션이 아니라 많은 **반응 지점**을 만든다.

| 순간 | 구현 | 시간 | 규칙 |
|---|---|---:|---|
| 누름 | 기존 `PressableScale` | 100ms | 모든 실제 탭 요소. full은 0.98 scale, fadeOnly는 opacity |
| 화면 첫 진입 | 기존 `StaggeredColumn` | 200ms + 60ms 간격 | 8px, 최대 4묶음, 전체 400ms 이하, 실행당 1회 |
| 선택/상태 | `AnimatedContainer`, `AnimatedSwitcher` | 150ms | 선택, 성공, 오류, 로딩→내용 |
| 값 변화 | 기존 `MLProgressBar`, `MLRing`, `MLCountUp`, `MLChart` | 200ms | 이전 값→새 값. 매 진입 시 0부터 세지 않음 |
| 화면 이동 | 플랫폼 기본 + 선택적 `Hero` | 기본/300ms | 예측형 뒤로가기 보존. 명확한 동일 요소에만 Hero |
| 성취 | 기존 particle/confetti | 600ms~2.5s | 사용자 행동 뒤 1회, 반복 없음, 축소 모션에서 제거 |
| 대화/일기 | `AnimatedSize`+fade, 선택적 focal Rive | 150~200ms | 메시지 추가·저장 완료의 인과만 표현 |

### 5.2 implicit와 explicit 선택

Flutter 공식 흐름과 현재 프로젝트에 맞춘 기준이다.

- 속성 하나가 상태에 따라 바뀜: `AnimatedContainer`, `AnimatedOpacity`, `AnimatedScale`, `TweenAnimationBuilder`
- 재생·역재생·여러 트랙·정확한 시점 제어가 필요함: `AnimationController` + `AnimatedBuilder`
- 같은 대상이 화면 사이를 이동함: `Hero`
- 실제 물리 반응이 사용자 이해에 도움 됨: `SpringSimulation` 또는 기존 `AppMotion.spring`
- 반복 일러스트 또는 복잡한 상태 머신이 디자이너 자산과 연결되어야 함: 그때만 Rive 검토

현재 `StaggeredColumn`, 결과 파티클, 오프닝처럼 제어가 필요한 곳은 explicit이 맞고, 카드·색·값 변화는 implicit이 맞다.

### 5.3 패키지 결정

- **flutter_animate**: 지금은 추가하지 않는다. 선언 문법은 짧아지지만 현재 Duration token guard, MotionLevel, 실행당 1회 정책을 다시 래핑해야 해 이익이 작다.
- **Lottie**: 고정된 After Effects 일러스트가 꼭 필요할 때는 쓸 수 있지만, 현재 앱에는 의존성이 없다. 반복 장식용으로 넣지 않는다.
- **Rive**: 상태 기반 상호작용과 한 자산의 디자인-개발 협업에는 강하다. Memory Garden 저장 완료처럼 하나의 focal state가 사용자 테스트에서 가치를 보일 때만 정확한 버전을 고정해 추가한다.
- **animations package/전역 route transition**: 현재는 추가하지 않는다. Android predictive back과 플랫폼 익숙함이 우선이다.

## 6. 잘 만든 Flutter 앱과 비교

| 사례 | 검증된 특징 | MemoryLink가 배울 점 | 모방하지 않을 점 |
|---|---|---|---|
| **Wonderous** | Flutter팀+gskinner 오픈소스 레퍼런스. 커스텀 전환·스크롤·접근성을 함께 목표로 함 | 공통 모션 토큰, 접근성 모드, shared element, 맞춤 컴포넌트 | 영화적 parallax, 고밀도 효과, 작은 텍스트 |
| **Superlist** | Flutter 공식 showcase의 멀티플랫폼 task/productivity 앱 | 매일 쓰는 앱의 짧고 일관된 마이크로 피드백 | 생산성 앱 수준 정보밀도와 복합 gesture |
| **SoFi** | Flutter 공식 사례. custom animation/motion과 package 기반 점진 마이그레이션 | 기능별 패키지/모듈, 독립 테스트, screenshot test, 점진 개선 | 금융 super-app의 밀도와 복잡한 메뉴 |
| **Tonal** | 건강·피트니스 Flutter 앱. custom chart, Rive animation, 긴 목록 | 건강 데이터에 브랜드 경험을 입히되 기능 parity 유지 | Rive를 모든 상태에 사용하거나 운동 앱의 강한 에너지 그대로 차용 |
| **Rive Editor** | 편집기 전체를 Flutter로 재작성, 실시간 인터랙티브 그래픽과 많은 테스트 | 단 하나의 핵심 인터랙션을 위한 상태 머신 가능성 | 일반 카드/내비게이션까지 custom canvas로 대체 |
| **Reflectly** | Flutter로 알려진 정신건강 저널 사례로 Memory Garden과 도메인이 가까움 | 따뜻한 온보딩과 기록 완료의 정서적 보상 | 짙은 보라·파랑 그라디언트 남발, 스트릭 압박 |

비교의 핵심은 “저 앱처럼 보이게”가 아니다. Wonderous의 모션 체계, SoFi의 모듈화, Tonal의 건강 데이터 커스텀 경험, Reflectly의 정서적 보상을 가져오되 MemoryLink의 고령 사용성 강도를 유지하는 것이다.

## 7. Flutter 아키텍처 청사진

### 7.1 유지할 것

- feature-first 디렉터리
- Provider/ChangeNotifier 의존성 주입과 상태 전달
- go_router
- `theme.dart`, 의미색, 반경, 현재 `core/motion`
- Android/iOS 플랫폼 기본 전환
- 테스트로 토큰과 접근성을 차단하는 방식

Flutter 공식 아키텍처도 UI/data layer, repository, ViewModel, 단방향 데이터 흐름을 강하게 권고하며 Provider와 go_router를 유효한 선택으로 다룬다. 따라서 상태관리 교체는 품질 개선의 선행조건이 아니다.

### 7.2 점진 구조

```text
lib/
  core/
    design_system/
      foundations/   colors, typography, spacing, radius, elevation
      components/    cards, metrics, status, loading, empty, error, nav
    motion/           현재 AppMotion/MotionSettings 유지
  features/
    home/
      presentation/
        home_screen.dart
        home_view_model.dart
        widgets/
    reports/
      domain/         status policy, immutable report model
      data/           report_repository.dart
      presentation/   reports_screen, reports_view_model, widgets/
```

한 번에 폴더를 모두 옮기지 말고 `reports`부터 이 패턴으로 만든 뒤 `home`에 적용한다.

### 7.3 rebuild 제어

현재 홈 상단은 여러 Provider 전체를 `watch`한다. 화면을 섹션 위젯으로 나누고 필요한 값만 선택한다.

```dart
Selector<PedometerManager, int>(
  selector: (_, value) => value.todaySteps,
  builder: (_, steps, __) => TodayStepsCard(steps: steps),
)
```

`Selector`는 모든 곳에 기계적으로 쓰지 않는다. 실제 기기의 Widget Rebuild Profiler에서 큰 화면이 자주 재빌드되는 지점을 먼저 확인한다.

### 7.4 반응형

- compact `<600`: 현재 1열과 floating bottom nav
- medium `600~839`: 제한 폭 1열 또는 중요 카드 2열
- expanded `>=840`: NavigationRail + 최대 콘텐츠 폭 + 2열 dashboard

이 값은 구현 시작점이지 사용자 검증을 대체하지 않는다. 기기 종류나 orientation 문자열이 아니라 `LayoutBuilder`의 실제 가용 폭으로 분기한다. 큰 글자에서는 폭이 충분해도 1열로 되돌아갈 수 있어야 한다.

### 7.5 성능 규칙

1. 느린 실제 Android 기기에서 `flutter run --profile`과 DevTools로 측정한다.
2. 60Hz의 약 16ms 프레임 예산을 넘는 UI/raster frame을 추적한다.
3. 큰 `build()`와 상위 `setState()`를 변화 단위 위젯으로 나눈다.
4. 긴 목록은 builder/sliver로 지연 생성한다.
5. blur, animated clipping, 넓은 opacity layer, 큰 그림자, `saveLayer` 유발 효과를 최소화한다.
6. `RepaintBoundary`와 IndexedStack 지연 생성은 측정 결과가 이익을 보일 때만 적용한다.
7. Impeller는 iOS와 Android API 29+에서 기본이지만 나쁜 장면 구성을 자동으로 고쳐 주지는 않는다.

## 8. Claude Design + Flutter 작업 방식

Claude로 디자인을 만드는 가장 좋은 방법은 “세련되게 만들어 줘”라고 요청하는 것이 아니라, **디자인 헌법과 컴포넌트 계약을 먼저 주고 한 화면씩 검증하는 것**이다.

### 권장 루프

1. `DESIGN.md`, `theme.dart`, 기존 공통 위젯, 대상 화면 캡처를 컨텍스트로 준다.
2. 코드 전에 정보 우선순위, 상태표, 컴포넌트 트리, 모션 맵을 먼저 받는다.
3. raw color·radius·duration 금지, 새 dependency 금지를 명시한다.
4. 한 화면만 구현한다.
5. 320dp, text scale 1.0/1.3/1.6/2.0, TalkBack, reduce motion에서 확인한다.
6. 현재 화면을 재캡처해 원안과 비교한다.
7. 통과한 패턴만 공통 컴포넌트로 승격한다.

### 재사용 프롬프트

```text
MemoryLink의 [화면명]을 개선하라.
대상은 60~80대 및 MCI 사용자이며 DESIGN.md가 최상위 규칙이다.
기존 ML 컴포넌트, Theme ColorScheme, AppMotion만 사용하고 raw color/radius/duration과 새 패키지를 추가하지 마라.

먼저 다음을 제시하라:
1) 사용자가 3초 안에 알아야 할 한 가지
2) normal/loading/empty/error/disabled 상태표
3) 위젯 계층과 재사용 컴포넌트
4) full/fadeOnly/none 모션 맵
5) 320dp 및 text scale 2.0 레이아웃 전략
6) Semantics와 56dp 터치 타깃 검증 목록

승인 후 Flutter 코드를 작성하라. 장식 모션, 반복 애니메이션, blur/glassmorphism, 전역 route transition은 사용하지 마라.
```

이 방식이면 Claude가 화면마다 새로운 스타일을 발명하는 것을 막고, 생성 결과가 기존 코드와 테스트 체계 안으로 들어온다.

## 9. 고령·MCI 접근성 합격선

- 터치: `AppTheme.minTapTarget`과 주요 버튼의 56dp 기본 정책을 유지한다. 현재 플로팅 내비는 폭 제약 때문에 48dp 예외이며 Flutter 공식 Android 가이드라인을 통과한다. 모든 요소가 56dp라고 간주하지 말고 컴포넌트별 실제 크기를 검증한다. 두 값 모두 WCAG 2.2 AA 24×24 CSS px 최소보다 여유가 있다.
- 대비: 일반 텍스트 4.5:1, 큰 텍스트와 필수 그래픽/컨트롤 3:1 이상. 핵심 건강 문구는 가능하면 7:1을 검토한다.
- 확대: 200%에서 내용과 기능 손실이 없어야 한다.
- 색: 색만으로 상태를 전달하지 않는다. 텍스트·아이콘·형태를 같이 쓴다.
- 시간: 인지 훈련의 시간 제한은 끄기, 조정, 연장 중 적절한 대안을 제공한다.
- 움직임: 5초를 넘는 자동 움직임은 pause/stop/hide가 필요하다. MemoryLink는 반복 모션 자체를 만들지 않는 것이 더 좋다.
- 점멸: 초당 3회 초과 점멸 금지.
- 입력/오류: 오류를 텍스트로 설명하고 수정 방법과 되돌리기를 제공한다.
- 인증: 비밀번호 기억이나 퍼즐에만 의존하지 않고 password manager, 붙여넣기 또는 대체 인증을 허용한다.
- 인지: 한 화면 한 주행동, 익숙한 위치, 일관된 명칭, 아이콘+텍스트, 예측 가능한 다음 단계가 핵심이다.

WCAG2Mobile 문서는 2025년 W3C Group Draft Note로 모바일 앱 적용에 유용하지만 규범 표준 자체는 아니다. 규범 수치는 WCAG 2.2 원문과 함께 사용해야 한다.

## 10. 실행 로드맵

### P0 — 1~2주: 현재 품질을 정확히 보이게 만들기

1. 현재 빌드로 대표 14개 화면을 재캡처하고 오래된 README 이미지를 교체한다.
2. AI 대화 empty state에 큰 추천 답변 2~3개를 추가한다.
3. 리포트 차트 데이터와 날짜/요일 라벨을 일치시킨다.
4. 모든 탭 화면의 마지막 콘텐츠가 floating nav에 가리지 않는지 실기기에서 확인한다.
5. 320dp와 text scale 2.0의 핵심 흐름 overflow를 0으로 만든다.
6. 훈련 시간 제한의 조정/해제 정책을 확정한다.
7. README의 Lottie 배지를 현재 의존성과 일치시킨다.

### P1 — 2~4주: 시각 위계와 목적 기반 모션

1. `MLCard`를 hero/standard/data/interactive variant로 나눈다.
2. 큰 라벤더 면은 화면당 하나로 제한하고 surface 기반 계층을 만든다.
3. 홈을 독립 섹션 위젯+Selector로 분리한다.
4. 리포트를 Repository+ViewModel+UI로 분리하고 상태 임계값을 도메인 정책으로 이동한다.
5. chat insert, diary save, training card→game identity의 목적 기반 모션만 추가한다.
6. 새 모션마다 full/fadeOnly/none 위젯 테스트를 추가한다.

### P2 — 4~8주: 측정 기반 고급화

1. 최저 사양 실기기 profile 기준선을 만든다: cold start, UI/raster frame, rebuild, memory.
2. 결과에 따라 IndexedStack 지연 생성, RepaintBoundary, 차트/이미지 최적화를 선택한다.
3. compact/medium/expanded shell과 tablet NavigationRail을 적용한다.
4. 고대비 라이트 완료 후 dark semantic text와 대비 테스트를 추가한다.
5. 60~80대 5~8명 형성평가에서 핵심 행동 발견, 오탭, 완료시간, 모션 불편을 관찰한다.
6. 이 테스트에서 가치가 확인된 경우에만 Memory Garden의 한 개 Rive focal animation을 검토한다.

## 11. 성공 지표

- 320dp와 text scale 1.0/1.3/1.6/2.0 핵심 흐름 overflow 0
- 버튼·주요 행동 56dp 기본 및 플로팅 내비 48dp 예외 정책, 대비 회귀 테스트 100% 통과
- 색만으로 전달되는 건강 상태 0
- 중요 컨트롤의 TalkBack/VoiceOver 이름·역할·값 확인 100%
- 자동 반복 모션 0, 일반 화면 진입 안무 400ms 초과 0
- 최저 사양 profile에서 사용자 핵심 흐름의 체감 jank 0, 초과 frame 원인 기록
- 사용자 평가에서 홈의 다음 행동과 리포트의 현재 상태를 도움 없이 설명 가능한지 확인

## 12. 최종 판단

Flutter라서 디자인 품질이 낮아지는 것이 아니다. Wonderous, SoFi, Tonal, Rive는 Flutter가 맞춤 UI, 모션, 차트, 실시간 그래픽을 만들 수 있음을 보여준다. 품질 차이는 프레임워크보다 다음에서 발생한다.

1. 색이 아니라 **토큰과 컴포넌트 계약**이 있는가.
2. 모션이 장식이 아니라 **상태와 공간을 설명**하는가.
3. 화면이 DB와 계산을 직접 소유하지 않고 **UI state를 그리는 데 집중**하는가.
4. 에뮬레이터 감상이 아니라 **실기기 profile과 접근성 테스트**로 검증하는가.
5. AI가 매 화면을 새로 발명하지 않고 **DESIGN.md 안에서 작업**하는가.

MemoryLink는 이미 1, 2, 4의 상당 부분을 갖췄다. 다음 단계는 새 라이브러리나 전면 재작성보다, 현재 시스템의 적용률을 높이고 홈·리포트 구조를 정리하며 실제 고령 사용자에게 핵심 행동이 더 빨리 보이는지 검증하는 것이다.

## 주요 출처

- Flutter animations: https://docs.flutter.dev/ui/animations
- Flutter performance best practices: https://docs.flutter.dev/perf/best-practices
- Flutter performance profiling: https://docs.flutter.dev/perf/ui-performance
- Flutter Impeller: https://docs.flutter.dev/perf/impeller
- Flutter architecture recommendations: https://docs.flutter.dev/app-architecture/recommendations
- Flutter adaptive best practices: https://docs.flutter.dev/ui/adaptive-responsive/best-practices
- Flutter accessibility: https://docs.flutter.dev/ui/accessibility
- Google M3 Expressive research: https://design.google/library/expressive-material-design-google-research
- W3C WCAG2Mobile: https://www.w3.org/TR/wcag2mobile/
- W3C cognitive accessibility: https://www.w3.org/WAI/cognitive/
- Wonderous official article: https://flutter.dev/blog/wonderous-explore-the-world-with-flutter
- Wonderous source: https://github.com/gskinnerTeam/flutter-wonderous-app
- Superlist showcase: https://flutter.dev/showcase/superlist
- SoFi showcase: https://flutter.dev/showcase/sofi
- Tonal showcase: https://flutter.dev/showcase/tonal
- Rive showcase: https://flutter.dev/showcase/rive
