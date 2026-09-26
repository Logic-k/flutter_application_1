# 07 — flutterfx_widgets 활용 모션·피드백 고도화 계획

- **기준일:** 2026-09-21
- **구분:** 별도 트랙 F(Stage 1~4와 독립). 06 힉스필드 계획의 **트랙 A(게임 피드백 기반)를 이 문서가 흡수·구체화**한다. 코드 변경은 Stage 1 CI 복구 이후 PR 단위로 병합
- **범위:** ① 눌림·정답·오답·완료 피드백, ② 결과·보상 축하, ③ 화면 진입·목록·진행 지표 모션, ④ AI 채팅 타이핑, ⑤ 선택 효과(회상 카드 긁기·스플래시 리빌)
- **원칙:** `DESIGN.md` §4 모션 규칙(4단 값·반복 금지·blur 진입 금지)이 상위 규범이다. flutterfx는 *복사해서 개조하는 소스 카탈로그*이지 의존성이 아니다

---

## 0. 한 줄 결론

flutterfx_widgets는 pub 패키지가 아니라 **70종 애니메이션 위젯의 복사-붙여넣기 카탈로그**다(문서가 "This is NOT a package"라고 명시). 70종 중 MemoryLink 규범을 통과하는 것은 **9종**이고, 그마저도 반복 재생·하드코딩 색·구식 문법 때문에 **전부 개조가 필요**하다. 감사 결과 앱에는 `AnimationController`가 0건이라 눌림·정답·오답·완료 피드백이 사실상 없고, 이것이 06 계획에서도 1순위로 지목됐으나 아직 미착수다. 따라서 순서는 **(1) 모션 토큰·축소 모션 게이트·눌림 프리미티브 → (2) `GameTemplate` 공통 피드백 → (3) 결과 시트 축하 → (4) 화면 진입·목록·진행 지표 → (5) AI 채팅 타이핑·선택 효과**이며, 의존성 추가 0건으로 약 9 작업일에 끝낸다. 충북 ICT 발표평가 데모 영상에는 (2)(3)이 가장 크게 보인다.

---

## 1. flutterfx_widgets 조사 결과 (2026-09-21 기준)

### 1.1 저장소 사실

| 항목 | 확인 내용 | MemoryLink 의미 |
|---|---|---|
| 형태 | GitHub `flutterfx/flutterfx_widgets`, 713★, 최종 push 2026-04-02. 앱 프로젝트 `fx_2_folder`(`publish_to: none`), `lib/` 아래 폴더 70개 = 위젯 1개 + 데모 1개 | `flutter pub add` 불가. 파일을 골라 `lib/core/fx/`로 복사 |
| 배포 | 문서(flutterfx.com/docs): "not a package… copy and paste". `packages/`에 4종 패키지화 시도 중 `flutterfx_blur_fade`·`flutterfx_scratch_to_reveal`만 pub.dev에 존재 | 패키지판도 쓰지 않는다. 개조가 전제라 소스 복사가 맞다 |
| SDK·의존성 | `sdk >=3.4.3`, `flutter_lints ^3`. 의존성: google_fonts, flutter_colorpicker, vector_math, sensors_plus, flutter_shaders, cached_network_image, url_launcher | 채택 9종은 **flutter만 의존**(confetti의 vector_math는 Flutter 전이 의존). 우리 pubspec 변경 0건 |
| 라이선스 | README·docs는 MIT라고 쓰지만 **저장소 루트에 LICENSE 파일이 없다**(`gh repo view` licenseInfo=null). `packages/flutterfx_blur_fade/LICENSE`에는 "MIT License, Copyright (c) 2024 FlutterFX"가 있다 | 복사본마다 파일 헤더에 출처 URL·커밋·MIT 표기, `THIRD_PARTY_NOTICES.md`에 등록(§3). 공모전 제출물 소스 zip에도 동봉 |
| 코드 품질 | 데모 품질. `Key? key` 구식 생성자, `withOpacity`(deprecated), 데모 전용 크로스 import(`package:fx_2_folder/stacked-cards/…`), 검정 배경·보라 그라데이션 하드코딩, `repeat()` 무한 루프(ShimmerButton 3s, CoolMode 1s), 매 프레임 `setState`(CoolMode), `Future.delayed` 스태거 | 우리 저장소는 `flutter_lints ^6`·analyze info 4 유지가 게이트다. **그대로 붙이면 즉시 lint·규범 위반** → §3 복사 규약 필수 |
| 접근성 | 70종 중 `MediaQuery.disableAnimations`·`reduceMotion`을 검사하는 위젯 **0건**. `AnimationController` 기반은 Flutter가 자동 단축하지만, Timer 기반(typing)·CustomPainter 루프(celebrate)·`Future.delayed` 스태거는 **자동 적용되지 않는다** | 축소 모션 게이트를 우리 쪽 공통 래퍼에서 건다(F-01) |

