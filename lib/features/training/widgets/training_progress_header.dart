import 'package:flutter/material.dart';
import '../../../core/ml_widgets.dart';
import '../../../core/theme.dart';

class TrainingProgressHeader extends StatelessWidget {
  const TrainingProgressHeader({
    super.key,
    required this.level,
    required this.totalXp,
    required this.xpInCurrentLevel,
    required this.xpForNextLevel,
  }) : assert(level > 0),
       assert(totalXp >= 0),
       assert(xpInCurrentLevel >= 0),
       assert(xpForNextLevel > 0);

  final int level;
  final int totalXp;
  final int xpInCurrentLevel;
  final int xpForNextLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentXp = xpInCurrentLevel.clamp(0, xpForNextLevel);
    final remainingXp = xpForNextLevel - currentXp;
    final progress = currentXp / xpForNextLevel;

    return Semantics(
      container: true,
      label: '레벨 $level, 총 $totalXp XP, 다음 레벨까지 $remainingXp XP',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppTheme.rChip),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('레벨 $level', style: theme.textTheme.titleLarge),
                  ),
                  // 훈련을 마치고 돌아오면 이전 XP 에서 새 XP 로 올라간다(08 계획 G-04).
                  MLCountUp(
                    value: totalXp,
                    semanticsLabel: '총 $totalXp XP',
                    builder: (context, xp) => Text(
                      '총 $xp XP',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.rBar),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '다음 레벨까지 $remainingXp XP',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
