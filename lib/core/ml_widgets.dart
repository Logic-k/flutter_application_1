// ─────────────────────────────────────────────────────────────────────────
// ml_widgets.dart  ·  MemoryLink 리디자인 — 방향 A 공용 위젯 모음
// 데이터/로직은 그대로 두고 "보이는 부분"만 이 위젯들로 감싸면 됩니다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'motion/app_motion.dart';
import 'motion/motion_play_log.dart';
import 'motion/motion_settings.dart';
import 'motion/pressable_scale.dart';
import 'theme.dart';

/// 1) 떠 있는 알약형 하단 네비게이션 (Peacock 스타일)
/// 사용:  Scaffold(extendBody: true, bottomNavigationBar: FloatingPillNav(...))
class MLNavItem {
  final IconData icon;
  final String label;
  const MLNavItem(this.icon, this.label);
}

class FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MLNavItem> items;
  /// true 면 활성 탭만 라벨 노출(여백 ↑), false 면 전체 라벨.
  final bool labelOnActiveOnly;

  /// 이 네비가 본문 위를 덮는 높이(SafeArea 제외).
  /// 바깥 Padding bottom 14 + 알약 Container vertical 9×2 + 탭 최소 높이 48.
  static const double overlayHeight = 14 + 18 + 48;

  /// 탭 화면의 스크롤 뷰가 둬야 할 하단 여백.
  ///
  /// `MainNavScreen`이 `extendBody: true`를 쓰기 때문에 본문은 네비 **뒤로**
  /// 흐른다. 이 값을 안 쓰고 숫자를 직접 박으면, 네비 높이가 바뀔 때 마지막
  /// 항목이 조용히 가려진다. 실제로 탭 높이를 접근성 기준(48dp)에 맞춰 올렸을 때
  /// 하드코딩된 110이 부족해져 E2E 4건이 깨졌다.
  static const double contentBottomInset = overlayHeight + 40;
  const FloatingPillNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.labelOnActiveOnly = true,
    this.items = const [
      MLNavItem(Icons.home_rounded, '홈'),
      MLNavItem(Icons.psychology_rounded, '인지훈련'),
      MLNavItem(Icons.directions_walk_rounded, '생활습관'),
      MLNavItem(Icons.bar_chart_rounded, '리포트'),
      MLNavItem(Icons.person_rounded, '내정보'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final canShowLabel = MediaQuery.sizeOf(context).width >= 340;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.rPill),
              border: Border.all(color: t.dividerColor),
              boxShadow: [
                BoxShadow(color: context.scheme.primary.withValues(alpha: 0.28), blurRadius: 30, offset: const Offset(0, 12)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (i) {
                final on = i == currentIndex;
                final showLabel = canShowLabel && (on || !labelOnActiveOnly);
                return Semantics(
                  label: items[i].label,
                  button: true,
                  selected: on,
                  excludeSemantics: true,
                  child: PressableScale(
                    child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: AppMotion.enter,
                      // 주 내비게이션이다. 예전 padding 9 + icon 22 = 40dp로는
                      // 고령 사용자의 오탭이 잦아 vertical을 13으로 올려 48dp를 만든다.
                      //
                      // 높이를 constraints나 alignment로 잡으면 안 된다. Container는
                      // alignment가 있으면 부모 제약만큼 팽창하므로, 알약이 화면 전체를
                      // 덮어 다른 요소를 전부 가린다(실제로 그렇게 만들어 E2E 20개 중
                      // 14개가 깨졌다). 패딩으로만 크기를 만든다.
                      padding: EdgeInsets.symmetric(horizontal: on ? 14 : 10, vertical: 13),
                      decoration: BoxDecoration(
                        color: on ? t.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.rSheet),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 비선택 탭도 읽혀야 한다. 예전 textFaint는 2.47:1이었다.
                          Icon(items[i].icon, size: 22, color: on ? t.colorScheme.onPrimary : t.colorScheme.onSurfaceVariant),
                          if (showLabel) ...[
                            const SizedBox(width: 7),
                            Text(items[i].label, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: on ? t.colorScheme.onPrimary : t.colorScheme.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ),
                );
              }),
            ),
          )],
        ),
      ),
    );
  }
}

/// 2) 그라디언트 히어로 카드 (인사/현황 헤더)
class MLHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const MLHeroCard({super.key, required this.child, this.padding = const EdgeInsets.all(22)});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      gradient: MLColors.grad,
      borderRadius: BorderRadius.circular(AppTheme.rCard + 2),
      boxShadow: [BoxShadow(color: context.scheme.primary.withValues(alpha: 0.30), blurRadius: 30, offset: const Offset(0, 12))],
    ),
    child: child,
  );
}

