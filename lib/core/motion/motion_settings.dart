import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../settings_provider.dart';

/// 축소 모션 판정을 한 곳에 모은다.
///
/// 세 신호를 OR 한다.
/// 1. `MediaQuery.disableAnimations` — Android "애니메이션 제거" 설정. Flutter 는 이 값으로
///    `AnimationController` 지속시간을 자동 단축하지만, Timer·수동 루프·`Future.delayed`
///    스태거에는 적용되지 않는다.
/// 2. `AccessibilityFeatures.reduceMotion` — iOS "동작 줄이기". 공식 문서대로 이 값은
///    `disableAnimations` 에 반영되지 **않으므로** 따로 읽는다.
/// 3. 앱 설정 "움직임 줄이기"(`SettingsProvider.reduceMotion`).
///
/// `true` 면 애니메이션 지속시간을 0으로 줄이는 것이 아니라 **최종 상태를 즉시 그린다**.
abstract final class MotionSettings {
  /// 이벤트 핸들러처럼 build 밖에서 읽을 때는 [listen] 을 false 로 준다.
  static bool reduceOf(BuildContext context, {bool listen = true}) {
    final platform = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .reduceMotion;
    var app = false;
    try {
      app = listen
          ? context.watch<SettingsProvider>().reduceMotion
          : context.read<SettingsProvider>().reduceMotion;
    } on ProviderNotFoundException {
      // SettingsProvider 없이 쓰이는 위젯 테스트·독립 화면은 플랫폼 신호만 본다.
    }
    return platform || reduceMotion || app;
  }
}
