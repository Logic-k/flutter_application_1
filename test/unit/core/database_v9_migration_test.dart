import 'dart:io';

import 'package:flutter_application_1/core/database_helper.dart';
import 'package:flutter_application_1/features/training/data/sqlite_training_progress_repository.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _allActivityIds = <String>[
  'comparison',
  'multiplication',
  'sequence',
  'categorization',
  'shape_sudoku',
  'shape_match',
  'sentence_reading',
  'daily_recall',
];

const _initialActivityIds = <String>[
  'comparison',
  'sequence',
  'shape_sudoku',
  'shape_match',
  'daily_recall',
];

void main() {
  late Directory tempDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper.closeForTest();
    tempDirectory = await Directory.systemTemp.createTemp('memorylink-db-v9-');
  });

  tearDown(() async {
    await DatabaseHelper.closeForTest();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('fresh v9 database creates training schema and indexes', () async {
    // Given
    final path = p.join(tempDirectory.path, 'fresh.db');
    DatabaseHelper.pathOverride = path;

    // When
    final db = await DatabaseHelper().database;

    // Then
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'training_%'",
    );
    expect(
      tables.map((row) => row['name']),
      containsAll(<String>[
        'training_scores',
        'training_attempts',
        'training_user_progress',
        'training_activity_progress',
        'training_unlocks',
      ]),
    );
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    expect(
      indexes.map((row) => row['name']),
      containsAll(<String>[
        'idx_training_attempts_user_date',
        'idx_training_attempts_user_activity_completed',
      ]),
    );
    expect(
      (await db.rawQuery('PRAGMA foreign_keys')).single['foreign_keys'],
      1,
    );
  });

  test(
    'file-backed v8 upgrade preserves scores and unlocks all activities',
    () async {
      // Given
      final path = p.join(tempDirectory.path, 'upgrade.db');
      final oldDb = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 8,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT UNIQUE
            )
          ''');
            await db.execute('''
            CREATE TABLE training_scores (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              category TEXT,
              score REAL,
              created_at TEXT
            )
          ''');
            await db.insert('users', {'id': 41, 'username': 'legacy'});
            await db.insert('training_scores', {
              'user_id': 41,
              'category': 'memory',
              'score': 88.0,
              'created_at': '2026-07-22T10:00:00.000',
            });
          },
        ),
      );
      await oldDb.close();
      DatabaseHelper.pathOverride = path;

      // When
      final db = await DatabaseHelper().database;

      // Then
      expect(
        (await db.rawQuery('PRAGMA user_version')).single['user_version'],
        9,
      );
      expect(
        (await db.query(
          'training_scores',
          where: 'user_id = 41',
        )).single['score'],
        88.0,
      );
      final progress = await db.query(
        'training_user_progress',
        where: 'user_id = ?',
        whereArgs: [41],
      );
      expect(progress, hasLength(1));
      final unlocks = await db.query(
        'training_unlocks',
        columns: ['activity_id'],
        where: 'user_id = ?',
        whereArgs: [41],
        orderBy: 'activity_id',
      );
      expect(
        unlocks.map((row) => row['activity_id']).toSet(),
        _allActivityIds.toSet(),
      );
    },
  );

  test('new user gets progress and initial unlocks atomically', () async {
    // Given
    DatabaseHelper.pathOverride = p.join(tempDirectory.path, 'new-user.db');
    final helper = DatabaseHelper();

    // When
    final userId = await helper.insertUser({
      'username': 'new-user',
      'password': 'secret',
    }, initialUnlockActivityIds: _initialActivityIds);
    final repository = SqliteTrainingProgressRepository(helper);

    // Then
    expect(await repository.getUserProgress(userId), isNotNull);
    expect(
      (await repository.getUnlocks(
        userId,
      )).map((unlock) => unlock.activityId).toSet(),
      _initialActivityIds.toSet(),
    );
  });

  test(
    'repository isolates accounts and ignores duplicate unlock and attempt',
    () async {
      // Given
      DatabaseHelper.pathOverride = p.join(tempDirectory.path, 'isolation.db');
      final helper = DatabaseHelper();
      final firstUser = await helper.insertUser({
        'username': 'first',
        'password': 'secret',
      }, initialUnlockActivityIds: _initialActivityIds);
      final secondUser = await helper.insertUser({
        'username': 'second',
        'password': 'secret',
      }, initialUnlockActivityIds: _initialActivityIds);
      final repository = SqliteTrainingProgressRepository(helper);
      const attempt = TrainingAttemptRecord(
        id: 'attempt-1',
        userId: 0,
        activityId: 'comparison',
        score: 90,
        correctAnswers: 9,
        totalQuestions: 10,
        durationMs: 1200,
        xpEarned: 49,
        completedAt: '2026-07-23T10:00:00.000+09:00',
        localDate: '2026-07-23',
      );

      // When
      await repository.transaction((transaction) async {
        await transaction.insertUnlock(
          userId: firstUser,
          activityId: 'multiplication',
          unlockedAt: '2026-07-23T10:00:00.000+09:00',
          source: 'mastery',
        );
        await transaction.insertUnlock(
          userId: firstUser,
          activityId: 'multiplication',
          unlockedAt: '2026-07-23T10:00:00.000+09:00',
          source: 'mastery',
        );
        expect(
          await transaction.insertAttempt(attempt.copyWith(userId: firstUser)),
          isTrue,
        );
        expect(
          await transaction.insertAttempt(attempt.copyWith(userId: firstUser)),
          isFalse,
        );
      });

      // Then
      expect(await repository.getAttempts(firstUser), hasLength(1));
      expect(await repository.getAttempts(secondUser), isEmpty);
      final firstUnlocks = await repository.getUnlocks(firstUser);
      expect(
        firstUnlocks.where((unlock) => unlock.activityId == 'multiplication'),
        hasLength(1),
      );
      expect(
        (await repository.getUnlocks(
          secondUser,
        )).where((unlock) => unlock.activityId == 'multiplication'),
        isEmpty,
      );
    },
  );

  test('constraints and thrown transactions leave no partial writes', () async {
    // Given
    DatabaseHelper.pathOverride = p.join(tempDirectory.path, 'rollback.db');
    final helper = DatabaseHelper();
    final userId = await helper.insertUser({
      'username': 'rollback',
      'password': 'secret',
    }, initialUnlockActivityIds: _initialActivityIds);
    final repository = SqliteTrainingProgressRepository(helper);
    final invalidAttempt = TrainingAttemptRecord(
      id: 'invalid',
      userId: userId,
      activityId: 'comparison',
      score: 101,
      correctAnswers: 1,
      totalQuestions: 1,
      durationMs: -1,
      xpEarned: 20,
      completedAt: '2026-07-23T10:00:00.000+09:00',
      localDate: '2026-07-23',
    );

    // When / Then
    await expectLater(
      repository.transaction((transaction) async {
        await transaction.insertUnlock(
          userId: userId,
          activityId: 'multiplication',
          unlockedAt: '2026-07-23T10:00:00.000+09:00',
          source: 'mastery',
        );
        await transaction.insertAttempt(invalidAttempt);
      }),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repository.getAttempts(userId), isEmpty);
    expect(
      (await repository.getUnlocks(
        userId,
      )).where((unlock) => unlock.activityId == 'multiplication'),
      isEmpty,
    );
  });

  test('foreign keys reject attempts for missing users', () async {
    // Given
    DatabaseHelper.pathOverride = p.join(tempDirectory.path, 'foreign-key.db');
    final helper = DatabaseHelper();
    final repository = SqliteTrainingProgressRepository(helper);

    // When / Then
    await expectLater(
      repository.transaction(
        (transaction) => transaction.insertAttempt(
          const TrainingAttemptRecord(
            id: 'orphan',
            userId: 999999,
            activityId: 'comparison',
            score: 80,
            correctAnswers: 8,
            totalQuestions: 10,
            durationMs: 1000,
            xpEarned: 48,
            completedAt: '2026-07-23T10:00:00.000+09:00',
            localDate: '2026-07-23',
          ),
        ),
      ),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repository.getAttempts(999999), isEmpty);
  });

  test(
    'reset deletes gamification rows and restores initial unlocks',
    () async {
      // Given
      DatabaseHelper.pathOverride = p.join(tempDirectory.path, 'reset.db');
      final helper = DatabaseHelper();
      final userId = await helper.insertUser({
        'username': 'reset',
        'password': 'secret',
      }, initialUnlockActivityIds: _initialActivityIds);
      final repository = SqliteTrainingProgressRepository(helper);
      await repository.transaction((transaction) async {
        await transaction.insertAttempt(
          TrainingAttemptRecord(
            id: 'reset-attempt',
            userId: userId,
            activityId: 'comparison',
            score: 80,
            correctAnswers: 8,
            totalQuestions: 10,
            durationMs: 1000,
            xpEarned: 48,
            completedAt: '2026-07-23T10:00:00.000+09:00',
            localDate: '2026-07-23',
          ),
        );
        await transaction.upsertActivityProgress(
          TrainingActivityProgressRecord(
            userId: userId,
            activityId: 'comparison',
            bestScore: 80,
            masteryStars: 2,
            completionCount: 1,
            firstCompletedAt: '2026-07-23T10:00:00.000+09:00',
            lastCompletedAt: '2026-07-23T10:00:00.000+09:00',
          ),
        );
      });
      await helper.insertScore(userId, 'calculation', 80);

      // When
      await helper.resetUserMeasurementData(
        userId,
        initialUnlockActivityIds: _initialActivityIds,
      );

      // Then
      expect(await repository.getAttempts(userId), isEmpty);
      expect(await repository.getActivityProgress(userId), isEmpty);
      expect(await helper.getScoreHistory(userId), isEmpty);
      final progress = await repository.getUserProgress(userId);
      expect(progress?.totalXp, 0);
      expect(progress?.currentStreak, 0);
      expect(
        (await repository.getUnlocks(
          userId,
        )).map((unlock) => unlock.activityId).toSet(),
        _initialActivityIds.toSet(),
      );
    },
  );
}