### 1.2 70종 분류와 채택 판정

**채택 9종(개조 후 사용):**

| 원본 폴더 | 원본 동작 | MemoryLink 용도 | 개조 요점 |
|---|---|---|---|
| `celebrate/` (`CoolMode`) | 누르는 동안 파티클이 계속 솟음, 1s `repeat()` + 매 프레임 setState | **정답 순간 1회 버스트**(≤600ms) | 누름 지속 → `burst()` 1회로 변경, `Listenable` 기반 painter, `RepaintBoundary`, 색은 colorScheme 2톤 |
| `confetti/` (`EnhancedConfetti…`) | 물리 기반 컨페티, 7가지 입자 모양, 옵션 클래스 | **훈련 완료·스트릭 갱신·해금** 축하(≤2.5s, 1회) | 입자 ≤60, 모양 2종(circle·rectangle), 색 3색 이내, 2.5s 후 자동 정지·dispose |
| `progress-bar/` (`ProgressLoader` + 전략 패턴) | 값 변경 시 이전→새 값 보간 | `MLProgressBar`·`MLRing`·게임 상단 진행 바의 **값 변화 200ms** | 전략 인터페이스는 버리고 `_ProgressLoaderState.didUpdateWidget` 보간 로직만 이식 |
| `visibility/` (`BlurFade`) | opacity + blur 10→0, delay 스태거 | **화면 진입 FadeSlideIn**(200ms, 카드 간 40ms) | **blur 제거**(DESIGN §4 금지), 8px 상향 슬라이드로 대체, delay는 `TickerMode` 존중 |
| `notification-list/` (`AnimatedNotificationCard`, `ImplicitlyAnimatedWidget`) | 목록 항목이 순차 삽입 | 훈련 기록 타임라인·알림·CS 목록 **스태거 진입** | 1,000ms 지연 → 40ms, 최초 1회만(스크롤 복귀 시 재생 금지) |
| `expandable-widget/` (`Disclosure`) | 200ms 펼침/접힘, InheritedWidget 상태 | 리포트 상세·FAQ·설정 하위 항목 접기 | 크로스 import 제거, 이미 200ms라 토큰만 치환 |
| `fx_11_typing_animation/` (`TypingAnimation`) | Timer로 글자 단위 표시 | **AI 채팅 응답 타이핑**(30ms/자) | 축소 모션 시 즉시 표시, 화면 읽기 시 완료 후 live region 1회 |
| `tools/curves.dart` (`SpringOutCurve`) | 오버슈트 조절 가능한 스프링 커브 | **눌림 복귀 곡선**·해금 노드 scale-in | `maxOvershoot` 0.2 → 0.05(고령 사용자 흔들림 최소화) |
| `scratch-to-reveal/` (`ScratchToReveal`) | 긁어서 드러내기, 햅틱 옵션 내장 | (선택) 일기 **"오늘의 회상 카드"**, 주간 보상 카드 | `enableHapticFeedback`를 `SettingsProvider.hapticFeedbackEnabled`에 연결, 대체 경로(탭으로 열기) 필수 |

**제외 61종과 이유(대표):**

