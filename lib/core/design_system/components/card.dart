// ─────────────────────────────────────────────────────────────────────────
// 역할 카드 — 핸드오프 §5.2 · 아키텍처 §3.3 (DS-005)
//
// 모든 카드를 같은 26 반경 + 그림자로 그리지 않는다. 역할이 위계와 행동을 함께 말한다.
//   hero        화면당 0~1장, gradient + hero 그림자, 핵심 요약
//   standard    일반 정보, 그림자 없이 outline
//   interactive 카드 전체가 버튼 하나 — 눌림 피드백(PressableScale 3단) + raised 그림자
//   data        숫자 + 단위 + 해석, outline. 값 모션은 쓰지 않는다(overshoot 금지)
//   support     오류·경고·도움·면책. 틴트 면, 그림자 없음(내용은 보통 MLStatusBanner)
// 기존 MLCard·MLHeroCard는 그대로 두고, 화면을 옮길 때(G4~) 이 위젯으로 바꾼다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../motion/pressable_scale.dart';
import '../../theme.dart';
import '../foundations/elevation.dart';
import '../foundations/spacing.dart';

enum MLCardRole { hero, standard, interactive, data, support }

class MLRoleCard extends StatelessWidget {
  const MLRoleCard({
    super.key,
    required this.role,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding,
  }) : assert(role != MLCardRole.interactive || onTap != null, 'interactive 카드는 onTap이 있어야 한다'),
       assert(onTap == null || role == MLCardRole.interactive, '누를 수 있는 카드는 interactive 역할로 만든다');

  final MLCardRole role;
  final Widget child;
  final VoidCallback? onTap;

  /// interactive 카드가 버튼으로 읽힐 이름. 없으면 안쪽 글자를 합쳐 읽는다.
  final String? semanticLabel;
  final EdgeInsets? padding;

  static double radiusOf(MLCardRole role) => switch (role) {
    MLCardRole.hero => AppTheme.rCard + 2,
    MLCardRole.interactive => AppTheme.rCard,
    MLCardRole.standard || MLCardRole.data => AppTheme.rPanel,
    MLCardRole.support => AppTheme.rTile,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final radius = BorderRadius.circular(radiusOf(role));
    final decoration = switch (role) {
      MLCardRole.hero => BoxDecoration(
        gradient: MLColors.grad,
        borderRadius: radius,
        boxShadow: AppElevation.hero(context.scheme.primary),
      ),
      MLCardRole.interactive => BoxDecoration(
        color: t.cardColor,
        borderRadius: radius,
        border: Border.all(color: t.dividerColor),
        boxShadow: AppElevation.raised,
      ),
      MLCardRole.standard || MLCardRole.data => BoxDecoration(
        color: t.cardColor,
        borderRadius: radius,
        border: Border.all(color: t.dividerColor),
      ),
      MLCardRole.support => BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
    };
    final card = Container(
      width: double.infinity,
      // 누를 수 있는 카드는 내용이 짧아도 터치 높이 56dp를 지킨다.
      constraints: role == MLCardRole.interactive
          ? const BoxConstraints(minHeight: AppTheme.minTapTarget)
          : null,
      padding: padding ??
          EdgeInsets.all(role == MLCardRole.hero ? AppSpacing.heroPadding : AppSpacing.contentGap),
      decoration: decoration,
      child: child,
    );
    if (onTap == null) {
      return role == MLCardRole.data ? Semantics(container: true, child: card) : card;
    }
    return Semantics(
      button: true,
      label: semanticLabel,
      child: PressableScale(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(borderRadius: radius, onTap: onTap, child: card),
        ),
      ),
    );
  }
}
