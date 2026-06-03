// ─────────────────────────────────────────────────────────────────────────
// ml_widgets.dart  ·  MemoryLink 리디자인 — 방향 A 공용 위젯 모음
// 데이터/로직은 그대로 두고 "보이는 부분"만 이 위젯들로 감싸면 됩니다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
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
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: t.dividerColor),
              boxShadow: [
                BoxShadow(color: MLColors.primary.withValues(alpha: 0.28), blurRadius: 30, offset: const Offset(0, 12)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (i) {
                final on = i == currentIndex;
                final showLabel = on || !labelOnActiveOnly;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: on ? 14 : 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: on ? t.colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].icon, size: 22, color: on ? t.colorScheme.onPrimary : MLColors.textFaint),
                        if (showLabel) ...[
                          const SizedBox(width: 7),
                          Text(items[i].label, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: on ? t.colorScheme.onPrimary : MLColors.textFaint)),
                        ],
                      ],
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
      boxShadow: [BoxShadow(color: MLColors.primary.withValues(alpha: 0.30), blurRadius: 30, offset: const Offset(0, 12))],
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
    return InkWell(borderRadius: BorderRadius.circular(AppTheme.rCard), onTap: onTap, child: card);
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

/// 6) 진행 바
class MLProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const MLProgressBar({super.key, required this.value, required this.color, this.height = 10});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: LinearProgressIndicator(
      value: value.clamp(0.03, 1.0),
      minHeight: height,
      backgroundColor: color.withValues(alpha: 0.14),
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ),
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
      SizedBox(width: size, height: size, child: CircularProgressIndicator(
        value: value.clamp(0, 1), strokeWidth: stroke, strokeCap: StrokeCap.round,
        backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(color))),
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
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
    ]),
  );
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
            decoration: BoxDecoration(color: MLColors.textSoft.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Text('Lv.$level', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MLColors.textSoft)),
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
          Text('${level * 10}%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
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
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(width: 4),
        Text(unit, style: const TextStyle(fontSize: 12.5, color: MLColors.textSoft)),
      ]),
    ]),
  );
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
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 21)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: titleColor)),
          if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: MLColors.textSoft))),
        ])),
        trailing ?? const Icon(Icons.chevron_right_rounded, color: MLColors.textFaint),
      ]),
    ),
  );
}