/// 3) 흰 카드 래퍼
class MLCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool soft; // true → 보조 배경(그림자 없음)
  final VoidCallback? onTap;
  const MLCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.soft = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: soft ? t.colorScheme.surfaceContainerHighest : t.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.rCard),
        border: Border.all(color: t.dividerColor),
        boxShadow: soft ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: child,
    );
    if (onTap == null) return card;
    // DESIGN.md §4 눌림 피드백. 리플만으로는 고령 사용자가 눌림을 확신하지 못한다.
    return PressableScale(
      child: InkWell(borderRadius: BorderRadius.circular(AppTheme.rCard), onTap: onTap, child: card),
    );
  }
}

/// 4) 아이콘 타일 (연한 틴트 사각형)
class MLIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const MLIconTile({super.key, required this.icon, required this.color, this.size = 50});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppTheme.rTile)),
    child: Icon(icon, color: color, size: size * 0.52),
  );
}

/// 5) 섹션 타이틀 (+ 우측 액션)
class MLSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const MLSectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 18.5, fontWeight: FontWeight.w800)),
      if (trailing != null) trailing!,
    ]),
  );
}

/// 값이 바뀌면 200ms 동안 이전 값에서 새 값으로 보간한다(07 계획 F-05).
/// 처음 그릴 때는 begin 이 없어 곧바로 현재 값이다 — 0에서 차오르는 연출은
/// "값 없음"과 "0"을 헷갈리게 하므로 하지 않는다(DESIGN.md §6.4).
Widget _animatedValue(BuildContext context, double value, Widget Function(double v) builder) =>
    TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: MotionSettings.reduceOf(context) ? Duration.zero : AppMotion.enter,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(v),
    );

/// 6) 진행 바
class MLProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const MLProgressBar({super.key, required this.value, required this.color, this.height = 10});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: _animatedValue(context, value.clamp(0.03, 1.0), (v) => LinearProgressIndicator(
      value: v,
      minHeight: height,
      backgroundColor: color.withValues(alpha: 0.14),
      valueColor: AlwaysStoppedAnimation<Color>(color),
    )),
  );
}

/// 7) 원형 링 게이지
class MLRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? center;
  const MLRing({super.key, required this.value, this.size = 120, this.stroke = 12, required this.color, this.center});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: Stack(alignment: Alignment.center, children: [
      SizedBox(width: size, height: size, child: CircularProgressIndicator(
        value: 1, strokeWidth: stroke, color: color.withValues(alpha: 0.14))),
      SizedBox(width: size, height: size, child: _animatedValue(context, value.clamp(0, 1).toDouble(), (v) => CircularProgressIndicator(
        value: v, strokeWidth: stroke, strokeCap: StrokeCap.round,
        backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(color)))),
      if (center != null) center!,
    ]),
  );
}

/// 8) 상태 칩 (신호등: 양호/보통/주의)
class MLStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const MLStatusPill({super.key, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppTheme.rField),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: _textColor, fontSize: 13, fontWeight: FontWeight.w800)),
    ]),
  );

  /// 점·테두리는 받은 색 그대로, 글자는 읽히는 색으로.
  /// 신호등 면 색(good/warn/bad)을 12% 틴트 위 글자로 쓰면 1.7~2.5:1 이었다.
  /// 그 밖의 색은 같은 색상에서 명도만 낮춘다(sky → 4.5:1 이상).
  Color get _textColor {
    if (color == MLColors.good) return MLColors.goodText;
    if (color == MLColors.warn) return MLColors.warnText;
    if (color == MLColors.bad) return MLColors.badText;
    return HSLColor.fromColor(color).withLightness(0.33).toColor();
  }
}

/// 9) 게임 카드 (트레이닝 센터 그리드)
class MLGameCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final int level; // 1..10
  final VoidCallback? onTap;
  const MLGameCard({super.key, required this.icon, required this.color, required this.title, required this.desc, required this.level, this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return MLCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          MLIconTile(icon: icon, color: color, size: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppTheme.rField)),
            child: Text('Lv.$level', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: t.colorScheme.onSurfaceVariant)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(title, style: t.textTheme.titleMedium?.copyWith(fontSize: 15.5)),
        const SizedBox(height: 3),
        Text(desc, style: t.textTheme.bodySmall?.copyWith(fontSize: 12.5)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: MLProgressBar(value: level / 10, color: color, height: 6)),
          const SizedBox(width: 8),
          Text('${level * 10}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ]),
      ]),
    );
  }
}

