// ─────────────────────────────────────────────────────────────────────────
// 모션 토큰 — DESIGN.md §4 "4단만 쓴다. 그 밖의 값은 쓰지 않는다."
//
// 화면 코드에서 Duration(milliseconds: N)을 직접 쓰지 않는다. 여기 네 값 중 하나를
// 고른다. 새 값이 필요하면 DESIGN.md §4 를 먼저 고친다.
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

  /// 1회성 축하 효과 상한(KWCAG 자동재생 3초 제한 안쪽).
  static const Duration celebrateMax = Duration(milliseconds: 2500);

  /// 정답 순간의 1회성 파티클. 축하 효과 범주라 [celebrateMax] 안쪽이면 된다.
  static const Duration burst = Duration(milliseconds: 600);

  /// 정답·오답 배지가 머무는 시간. 움직임이 아니라 "읽을 시간"이다.
  /// "아쉬워요 · 정답은 42" 같은 한 줄을 고령 사용자가 읽을 수 있게 잡았다.
  /// 앞뒤로 [fade] 가 붙어 총 1.7초 보인다(KWCAG 자동재생 3초 안쪽).
  /// 배지는 터치를 막지 않으므로 길어도 다음 문항 풀이를 늦추지 않는다.
  static const Duration feedbackHold = Duration(milliseconds: 1400);

  /// 눌림 시 축소 비율. DESIGN.md §4 "scale(0.98) 수준의 즉각 반응".
  static const double pressScale = 0.98;

  /// 눌림 복귀·해금 노드 scale-in 곡선.
  static const Curve springOut = MLSpringOutCurve();
}
