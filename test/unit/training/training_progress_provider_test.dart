import 'dart:async';

import 'package:flutter_application_1/features/training/application/training_attempt_input.dart';
import 'package:flutter_application_1/features/training/application/training_completion_result.dart';
import 'package:flutter_application_1/features/training/application/training_completion_service.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 23, 1);

  group('TrainingProgressProvider', () {
    test('login, logout, A-B-A 전환 시 사용자별 상태만 노출한다', () async {
      final repository = _FakeRepository()
        ..progressByUser[1] = _progress(1, xp: 140, streak: 2)
        ..progressByUser[2] = _progress(2, xp: 45, streak: 1)
        ..unlocksByUser[1] = [_unlock(1, 'multiplication')]
        ..activityByUser[1] = [_activity(1, 'comparison', stars: 2)]
        ..todayByUser[1] = 2
        ..todayByUser[2] = 1;
      final provider = _provider(repository, now);

      await provider.updateUser(1);
      expect(provider.userId, 1);
      expect(provider.totalXp, 140);
      expect(provider.level, 2);
      expect(provider.currentStreak, 2);
      expect(provider.todayDistinctActivityCount, 2);
      expect(provider.isUnlocked('multiplication'), isTrue);
      expect(provider.activityProgressById['comparison']?.masteryStars, 2);

      final logout = provider.updateUser(null);
      expect(provider.userId, isNull);
      expect(provider.totalXp, 0);
      expect(provider.currentStreak, 0);
      expect(provider.todayDistinctActivityCount, 0);
      expect(provider.activityProgressById, isEmpty);
      expect(provider.unlockedActivityIds, isEmpty);
      await logout;

      await provider.updateUser(2);
      expect(provider.totalXp, 45);
      expect(provider.activityProgressById, isEmpty);
      await provider.updateUser(1);
      expect(provider.totalXp, 140);
      expect(provider.activityProgressById, contains('comparison'));
    });

    test('느린 A 로드 결과가 이후 B 상태를 덮어쓰지 않는다', () async {
      final repository = _FakeRepository()
        ..progressByUser[1] = _progress(1, xp: 100, streak: 3)
        ..progressByUser[2] = _progress(2, xp: 250, streak: 5);
      final delayedA = Completer<TrainingUserProgressRecord?>();
      repository.progressLoaders[1] = () => delayedA.future;
      final provider = _provider(repository, now);

      final loadA = provider.updateUser(1);
      await Future<void>.delayed(Duration.zero);
      await provider.updateUser(2);
      expect(provider.userId, 2);
      expect(provider.totalXp, 250);

      delayedA.complete(repository.progressByUser[1]);
      await loadA;
      expect(provider.userId, 2);
      expect(provider.totalXp, 250);
      expect(provider.currentStreak, 5);
    });

    test('로드 실패를 노출하고 refresh 성공 시 오류를 지운다', () async {
      final repository = _FakeRepository()
        ..progressErrors[1] = StateError('load failed');
      final provider = _provider(repository, now);

      await provider.updateUser(1);
      expect(provider.error, isA<StateError>());
      expect(provider.isLoading, isFalse);
      expect(provider.totalXp, 0);

      repository.progressErrors.remove(1);
      repository.progressByUser[1] = _progress(1, xp: 80, streak: 1);
      await provider.refresh();
      expect(provider.error, isNull);
      expect(provider.totalXp, 80);
    });

    test('저장 실패 후 재시도하면 결과를 반환하고 최신 상태를 다시 읽는다', () async {
      final repository = _FakeRepository()
        ..progressByUser[1] = _progress(1, xp: 0, streak: 0);
      var shouldFail = true;
      final service = _FakeCompletionService(
        repository,
        now,
        onComplete: (input) async {
          if (shouldFail) {
            throw StateError('save failed');
          }
          repository.progressByUser[1] = _progress(1, xp: 45, streak: 1);
          repository.todayByUser[1] = 1;
          return _result(input, now);
        },
      );
      final provider = TrainingProgressProvider(
        repository: repository,
        completionService: service,
        clock: () => now,
      );
      await provider.updateUser(1);
      final input = TrainingAttemptInput(
        attemptId: 'attempt-1',
        userId: 1,
        activityId: 'comparison',
        completedAt: now,
        score: 50,
      );

      await expectLater(provider.complete(input), throwsStateError);
      expect(provider.error, isA<StateError>());
      expect(provider.isSaving, isFalse);

      shouldFail = false;
      final result = await provider.complete(input);
      expect(result.totalXp, 45);
      expect(provider.error, isNull);
      expect(provider.totalXp, 45);
      expect(provider.todayDistinctActivityCount, 1);
      expect(provider.isSaving, isFalse);
    });

    test('현재 사용자와 다른 완료 요청은 저장하지 않는다', () async {
      final repository = _FakeRepository();
      final provider = _provider(repository, now);
      await provider.updateUser(1);

      await expectLater(
        provider.complete(
          TrainingAttemptInput(
            attemptId: 'wrong-user',
            userId: 2,
            activityId: 'comparison',
            completedAt: now,
            score: 50,
          ),
        ),
        throwsStateError,
      );
    });
  });
}

