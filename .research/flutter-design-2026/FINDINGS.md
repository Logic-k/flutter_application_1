# FINDINGS — flutter-design-2026

클로드 디자인(calm-design) + Flutter 로 세련·모션 풍부한 MemoryLink UI 를 만드는 방법 리서치.
max_cycles=8 (000~007, 007=executive summary).

---

## Cycle 000 — 하위질문 1: 클로드 디자인(calm-design) 원칙 정본 [strong]

calm-design 스킬 = 'AI 티(AI slop)'를 차단하는 차분한 프리미엄 디자인 시스템.
- **4 다이얼**: DESIGN_VARIANCE(기본7) / MOTION_INTENSITY(기본6) / VISUAL_DENSITY(기본4) / LANGUAGE(ko).
- **안티-슬롭 5원칙**: Pretendard 강제 / Off-Black #0A0A0A / **보라·파란 AI 그래디언트 금지(LILA BAN), 채도<80%** / Bento·비대칭 레이아웃 / 웹 min-h-[100dvh].
- **모션 5법칙**: GPU 속성(transform/opacity)만, spring physics 기본(linear 금지), MOTION=1 이어도 hover 유지, reduce-motion 의무, 모바일 강도↓.
- **MOTION_INTENSITY 척도**: 3-4 fade+짧은 transform / **5-6(기본) stagger+spring bounce+scroll fade-up** / 9-10 영화적.
- **핵심 통찰**: 라벤더 #6C5CE7 단일 액센트는 calm-design 관점에서 정확히 옳다. 금지 대상은 '색'이 아니라 '보라+파란 그래디언트 남발'. 현재 앱 모션은 사실상 3-4 → 사용자가 원하는 '모션 많이'는 5-6 으로 올리는 것. 고령 타깃이라 9-10 은 금지.
- 출처: `C:\Users\kimmi\.kiro\crew\skills\imported\claude_code\calm-design\SKILL.md`, `.../references/motion-system.md`
- 남긴 과제: 스킬 모션 예제가 전부 React/Framer Motion/CSS → Flutter 번역이 다음 과제.

## Cycle 001 — 하위질문 3: Flutter 모션 implicit/explicit/패키지 트레이드오프 [strong]

Flutter 공식 결정트리(docs.flutter.dev/ui/animations): **implicit(AnimatedX) 우선 → 제어 필요시 explicit(AnimationController) → 물리감 필요시 SpringSimulation**. 성능은 세 경로 동일, 선택 기준은 '제어 필요성'.
- **이미 구현됨**: `app_motion.dart` 의 `AppMotion.spring = SpringDescription.withDampingRatio(mass1, stiffness380, ratio0.8)` = M3 Expressive spatial default 수치, 패키지 미사용 명시. `springOut = MLSpringOutCurve()`. `pressable_scale.dart` = AnimatedScale(0.98)+AnimatedOpacity, MotionLevel 3단 분기.
- **React→Flutter 번역 사실상 완료**: calm-design 의 `cubic-bezier(0.16,1,0.3,1)` ≈ `Curves.easeOutExpo`(현 MLSpringOutCurve 계열), framer-motion spring ≈ `SpringDescription.withDampingRatio`. 앱은 M3 수치(380/0.8) 채택.
- **패키지 판단**: flutter_animate = 선언형 편의뿐 성능 이점 없음 + 4단 Duration 토큰 가드와 충돌 → 도입 실익 낮음. rive/lottie = 특정 마이크로/일러스트에만. **animations 패키지의 SharedAxisTransition(라우트 전환)만 선택적 검토 가치**.
- **핵심 통찰**: '모션을 풍부하게' = 새 패키지가 아니라 (a) StaggeredColumn 을 리스트/그리드로 확대, (b) counter-up·scroll fade-up 등 MOTION 5-6 패턴을 기존 토큰 안에서 추가하는 문제.
- 출처: docs.flutter.dev/ui/animations, `lib/core/motion/app_motion.dart`, `lib/core/motion/pressable_scale.dart`

## Cycle 002 — 하위질문 2 (트랙 A): 2026 Flutter/Material 3 공식 디자인 정본 [strong]

**Material 3 Expressive 는 M3 의 공식 진화판**이며(정본 진입 `m3.material.io`), 표현의 근본 5요소 = **color·shape·size·motion·containment**. 이 요소들은 '화려함'이 아니라 핵심 액션을 돋보이게 하고 유사 요소를 묶어 **가독·사용성**을 높이는 장치로 정의됨 (design.google 리서치 1차).

