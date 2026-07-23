import 'package:flutter/material.dart';

class DailyGoalPanel extends StatelessWidget {
  const DailyGoalPanel({
    super.key,
    required this.completedActivities,
    required this.goalActivities,
    required this.streakDays,
  }) : assert(completedActivities >= 0),
       assert(goalActivities > 0),
       assert(streakDays >= 0);

  final int completedActivities;
  final int goalActivities;
  final int streakDays;

  String get _encouragement {
    final remaining = goalActivities - completedActivities;
    if (remaining <= 0) {
      return '오늘 목표를 달성했어요. 꾸준한 과정이 쌓이고 있어요.';
    }
    if (remaining == 1) {
      return '한 가지 활동만 더 하면 오늘 목표를 달성해요.';
    }
    return '천천히 시작해도 좋아요. 활동 $remaining개가 남았어요.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = completedActivities.clamp(0, goalActivities);
    final progress = completed / goalActivities;

    return Semantics(
      container: true,
      label:
          '오늘 목표 $completedActivities/$goalActivities, $streakDays일 연속 학습 중. $_encouragement',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
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
                    Icons.flag_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '오늘 목표 $completedActivities/$goalActivities',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: theme.colorScheme.tertiary,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$streakDays일 연속 학습 중',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_encouragement, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
