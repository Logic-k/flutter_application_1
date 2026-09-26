import '../data/training_progress_repository.dart';

class TrainingCompletionResult {
  const TrainingCompletionResult({
    required this.attempt,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.masteryStars,
    required this.completionCount,
    required this.bestScore,
    required this.todayDistinctActivityCount,
    required this.newlyUnlockedActivityIds,
    required this.isDuplicate,
    required this.scoreCategory,
    this.isNewBest = false,
    this.isStreakExtended = false,
    this.isDailyGoalJustMet = false,
  });

  final TrainingAttemptRecord attempt;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int masteryStars;
  final int completionCount;
  final double? bestScore;
  final int todayDistinctActivityCount;
  final Set<String> newlyUnlockedActivityIds;
  final bool isDuplicate;
  final String? scoreCategory;

  /// 이전 최고 점수를 넘었다(첫 완료는 비교 대상이 없어 해당하지 않는다).
  final bool isNewBest;

  /// 오늘 첫 훈련으로 연속 학습일이 2일 이상으로 늘었다.
  final bool isStreakExtended;

  /// 이번 완료로 오늘 목표 활동 수에 막 도달했다.
  final bool isDailyGoalJustMet;

  /// 컨페티는 매번이 아니라 이 순간에만 터뜨린다(07 계획 F-03 "변동 보상").
  /// 중복 제출로 다시 받은 결과는 이미 축하한 것이라 세 값 모두 false 다.
  bool get shouldCelebrate =>
      isNewBest || isStreakExtended || isDailyGoalJustMet;
}