/// 10) 지표 메트릭 카드 (생활습관 그리드)
class MLMetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  const MLMetricCard({super.key, required this.icon, required this.color, required this.label, required this.value, required this.unit});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(AppTheme.rTile),
      border: Border.all(color: color.withValues(alpha: 0.16)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Text(unit, style: TextStyle(fontSize: 13, color: context.scheme.onSurfaceVariant)),
      ]),
    ]),
  );
}

/// 10.5) 오류 상태 뷰 (재시도 버튼 포함)
///
/// 네트워크·Firestore 실패를 "빈 목록"과 구분해 보여준다. 예전에는
/// cs_service가 실패를 빈 리스트로 반환해 사용자에게는 "등록된
/// 공지사항이 없습니다"로 위장됐고, 일부 화면은 원시 예외 문자열을
/// 고령 사용자에게 그대로 노출했다.
class MLErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const MLErrorState({
    super.key,
    this.message = '일시적인 문제로 불러오지 못했습니다.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: context.scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 11) 설정/링크 행 (내 정보)
class MLListRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing; // 토글/값/Chevron
  final VoidCallback? onTap;
  const MLListRow({super.key, required this.icon, required this.color, required this.title, this.subtitle, this.titleColor, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppTheme.rField)),
          child: Icon(icon, color: color, size: 21)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: titleColor)),
          if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle!, style: TextStyle(fontSize: 13, color: context.scheme.onSurfaceVariant))),
        ])),
        trailing ?? Icon(Icons.chevron_right_rounded, color: context.scheme.onSurfaceVariant),
      ]),
    ),
  );
}

/// 12) 차트 진입 애니메이션 (08 계획 G-04)
///
/// fl_chart 차트는 두 데이터 상태 사이만 보간하고 첫 빌드 진입 애니메이션이 없다.
/// 그래서 첫 프레임은 기준선(0값) 데이터로 그리고, 다음 프레임에 실데이터로 바꿔
/// 차트가 자라나게 한다. [builder] 는 `entered == false` 면 y 를 0 으로 둔 데이터를,
/// 받은 `duration`·`curve` 는 fl_chart 생성자의 `duration`·`curve` 에 그대로 넣는다.
///
/// - 곡선은 오버슈트 없는 easeOutCubic 이다. 스프링은 값이 실제보다 잠깐 커 보이게
///   만들어 데이터를 과장한다.
/// - 같은 [playKey] 는 앱 실행 동안 한 번만 자라난다. 숨은 탭(TickerMode 꺼짐)은
///   처음 보이는 순간까지 기다린다.
/// - 움직임 줄이기(fadeOnly·none)면 처음부터 실데이터이고 이후 데이터 변경도
///   보간 없이 바뀐다(fl_chart 기본 150ms linear 보간까지 끈다).
/// - 값 없음(null)은 builder 가 0 이 아니라 빈 상태로 그려야 한다(DESIGN.md §6.4).
class MLChart extends StatefulWidget {
  const MLChart({super.key, required this.playKey, required this.builder});

  final String playKey;
  final Widget Function(BuildContext context, bool entered, Duration duration, Curve curve) builder;

  @override
  State<MLChart> createState() => _MLChartState();
}

class _MLChartState extends State<MLChart> {
  bool _entered = true;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    final level = MotionSettings.levelOf(context, listen: false);
    if (level != MotionLevel.full || MotionPlayLog.hasPlayed(widget.playKey)) {
      _decided = true;
      return;
    }
    // 숨은 탭에서는 기준선으로 기다렸다가, 보이는 순간 자라난다.
    _entered = false;
    if (!TickerMode.valuesOf(context).enabled) return;
    _decided = true;
    MotionPlayLog.markPlayed(widget.playKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final full = MotionSettings.levelOf(context) == MotionLevel.full;
    return widget.builder(
      context,
      _entered,
      full ? AppMotion.enter : Duration.zero,
      Curves.easeOutCubic,
    );
  }
}

/// 13) 숫자 카운트업 (08 계획 G-04)
///
/// 값이 바뀌면 이전 값에서 새 값으로 [AppMotion.enter] 동안 올라간다(훈련 뒤 XP·연속 학습).
/// [playKey] 를 주면 화면 첫 진입에 한 번 0 에서 올라간다 — 오늘 걸음처럼 "오늘 쌓인 양"
/// 에만 쓴다. 누적 XP 처럼 변하지 않은 값을 0 부터 세면 방금 얻은 것처럼 읽힌다.
/// 움직임 줄이기면 즉시 최종 값이다.
/// 글자가 매 프레임 바뀌므로 스크린리더에는 [semanticsLabel] 로 최종 값만 준다.
/// null 은 카운트업하지 않는다 — 호출부가 "측정 못 함"을 따로 그린다(DESIGN.md §6.4).
class MLCountUp extends StatefulWidget {
  const MLCountUp({
    super.key,
    required this.value,
    required this.builder,
    this.playKey,
    this.semanticsLabel,
  });