- **고령 타깃 직결 근거(가장 중요)**: 아이트래킹 랩 실험(10개 앱, M3 vs M3 Expressive 무작위 순서)에서 참가자가 핵심 UI 요소를 M3 Expressive 에서 **최대 4배 빠르게** 인지. 통상 고령층이 요소 탐색에 더 오래 걸리지만, M3 Expressive 에서는 **45세+ 사용자가 젊은 사용자와 동등한 fixation time** — "age effects 의 극적 소거". 큰 버튼·고대비 컨테인먼트가 movement/visual ability 가 다양한 사용자에게도 더 사용하기 쉬움. → MemoryLink 60~80대·MCI 타깃에 M3 Expressive 채택의 1차 정당화 근거.
- **공식 경고(그대로 채택)**: (1) **기능 우선** — 시각 장식이 명료성을 해치면 실패(재배치 플레이리스트/이메일 라벨 제거 실험에서 usability 하락). (2) **확립된 UI 패턴 존중**(리스트·carousel 등). (3) **차분한(calmer) 버전을 선호하는 강한 소수 존재 → 사용자 니즈에서 출발, 강도를 의도적으로 조절**. 이 세 번째가 calm-design 라벤더 톤과 M3 Expressive 를 화해시키는 공식 근거.
- **선호도 수치(1차, 과장 배제)**: 전 연령 net-positive, 18–24세에서 최대 87% 선호. 46개 연구·18,000명+ 참가자. (수치는 '리서치가 주장하는 바'로 표기 — 임상·성능 수치 아님.)
- **Flutter 측 정본**: `docs.flutter.dev/ui/design/material` (2026-07-31 갱신, Flutter 3.47). Flutter **3.16부터 Material 3 기본 활성**(`useMaterial3=true`), M2 는 deprecation 예정. dynamic color·design tokens·large-screen·enhanced accessibility 를 M3 가 제공한다고 명시.
- **결론(트랙 A 축 고정)**: MemoryLink 는 M3 Expressive 의 *큰 타깃 / 색 강조 / 스프링 모션* 축은 취하되, **강도는 calm 쪽(라벤더 단일 액센트, MOTION 5–6 상한)** 으로 눌러야 한다. 이는 두 시스템의 충돌이 아니라 공식 문서가 명시적으로 권장하는 '의도적 강도 조절'이다.
- 출처: design.google/library/expressive-material-design-google-research, docs.flutter.dev/ui/design/material, m3.material.io, m3.material.io/blog/building-with-m3-expressive

**트랙 A 유효 URL 맵(현행 확인, 다음 사이클 진입점)**: 디자인 `ui/design/material`·`ui/design/text/typography` / 모션 `ui/animations`(+`/implicit-animations`,`/hero-animations`,`/staggered-animations`), `cookbook/animation/page-route-animation`, `cookbook/animation/physics-simulation` / 성능 `perf`·`perf/impeller`·`perf/best-practices`·`perf/rendering-performance`·`ui/design/graphics/fragment-shaders` / adaptive `ui/adaptive-responsive`(+`/large-screens`) / 아키텍처 `app-architecture/guide`·`app-architecture/recommendations` / 접근성 `ui/accessibility`(+`/ui-design-and-styling`). 전체는 cycle_002.json `track_a_urls`.

## Cycle 003 — 하위질문 4 (트랙 B): 잘 만든 Flutter 앱 벤치마크 [strong]

> 파일명 충돌 복구: 트랙 B 는 원래 cycle_002 로 기록했으나 병렬 트랙 A 워커와 충돌 → cycle_003 으로 이동, cycle_002 는 트랙 A(Q2) 로 복원.

신뢰 출처로 Flutter 제작이 확인된 6개 쇼케이스를 선정·비교. 미확인 후보는 제외(브리프 지시 준수).

