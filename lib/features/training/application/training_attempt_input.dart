class TrainingAttemptInput {
  const TrainingAttemptInput({
    required this.attemptId,
    required this.userId,
    required this.activityId,
    required this.completedAt,
    this.score,
    this.correctAnswers,
    this.totalQuestions,
    this.durationMs,
  });

  final String attemptId;
  final int userId;
  final String activityId;
  final DateTime completedAt;
  final double? score;
  final int? correctAnswers;
  final int? totalQuestions;
  final int? durationMs;
}
