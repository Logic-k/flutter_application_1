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
}
