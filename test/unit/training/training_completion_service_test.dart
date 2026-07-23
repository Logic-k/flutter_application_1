import 'package:flutter_application_1/features/training/application/training_attempt_input.dart';
import 'package:flutter_application_1/features/training/application/training_completion_service.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingCompletionService', () {
    late _FakeTrainingProgressRepository repository;
    late TrainingCompletionService service;
    final now = DateTime.utc(2026, 7, 23, 3);

    setUp(() {
      repository = _FakeTrainingProgressRepository();
      repository.progress[1] = const TrainingUserProgressRecord(
        userId: 1,
        totalXp: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastTrainingDate: null,
        updatedAt: '2026-07-22T00:00:00.000Z',
      );
      service = TrainingCompletionService(
        repository: repository,
        clock: () => now,
      );
    });

    test('90점 최초 완료를 한 트랜잭션으로 반영한다', () async {
      // Given
      final input = _scoredAttempt(
        id: 'attempt-1',
        activityId: 'comparison',
        completedAt: now,
        score: 90,
      );

      // When
      final result = await service.complete(input);

      // Then
      expect(result.attempt.xpEarned, 49);
      expect(result.totalXp, 49);
      expect(result.level, 1);
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.masteryStars, 3);
      expect(result.completionCount, 1);
      expect(result.bestScore, 90);
      expect(result.todayDistinctActivityCount, 1);
      expect(result.newlyUnlockedActivityIds, {'multiplication'});
      expect(result.scoreCategory, 'calculation');
      expect(repository.legacyScores.single.score, 90);
      expect(repository.transactionCount, 1);
    });

    test('같은 attempt ID 재전송은 쓰기와 XP를 반복하지 않는다', () async {
      // Given
      final input = _scoredAttempt(
        id: 'attempt-duplicate',
        activityId: 'comparison',
        completedAt: now,
        score: 90,
      );
      final original = await service.complete(input);
      final snapshot = repository.snapshot();

      // When
      final duplicate = await service.complete(input);

      // Then
      expect(duplicate.isDuplicate, isTrue);
      expect(duplicate.attempt.xpEarned, original.attempt.xpEarned);
      expect(repository.snapshot(), snapshot);
    });

    test('재도전은 최초 보너스 없이 최고 점수와 완료 횟수만 높인다', () async {
      // Given
      await service.complete(
        _scoredAttempt(
          id: 'attempt-first',
          activityId: 'sequence',
          completedAt: now,
          score: 70,
        ),
      );

      // When
      final result = await service.complete(
        _scoredAttempt(
          id: 'attempt-retry',
          activityId: 'sequence',
          completedAt: now.add(const Duration(minutes: 2)),
          score: 60,
        ),
      );

      // Then
      expect(result.attempt.xpEarned, 26);
      expect(result.totalXp, 73);
      expect(result.masteryStars, 2);
      expect(result.bestScore, 70);
      expect(result.completionCount, 2);
      expect(result.todayDistinctActivityCount, 1);
      expect(result.newlyUnlockedActivityIds, isEmpty);
    });

    test('일상 회상은 XP와 일일 목표만 기록한다', () async {
      // Given
      final input = TrainingAttemptInput(
        attemptId: 'recall-1',
        userId: 1,
        activityId: 'daily_recall',
        completedAt: now,
        durationMs: 5000,
      );

      // When
      final result = await service.complete(input);

      // Then
      expect(result.attempt.score, isNull);
      expect(result.attempt.xpEarned, 40);
      expect(result.masteryStars, 0);
      expect(result.completionCount, 1);
      expect(result.bestScore, isNull);
      expect(result.todayDistinctActivityCount, 1);
      expect(result.scoreCategory, isNull);
      expect(repository.activityProgress.values.single.masteryStars, 0);
      expect(repository.activityProgress.values.single.bestScore, isNull);
      expect(repository.legacyScores, isEmpty);
    });

    test('일상 회상 재참여에는 최초 완료 보너스를 다시 주지 않는다', () async {
      // Given
      await service.complete(
        TrainingAttemptInput(
          attemptId: 'recall-first',
          userId: 1,
          activityId: 'daily_recall',
          completedAt: now,
        ),
      );

      // When
      final result = await service.complete(
        TrainingAttemptInput(
          attemptId: 'recall-second',
          userId: 1,
          activityId: 'daily_recall',
          completedAt: now.add(const Duration(minutes: 5)),
        ),
      );

      // Then
      expect(result.attempt.xpEarned, 20);
      expect(result.totalXp, 60);
      expect(result.completionCount, 2);
      expect(result.todayDistinctActivityCount, 1);
    });

    test('다른 사용자와 충돌한 attempt ID는 기존 결과를 노출하지 않는다', () async {
      // Given
      await service.complete(
        _scoredAttempt(
          id: 'shared-attempt',
          activityId: 'comparison',
          completedAt: now,
          score: 90,
        ),
      );
      final snapshot = repository.snapshot();

      // When
      final future = service.complete(
        TrainingAttemptInput(
          attemptId: 'shared-attempt',
          userId: 2,
          activityId: 'comparison',
          completedAt: now,
          score: 90,
        ),
      );

      // Then
      await expectLater(future, throwsA(isA<StateError>()));
      expect(repository.snapshot(), snapshot);
    });

    test('전날 다음 날의 첫 완료에서 streak를 올린다', () async {
      // Given
      repository.progress[1] = const TrainingUserProgressRecord(
        userId: 1,
        totalXp: 80,
        currentStreak: 4,
        longestStreak: 6,
        lastTrainingDate: '2026-07-22',
        updatedAt: '2026-07-22T00:00:00.000Z',
      );

      // When
      final result = await service.complete(
        _scoredAttempt(
          id: 'attempt-streak',
          activityId: 'shape_match',
          completedAt: now,
          score: 50,
        ),
      );

      // Then
      expect(result.currentStreak, 5);
      expect(result.longestStreak, 6);
      expect(result.level, 2);
    });

    test('미래 날짜는 현재 서울 날짜로 제한한다', () async {
      // Given
      final future = now.add(const Duration(days: 3));

      // When
      final result = await service.complete(
        _scoredAttempt(
          id: 'attempt-future',
          activityId: 'shape_sudoku',
          completedAt: future,
          score: 50,
        ),
      );

      // Then
      expect(result.attempt.localDate, '2026-07-23');
      expect(result.attempt.completedAt, now.toIso8601String());
    });

    test('트랜잭션 중 예외가 발생하면 어떤 변경도 남기지 않는다', () async {
      // Given
      repository.failOnLegacyScore = true;
      final snapshot = repository.snapshot();

      // When
      final future = service.complete(
        _scoredAttempt(
          id: 'attempt-failure',
          activityId: 'comparison',
          completedAt: now,
          score: 90,
        ),
      );

      // Then
      await expectLater(future, throwsA(isA<StateError>()));
      expect(repository.snapshot(), snapshot);
    });
  });
}

