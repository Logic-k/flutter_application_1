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
    this.completionStatus = TrainingCompletionStatus.completed,
    this.assistanceLevel,
    this.sessionContext,
    this.contentVersion,
    this.responseCode,
  });

  final String attemptId;
  final int userId;
  final String activityId;
  final DateTime completedAt;
  final double? score;
  final int? correctAnswers;
  final int? totalQuestions;
  final int? durationMs;
  final String completionStatus;
  final String? assistanceLevel;
  final String? sessionContext;
  final String? contentVersion;
  final String? responseCode;
}

abstract final class TrainingCompletionStatus {
  static const completed = 'completed';
  static const stopped = 'stopped';
  static const technicalIssue = 'technical_issue';

  static const values = <String>{completed, stopped, technicalIssue};
}

abstract final class TrainingAssistanceLevel {
  static const independent = 'independent';
  static const verbalPrompt = 'verbal_prompt';
  static const handsOnHelp = 'hands_on_help';

  static const values = <String>{independent, verbalPrompt, handsOnHelp};
}

abstract final class TrainingSessionContext {
  static const selfPractice = 'self_practice';
  static const homePractice = 'home_practice';
  static const centerPractice = 'center_practice';

  static const values = <String>{selfPractice, homePractice, centerPractice};
}