- **장식·자동재생 모션**(`background-*` 8종, `orbit*`, `particles*`, `dots`, `grid-*`, `light_effect`, `decoration-*`, `butterfly*`, `tree`): DESIGN §4 "자동 재생·반복 금지", KWCAG 3초 규칙 위반. 로딩 자리엔 스켈레톤 규범이 있다.
- **AI 생성물 지문**(`fx_7_border_beam`, `fx_8_meteor_border`, `fx_9_neon_card`, `button-shimmer`, `background-aurora`, `gemini-splash`): 다크 배경·보라 그라데이션 전제. DESIGN §5 위반. `button-shimmer`는 3초 후 정지로 개조 가능하나 CTA에 필요한 건 눌림 반응이지 반짝임이 아니다.
- **쉐이더 계열**(`shader-learning`, `motion-blur`, `smoke`, `noise`, `fractal-glass`, `frosty_card`): FragmentShader는 3.41에서 개선됐지만 Android API 29 미만은 Impeller 대신 OpenGL 폴백이라 **이중 경로 검증 비용**이 크고, 고령 사용자 기기가 구형일 확률이 높다.
- **가독성 훼손 텍스트 효과**(`fx_10_hyper_text`, `fx_12/13_rotating_text*`, `fx_14_text_chaotic_spring`, `text-3d-pop`(센서 기반), `text-morph`, `text-on-path`, `text-shine`, `thanos-snap`): 글자가 움직이면 65+ 사용자 읽기가 늦어진다(DESIGN §4 "blur 진입은 읽기를 늦춘다"와 같은 이유).
- **데모 성격·무거움**(`globe`, `vinyl`, `book-open`, `books`, `page-flip`, `folder_shape`, `stacked-*`, `infinite-scrolling`, `ticker`, `circles_selector`, `slider`, `toolbar-search`, `avatar-circles`(사진 URL 전제), `bottom-sheet`(표준 `showModalBottomSheet` 이미 사용), `loader-*`, `splash-door-open`, `debug-overlay-3D`(개발 도구)).
- **보류 1종**: `splash-reveal`(`CircularRevealClipper`) — 스플래시→홈 300ms 원형 리빌. 규범엔 맞으나 콜드스타트 7.3s 개선이 먼저다(F-07 선택).

### 1.3 외부 리서치 요약 (근거 등급은 05 등록부 규약)

| 주제 | 확인 내용 | 적용 |
|---|---|---|
| Flutter 3.41 (공식 권장) | 저장소는 3.41.5. `FragmentShader` 동기 이미지 디코딩·고비트 텍스처 추가. Impeller는 Android API 29+ 기본, 미만은 GL 폴백 | 쉐이더 효과 제외 근거. 나머지 채택 위젯은 Canvas·Transform만 써서 폴백 경로에서도 동일 |
| 축소 모션 (공식 의무) | `MediaQueryData.disableAnimations`는 Android "애니메이션 제거"에 대응하고 `AnimationController` 지속시간을 엔진이 자동 단축. **iOS reduceMotion은 별도 플래그**(`AccessibilityFeatures.reduceMotion`)라 이 값에 반영되지 않는다. Timer·수동 루프는 개발자가 직접 검사해야 한다 | F-01 `MotionSettings`가 세 신호(disableAnimations ∨ reduceMotion ∨ 앱 설정)를 합쳐 한 곳에서 판정 |
| WCAG 2.3.3·KWCAG 2.2 (공식 의무) | 상호작용 유발 모션은 끌 수 있어야 하고, 자동 재생 소리는 3초 내 정지, 깜빡임 3Hz 초과 금지 | 앱 설정에 "움직임 줄이기"·"효과음" 토글 신설. 축하 효과 ≤2.5s, 효과음 ≤300ms |
| 고령자 멀티모달 피드백 (연구 결과) | Lee & Spence 2009(HAID): 시각+청각(+촉각) 피드백이 고령자 이중과제 수행·주관 만족을 높임. Hwangbo 외 2013(IJHCI): 고령자 포인팅 성능이 **오디오+촉각 조건에서 최고**, 타깃 크기·간격 영향 큼 | 눌림 피드백을 **scale 0.98 + 햅틱 + 짧은 효과음 3겹**으로 설계. 색만으로 정답/오답을 주지 않는다(DESIGN §5) |
| 고령자 앱 설계 체계적 문헌고찰 (연구 결과) | Amouzadeh 외 2025(132편): 단순 내비게이션·큰 글자와 타깃·오류 관용·음성이 핵심. 인지 과부하가 최대 장벽 | 모션은 상태 변화를 알릴 때만(DESIGN `MOTION_INTENSITY 2`). 화면 진입 스태거 총합 400ms 상한 |
| NN/g 고령자 사용성 (전문가 권고) | "startling sounds"·작은 타깃·읽기 어려운 오류 메시지가 주요 불만 | 효과음은 낮은 음량·짧게, 오답음은 경고음이 아닌 낮은 톤 |
| 디지털 인지훈련 참여도 (연구 결과) | SCOT RCT 2024(n=60): 효과는 훈련 중 **참여도·성과가 높은 집단**에서만 유의. Brill 외 2024 BJPsych Open(n=160): 3개월 CCT 인지 효과 없음, 장기 훈련에서 주관적 개선, 주 4.87회 adherence는 게임 재미·즉시 피드백·사회적 요소가 유지 | 피드백 도입은 "예쁘게"가 아니라 **완주율·주간 활성일 유지 수단**. F-08에서 전후 비교 지표를 남긴다. 효과 주장은 하지 않는다(README 제품 경계) |
| 보상 화면 사례 (실무 사례) | Lumosity 변동 보상 리디자인: 사용자가 가장 자랑스러워한 것은 **스트릭과 최고 점수**, 주간 3일·월간 10/20일 마일스톤 추가 후 A/B에서 참여·유지 소폭 상승 | 컨페티는 매번이 아니라 **스트릭 갱신·최고점·주간 목표 달성**에만(변동 보상). 일반 완료는 별 점등·XP 카운트업까지 |
| 대안 패키지 (프로젝트 판단) | `motor`(스프링·M3 모션 토큰 통합 API), `material_3_expressive`(M3E 컴포넌트, `material_ui`·`motor`·`dynamic_color` 의존), `flutter_animate`(체이닝 편의) | 지금은 **의존성 0 추가**로 간다. `motor`는 Stage 3 이후 스프링 통일 시 재검토(§6) |
| 국내 경쟁 (시장 사실) | 기억산책(서울·충북 광역치매센터 납품, 기관용), 전국두뇌자랑(지자체 납품, 전용 컨트롤러) — 둘 다 B2G | 개인·보호자·보행을 묶은 B2C는 비어 있다. "기관 앱보다 반응이 살아 있다"가 체감 차별점 |

