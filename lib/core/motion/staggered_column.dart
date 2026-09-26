import 'package:flutter/widgets.dart';

import 'app_motion.dart';
import 'motion_play_log.dart';
import 'motion_settings.dart';

/// 화면 첫 진입 때 요소들을 순서대로 들인다(08 계획 G-02).
///
/// Flutter 공식 스태거 패턴 그대로다 — 컨트롤러 **하나**에 자식마다
/// `Interval(i·stagger, i·stagger + enter)` 를 건다. Timer·`Future.delayed` 가 없어
/// 축소 모션·`TickerMode`·dispose 가 한 곳에서 처리된다.
///
/// - 자식 i 는 [AppMotion.stagger] × i 만큼 늦게 시작해 [AppMotion.enter] 동안
///   8px 올라오며 나타난다. 전체는 [AppMotion.choreographyMax](400ms)를 넘지 않는다.
///   그래서 자식은 최대 [StaggerScope.maxSlots](4)개이고, 더 많으면 호출부가 묶는다.
/// - 같은 [playKey] 는 앱 실행 동안 한 번만 재생한다(탭 재진입·스크롤 복귀는 무모션).
/// - [MotionLevel.fadeOnly] 는 이동·순차 없이 [AppMotion.fade] 동안 함께 페이드,
///   [MotionLevel.none] 은 첫 프레임부터 최종 상태.
/// - 반복·자동 재생은 없다.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.playKey,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  });

  final String playKey;

  /// 순서대로 들어올 묶음. 간격(SizedBox)은 묶음 안에 넣는다.
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    assert(
      children.length <= StaggerScope.maxSlots,
      'StaggeredColumn 자식 ${children.length}개 — 400ms 상한 때문에 '
      '${StaggerScope.maxSlots}개까지다. 가까운 요소끼리 Column 으로 묶어라.',
    );
    return StaggerScope(
      playKey: playKey,
      slots: children.length,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: [
          for (var i = 0; i < children.length; i++)
            StaggerItem(index: i, child: children[i]),
        ],
      ),
    );
  }
}

/// 컨트롤러를 소유하고 아래의 [StaggerItem] 들에 나눠 준다.
///
/// `ListView`·`Wrap` 처럼 [StaggeredColumn] 을 쓸 수 없는 자리에서 직접 쓴다.
/// [StaggerItem.index] 가 [slots] 이상이면 마지막 칸과 함께 나온다 — 목록 길이가
/// 바뀌어도 400ms 상한을 지킨다.
class StaggerScope extends StatefulWidget {
  const StaggerScope({
    super.key,
    required this.playKey,
    required this.child,
    this.slots = maxSlots,
  }) : assert(slots >= 1);

  /// (400 − 200) / 60 + 1 = 4.
  static const int maxSlots = 4;

  /// 전체 안무 길이. 테스트와 호출부가 같은 계산을 쓴다.
  static Duration totalFor(int slots) =>
      AppMotion.enter + AppMotion.stagger * (slots.clamp(1, maxSlots) - 1);

  final String playKey;
  final int slots;
  final Widget child;

  @override
  State<StaggerScope> createState() => _StaggerScopeState();
}

class _StaggerScopeState extends State<StaggerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final int _slots = widget.slots.clamp(1, StaggerScope.maxSlots);
  MotionLevel _level = MotionLevel.full;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    // 숨은 탭(`TickerMode` 꺼짐)은 보이는 순간까지 결정을 미룬다. 그동안은
    // 최종 상태로 그려 두어, 어떤 경우에도 내용이 투명한 채로 남지 않게 한다.
    if (!TickerMode.valuesOf(context).enabled) {
      _controller.value = 1;
      return;
    }
    _decided = true;
    _level = MotionSettings.levelOf(context, listen: false);
    if (_level == MotionLevel.none || MotionPlayLog.hasPlayed(widget.playKey)) {
      _controller.value = 1;
      return;
    }
    MotionPlayLog.markPlayed(widget.playKey);
    _controller.duration = _level == MotionLevel.fadeOnly
        ? AppMotion.fade
        : StaggerScope.totalFor(_slots);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StaggerData(
      controller: _controller,
      slots: _slots,
      slide: _level == MotionLevel.full,
      child: widget.child,
    );
  }
}

class _StaggerData extends InheritedWidget {
  const _StaggerData({
    required this.controller,
    required this.slots,
    required this.slide,
    required super.child,
  });

  final AnimationController controller;
  final int slots;
  final bool slide;

  @override
  bool updateShouldNotify(_StaggerData old) =>
      old.controller != controller || old.slots != slots || old.slide != slide;
}

/// [StaggerScope] 안에서 [index] 번째 순서로 들어온다. 스코프 밖이면 그대로 그린다.
class StaggerItem extends StatelessWidget {
  const StaggerItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  static const double offsetDp = 8;

  @override
  Widget build(BuildContext context) {
    final data = context.dependOnInheritedWidgetOfExactType<_StaggerData>();
    if (data == null) return child;
    final Animation<double> t;
    if (data.slide) {
      final total = StaggerScope.totalFor(data.slots).inMicroseconds;
      final start =
          (AppMotion.stagger * index.clamp(0, data.slots - 1)).inMicroseconds /
          total;
      final end = start + AppMotion.enter.inMicroseconds / total;
      t = data.controller.drive(
        CurveTween(
          curve: Interval(start, end.clamp(0, 1).toDouble(), curve: Curves.easeOutCubic),
        ),
      );
    } else {
      t = data.controller.drive(CurveTween(curve: Curves.easeOut));
    }
    // 끝난 뒤에도 트리 모양을 바꾸지 않는다 — 바꾸면 안쪽 TextField 등의 상태가 초기화된다.
    // 불투명도 1 의 Opacity 와 이동 0 의 Transform 은 레이어를 만들지 않는다.
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, data.slide ? offsetDp * (1 - t.value) : 0),
          child: child,
        ),
      ),
    );
  }
}
