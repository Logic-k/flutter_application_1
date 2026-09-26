import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/user_provider.dart';
import '../domain/training_progress_rules.dart';
import '../widgets/training_result_sheet.dart';
import 'training_completion_result.dart';

final Random _secureRandom = Random.secure();

String createTrainingAttemptId() {
  final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

Future<void> showTrainingCompletionResult(
  BuildContext context,
  TrainingCompletionResult result,
) async {
  final scoreCategory = result.scoreCategory;
  final score = result.attempt.score;
  if (scoreCategory != null && score != null) {
    context.read<UserProvider>().setCognitiveScore(
      scoreCategory,
      score,
      persist: false,
    );
  }

  final unlockedName = result.newlyUnlockedActivityIds.isEmpty
      ? null
      : trainingActivityName(result.newlyUnlockedActivityIds.first);
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (sheetContext) => TrainingResultSheet(
      encouragement: _encouragementFor(result),
      xpEarned: result.attempt.xpEarned,
      todayCompletedActivities: result.todayDistinctActivityCount,
      todayGoalActivities: dailyActivityGoal,
      masteryStars: result.masteryStars,
      bestScore: result.bestScore?.round(),
      unlockedActivityName: unlockedName,
      celebrate: result.shouldCelebrate,
      highlight: _highlightFor(result),
      onContinue: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

String trainingActivityName(String activityId) => switch (activityId) {
  'comparison' => '누가 큰가요?',
  'multiplication' => '구구단 맞추기',
  'sequence' => '규칙 찾아보기',
  'categorization' => '범주화 훈련',
  'shape_sudoku' => '그림 스도쿠',
  'shape_match' => '같은 모양 찾기',
  'sentence_reading' => '문장 읽기 훈련',
  'daily_recall' => '일상 회상 훈련',
  _ => throw ArgumentError.value(activityId, 'activityId', 'Unknown activity'),
};

/// 활동 아이콘. 허브 코스 노드와 게임 화면 목표 카드가 같은 아이콘을 쓴다.
IconData trainingActivityIcon(String activityId) => switch (activityId) {
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

/// 허브 → 게임 화면으로 아이콘이 이어지는 공유 요소 전환(Hero)의 태그.
/// 같은 화면에 같은 태그가 둘이면 Hero 가 예외를 던지므로 활동당 하나만 만든다.
String trainingActivityHeroTag(String activityId) =>
    'training-activity-$activityId';

/// 왜 축하하는지 글로 말한다. 컨페티만 터지면 무엇을 해냈는지 알 수 없다.
String? _highlightFor(TrainingCompletionResult result) {
  if (result.isNewBest) return '최고 기록을 넘었어요';
  if (result.isDailyGoalJustMet) return '오늘 목표를 모두 채웠어요';
  if (result.isStreakExtended) return '${result.currentStreak}일 연속 학습 중이에요';
  return null;
}

String _encouragementFor(TrainingCompletionResult result) {
  if (result.attempt.score == null) {
    return '오늘의 기억을 차분히 떠올렸어요.';
  }
  if (result.masteryStars >= 3) {
    return '집중해서 끝까지 해냈어요.';
  }
  return '오늘도 한 과정을 완주했어요.';
}
