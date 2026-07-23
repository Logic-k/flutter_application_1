import 'package:flutter/material.dart';

class TrainingResultSheet extends StatelessWidget {
  const TrainingResultSheet({
    super.key,
    required this.encouragement,
    required this.xpEarned,
    required this.todayCompletedActivities,
    required this.todayGoalActivities,
    required this.masteryStars,
    required this.onContinue,
    this.bestScore,
    this.unlockedActivityName,
  }) : assert(xpEarned >= 0),
       assert(todayCompletedActivities >= 0),
       assert(todayGoalActivities > 0),
       assert(masteryStars >= 0 && masteryStars <= 3);

  final String encouragement;
  final int xpEarned;
  final int todayCompletedActivities;
  final int todayGoalActivities;
  final int masteryStars;
  final int? bestScore;
  final String? unlockedActivityName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masteryText = bestScore == null
        ? '숙련도 별 $masteryStars개'
        : '숙련도 별 $masteryStars개 · 최고 $bestScore점';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Semantics(
          container: true,
          label: '훈련 결과',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.celebration_rounded,
                color: theme.colorScheme.primary,
                size: 36,
                semanticLabel: '훈련 완료',
              ),
              const SizedBox(height: 10),
              Text(
                encouragement,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              _ResultRow(icon: Icons.bolt_rounded, label: '+$xpEarned XP'),
              _ResultRow(
                icon: Icons.flag_rounded,
                label: '오늘 목표 $todayCompletedActivities/$todayGoalActivities',
              ),
              _ResultRow(icon: Icons.star_rounded, label: masteryText),
              if (unlockedActivityName != null) ...[
                _ResultRow(
                  icon: Icons.lock_open_rounded,
                  label: '새 활동 열림: $unlockedActivityName',
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const Key('training-result-continue'),
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('계속하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