---

## 2. 현재 기준선 (2026-09-21 감사)

| 영역 | 확인된 사실 | 계획상 의미 |
|---|---|---|
| 명시 애니메이션 | `lib/`에 `AnimationController` **0건**, `flutter_animate`·`lottie` 없음. 암묵 애니메이션은 `FloatingPillNav`의 `AnimatedContainer` 200ms 1곳 | 06 트랙 A 미착수 상태 그대로. 이 문서가 트랙 A를 대체한다 |
| 눌림 피드백 | `MLCard`는 `InkWell` 리플만. `scale(0.98)`(DESIGN §4 필수)은 어디에도 없음 | F-01 `PressableScale` 1개로 `MLCard`·`MLGameCard`·온보딩 목표 카드·`FilledButton` 테마를 한 번에 |
| 게임 피드백 | 햅틱 2/7종(categorization·shape_sudoku). comparison·multiplication은 정답/오답 시각 표시 없음(`comparison_game.dart:36` 주석이 이를 인정). 효과음 0 | `GameTemplate`에 공통 피드백 계층을 넣고 7종이 콜백만 호출 |
| 결과 시트 | `training_result_sheet.dart`: 아이콘 5줄 정적 나열, `Icons.celebration_rounded` 36px | F-03 자리 확정 |
| 진행 지표 | `MLProgressBar`·`MLRing`·게임 상단 바 모두 `AlwaysStoppedAnimation` → 값이 점프 | F-05 |
| 설정 | `hapticFeedbackEnabled`·`voiceGuidanceEnabled` 있음. **움직임 줄이기·효과음 설정 없음** | F-01에서 두 항목 추가 |
| 테스트 | `test/` 정의 284개(정본 실측은 307 통과). `test/widget/training/game_template_test.dart`가 mocktail·MultiProvider 패턴으로 존재 | 새 위젯 테스트는 이 파일 패턴을 따른다 |
| 공모전 | 충북 ICT 서면평가 통과 시 발표평가 대기, 한이음·TTA 제출 완료 | 발표 데모 영상에 F-02·F-03이 즉시 보인다 |
| 06 계획과 관계 | 06 §3 트랙 A(A-01 공통 피드백 레이어)와 겹침 | **06 A-01은 이 문서 F-02로 이관**. 06의 힉스필드 일러스트(트랙 B)는 F-03 이후 착수 |

---

## 3. 복사 규약 (모든 PR의 공통 완료 조건)

1. **위치:** 토큰·게이트·프리미티브는 `lib/core/motion/`, flutterfx 개조본은 `lib/core/fx/`. 파일 헤더 템플릿:
   ```dart
   // Adapted from flutterfx/flutterfx_widgets (lib/celebrate/celebrate.dart, commit <sha>)
   // Copyright (c) 2024 FlutterFX — MIT License. Modified for MemoryLink: <한 줄 요약>
   ```
   저장소 루트에 `THIRD_PARTY_NOTICES.md`를 신설해 원본 경로·커밋·변경 요약을 표로 관리한다. 공모전 소스 zip에 포함한다.