TrainingAttemptInput _scoredAttempt({
  required String id,
  required String activityId,
  required DateTime completedAt,
  required double score,
}) => TrainingAttemptInput(
  attemptId: id,
  userId: 1,
  activityId: activityId,
  completedAt: completedAt,
  score: score,
  correctAnswers: score ~/ 10,
  totalQuestions: 10,
  durationMs: 1000,
);

class _LegacyScore {
  const _LegacyScore(this.userId, this.category, this.score, this.createdAt);

  final int userId;
  final String category;
  final double score;
  final String createdAt;

  @override
  String toString() => '$userId:$category:$score:$createdAt';
}

class _FakeTrainingProgressRepository implements TrainingProgressRepository {
  Map<String, TrainingAttemptRecord> attempts = {};
  Map<int, TrainingUserProgressRecord> progress = {};
  Map<String, TrainingActivityProgressRecord> activityProgress = {};
  Set<String> unlocks = {};
  List<_LegacyScore> legacyScores = [];
  bool failOnLegacyScore = false;
  int transactionCount = 0;

  String snapshot() =>
      '${attempts.keys.toList()};'
      '${progress.values.map((value) => '${value.userId}:${value.totalXp}:${value.currentStreak}:${value.longestStreak}:${value.lastTrainingDate}').toList()};'
      '${activityProgress.values.map((value) => '${value.userId}:${value.activityId}:${value.bestScore}:${value.masteryStars}:${value.completionCount}').toList()};'
      '$unlocks;'
      '$legacyScores';