  final int value;
  final String? playKey;
  final Widget Function(BuildContext context, int value) builder;
  final String? semanticsLabel;

  @override
  State<MLCountUp> createState() => _MLCountUpState();
}

class _MLCountUpState extends State<MLCountUp> {
  int? _from;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_from != null) return;
    final key = widget.playKey;
    if (key == null) {
      _from = widget.value;
      return;
    }
    if (!TickerMode.valuesOf(context).enabled) return; // 숨은 탭은 보일 때 정한다.
    final level = MotionSettings.levelOf(context, listen: false);
    if (level != MotionLevel.full || MotionPlayLog.hasPlayed(key)) {
      _from = widget.value;
    } else {
      MotionPlayLog.markPlayed(key);
      _from = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final full = MotionSettings.levelOf(context) == MotionLevel.full;
    final counter = TweenAnimationBuilder<int>(
      tween: IntTween(begin: _from ?? widget.value, end: widget.value),
      duration: full ? AppMotion.enter : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => widget.builder(context, v),
    );
    final label = widget.semanticsLabel;
    if (label == null) return counter;
    return Semantics(label: label, excludeSemantics: true, child: counter);
  }
}

/// 14) 스켈레톤 블록 (08 계획 G-05, DESIGN.md §4 "레이아웃 모양을 닮은 스켈레톤")
///
/// 정적 블록이다. 반짝임(shimmer)은 반복 애니메이션이라 쓰지 않는다(KWCAG 자동재생).
/// 색은 장식용 경계선(`dividerColor`)이라 흰 카드 위에서 보이고 대비 요건이 없다.
class MLSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const MLSkeleton({super.key, this.width, this.height = 14, this.radius = AppTheme.rChip});
  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).dividerColor,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// 카드 한 장 모양의 스켈레톤: 아이콘 타일 + 제목 줄 + 보조 줄.
/// [lines] 는 보조 줄 수, [leading] 이 false 면 아이콘 자리를 비운다.
class MLSkeletonCard extends StatelessWidget {
  final int lines;
  final bool leading;
  final double? height;
  const MLSkeletonCard({super.key, this.lines = 1, this.leading = true, this.height});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.rCard),
        border: Border.all(color: t.dividerColor),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (leading) ...[
          const MLSkeleton(width: 44, height: 44, radius: AppTheme.rTile),
          const SizedBox(width: 14),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FractionallySizedBox(widthFactor: 0.55, child: MLSkeleton(height: 16)),
          for (var i = 0; i < lines; i++) ...[
            const SizedBox(height: 10),
            FractionallySizedBox(widthFactor: i.isEven ? 0.9 : 0.7, child: const MLSkeleton(height: 12)),
          ],
        ])),
      ]),
    );
  }
}

/// 목록 로딩 자리. 실제 목록과 같은 간격으로 카드 [count] 장을 그린다.
/// 스크린리더에는 블록 대신 "불러오는 중" 한 번만 읽힌다.
/// 다른 스크롤 뷰 안에 넣을 때는 [shrinkWrap] 을 true 로 준다.
class MLSkeletonList extends StatelessWidget {
  final int count;
  final int lines;
  final bool leading;
  final EdgeInsetsGeometry padding;
  final double spacing;
  const MLSkeletonList({
    super.key,
    this.count = 4,
    this.lines = 1,
    this.leading = true,
    this.padding = const EdgeInsets.all(20),
    this.spacing = 12,
    this.shrinkWrap = false,
  });
  final bool shrinkWrap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '불러오는 중',
    excludeSemantics: true,
    child: ListView.separated(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      itemBuilder: (_, _) => MLSkeletonCard(lines: lines, leading: leading),
    ),
  );
}

/// 로딩(스켈레톤) → 내용 전환. 움직임 줄이기에서도 크로스페이드는 남기고
/// (불투명도 변화), 애니메이션 제거(none)면 바로 바꾼다.
class MLLoadSwitcher extends StatelessWidget {
  final bool loading;
  final Widget skeleton;
  final Widget child;
  const MLLoadSwitcher({super.key, required this.loading, required this.skeleton, required this.child});
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MotionSettings.levelOf(context) == MotionLevel.none ? Duration.zero : AppMotion.fade,
    child: KeyedSubtree(
      key: ValueKey<bool>(loading),
      child: loading ? skeleton : child,
    ),
  );
}
