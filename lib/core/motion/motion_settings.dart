import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../settings_provider.dart';

/// 모션 3단(08 계획 G-01).
///
/// WCAG 2.3.3 의 "motion animation" 정의는 크기·형태·위치를 바꾸지 않는 색·불투명도
/// 변화를 **제외**한다. 그래서 움직임 줄이기는 "전부 끄기"가 아니라 이동·확대·파티클만
/// 끄고 페이드는 남기는 단계([fadeOnly])를 따로 둔다. 정답·오답 배지처럼 상태를 알리는
/// 페이드까지 사라지면 인지 피드백이 약해진다.
enum MotionLevel {
  /// 모든 모션.
  full,

  /// 이동·확대·파티클·스태거 없음. [AppMotion.fade] 이하의 페이드와 색 전환만.
  fadeOnly,

  /// 애니메이션 없음. 최종 상태를 즉시 그린다.
  none,
}

/// 축소 모션 판정을 한 곳에 모은다.
///
/// 세 신호를 본다.
/// 1. `MediaQuery.disableAnimations` — Android "애니메이션 제거" 설정. 사용자가 OS 전체의
///    애니메이션을 끈 것이므로 [MotionLevel.none]. Flutter 는 이 값으로
///    `AnimationController` 지속시간을 자동 단축하지만, Timer·수동 루프·`Future.delayed`
///    스태거에는 적용되지 않는다.
/// 2. `AccessibilityFeatures.reduceMotion` — iOS "동작 줄이기". 공식 문서대로 이 값은
///    `disableAnimations` 에 반영되지 **않으므로** 따로 읽는다. Apple HIG 가 이 설정에서
///    슬라이드·줌을 크로스페이드로 바꾸라고 하므로 [MotionLevel.fadeOnly].
/// 3. 앱 설정 "움직임 줄이기"(`SettingsProvider.reduceMotion`) — [MotionLevel.fadeOnly].
abstract final class MotionSettings {
  /// 이벤트 핸들러처럼 build 밖에서 읽을 때는 [listen] 을 false 로 준다.
  static MotionLevel levelOf(BuildContext context, {bool listen = true}) {
    final platform = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (platform) return MotionLevel.none;
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
    return reduceMotion || app ? MotionLevel.fadeOnly : MotionLevel.full;
  }

  /// 이동·확대 모션을 꺼야 하는가(= [levelOf] 가 [MotionLevel.full] 이 아님).
  /// 페이드까지 끌지는 [levelOf] 로 따로 판단한다.
  static bool reduceOf(BuildContext context, {bool listen = true}) =>
      levelOf(context, listen: listen) != MotionLevel.full;
}