2. **문법:** `super.key`, `withValues(alpha:)`, 색은 전부 `context.scheme`·`AppTheme` 토큰. 데모 파일(`*_demo.dart`)은 복사하지 않는다.
3. **모션 값:** `AppMotion.press(100)`·`fade(150)`·`enter(200)`·`route(300)` 네 토큰만. 원본의 1,000ms·3s 값은 전부 치환.
4. **축소 모션:** 모든 진입점이 `MotionSettings.of(context).reduce`를 읽어 `true`면 **최종 상태를 즉시 그린다**(지속시간 0이 아니라 애니메이션 자체를 건너뜀). Timer·`Future.delayed` 기반은 이 검사 없이는 병합 금지.
5. **반복 금지:** `repeat()` 호출 금지. 모든 효과는 1회성이며 상한 2.5s. 완료 후 컨트롤러 `dispose`.
6. **성능:** 파티클·컨페티는 `CustomPainter` + `Listenable` 재도색(매 프레임 `setState` 금지), `RepaintBoundary`로 격리, 입자 ≤60.
7. **테스트:** 개조 파일당 위젯 테스트 1개 — (a) 축소 모션 시 첫 프레임에 최종 상태, (b) 정상 모드에서 토큰 시간 경과 후 최종 상태, (c) `pumpAndSettle` 통과(= 무한 애니메이션 없음의 증명). 텍스트 배율 2.0에서 오버플로 없음.
8. **접근성:** 시각 효과는 `ExcludeSemantics`, 상태는 텍스트 live region으로 따로 전달(기존 comparison 게임의 `_lastAnswerFeedback` 패턴 유지).

---

## 4. 트랙 F 작업 패킷

### F-00 라이선스·출처 규약
- **구분/기간:** 필수 · 0.5일 · **완료 2026-09-21**(미커밋 작업 트리)
- **작업:** `THIRD_PARTY_NOTICES.md` 신설, 헤더 템플릿 확정, `documentation_consistency_test.dart`에 "lib/core/fx/ 파일은 헤더에 MIT 표기 필수" 검사 추가. (선택) 업스트림에 루트 LICENSE 파일 추가 요청 이슈.
- **완료 조건:** 테스트가 헤더 없는 fx 파일을 실패시킴.

### F-01 모션 기반 — 토큰·게이트·눌림 프리미티브
- **구분/기간:** 필수 · 1일 · **완료 2026-09-21**(미커밋 작업 트리). 실측: analyze info 4 유지, 테스트 334/334. 이탈: `FilledButton` 테마는 `ButtonStyle`에 scale 속성이 없어 M3 pressed 오버레이만 유지하고 `PressableScale` 미적용. 효과음 에셋은 미준비라 `SystemSound.click` 폴백 상태
- **근거:** DESIGN §4 "눌림 피드백 필수"가 미구현. 고령자 멀티모달 피드백 연구(§1.3). iOS reduceMotion이 `disableAnimations`에 반영되지 않는 공식 문서.
- **작업:**
  1. `lib/core/motion/app_motion.dart`: 4단 Duration 토큰, `SpringOutCurve` 개조본(`maxOvershoot 0.05`).
  2. `lib/core/motion/motion_settings.dart`: `reduce = MediaQuery.disableAnimationsOf(ctx) || WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion || settings.reduceMotion`.
  3. `SettingsProvider`에 `reduceMotion`·`soundEffectsEnabled` 추가 + 설정 화면 토글 2개(기존 햅틱 토글 옆).
  4. `lib/core/motion/pressable_scale.dart`: `Listener`+`AnimatedScale`(100ms, 0.98) 래퍼. `MLCard(onTap)`·`MLGameCard`·온보딩 목표 카드·`FloatingPillNav` 항목에 적용. `FilledButton` 테마는 `WidgetStateProperty`로 pressed 시 scale 동일값.
  5. `lib/core/services/sound_service.dart`: 정답·오답·완료 3종 SFX 재생(에셋은 06 §1.2 `seed_audio` 파이프라인으로 생성, 각 ≤300ms, 음량 0.5). 에셋 준비 전엔 `SystemSound.play(SystemSoundType.click)` 폴백.
- **완료 조건:** 위젯 테스트 4개(토큰 값, 게이트 3신호 OR, PressableScale 눌림/복귀, 설정 저장). Maestro `settings` 플로우에 토글 2개 확인 스텝 추가.

