import 'package:flutter_application_1/features/training/domain/training_progress_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XP and level rules', () {
    test(
      'characterization: catalog-backed scored completion keeps its formula',
      () {
        expect(
          calculateCompletionXp(
            activityId: 'sequence',
            score: 84,
            isFirstCompletion: false,
          ),
          28,
        );
      },
    );

    test('90-score first completion yields exactly 49 XP', () {
      expect(
        calculateCompletionXp(
          activityId: 'comparison',
          score: 90,
          isFirstCompletion: true,
        ),
        49,
      );
    });

    test('repeat completion omits only the first-completion bonus', () {
      expect(
        calculateCompletionXp(
          activityId: 'comparison',
          score: 90,
          isFirstCompletion: false,
        ),
        29,
      );
      expect(
        calculateCompletionXp(
          activityId: 'daily_recall',
          isFirstCompletion: true,
        ),
        40,
      );
      expect(
        calculateCompletionXp(
          activityId: 'daily_recall',
          isFirstCompletion: false,
        ),
        20,
      );
    });

    test('rounds the score bonus to the nearest integer', () {
      expect(
        calculateCompletionXp(
          activityId: 'comparison',
          score: 94.9,
          isFirstCompletion: false,
        ),
        29,
      );
      expect(
        calculateCompletionXp(
          activityId: 'comparison',
          score: 95,
          isFirstCompletion: false,
        ),
        30,
      );
    });

    test('rejects malformed scores and score/activity mismatches', () {
      for (final score in <double>[-1, 101, double.nan, double.infinity]) {
        expect(
          () => calculateCompletionXp(
            activityId: 'comparison',
            score: score,
            isFirstCompletion: false,
          ),
          throwsRangeError,
        );
      }
      expect(
        () => calculateCompletionXp(
          activityId: 'comparison',
          isFirstCompletion: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateCompletionXp(
          activityId: 'daily_recall',
          score: 80,
          isFirstCompletion: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateCompletionXp(
          activityId: 'unknown',
          score: 80,
          isFirstCompletion: false,
        ),
        throwsArgumentError,
      );
    });

    test('level boundary is 99/100 XP and XP cannot be negative', () {
      expect(levelForTotalXp(0), 1);
      expect(levelForTotalXp(99), 1);
      expect(levelForTotalXp(100), 2);
      expect(levelForTotalXp(999), 10);
      expect(() => levelForTotalXp(-1), throwsRangeError);
    });
  });

  group('mastery rules', () {
    test('uses completion, 70, and 90 thresholds', () {
      expect(masteryStarsForScore(0), 1);
      expect(masteryStarsForScore(69.9), 1);
      expect(masteryStarsForScore(70), 2);
      expect(masteryStarsForScore(89.9), 2);
      expect(masteryStarsForScore(90), 3);
      expect(masteryStarsForScore(100), 3);
    });

    test('preserves the highest mastery and validates inputs', () {
      expect(updatedMasteryStars(previousStars: 3, score: 10), 3);
      expect(updatedMasteryStars(previousStars: 1, score: 70), 2);
      expect(
        () => updatedMasteryStars(previousStars: 4, score: 80),
        throwsRangeError,
      );
      expect(() => masteryStarsForScore(-1), throwsRangeError);
      expect(() => masteryStarsForScore(101), throwsRangeError);
    });
  });

  group('daily distinct completion rule', () {
    test('counts duplicate activities only once', () {
      expect(
        countDistinctDailyActivities(<String>[
          'comparison',
          'comparison',
          'sequence',
          'daily_recall',
        ]),
        3,
      );
    });

    test('rejects unknown activity IDs', () {
      expect(
        () => countDistinctDailyActivities(<String>['comparison', 'unknown']),
        throwsArgumentError,
      );
    });

    test('counts distinct activities only on the requested Seoul date', () {
      final completions = <TrainingActivityCompletion>[
        TrainingActivityCompletion(
          activityId: 'comparison',
          completedAt: DateTime.utc(2026, 7, 22, 14, 59),
        ),
        TrainingActivityCompletion(
          activityId: 'comparison',
          completedAt: DateTime.utc(2026, 7, 22, 15),
        ),
        TrainingActivityCompletion(
          activityId: 'comparison',
          completedAt: DateTime.utc(2026, 7, 22, 16),
        ),
        TrainingActivityCompletion(
          activityId: 'sequence',
          completedAt: DateTime.utc(2026, 7, 23, 1),
        ),
        TrainingActivityCompletion(
          activityId: 'daily_recall',
          completedAt: DateTime.utc(2026, 7, 23, 14, 59),
        ),
        TrainingActivityCompletion(
          activityId: 'multiplication',
          completedAt: DateTime.utc(2026, 7, 23, 15),
        ),
      ];

      expect(
        countDistinctDailyActivitiesForSeoulDate(
          completions: completions,
          date: DateTime.utc(2026, 7, 23, 3),
        ),
        3,
      );
      expect(
        countDistinctDailyActivitiesForSeoulDate(
          completions: completions,
          date: DateTime.utc(2026, 7, 24, 3),
        ),
        1,
      );
    });

    test(
      'date-aware counting rejects unknown IDs before returning a count',
      () {
        expect(
          () => countDistinctDailyActivitiesForSeoulDate(
            completions: <TrainingActivityCompletion>[
              TrainingActivityCompletion(
                activityId: 'comparison',
                completedAt: DateTime.utc(2026, 7, 23),
              ),
              TrainingActivityCompletion(
                activityId: 'malformed',
                completedAt: DateTime.utc(2020),
              ),
            ],
            date: DateTime.utc(2026, 7, 23),
          ),
          throwsArgumentError,
        );
      },
    );
  });

  group('Asia/Seoul streak rule', () {
    final now = DateTime.utc(2026, 7, 23, 3); // 2026-07-23 12:00 KST

    test('starts at one and increments on the next Seoul date', () {
      expect(
        updateTrainingStreak(
          currentStreak: 0,
          lastTrainingDate: null,
          completedAt: DateTime.utc(2026, 7, 22, 16),
          now: now,
        ),
        const TrainingStreakUpdate(
          currentStreak: 1,
          trainingDate: '2026-07-23',
          didChange: true,
        ),
      );
      expect(
        updateTrainingStreak(
          currentStreak: 4,
          lastTrainingDate: '2026-07-22',
          completedAt: DateTime.utc(2026, 7, 22, 16),
          now: now,
        ).currentStreak,
        5,
      );
    });

    test('same-day and older completions do not change the streak', () {
      final sameDay = updateTrainingStreak(
        currentStreak: 4,
        lastTrainingDate: '2026-07-23',
        completedAt: DateTime.utc(2026, 7, 23, 5),
        now: now,
      );
      expect(sameDay.currentStreak, 4);
      expect(sameDay.didChange, isFalse);

      final older = updateTrainingStreak(
        currentStreak: 4,
        lastTrainingDate: '2026-07-23',
        completedAt: DateTime.utc(2026, 7, 21, 5),
        now: now,
      );
      expect(older.currentStreak, 4);
      expect(older.trainingDate, '2026-07-23');
      expect(older.didChange, isFalse);
    });

    test('missed day resets the streak to one', () {
      expect(
        updateTrainingStreak(
          currentStreak: 8,
          lastTrainingDate: '2026-07-20',
          completedAt: DateTime.utc(2026, 7, 23, 2),
          now: now,
        ).currentStreak,
        1,
      );
    });

    test('future completion is clamped to the current Seoul date', () {
      final result = updateTrainingStreak(
        currentStreak: 2,
        lastTrainingDate: '2026-07-22',
        completedAt: DateTime.utc(2030, 1, 1),
        now: now,
      );
      expect(result.currentStreak, 3);
      expect(result.trainingDate, '2026-07-23');
    });

    test('Seoul midnight boundary is used regardless of DateTime zone', () {
      expect(seoulDateString(DateTime.utc(2026, 7, 22, 14, 59)), '2026-07-22');
      expect(seoulDateString(DateTime.utc(2026, 7, 22, 15)), '2026-07-23');
    });

    test('rejects invalid stored state', () {
      expect(
        () => updateTrainingStreak(
          currentStreak: -1,
          lastTrainingDate: null,
          completedAt: now,
          now: now,
        ),
        throwsRangeError,
      );
      expect(
        () => updateTrainingStreak(
          currentStreak: 1,
          lastTrainingDate: '2026/07/22',
          completedAt: now,
          now: now,
        ),
        throwsFormatException,
      );
    });
  });
}
