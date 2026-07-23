class TrainingAttemptRecord {
  const TrainingAttemptRecord({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.durationMs,
    required this.xpEarned,
    required this.completedAt,
    required this.localDate,
  });

  final String id;
  final int userId;
  final String activityId;
  final double? score;
  final int? correctAnswers;
  final int? totalQuestions;
  final int? durationMs;
  final int xpEarned;
  final String completedAt;
  final String localDate;

  TrainingAttemptRecord copyWith({int? userId}) => TrainingAttemptRecord(
    id: id,
    userId: userId ?? this.userId,
    activityId: activityId,
    score: score,
    correctAnswers: correctAnswers,
    totalQuestions: totalQuestions,
    durationMs: durationMs,
    xpEarned: xpEarned,
    completedAt: completedAt,
    localDate: localDate,
  );
}

class TrainingUserProgressRecord {
  const TrainingUserProgressRecord({
    required this.userId,
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastTrainingDate,
    required this.updatedAt,
  });

  final int userId;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final String? lastTrainingDate;
  final String updatedAt;
}

class TrainingActivityProgressRecord {
  const TrainingActivityProgressRecord({
    required this.userId,
    required this.activityId,
    required this.bestScore,
    required this.masteryStars,
    required this.completionCount,
    required this.firstCompletedAt,
    required this.lastCompletedAt,
  });

  final int userId;
  final String activityId;
  final double? bestScore;
  final int masteryStars;
  final int completionCount;
  final String? firstCompletedAt;
  final String? lastCompletedAt;
}

class TrainingUnlockRecord {
  const TrainingUnlockRecord({
    required this.userId,
    required this.activityId,
    required this.unlockedAt,
    required this.source,
  });

  final int userId;
  final String activityId;
  final String unlockedAt;
  final String source;
}

abstract interface class TrainingProgressRepository {
  Future<TrainingAttemptRecord?> getAttempt(String attemptId);

  Future<List<TrainingAttemptRecord>> getAttempts(int userId);

  Future<TrainingUserProgressRecord?> getUserProgress(int userId);

  Future<List<TrainingActivityProgressRecord>> getActivityProgress(int userId);

  Future<List<TrainingUnlockRecord>> getUnlocks(int userId);

  Future<int> getDistinctCompletedActivityCount(int userId, String localDate);

  Future<T> transaction<T>(
    Future<T> Function(TrainingProgressTransaction transaction) action,
  );
}

abstract interface class TrainingProgressTransaction {
  Future<TrainingAttemptRecord?> getAttempt(String attemptId);

  Future<bool> insertAttempt(TrainingAttemptRecord attempt);

  Future<TrainingUserProgressRecord?> getUserProgress(int userId);

  Future<void> upsertUserProgress(TrainingUserProgressRecord progress);

  Future<TrainingActivityProgressRecord?> getActivityProgress(
    int userId,
    String activityId,
  );

  Future<void> upsertActivityProgress(TrainingActivityProgressRecord progress);

  Future<bool> insertUnlock({
    required int userId,
    required String activityId,
    required String unlockedAt,
    required String source,
  });

  Future<void> insertLegacyScore({
    required int userId,
    required String category,
    required double score,
    required String createdAt,
  });

  Future<int> getDistinctCompletedActivityCount(int userId, String localDate);
}
