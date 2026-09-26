import 'package:flutter/widgets.dart';

import 'app_motion.dart';
import 'motion_play_log.dart';
import 'motion_settings.dart';

/// 화면에 처음 들어올 때 아래에서 8px 올라오며 나타난다(07 계획 F-04).
///
/// - blur 는 쓰지 않는다(DESIGN.md §4 "blur 진입은 읽기를 늦춘다").
/// - [index] 마다 40ms 씩 늦게 시작하되 [maxStaggered] 번째부터는 같이 나온다.
///   총 시간이 400ms 를 넘지 않게 하려는 상한이다.
/// - 같은 [playKey] 는 앱 실행 동안 한 번만 재생한다. 탭을 오갈 때마다 다시 움직이면
///   "무엇이 바뀌었나"를 매번 다시 읽게 만든다.
/// - Timer 를 쓰지 않고 컨트롤러 하나의 [Interval] 로 지연을 만든다.
/// - [MotionLevel.fadeOnly] 면 이동·지연 없이 [AppMotion.fade] 동안 페이드만,
///   [MotionLevel.none] 이면 처음부터 최종 상태다.
///
/// 여러 요소를 순서대로 들일 때는 `StaggeredColumn` 을 쓴다(08 계획 G-02).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.playKey,
    required this.index,
    required this.child,
  });

  final String playKey;
  final int index;
  final Widget child;

  static const Duration stagger = Duration(milliseconds: 40);
  static const int maxStaggered = 4;
  static const double offsetDp = 8;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final int _delayMs =
      FadeSlideIn.stagger.inMilliseconds *
      widget.index.clamp(0, FadeSlideIn.maxStaggered);
  late final AnimationController _controller = AnimationController(vsync: this);
  Animation<double> _t = kAlwaysCompleteAnimation;
  bool _slide = true;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final key = '${widget.playKey}#${widget.index}';
    final level = MotionSettings.levelOf(context, listen: false);
    if (level == MotionLevel.none || MotionPlayLog.hasPlayed(key)) {
      _controller.value = 1;
      return;
    }
    MotionPlayLog.markPlayed(key);
    if (level == MotionLevel.fadeOnly) {
      _slide = false;
      _controller.duration = AppMotion.fade;
      _t = _controller.drive(CurveTween(curve: Curves.easeOut));
    } else {
      _controller.duration = AppMotion.enter + Duration(milliseconds: _delayMs);
      _t = _controller.drive(
        CurveTween(
          curve: Interval(
            _delayMs / _controller.duration!.inMilliseconds,
            1,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, _slide ? FadeSlideIn.offsetDp * (1 - _t.value) : 0),
          child: child,
        ),
      ),
    );
  }
}