TrainingProgressProvider _provider(_FakeRepository repository, DateTime now) {
  return TrainingProgressProvider(
    repository: repository,
    completionService: _FakeCompletionService(repository, now),
    clock: () => now,
  );
}

TrainingUserProgressRecord _progress(
  int userId, {
  required int xp,
  required int streak,
}) {
  return TrainingUserProgressRecord(
    userId: userId,
    totalXp: xp,
    currentStreak: streak,
    longestStreak: streak,
    lastTrainingDate: '2026-07-23',
    updatedAt: '2026-07-23T01:00:00.000Z',
  );
}

TrainingUnlockRecord _unlock(int userId, String activityId) {
  return TrainingUnlockRecord(
    userId: userId,
    activityId: activityId,
    unlockedAt: '2026-07-23T01:00:00.000Z',
    source: 'test',
  );
}

TrainingActivityProgressRecord _activity(
  int userId,
  String activityId, {
  required int stars,
}) {
  return TrainingActivityProgressRecord(
    userId: userId,
    activityId: activityId,
    bestScore: 80,
    masteryStars: stars,
    completionCount: 1,
    firstCompletedAt: '2026-07-23T01:00:00.000Z',
    lastCompletedAt: '2026-07-23T01:00:00.000Z',
  );
}

TrainingCompletionResult _result(TrainingAttemptInput input, DateTime now) {
  return TrainingCompletionResult(
    attempt: TrainingAttemptRecord(
      id: input.attemptId,
      userId: input.userId,
      activityId: input.activityId,
      score: input.score,
      correctAnswers: null,
      totalQuestions: null,
      durationMs: null,
      xpEarned: 45,
      completedAt: now.toIso8601String(),
      localDate: '2026-07-23',
    ),
    totalXp: 45,
    level: 1,
    currentStreak: 1,
    longestStreak: 1,
    masteryStars: 1,
    completionCount: 1,
    bestScore: 50,
    todayDistinctActivityCount: 1,
    newlyUnlockedActivityIds: const {},
    isDuplicate: false,
    scoreCategory: 'calculation',
  );
}

class _FakeCompletionService extends TrainingCompletionService {
  _FakeCompletionService(
    TrainingProgressRepository repository,
    DateTime now, {
    this.onComplete,
  }) : super(repository: repository, clock: () => now);

  final Future<TrainingCompletionResult> Function(TrainingAttemptInput input)?
  onComplete;

  @override
  Future<TrainingCompletionResult> complete(TrainingAttemptInput input) {
    final callback = onComplete;
    if (callback == null) {
      throw UnimplementedError();
    }
    return callback(input);
  }
}

class _FakeRepository implements TrainingProgressRepository {
  final Map<int, TrainingUserProgressRecord> progressByUser = {};
  final Map<int, List<TrainingActivityProgressRecord>> activityByUser = {};
  final Map<int, List<TrainingUnlockRecord>> unlocksByUser = {};
  final Map<int, int> todayByUser = {};
  final Map<int, Object> progressErrors = {};
  final Map<int, Future<TrainingUserProgressRecord?> Function()>
  progressLoaders = {};

  @override
  Future<TrainingUserProgressRecord?> getUserProgress(int userId) {
    final error = progressErrors[userId];
    if (error != null) {
      return Future.error(error);
    }
    final loader = progressLoaders[userId];
    return loader?.call() ?? Future.value(progressByUser[userId]);
  }

  @override
  Future<List<TrainingActivityProgressRecord>> getActivityProgress(int userId) {
    return Future.value(activityByUser[userId] ?? const []);
  }

  @override
  Future<List<TrainingUnlockRecord>> getUnlocks(int userId) {
    return Future.value(unlocksByUser[userId] ?? const []);
  }

  @override
  Future<int> getDistinctCompletedActivityCount(int userId, String localDate) {
    return Future.value(todayByUser[userId] ?? 0);
  }

  @override
  Future<TrainingAttemptRecord?> getAttempt(String attemptId) async => null;

  @override
  Future<List<TrainingAttemptRecord>> getAttempts(int userId) async => const [];

  @override
  Future<T> transaction<T>(
    Future<T> Function(TrainingProgressTransaction transaction) action,
  ) {
    throw UnimplementedError();
  }
}
