import 'package:flutter/widgets.dart';

import 'app_motion.dart';
import 'motion_settings.dart';

/// 눌리는 동안 자식을 [AppMotion.pressScale] 로 줄였다가 놓으면 되돌린다.
///
/// DESIGN.md §4: "눌림 피드백은 필수. 고령 사용자는 '눌렸는지 모르겠어서' 두 번 누른다."
/// 제스처를 가로채지 않도록 [Listener] 만 쓴다. 안쪽의 `InkWell`·`GestureDetector` 가
/// 그대로 탭을 처리한다. 축소 모션이면 애니메이션 없이 즉시 상태만 바꾼다.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = AppMotion.pressScale,
  }) : assert(scale > 0 && scale <= 1);

  final Widget child;

  /// `false` 면 반응하지 않는다(비활성 카드 등).
  final bool enabled;

  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MotionSettings.reduceOf(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: reduce ? Duration.zero : AppMotion.press,
        curve: _pressed ? Curves.easeOut : AppMotion.springOut,
        child: widget.child,
      ),
    );
  }
}
