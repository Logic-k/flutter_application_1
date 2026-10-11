# 리서치 브리프 — 트랙 C: 공식 문서 기반 재검증 + 비회귀 실행 계획

## 질문 (Question)
MemoryLink 리서치를 한 번 더 꼼꼼히 재검증한다. 44개 GoRouter 경로와 비라우트 UI,
모든 저장·센서·AI·보호자·관리자 기능을 **해치지 않으면서** 전 화면 디자인과 모션을
개선하는 최고의 실행 계획과 **비회귀 검증 계약**을 만든다.

## 트랙 C 지시
2026-09 현재 **Flutter / Material 3 Expressive / Android / Apple HIG / W3C** 의
**공식 문서를 1차 소스로 우선**해 다음을 재조사:
- 전체 앱 디자인 시스템 / 모션 / reduced motion
- 고령·인지 접근성 / adaptive layout
- performance profiling / accessibility testing

Flutter 실제 앱 사례 **5개 안팎을 Flutter 공식 showcase 또는 제작사 1차 출처로만** 검증.
헬스·인지 앱에서 **채택/금지할 패턴**을 구분하고 각 항목의 **URL + 문서 상태**
(규범 normative / 가이드 guide / 연구 주장 research-claim) 를 명시한다.

## 하위 질문 (AUTHORITATIVE checklist)
- C1. 공식 문서 정본 목록 + 문서 상태 분류 (Flutter/M3E/Android/Apple/W3C)
- C2. 모션 & reduced-motion 3신호(iOS/Android/WCAG 2.3.3) 공식 근거 재확인
- C3. 고령·인지 접근성: WCAG 2.2 (normative) vs COGA/WCAG2Mobile (guide) 구분 + 대상 성공기준
- C4. adaptive layout: Flutter adaptive/responsive + M3 window size class 공식 지침
- C5. performance profiling: Impeller/DevTools/raster·UI thread/best-practices 공식 절차
- C6. accessibility testing: 자동(flutter test semantics) + 수동(TalkBack/VoiceOver) 공식 절차
- C7. Flutter 앱 5개 first-party 검증 + 헬스·인지 채택/금지 패턴
- C8. 종합: 전 화면 실행 계획 + 44경로 비회귀 검증 계약 (executive summary)

## 허용 소스 (1차 우선)
- docs.flutter.dev, api.flutter.dev, m3.material.io, design.google, goo.gle
- developer.android.com, developer.apple.com (HIG)
- w3.org/TR (WCAG 2.2 등), w3.org/WAI
- flutter.dev/showcase, 제작사 1차 출처(공식 블로그/GitHub)
- 로컬 코드베이스 lib/**, test/**, 라우터 lib/core/router.dart

## max_cycles
8 (cycle 000 ~ 007; 007 = executive summary + 비회귀 계약)