### F-02 `GameTemplate` 공통 피드백 계층 (06 A-01 이관)
- **구분/기간:** 필수 · 2일 · **완료 2026-09-24**(미커밋 작업 트리). 이탈: 파티클은 flutterfx `celebrate` 복사가 아니라 자체 구현(`lib/core/motion/burst_particles.dart`, 헤더 불필요). 배지 표시 시간은 실기 확인 뒤 900ms → **1.7초**(고령 사용자 읽기 시간, 배지는 터치를 막지 않음). 게임 7종 모두 `GameFeedbackController` 경유, 오답 배지에 정답 병기. Maestro `training_game_flow`에 배지 확인 단계 추가
- **근거:** 7종 게임이 각자 피드백을 구현하고 있어 2종은 시각 표시가 없다. 고령 사용자는 눌렸는지 몰라 두 번 누른다(DESIGN §4). 정답/오답을 색만으로 주지 않는다(§5).
- **작업:**
  1. `GameFeedbackController`(ChangeNotifier): `correct()`, `wrong()`, `complete()`. `GameTemplate`이 `Provider`로 자식에 노출. 각 게임의 `_checkAnswer`는 `context.read<GameFeedbackController>().correct()` 한 줄로 교체(햅틱·SFX·시각 효과가 한 곳에서 처리).
  2. 정답: `lib/core/fx/burst_particles.dart`(celebrate 개조) 600ms 1회 + 초록 체크 오버레이(아이콘+"정답입니다" 텍스트, 150ms 페이드) + `mediumImpact` + 정답음.
  3. 오답: `ShakeX` 150ms(±4px 2회, 원본 curves 응용) + 빨강 X 오버레이("다시 볼까요?") + `heavyImpact` + 낮은 오답음. 흔들림은 축소 모션 시 생략, 오버레이 텍스트는 유지.
  4. 상단 진행 바 값 변화 200ms(progress-bar 개조 보간).
  5. comparison·multiplication에 시각 피드백 연결(기존 live region 텍스트는 유지).
  6. 카테고리·스도쿠의 개별 햅틱 코드 제거(중복 진동 방지).
- **완료 조건:** `game_template_test.dart` 확장(정답·오답·축소 모션 3케이스), 7종 게임 테스트 통과, Maestro 훈련 플로우에서 정답 오버레이 텍스트 `assertVisible`. 에뮬레이터 훈련 1회 완주 시 16ms 초과 프레임 <1%(DevTools timeline 캡처 첨부).

### F-03 완료·보상 축하
- **구분/기간:** 필수 · 1.5일 · **완료 2026-09-24**(결과 시트·완료 서비스). 이탈: 컨페티 색은 권장안(primary·primaryContainer·onPrimary)이 흰 시트에서 안 보여 **primary·앰버·민트**로. 축하 이유를 글로 주는 칩("최고 기록을 넘었어요" 등) 추가. 3·4번(코스맵 해금 scale-in, 홈 스트릭 펄스)은 미착수
- **근거:** 참여도가 효과를 좌우한다는 RCT 2건, 스트릭·최고점이 가장 자랑스러운 순간이라는 Lumosity 사례(§1.3). 변동 보상 원칙.
- **작업:**
  1. `lib/core/fx/celebration_burst.dart`(confetti 개조): 입자 ≤60, 원형·사각형 2종, 색 3색(primary·primaryContainer·onPrimary), 2.5s 후 자동 정지. `RepaintBoundary`.
  2. `TrainingResultSheet`: 열릴 때 별 3개 순차 점등(150ms 간격, 총 450ms), XP `TweenAnimationBuilder` 300ms 카운트업, 컨페티는 **`isStreakExtended || isNewBest || isDailyGoalJustMet`일 때만**. 시트 파라미터에 이 3개 bool 추가(`TrainingCompletionResult`에서 산출).
  3. 코스맵 해금 노드: `CourseNode`에 `justUnlocked` → 200ms scale-in(SpringOutCurve 개조).
  4. 홈 스트릭 배지: 값이 늘어난 첫 표시에서 1회 펄스(150ms).
- **완료 조건:** 결과 시트 테스트(컨페티 조건 3종·일반 완료 시 미표시·축소 모션 시 즉시 최종 상태), `pumpAndSettle` 통과. 발표 데모 영상용 30초 캡처 1편.

### F-04 화면 진입·목록 스태거
- **구분/기간:** 권장 · 1.5일 · **부분 완료 2026-09-24**: 1번(홈 6개 구역 `FadeSlideIn`, 자체 구현)만. 2·3번(목록 스태거·Disclosure) 미착수. 추가: 릴스 참고 **허브 코스 노드 → 게임 목표 카드 `Hero` 아이콘 전환**
- **작업:**
  1. `lib/core/fx/fade_slide_in.dart`(BlurFade 개조, blur 제거, 8px 상향): 홈 카드 4장 40ms 간격(총 <400ms), 최초 진입 1회만(`PageStorage` 키로 재생 여부 기억).
  2. `lib/core/fx/staggered_list_item.dart`(AnimatedNotificationCard 개조): 훈련 기록 타임라인·알림·CS 문의 목록. 화면당 최초 12개까지만 스태거, 이후는 즉시.
  3. `lib/core/fx/disclosure.dart`: 리포트 상세 섹션·FAQ 답변 접기(현재 `ExpansionTile` 사용처만 교체, 동작 동일).
