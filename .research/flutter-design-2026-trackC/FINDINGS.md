# FINDINGS — flutter-design-2026-trackC (트랙 C 재검증)

2026-09 현재 Flutter/M3 Expressive/Android/Apple HIG/W3C **공식 문서 1차 우선**으로
flutter-design-2026 결과를 재검증하고, 44개 GoRouter 경로 + 비라우트 UI의
**비회귀 검증 계약** + 전 화면 디자인·모션 실행 계획을 만든다.
max_cycles=8 (000~007, 007=executive summary + 비회귀 계약). **코드 변경 없음.**

기준 grounding: `lib/core/router.dart` 에 top-level GoRoute path 36+ (게임 하위 포함 ~44),
prior 캠페인 결론 = "Calm Expressive Lavender" 점진 개선(전면 재디자인/상태관리 교체 아님).

---

## Cycle 000 — C1: 공식 문서 정본 맵 + 문서 상태 분류 [strong]

**핵심**: 재검증의 축은 문서를 규범/가이드/연구주장으로 라벨링하는 것.

- **규범(normative)**: WCAG 2.2 원문(2.3.3 Animation from Interactions AAA, 2.5.5/2.5.8 Target Size,
  1.4.3/1.4.11 대비, 2.2.x 시간조절), Apple HIG(App Store 심사 결합).
- **가이드(guide, official이나 비규범)**: docs.flutter.dev 전체, m3.material.io + M3 Expressive,
  developer.android.com Material3, **W3C COGA 'Making Content Usable' = Working Group Note(2021-04-29)**.
- **연구주장(research-claim)**: design.google Expressive Material Design 연구
  ('최대 4배 빠른 인지', '45세+ age-effect 감소', '18-24세 87% 선호') — Google UX 연구 보고치.

**통찰**: prior 결론은 유효. 다만 비회귀 계약의 **통과 기준은 규범(WCAG 2.2)만** 쓰고,
가이드·연구주장은 '방향 근거'로만 사용해야 근거 강도가 정직해진다.

- 출처: m3.material.io, goo.gle/4dCUvlj(2025-05), design.google/library/expressive-material-design-google-research,
  w3.org/TR/coga-usable, w3.org/news/2021/working-group-note-making-content-usable-...

---

## Research State

**답한 것**: C1(정본 맵+문서상태 분류) 확정. M3E=official-guide, COGA=WG Note/guide, WCAG2.2=유일 규범 기준선.

**열린 하위질문(우선순위)**:
- C2 모션 & reduced-motion 3신호(iOS reduce-motion / Android disable-animations / WCAG 2.3.3) 공식 근거 재확인
- C3 WCAG 2.2 대상 성공기준(Target Size 2.5.8, 2.3.3, 시간조절 2.2.1) 조문 확정
- C4 adaptive layout: Flutter adaptive/responsive + M3 window size class
- C5 performance profiling: Impeller/DevTools/raster·UI thread 절차
- C6 accessibility testing: 자동 semantics 테스트 + 수동 TalkBack/VoiceOver 절차
- C7 Flutter 앱 5개 first-party 검증 + 헬스·인지 채택/금지 패턴
- C8 종합: 전 화면 실행 계획 + 44경로 비회귀 계약

**리드**: prior cycle_002/003 이 M3E·벤치마크를 이미 검증 → 트랙 C 는 '문서 상태 라벨' + '비회귀 계약'에 집중.
**약점**: 44경로 실제 목록 완전 확정 필요(게임 하위 라우트 포함). 비라우트 UI(모달/바텀시트/다이얼로그) 목록화 필요.
**데드엔드**: 새 애니메이션 패키지 도입(prior 에서 실익 낮음으로 종결) — 재조사 불필요.
