import 'dart:math' as math;

import '../data/training_progress_repository.dart';
import '../domain/training_catalog.dart';
import '../domain/training_progress_rules.dart';
import 'training_attempt_input.dart';
import 'training_completion_result.dart';

typedef TrainingClock = DateTime Function();

class TrainingCompletionService {
  const TrainingCompletionService({
    required TrainingProgressRepository repository,
    required TrainingClock clock,
  }) : _repository = repository,
       _clock = clock;

  final TrainingProgressRepository _repository;
  final TrainingClock _clock;

  Future<TrainingCompletionResult> complete(TrainingAttemptInput input) async {
    _validateInput(input);
    final activity = trainingActivityById(input.activityId);
    final now = _clock().toUtc();

    return _repository.transaction((transaction) async {
      final duplicate = await transaction.getAttempt(input.attemptId);
      if (duplicate != null) {
        if (duplicate.userId != input.userId ||
            duplicate.activityId != input.activityId) {
          throw StateError(
            'Attempt ID ${input.attemptId} belongs to another completion',
          );
        }
        return _resultForExistingAttempt(
          transaction: transaction,
          attempt: duplicate,
          scoreCategory: trainingActivityById(
            duplicate.activityId,
          ).scoreCategory,
        );
      }

      final previousActivityProgress = await transaction.getActivityProgress(
        input.userId,
        input.activityId,
      );
      final isFirstCompletion = previousActivityProgress == null;
      final xpEarned = calculateCompletionXp(
        activityId: input.activityId,
        isFirstCompletion: isFirstCompletion,
        score: input.score,
      );
      final effectiveCompletedAt = _clampFutureDate(input.completedAt, now);
      final localDate = seoulDateString(effectiveCompletedAt);
      final attempt = TrainingAttemptRecord(
        id: input.attemptId,
        userId: input.userId,
        activityId: input.activityId,
        score: input.score,
        correctAnswers: input.correctAnswers,
        totalQuestions: input.totalQuestions,
        durationMs: input.durationMs,
        xpEarned: xpEarned,
        completedAt: effectiveCompletedAt.toIso8601String(),
        localDate: localDate,
      );

      final wasInserted = await transaction.insertAttempt(attempt);
      if (!wasInserted) {
        final existing = await transaction.getAttempt(input.attemptId);
        if (existing == null) {
          throw StateError(
            'Attempt insertion was ignored without an existing row',
          );
        }
        return _resultForExistingAttempt(
          transaction: transaction,
          attempt: existing,
          scoreCategory: activity.scoreCategory,
        );
      }

      if (activity.scoreCategory case final category?) {
        await transaction.insertLegacyScore(
          userId: input.userId,
          category: category,
          score: input.score!,
          createdAt: effectiveCompletedAt.toIso8601String(),
        );
      }

      final activityProgress = _updatedActivityProgress(
        input: input,
        completedAt: effectiveCompletedAt,
        previous: previousActivityProgress,
      );
      await transaction.upsertActivityProgress(activityProgress);

      final previousUserProgress =
          await transaction.getUserProgress(input.userId) ??
          TrainingUserProgressRecord(
            userId: input.userId,
            totalXp: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastTrainingDate: null,
            updatedAt: now.toIso8601String(),
          );
      final streak = updateTrainingStreak(
        currentStreak: previousUserProgress.currentStreak,
        lastTrainingDate: previousUserProgress.lastTrainingDate,
        completedAt: effectiveCompletedAt,
        now: now,
      );
      final updatedUserProgress = TrainingUserProgressRecord(
        userId: input.userId,
        totalXp: previousUserProgress.totalXp + xpEarned,
        currentStreak: streak.currentStreak,
        longestStreak: math.max(
          previousUserProgress.longestStreak,
          streak.currentStreak,
        ),
        lastTrainingDate: streak.trainingDate,
        updatedAt: now.toIso8601String(),
      );
      await transaction.upsertUserProgress(updatedUserProgress);

      final newlyUnlocked = <String>{};
      for (final candidate in trainingCatalog) {
        if (candidate.prerequisiteId != input.activityId) {
          continue;
        }
        final inserted = await transaction.insertUnlock(
          userId: input.userId,
          activityId: candidate.id,
          unlockedAt: effectiveCompletedAt.toIso8601String(),
          source: 'prerequisite',
        );
        if (inserted) {
          newlyUnlocked.add(candidate.id);
        }
      }

      final todayDistinct = await transaction.getDistinctCompletedActivityCount(
        input.userId,
        localDate,
      );
      return TrainingCompletionResult(
        attempt: attempt,
        totalXp: updatedUserProgress.totalXp,
        level: levelForTotalXp(updatedUserProgress.totalXp),
        currentStreak: updatedUserProgress.currentStreak,
        longestStreak: updatedUserProgress.longestStreak,
        masteryStars: activityProgress.masteryStars,
        completionCount: activityProgress.completionCount,
        bestScore: activityProgress.bestScore,
        todayDistinctActivityCount: todayDistinct,
        newlyUnlockedActivityIds: Set.unmodifiable(newlyUnlocked),
        isDuplicate: false,
        scoreCategory: activity.scoreCategory,
      );
    });
  }