- **완료 조건:** 각 위젯 테스트 1개, 홈 골든 아님(스냅샷 불안정 회피) — 대신 스태거 종료 후 `find.byType` 개수 검증.

### F-05 진행 지표 애니메이션
- **구분/기간:** 권장 · 1일 · **완료 2026-09-24**(`MLProgressBar`·`MLRing`·게임 상단 바)
- **작업:** `MLProgressBar`·`MLRing`에 progress-bar 개조 보간(200ms) 적용. 생활습관 지표 카드·오늘 목표 패널·훈련 헤더가 자동 수혜. 첫 빌드는 애니메이션 없이 즉시(스켈레톤 → 값 전환 시 0에서 차오르는 연출 금지: 값 없음과 0을 구분하는 DESIGN §6.4).
- **완료 조건:** `training_progress_widgets_test.dart` 확장.

### F-06 AI 채팅 타이핑
- **구분/기간:** 권장 · 0.5일
- **작업:** `lib/core/fx/typing_text.dart`(TypingAnimation 개조): 스트리밍 청크가 도착할 때마다 30ms/자로 따라잡기, 축소 모션·화면 읽기 활성 시 즉시 표시, 완료 시 `SemanticsService.announce` 1회. 기존 `ai_chat` 응답 버블에만 적용.
- **완료 조건:** 테스트 2개(정상·축소), 답변이 길 때(500자) 15초 내 완료 보장(글자당 시간을 길이에 반비례로 조정).

### F-07 선택 효과
- **구분:** 향후 · 각 0.5일
- **후보:** (a) `ScratchToReveal` "오늘의 회상 카드"(일기 탭, 탭으로 여는 대체 경로 필수), (b) `CircularRevealClipper` 스플래시→홈 300ms(콜드스타트 개선 뒤), (c) 온보딩 목표 카드 선택 시 체크 아이콘 scale-in.
- **착수 조건:** F-01~F-05 병합 후, 사용자 결정 §7-3.

### F-08 검증·게이트 (모든 PR 공통 + 트랙 종료 시)
- `flutter analyze` info ≤4(현재 4), 단위·위젯 테스트 전부 통과, Maestro 게이팅 20 유지.
- 에뮬레이터(`-gpu angle_indirect`, 05 계획 재현 명령)에서 훈련 1회 완주 프레임 통계 첨부.
- Android "애니메이션 제거" ON 상태로 Maestro 훈련 플로우 1회 통과(축소 모션 경로 검증).
- 텍스트 배율 2.0 스크린샷 3장(게임·결과 시트·홈).
- 실기기 1대: API 28 이하(GL 폴백) 또는 저사양 기기에서 결과 시트 컨페티 육안 확인.
- **전후 비교 지표(선택이지만 권장):** 로컬 DB에 이미 있는 훈련 세션 완주율·주간 활성일을 F-02 병합 전 4주/후 4주로 비교해 `05_RESEARCH_EVIDENCE_REGISTER.md`에 기록. 효과 주장에는 쓰지 않는다.

---

## 5. 순서·일정·다른 계획과의 관계

| 순서 | 패킷 | 기간 | 선행 | 비고 |
|---|---|---|---|---|
| 1 | F-00 + F-01 | 1.5일 | Stage 1 CI 복구 | 한 PR |
| 2 | F-02 | 2일 | F-01 | 06 A-01 대체. **발표 데모 1순위** |
| 3 | F-03 | 1.5일 | F-02 | 발표 데모 2순위 |
| 4 | F-04 + F-05 | 2.5일 | F-01 | 병렬 가능 |
| 5 | F-06 | 0.5일 | F-01 | |
| 6 | F-07 | 선택 | F-05 | |
| — | F-08 | 각 PR | | |

- 총 **약 9 작업일**(F-07 제외). 06 계획의 힉스필드 일러스트·SFX 자산(트랙 B)은 F-03 이후에 착수하고, F-01의 SFX 3종이 트랙 B의 첫 자산이 된다.
- 03 Stage 3(제품 가치)의 "주간 빈도 스트릭" 결정(리디자인 딥리서치 결론)과 F-03의 컨페티 조건이 연동된다. 스트릭 정의가 바뀌면 `isStreakExtended` 산출만 바꾸면 된다.

