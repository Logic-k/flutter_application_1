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

String _encouragementFor(TrainingCompletionResult result) {
  if (result.attempt.score == null) {
    return '오늘의 기억을 차분히 떠올렸어요.';
  }
  if (result.masteryStars >= 3) {
    return '집중해서 끝까지 해냈어요.';
  }
  return '오늘도 한 과정을 완주했어요.';
}
