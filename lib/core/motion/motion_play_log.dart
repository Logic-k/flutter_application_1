import 'package:flutter/foundation.dart';

/// 앱 실행 동안 한 번만 재생하는 진입 모션의 기록.
///
/// 탭을 오갈 때마다 다시 움직이면 "무엇이 바뀌었나"를 매번 다시 읽게 만든다.
/// Apple HIG 도 빈번한 상호작용에는 모션을 넣지 말라고 한다(08 계획 §3).
/// `FadeSlideIn` 과 `StaggerScope` 가 같은 저장소를 쓴다.
abstract final class MotionPlayLog {
  static final Set<String> _played = <String>{};

  static bool hasPlayed(String key) => _played.contains(key);

  static void markPlayed(String key) => _played.add(key);

  /// 테스트에서 재생 기록을 비운다.
  @visibleForTesting
  static void reset() => _played.clear();
}
