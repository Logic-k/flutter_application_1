# 리서치 브리프 — 클로드 디자인 + Flutter 로 세련되고 모션 풍부한 앱 만들기

## 질문 (Question)
현재 MemoryLink 앱은 Claude Design 으로 설계했고 라벤더(#6C5CE7) "라벤더 캄" 톤이다.
클로드 디자인 + Flutter 로 **세련되고, 깔끔하고, 모션이 풍부한** UI 를 만드는 방법을,
Flutter 로 잘 만든 실제 앱들과 비교해서 정리한다. 어떤 디자인 방향이 좋은지,
그리고 Flutter 를 **어떻게 설계**해야 좋은 앱이 되는지 근거 기반으로 리서치한다.

## 프로젝트 현재 상태 (grounding)
- 테마: Material 3 + `ColorScheme.fromSeed(seedColor=#6C5CE7)`, Pretendard, 라이트 기본/다크 지원
- 모션: 자체 시스템 `lib/core/motion/` (fade_slide_in, staggered_column, motion_settings)
  — WCAG 2.3.3 / iOS reduce-motion / Android disable-animations 3신호 존중, MotionLevel(full/fadeOnly/none)
- 애니메이션 패키지: **없음** (flutter_animate / lottie / rive 미도입). 순수 AnimationController + implicit widgets.
- 접근성: TTAK.KO-08.0057 준용 — 고령·정보취약계층 타깃, minTapTarget 56dp, WCAG AA 대비 강제(테스트로 회귀 차단)
- 상태관리: provider. 라우팅: go_router. 차트: fl_chart.

## 하위 질문 (AUTHORITATIVE checklist)
1. **클로드 디자인 원칙 정본**: "Claude Design" / calm-design 스킬이 규정하는 실제 원칙
   (calm·dense·utilitarian, AI-tells 회피, 타이포/컬러/모션 시스템)은 무엇인가? 로컬 스킬 파일이 정본.
2. **2026 Flutter 디자인 트렌드/모범**: Material 3 expressive, 글래스/뉴모피즘 여부, 컬러·타이포·간격 시스템의 현재 모범.
3. **Flutter 모션을 "풍부하되 세련되게" 하는 법**: implicit(AnimatedX) vs explicit(AnimationController) vs 패키지
   (flutter_animate / rive / lottie / Hero / shared-axis) 의 각 용처와 성능·유지보수 트레이드오프.
4. **잘 만든 Flutter 앱 벤치마크**: 실제로 세련된 Flutter 앱 사례와 그들이 쓴 기법 (레퍼런스/오픈소스).
5. **Flutter 아키텍처 설계**: 좋은 앱을 만드는 프로젝트 구조·상태관리·성능(리빌드 최소화, 60/120fps) 원칙.
6. **접근성과 모션의 양립**: 고령 타깃 + 화려한 모션의 충돌을 어떻게 푸는가 (reduce-motion, 의미 있는 모션).
7. **이 앱에 대한 구체 권고**: 위를 종합해 MemoryLink 에 실제로 적용할 디자인 방향 + Flutter 설계 개선안.

## 허용 소스
- 로컬 스킬: `C:\Users\kimmi\.kiro\crew\skills\imported\claude_code\calm-design\**`
- 로컬 코드베이스: `E:\Test_Android\flutter_application_1\lib\**`
- 공개 웹: docs.flutter.dev, m3.material.io, pub.dev, 신뢰할 만한 기술 블로그
- 사용자 Knowledge Library

## Questions 지시
자율 진행. scope 를 근본적으로 바꿀 진짜 모호함이 있을 때만 questions.json 으로 1개 질문. 아니면 가정 기록 후 진행.

## max_cycles
8 (cycle 000 ~ 007; 007 은 executive summary)