  Future<TrainingCompletionResult> _resultForExistingAttempt({
    required TrainingProgressTransaction transaction,
    required TrainingAttemptRecord attempt,
    required String? scoreCategory,
  }) async {
    final userProgress = await transaction.getUserProgress(attempt.userId);
    if (userProgress == null) {
      throw StateError(
        'Progress is missing for completed attempt ${attempt.id}',
      );
    }
    final activityProgress = await transaction.getActivityProgress(
      attempt.userId,
      attempt.activityId,
    );
    final todayDistinct = await transaction.getDistinctCompletedActivityCount(
      attempt.userId,
      attempt.localDate,
    );
    return TrainingCompletionResult(
      attempt: attempt,
      totalXp: userProgress.totalXp,
      level: levelForTotalXp(userProgress.totalXp),
      currentStreak: userProgress.currentStreak,
      longestStreak: userProgress.longestStreak,
      masteryStars: activityProgress?.masteryStars ?? 0,
      completionCount: activityProgress?.completionCount ?? 0,
      bestScore: activityProgress?.bestScore,
      todayDistinctActivityCount: todayDistinct,
      newlyUnlockedActivityIds: const {},
      isDuplicate: true,
      scoreCategory: scoreCategory,
    );
  }
}

TrainingActivityProgressRecord _updatedActivityProgress({
  required TrainingAttemptInput input,
  required DateTime completedAt,
  required TrainingActivityProgressRecord? previous,
}) {
  final score = input.score;
  final bestScore = score == null
      ? previous?.bestScore
      : math.max(previous?.bestScore ?? score, score);
  final masteryStars = score == null
      ? previous?.masteryStars ?? 0
      : updatedMasteryStars(
          previousStars: previous?.masteryStars ?? 0,
          score: score,
        );
  return TrainingActivityProgressRecord(
    userId: input.userId,
    activityId: input.activityId,
    bestScore: bestScore,
    masteryStars: masteryStars,
    completionCount: (previous?.completionCount ?? 0) + 1,
    firstCompletedAt:
        previous?.firstCompletedAt ?? completedAt.toIso8601String(),
    lastCompletedAt: completedAt.toIso8601String(),
  );
}

DateTime _clampFutureDate(DateTime completedAt, DateTime now) {
  final normalized = completedAt.toUtc();
  return seoulDateString(normalized).compareTo(seoulDateString(now)) > 0
      ? now
      : normalized;
}

void _validateInput(TrainingAttemptInput input) {
  if (input.attemptId.trim().isEmpty) {
    throw ArgumentError.value(
      input.attemptId,
      'attemptId',
      'Must not be empty',
    );
  }
  if (input.userId <= 0) {
    throw RangeError.range(input.userId, 1, null, 'userId');
  }
  if (input.durationMs case final duration? when duration < 0) {
    throw RangeError.range(duration, 0, null, 'durationMs');
  }
  final correct = input.correctAnswers;
  final total = input.totalQuestions;
  if ((correct == null) != (total == null)) {
    throw ArgumentError('correctAnswers and totalQuestions must be paired');
  }
  if (correct != null && (correct < 0 || total! <= 0 || correct > total)) {
    throw ArgumentError('Question counts must satisfy 0 <= correct <= total');
  }
}
