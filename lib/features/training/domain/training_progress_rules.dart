import 'dart:math' as math;

import 'training_catalog.dart';

const int completionBaseXp = 20;
const int firstCompletionBonusXp = 20;
const int xpPerLevel = 100;
const int dailyActivityGoal = 3;

int calculateCompletionXp({
  required String activityId,
  required bool isFirstCompletion,
  double? score,
}) {
  final activity = trainingActivityById(activityId);
  final firstCompletionXp = isFirstCompletion ? firstCompletionBonusXp : 0;

  if (activity.isParticipationOnly) {
    if (score != null) {
      throw ArgumentError.value(
        score,
        'score',
        '$activityId does not accept a score',
      );
    }
    return completionBaseXp + firstCompletionXp;
  }

  if (score == null) {
    throw ArgumentError.notNull('score');
  }
  _validateScore(score);
  return completionBaseXp + (score / 10).round() + firstCompletionXp;
}

int levelForTotalXp(int totalXp) {
  if (totalXp < 0) {
    throw RangeError.range(totalXp, 0, null, 'totalXp');
  }
  return (totalXp ~/ xpPerLevel) + 1;
}

int masteryStarsForScore(double score) {
  _validateScore(score);
  if (score >= 90) {
    return 3;
  }
  if (score >= 70) {
    return 2;
  }
  return 1;
}

int updatedMasteryStars({required int previousStars, required double score}) {
  if (previousStars < 0 || previousStars > 3) {
    throw RangeError.range(previousStars, 0, 3, 'previousStars');
  }
  return math.max(previousStars, masteryStarsForScore(score));
}

int countDistinctDailyActivities(Iterable<String> completedActivityIds) {
  final distinctIds = <String>{};
  for (final activityId in completedActivityIds) {
    trainingActivityById(activityId);
    distinctIds.add(activityId);
  }
  return distinctIds.length;
}

class TrainingActivityCompletion {
  const TrainingActivityCompletion({
    required this.activityId,
    required this.completedAt,
  });

  final String activityId;
  final DateTime completedAt;
}

int countDistinctDailyActivitiesForSeoulDate({
  required Iterable<TrainingActivityCompletion> completions,
  required DateTime date,
}) {
  final completionList = completions.toList(growable: false);
  for (final completion in completionList) {
    trainingActivityById(completion.activityId);
  }

  final requestedDate = seoulDateString(date);
  return countDistinctDailyActivities(
    completionList
        .where(
          (completion) =>
              seoulDateString(completion.completedAt) == requestedDate,
        )
        .map((completion) => completion.activityId),
  );
}

String seoulDateString(DateTime timestamp) {
  final seoulTime = timestamp.toUtc().add(const Duration(hours: 9));
  return '${seoulTime.year.toString().padLeft(4, '0')}-'
      '${seoulTime.month.toString().padLeft(2, '0')}-'
      '${seoulTime.day.toString().padLeft(2, '0')}';
}

TrainingStreakUpdate updateTrainingStreak({
  required int currentStreak,
  required String? lastTrainingDate,
  required DateTime completedAt,
  required DateTime now,
}) {
  if (currentStreak < 0) {
    throw RangeError.range(currentStreak, 0, null, 'currentStreak');
  }

  final today = _parseDate(seoulDateString(now));
  final rawCompletionDate = _parseDate(seoulDateString(completedAt));
  final completionDate = rawCompletionDate.isAfter(today)
      ? today
      : rawCompletionDate;

  if (lastTrainingDate == null) {
    return TrainingStreakUpdate(
      currentStreak: 1,
      trainingDate: _formatDate(completionDate),
      didChange: true,
    );
  }

  final lastDate = _parseDate(lastTrainingDate);
  if (!completionDate.isAfter(lastDate)) {
    return TrainingStreakUpdate(
      currentStreak: currentStreak,
      trainingDate: _formatDate(lastDate),
      didChange: false,
    );
  }

  final isConsecutiveDay = completionDate.difference(lastDate).inDays == 1;
  return TrainingStreakUpdate(
    currentStreak: isConsecutiveDay ? currentStreak + 1 : 1,
    trainingDate: _formatDate(completionDate),
    didChange: true,
  );
}

class TrainingStreakUpdate {
  const TrainingStreakUpdate({
    required this.currentStreak,
    required this.trainingDate,
    required this.didChange,
  });

  final int currentStreak;
  final String trainingDate;
  final bool didChange;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingStreakUpdate &&
          currentStreak == other.currentStreak &&
          trainingDate == other.trainingDate &&
          didChange == other.didChange;

  @override
  int get hashCode => Object.hash(currentStreak, trainingDate, didChange);
}

void _validateScore(double score) {
  if (!score.isFinite || score < 0 || score > 100) {
    throw RangeError.range(score, 0, 100, 'score');
  }
}

DateTime _parseDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw FormatException('Expected an ISO local date (yyyy-MM-dd)', value);
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  if (_formatDate(date) != value) {
    throw FormatException('Invalid calendar date', value);
  }
  return date;
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
