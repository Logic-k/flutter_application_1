import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'application/training_completion_ui.dart';
import 'domain/training_activity.dart';
import 'domain/training_catalog.dart';
import 'domain/training_progress_rules.dart';
import 'training_progress_provider.dart';
import 'widgets/course_node.dart';
import 'widgets/course_path.dart';
import 'widgets/daily_goal_panel.dart';
import 'widgets/training_progress_header.dart';

class TrainingHubScreen extends StatelessWidget {
  const TrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<TrainingProgressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('두뇌 트레이닝 센터')),
      body: RefreshIndicator(
        onRefresh: progress.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TrainingProgressHeader(
                level: progress.level,
                totalXp: progress.totalXp,
                xpInCurrentLevel: progress.totalXp % xpPerLevel,
                xpForNextLevel: xpPerLevel,
              ),
              const SizedBox(height: 12),
              DailyGoalPanel(
                completedActivities: progress.todayDistinctActivityCount,
                goalActivities: dailyActivityGoal,
                streakDays: progress.currentStreak,
              ),
              if (progress.error != null) ...[
                const SizedBox(height: 12),
                _LoadError(onRetry: progress.refresh),
              ],
              const SizedBox(height: 24),
              if (progress.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                for (final entry in _activitiesByArea.entries) ...[
                  _AreaHeading(entry.key),
                  CoursePath(
                    nodes: [
                      for (final activity in entry.value)
                        _courseNode(context, progress, activity),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
            ],
          ),
        ),
      ),
    );
  }

  CourseNode _courseNode(
    BuildContext context,
    TrainingProgressProvider progress,
    TrainingActivity activity,
  ) {
    final activityProgress = progress.activityProgressById[activity.id];
    final isCompleted = (activityProgress?.completionCount ?? 0) > 0;
    final isUnlocked = progress.isUnlocked(activity.id);
    final status = isCompleted
        ? CourseNodeStatus.completed
        : isUnlocked
        ? CourseNodeStatus.available
        : CourseNodeStatus.locked;

    return CourseNode(
      key: Key('course-node-${activity.id}'),
      title: trainingActivityName(activity.id),
      description: _descriptionFor(activity.id),
      icon: _iconFor(activity.id),
      status: status,
      masteryStars: activityProgress?.masteryStars ?? 0,
      onTap: () {
        if (isUnlocked) {
          context.push(activity.route);
          return;
        }
        final prerequisite = trainingActivityName(activity.prerequisiteId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('먼저 $prerequisite 활동을 한 번 완료해 보세요.')),
        );
      },
    );
  }
}

class _AreaHeading extends StatelessWidget {
  const _AreaHeading(this.area);

  final String area;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(Icons.route_rounded, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$area 과정', style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded),
          const SizedBox(width: 8),
          const Expanded(child: Text('진행 기록을 불러오지 못했습니다.')),
          IconButton(
            tooltip: '다시 불러오기',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    ),
  );
}

final Map<String, List<TrainingActivity>> _activitiesByArea = _groupActivities();

Map<String, List<TrainingActivity>> _groupActivities() {
  final grouped = <String, List<TrainingActivity>>{};
  for (final activity in trainingCatalog) {
    (grouped[activity.displayArea] ??= []).add(activity);
  }
  return Map<String, List<TrainingActivity>>.unmodifiable({
    for (final entry in grouped.entries)
      entry.key: List<TrainingActivity>.unmodifiable(entry.value),
  });
}

String _descriptionFor(String activityId) => switch (activityId) {
  'comparison' => '두 수식을 비교하며 판단해요.',
  'multiplication' => '곱셈 문제를 차근차근 풀어요.',
  'sequence' => '숫자에 숨어 있는 규칙을 찾아요.',
  'categorization' => '낱말을 알맞은 범주로 나눠요.',
  'shape_sudoku' => '그림의 위치를 기억해 채워요.',
  'shape_match' => '같은 모양을 빠르게 찾아요.',
  'sentence_reading' => '문장을 소리 내어 또박또박 읽어요.',
  'daily_recall' => '오늘의 기억을 편안하게 떠올려요.',
  _ => '',
};

IconData _iconFor(String activityId) => switch (activityId) {
  'comparison' => Icons.compare_arrows_rounded,
  'multiplication' => Icons.grid_3x3_rounded,
  'sequence' => Icons.reorder_rounded,
  'categorization' => Icons.category_rounded,
  'shape_sudoku' => Icons.extension_rounded,
  'shape_match' => Icons.auto_awesome_motion_rounded,
  'sentence_reading' => Icons.record_voice_over_rounded,
  'daily_recall' => Icons.favorite_rounded,
  _ => Icons.psychology_rounded,
};