| 앱 | Flutter 근거 | 배울 것 | 모방 금지 | 소스 |
|---|---|---|---|---|
| **Wonderous** | gskinner+Flutter팀 공식·오픈소스 | 커스텀 전환·parallax·이미지 컬러추출 테마, **'화려한 모션+접근성 동시'의 공식 레퍼런스** | 고밀도 이펙트·작은 텍스트·영화적 스크롤(MOTION 9-10, 고령 부적합) | [gh](https://github.com/gskinnerTeam/flutter-wonderous-app) · [blog](https://flutter.dev/blog/wonderous-explore-the-world-with-flutter) |
| **Reflectly** (정신건강 저널) | flutter.dev/showcase, developer.android.com | 감정일기 도메인 동일, 따뜻한 온보딩·부드러운 spring | 짙은 보라·파란 그래디언트(LILA BAN), 게임화 스트릭 압박 | [showcase](https://flutter.dev/showcase/reflectly) |
| **Superlist** | flutter.dev/showcase + 오픈소스 | 정교한 마이크로인터랙션, `super_sliver_list` 대용량 리스트 성능 | 생산성앱식 정보밀도·복잡 제스처 | [showcase](https://flutter.dev/showcase/superlist) · [oss](https://www.superlist.com/open-source) |
| **Google Pay** | flutter.dev/showcase | 대규모 검증된 접근성·정보위계·리빌드 최소화 | 핀테크식 촘촘한 밀도 | [showcase](https://flutter.dev/showcase/google-pay) |
| **Flutter Gallery / flutter_animate** | 공식(단 Gallery는 2024-06 **아카이브**) | 위젯·전환 패턴 정본 카탈로그, fade/scale/shimmer 레퍼런스 | Gallery는 최신 M3 미반영 → 패턴 사전으로만. flutter_animate 도입 실익 낮음(cycle_001) | [gh](https://github.com/flutter/gallery) · [animate](https://github.com/gskinner/flutter_animate) |
| **flutter_vignettes / Flokk** | gskinner+Google 오픈소스 | 개별 마이크로인터랙션 아이디어 카탈로그(리스트삭제·물결전환 등) | 실험용 '기발한' 이펙트는 프로덕션·고령 부적합 | [gh](https://github.com/gskinnerTeam/flutter_vignettes) |

- **핵심 통찰**: 최근접 3개는 (1) **Wonderous** — flutter.dev 명시 목표 'novel animations — all while keeping accessibility top of mind' 가 MemoryLink 딜레마와 **동일**. MemoryLink 의 MotionLevel 3신호 시스템은 Wonderous 의 접근성 배려를 코드로 제도화한 버전. (2) **Reflectly** — 감정일기(Memory Garden) 최근접 벤치마크, '따뜻함은 취하되 그래디언트 남발은 버린다'. (3) **Google Pay** — 결제 앱 수준 접근성·명료성을 헬스·고령 앱에 이식.
- 출처: 상기 표(전부 flutter.dev/showcase 또는 gskinner/Flutter팀 공식으로 검증)

---

## Cycle 004 — 트랙 C / 하위질문 6: 고령·MCI 접근성 + 모션 안전성 권위 기준 정본 [strong]

60~80대·MCI 타깃 접근성·모션 안전성을 8개 원칙축으로 정리, 숫자 기준을 **출처별로 분리**하고 URL 을 못박음. (상세 cycle_004.json)

**1. 터치 타깃(출처마다 다름 — 혼동 주의)**: WCAG 2.2 AA(2.5.8) **24×24 CSS px**+간격예외 https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum · WCAG 2.2 AAA(2.5.5) **44×44 CSS px** https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced · Apple HIG **44×44 pt** https://developer.apple.com/design/tips/ · Material/Android **48×48 dp** https://m3.material.io/foundations/designing/structure → MemoryLink **56dp** 는 넷 다 상회(유지 권고).

**2. 글자 확대**: 1.4.4 Resize Text(AA) **200%** https://www.w3.org/WAI/WCAG22/Understanding/resize-text · 1.4.10 Reflow(AA) **320 CSS px** https://w3c.github.io/wcag/understanding/reflow · 1.4.12 Text Spacing(AA) 행간1.5×·문단2×·자간0.12×·어간0.16× https://www.w3.org/WAI/WCAG22/Understanding/text-spacing · Flutter `MediaQuery.textScaler` 존중(fontSize 하드코딩 금지).

**3. 대비**: 1.4.3(AA) 본문 **4.5:1**·대형(18pt↑/14pt bold↑) **3:1** https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum · 1.4.6(AAA) 본문 **7:1** https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced · 1.4.11 Non-text(AA) **3:1** https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast · 고령: 핵심 텍스트 AAA 7:1 검토.

**4. 색 외 단서**: 1.4.1 Use of Color(A) 색 단독 금지 https://www.w3.org/WAI/WCAG22/Understanding/use-of-color → CV 신호등은 텍스트(정상/경고/고위험)+아이콘 병기.

**5. 시간 제한**: 2.2.1 Timing Adjustable(A) 끄기/조정(10×)/연장 https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable · 2.2.3 No Timing(AAA) https://www.w3.org/WAI/WCAG22/Understanding/no-timing → 훈련 게임 제한시간 조정/해제.

**6. 오류 복구**: 3.3.1(A) 식별·3.3.3(AA) 제안·3.3.4(AA) 되돌리기/검증/확인·**3.3.7 Redundant Entry(A, 2.2신규)** 재입력 금지·**3.3.8 Accessible Authentication(AA, 2.2신규)** 인지테스트 없는 인증. https://www.w3.org/WAI/WCAG22/Understanding/error-identification 외.

**7. 애니메이션 감소(모션 안전성 3축)**: 2.3.1 Three Flashes(A, 강행) 1초 3회 초과 금지 https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold · 2.2.2 Pause/Stop/Hide(A) 5초↑ 자동움직임 제어 https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide · 2.3.3 Animation from Interactions(AAA) reduce-motion https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions · 플랫폼 iOS `isReduceMotionEnabled`/Android `ANIMATOR_DURATION_SCALE=0`/Flutter `MediaQuery.disableAnimations` → MemoryLink 3신호 MotionLevel = WCAG AAA 자발 준수(모범, Wonderous 'accessibility top of mind' 를 코드로 제도화).

**8. 화면 정보량**: W3C COGA *Making Content Usable*(보충지침, 성공기준 아님) 한 화면 한 작업·단계 최소·아이콘+텍스트·시간제한 제거·명료 언어 https://www.w3.org/TR/coga-usable/ (체크 https://www.w3.org/WAI/WCAG2/supplemental/#cognitiveaccessibilityguidance) · Apple HIG 명료성 https://developer.apple.com/design/human-interface-guidelines/ → MCI: 카드당 정보 1~2개, 아이콘 단독 금지.

**TTA**: TTAK.KO-08.0057(모바일 앱 콘텐츠 접근성 지침, 한국 정보통신단체표준) — WCAG/KWCAG 준용, 고령·정보취약 타깃. 원문 tta.or.kr 회원 열람이라 1차 URL 미확보(후속 확인 대상).

- 출처: 위 각 W3C/Apple/Material URL.

---

## Research State — Cycle 004 checkpoint (Cycle 007에서 완료됨)

**답변 완료(강):** Q1(calm-design 정본), Q2(M3/M3 Expressive 공식 정본 + 트랙 A URL 맵 + 고령 age-effect erasure 근거), Q3(Flutter 모션 트레이드오프, 앱이 이미 native 정합), Q4(트랙 B 벤치마크 6개 검증·비교 완료), **Q6/트랙C(고령·MCI 접근성·모션 안전성 8원칙축·출처별 숫자·URL 완비 — WCAG 2.2 AA/AAA·Apple HIG·Material·COGA)**.

**열린 하위질문:**
- **Q5 Flutter 아키텍처 + 성능(트랙 A 핵심 미확인)** — `docs.flutter.dev/app-architecture/guide`·`recommendations` + `perf/best-practices`·`perf/rendering-performance`·`perf/impeller`(16.67ms 프레임/build·repaint 최소화/shader 워밍업) 1차 정리 + 로컬 `lib/**` 대조. **다음 우선순위**. Superlist 의 super_sliver_list 를 리스트 성능 레버로 연결 가능.
- Q6 접근성과 모션의 양립 — `ui/accessibility/ui-design-and-styling` 1차 + 앱 `motion_settings.dart` MotionLevel 3신호 코드 검증(강근거 예상). Wonderous 의 '접근성 top of mind' 와 교차 인용 가능.
- Q7 이 앱 구체 권고 (cycle 007 executive summary 에서 확정).

**리드:** Q4 완료로 Q7 권고 판단 기준(따를 것/버릴 것) 확보. Q5·Q6 는 트랙 A 문서 1건씩 + 로컬 코드 대조로 강근거 가능.

**약한 곳/데드엔드:** 성능 수치는 '문서가 주장하는 바'로 한정(16.67ms=60fps 예산은 사실, 개선율 과장 회피). 병렬 워커 간 cycle 파일명 충돌 1회 발생·복구 완료 — 이후 워커는 쓰기 직전 findings/ 재확인 권장.

**다음 사이클 결정(잠정):** Q5 트랙 A — `perf/best-practices` + `perf/rendering-performance` + `app-architecture/recommendations` 1차 정리 후 `lib/**` 대조.



## Cycle 005 — 하위질문 5·6: Flutter 아키텍처·성능·모션 접근성 코드 검증 [strong]

Flutter 3.47 공식 아키텍처 권고는 UI/data layer, Repository, View/ViewModel, 단방향 데이터 흐름, DI를 강하게 권고한다. Provider/ChangeNotifier는 유효한 선택이고 go_router도 권고된다. 따라서 MemoryLink의 feature-first + Provider + go_router를 교체할 이유는 없다.

성능 공식 기준은 약 16ms/60Hz 프레임 예산이며, debug/emulator가 아니라 느린 실제 기기의 profile mode와 DevTools로 판단해야 한다. 큰 build를 변화 단위의 작은 위젯으로 나누고 setState를 국소화하며, saveLayer·넓은 opacity·animated clipping·불필요한 그림자를 측정 후 줄인다. Impeller는 iOS와 Android API 29+의 기본 렌더러지만 장면 구성 비용을 자동 해결하지 않는다.

프로젝트 대조:
- `main.dart`는 무거운 초기화를 첫 프레임 뒤로 미뤘고 실패를 앱 기동과 분리했다.
- `core/motion`의 4단 토큰, MotionLevel 3단, 단일 컨트롤러 stagger, 정적 skeleton, 차트/숫자 모션은 공식 원칙과 잘 맞는다.
- `home_screen.dart`는 여러 Provider 전체를 상단에서 watch하고 큰 화면 트리를 가진다. 섹션 위젯+Selector가 우선이다.
- `reports_screen.dart`는 DB, 로딩, 추이/임계 계산, chart 가공, UI가 한 State에 섞였다. Repository+ViewModel+UI 분리가 우선이다.
- `IndexedStack` 지연 생성은 콜드 스타트와 상태 보존의 trade-off라 실기기 측정 후 결정한다.

출처: https://docs.flutter.dev/app-architecture/recommendations · https://docs.flutter.dev/perf/best-practices · https://docs.flutter.dev/perf/ui-performance · https://docs.flutter.dev/perf/impeller · https://docs.flutter.dev/ui/adaptive-responsive/best-practices

## Cycle 006 — 하위질문 7: MemoryLink 맞춤 청사진 [strong]

단일 방향을 **Calm Expressive Lavender**로 확정했다. 라벤더·큰 타깃·예측 가능한 패턴은 유지하고 M3 Expressive의 color/shape/size/motion/containment를 핵심 행동 발견과 상태 이해에만 쓴다. 한 화면 큰 라벤더 면은 하나, category 색은 보조 기호, card는 hero/standard/data/interactive 역할별 variant로 구분한다.

모션은 press, screen entry, state, metric, navigation, achievement, chat/diary 일곱 순간으로 제한한다. 반복 장식은 금지하고 기존 full/fadeOnly/none을 모든 신규 모션에 적용한다. `flutter_animate`와 Lottie는 추가하지 않으며, Rive는 한 개 focal state가 사용자 테스트에서 가치를 보일 때만 검토한다.

로드맵:
- P0: 현재 화면 재캡처, AI chat empty state, report chart label/nav inset, 320dp·text scale 2.0, 시간 제한 정책.
- P1: MLCard variant, home section+Selector, reports Repository+ViewModel, 목적 기반 신규 모션 3개.
- P2: 저사양 profile 기준선, 측정 기반 lazy tab/RepaintBoundary, tablet shell, 다크 대비, 고령 사용자 형성평가.

상세: `findings/cycle_006.json`

## Cycle 007 — Executive summary [strong]

MemoryLink의 문제는 Flutter의 한계나 디자인 시스템 부재가 아니라 **성숙한 시스템의 화면 적용 편중과 일부 큰 화면의 책임 혼합**이다. 전면 재작성·상태관리 교체·애니메이션 패키지 대량 도입보다 현재 기반을 유지하며 시각 위계, 목적 기반 모션, UI/data 분리, 실기기 검증을 강화하는 것이 최선이다.

최종 산출물: [FINAL_REPORT.md](FINAL_REPORT.md)

### Research State — COMPLETE

Q1~Q7을 모두 완료했다. 근거는 Flutter 3.47 공식 애니메이션·성능·아키텍처·adaptive·접근성 문서, Google M3 Expressive 연구, W3C WCAG2Mobile/COGA, Flutter 공식 showcase와 로컬 코드·테스트·14개 캡처다.

주의: M3 Expressive의 최대 4배 탐색/45세+ 결과는 Google 연구가 보고한 UX 수치이며 임상 근거가 아니다. WCAG2Mobile은 Group Draft Note이고 규범 기준은 WCAG 2.2다. 루트 캡처는 현재 코드보다 오래되어 재캡처가 필요하다.