  @override
  Future<TrainingAttemptRecord?> getAttempt(String attemptId) async =>
      attempts[attemptId];

  @override
  Future<List<TrainingAttemptRecord>> getAttempts(int userId) async =>
      attempts.values.where((attempt) => attempt.userId == userId).toList();

  @override
  Future<List<TrainingActivityProgressRecord>> getActivityProgress(
    int userId,
  ) async =>
      activityProgress.values.where((item) => item.userId == userId).toList();

  @override
  Future<int> getDistinctCompletedActivityCount(
    int userId,
    String localDate,
  ) async => attempts.values
      .where(
        (attempt) => attempt.userId == userId && attempt.localDate == localDate,
      )
      .map((attempt) => attempt.activityId)
      .toSet()
      .length;

  @override
  Future<List<TrainingUnlockRecord>> getUnlocks(int userId) async =>
      unlocks.where((key) => key.startsWith('$userId:')).map((key) {
        final activityId = key.split(':').last;
        return TrainingUnlockRecord(
          userId: userId,
          activityId: activityId,
          unlockedAt: '2026-07-23T03:00:00.000Z',
          source: 'prerequisite',
        );
      }).toList();

  @override
  Future<TrainingUserProgressRecord?> getUserProgress(int userId) async =>
      progress[userId];

  @override
  Future<T> transaction<T>(
    Future<T> Function(TrainingProgressTransaction transaction) action,
  ) async {
    transactionCount++;
    final staged = _FakeTrainingProgressRepository()
      ..attempts = Map.of(attempts)
      ..progress = Map.of(progress)
      ..activityProgress = Map.of(activityProgress)
      ..unlocks = Set.of(unlocks)
      ..legacyScores = List.of(legacyScores)
      ..failOnLegacyScore = failOnLegacyScore;
    final result = await action(_FakeTransaction(staged));
    attempts = staged.attempts;
    progress = staged.progress;
    activityProgress = staged.activityProgress;
    unlocks = staged.unlocks;
    legacyScores = staged.legacyScores;
    return result;
  }
}

class _FakeTransaction implements TrainingProgressTransaction {
  const _FakeTransaction(this.repository);

  final _FakeTrainingProgressRepository repository;

  @override
  Future<TrainingActivityProgressRecord?> getActivityProgress(
    int userId,
    String activityId,
  ) async => repository.activityProgress['$userId:$activityId'];

  @override
  Future<TrainingAttemptRecord?> getAttempt(String attemptId) async =>
      repository.attempts[attemptId];

  @override
  Future<int> getDistinctCompletedActivityCount(int userId, String localDate) =>
      repository.getDistinctCompletedActivityCount(userId, localDate);

  @override
  Future<TrainingUserProgressRecord?> getUserProgress(int userId) async =>
      repository.progress[userId];

  @override
  Future<bool> insertAttempt(TrainingAttemptRecord attempt) async {
    if (repository.attempts.containsKey(attempt.id)) {
      return false;
    }
    repository.attempts[attempt.id] = attempt;
    return true;
  }

  @override
  Future<void> insertLegacyScore({
    required int userId,
    required String category,
    required double score,
    required String createdAt,
  }) async {
    if (repository.failOnLegacyScore) {
      throw StateError('forced legacy score failure');
    }
    repository.legacyScores.add(
      _LegacyScore(userId, category, score, createdAt),
    );
  }

  @override
  Future<bool> insertUnlock({
    required int userId,
    required String activityId,
    required String unlockedAt,
    required String source,
  }) async => repository.unlocks.add('$userId:$activityId');

  @override
  Future<void> upsertActivityProgress(
    TrainingActivityProgressRecord progress,
  ) async {
    repository.activityProgress['${progress.userId}:${progress.activityId}'] =
        progress;
  }

  @override
  Future<void> upsertUserProgress(TrainingUserProgressRecord progress) async {
    repository.progress[progress.userId] = progress;
  }
}