---

## 6. flutterfx 밖의 발전 후보 (리서치 결과, 우선순위 순)

1. **효과음·움직임 줄이기 설정** — F-01에 포함. 근거: KWCAG·WCAG 2.3.3, NN/g.
2. **변동 보상 체계 재설계** — 주간 3일·월간 10일 마일스톤을 `TrainingCompletionResult`에 추가. 03 Stage 3에 편입 제안. 근거: Lumosity 사례, RCT의 참여도 변수.
3. **`motor` 패키지로 스프링 통일** — Stage 3 이후. 의존성 1개 추가로 `MaterialSpringMotion` 토큰을 얻고 `SpringOutCurve` 개조본을 폐기할 수 있다. 지금 넣지 않는 이유: 트랙 F 범위에 스프링이 2곳뿐.
4. **Material 3 Expressive** — `material_3_expressive`는 `material_ui`·`motor`·`dynamic_color`까지 끌고 와 테마 전면 교체가 된다. 보류. 대신 M3E의 "눌림 스프링·상태 레이어" 개념만 `PressableScale`에 반영.
5. **참여도 지표 계측** — F-08 전후 비교. 이후 Firebase Analytics 이벤트로 승격은 02 Stage 2(관측성)에서.
6. **골든 테스트** — 모션 종료 프레임 스냅샷. 현재는 `pumpAndSettle`+상태 검증으로 충분. 힉스필드 일러스트 도입 뒤 재검토.
7. **Fragment shader 효과** — 제외 유지. 재검토 조건: 사용자 기기 분포에서 API 29+ 비율이 확인되고, 저사양 기기 프레임 측정 체계가 생겼을 때.

---

## 7. 사용자 결정이 필요한 것

1. **효과음 기본값** — 권장: 기본 ON, 첫 훈련 시작 시 "소리가 납니다. 설정에서 끌 수 있어요" 1회 안내, 음량 0.5. 대안: 기본 OFF(무음 기기 사용자 배려).
2. **컨페티 색** — DESIGN §5 "강조색 하나" 원칙과 다색 컨페티가 충돌. 권장: primary·primaryContainer·onPrimary 3색 이내.
3. **F-07 선택 효과 착수 여부** — 회상 카드 긁기는 일기 기능 방향(Stage 3)과 맞물린다. F-05 이후 결정.
4. **업스트림 LICENSE 부재 대응** — 권장: 헤더+NOTICES로 진행하고 메인테이너에게 LICENSE 파일 추가 이슈를 올려 답을 기록. 답이 오기 전에도 `packages/` 하위 MIT 문구가 저작자 의사를 보여주므로 진행 가능하다고 판단.

---

## 8. 참고 자료

- 저장소·문서: https://github.com/flutterfx/flutterfx_widgets · https://www.flutterfx.com/docs · `packages/flutterfx_blur_fade/LICENSE`(MIT, 2024 FlutterFX)
- Flutter 공식: What's new in Flutter 3.41 (2026-02) · `MediaQueryData.disableAnimations` API 문서 · Impeller 렌더링 엔진 문서(Android API 29+ 기본) · `RepaintBoundary`·`pumpAndSettle` API 문서
- 접근성: KWCAG 2.2(자동 재생·정지 수단) · WCAG 2.1 SC 2.3.3 Animation from Interactions · VGV Flutter accessibility skill(`disableAnimations` 게이트 체크리스트)
- 고령자 연구: Amouzadeh 외 2025, "Optimizing mobile app design for older adults", 체계적 문헌고찰(PMC12350549) · Lee & Spence 2009, HAID, 터치스크린 멀티모달 피드백과 고령자 수행 · Hwangbo 외 2013, IJHCI, 고령자 스마트폰 포인팅 성능(오디오+촉각) · NN/g "Usability for Older Adults: Challenges and Changes"(2019)
- 인지훈련 참여도: Funghi 외 2024, SCOT RCT, Arch Gerontol Geriatr(doi:10.1016/j.archger.2024.105405) · Brill 외 2024, BJPsych Open(doi:10.1192/bjo.2024.797) · GAHOCON 파일럿 RCT 2024, JMIR Rehabil Assist Technol(doi:10.2196/60155)
- 사례·패키지: Lumosity 보상 화면 리디자인 사례(roxannecook.com/rewards) · pub.dev `motor` · pub.dev `material_3_expressive` · pub.dev `flutter_animate`
- 국내 시장: 기억산책(memorywalk.kr) · 전국두뇌자랑(thinkgoodbrain.com)
