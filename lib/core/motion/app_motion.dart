// ─────────────────────────────────────────────────────────────────────────
// 모션 토큰 — DESIGN.md §4 "4단만 쓴다. 그 밖의 값은 쓰지 않는다."
//
// 화면 코드에서 Duration(milliseconds: N)을 직접 쓰지 않는다. 여기 네 값 중 하나를
// 고른다. 새 값이 필요하면 DESIGN.md §4 를 먼저 고친다.
// `test/unit/core/motion_token_guard_test.dart` 가 화면 코드의 직접 사용을 막는다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/animation.dart';

import '../fx/spring_out_curve.dart';

abstract final class AppMotion {
  /// 눌림 피드백.
  static const Duration press = Duration(milliseconds: 100);

  /// 색·투명도 전환.
  static const Duration fade = Duration(milliseconds: 150);

  /// 화면 내 요소 등장·퇴장.
  static const Duration enter = Duration(milliseconds: 200);

  /// 화면 전환.
  static const Duration route = Duration(milliseconds: 300);

  /// `StaggeredColumn` 자식 간 간격. 4단 값이 아니라 **간격**이다 — 각 자식은 여전히
  /// [enter] 동안 움직인다(08 계획 G-01, 40 vs 60ms 는 §7-③ 실기기 확인 대상).
  static const Duration stagger = Duration(milliseconds: 60);

  /// 한 화면 진입 안무 전체의 상한. NN/g "큰 전환도 400ms 를 넘기지 않는다"(08 계획 §3).
  /// [enter] + [stagger] × 3 = 380ms 라 한 묶음의 자식은 최대 4개다.
  static const Duration choreographyMax = Duration(milliseconds: 400);

  /// 1회성 축하 효과 상한(KWCAG 자동재생 3초 제한 안쪽).
  static const Duration celebrateMax = Duration(milliseconds: 2500);

  /// 정답 순간의 1회성 파티클. 축하 효과 범주라 [celebrateMax] 안쪽이면 된다.
  static const Duration burst = Duration(milliseconds: 600);

  /// 정답·오답 배지가 머무는 시간. 움직임이 아니라 "읽을 시간"이다.
  /// "아쉬워요 · 정답은 42" 같은 한 줄을 고령 사용자가 읽을 수 있게 잡았다.
  /// 앞뒤로 [fade] 가 붙어 총 1.7초 보인다(KWCAG 자동재생 3초 안쪽).
  /// 배지는 터치를 막지 않으므로 길어도 다음 문항 풀이를 늦추지 않는다.
  static const Duration feedbackHold = Duration(milliseconds: 1400);

  /// 정답·오답을 누른 뒤 다음 문항으로 넘어가기까지의 멈춤. 움직임이 아니라
  /// "방금 누른 보기의 색 변화를 확인할 시간"이다. 보기 선택 뒤 문항 전체가 바뀌는
  /// 게임(분류하기)만 쓴다. [feedbackHold] 와 달리 문항 진행을 실제로 늦추므로 짧다.
  static const Duration nextQuestionDelay = Duration(milliseconds: 700);

  /// 눌림 시 축소 비율. DESIGN.md §4 "scale(0.98) 수준의 즉각 반응".
  static const double pressScale = 0.98;

  /// 움직임 줄이기(fadeOnly)에서 축소 대신 쓰는 눌림 표시 불투명도.
  /// 크기가 바뀌지 않는 불투명도 변화는 WCAG 2.3.3 의 "motion animation" 이 아니다.
  static const double pressOpacity = 0.72;

  /// 눌림 복귀·해금 노드 scale-in 곡선.
  static const Curve springOut = MLSpringOutCurve();

  /// 물리 기반 전환이 필요할 때의 스프링. M3 Expressive spatial default
  /// (stiffness 380, damping ratio 0.8) 수치만 차용했다 — 패키지는 쓰지 않는다(08 계획 §2.1).
  static final SpringDescription spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.8,
  );
}
