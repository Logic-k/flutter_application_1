import 'package:flutter_application_1/core/database_helper.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqliteTrainingProgressRepository implements TrainingProgressRepository {
  const SqliteTrainingProgressRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<TrainingAttemptRecord?> getAttempt(String attemptId) async {
    final db = await _databaseHelper.database;
    return _SqliteTrainingProgressTransaction(db).getAttempt(attemptId);
  }

  @override
  Future<List<TrainingAttemptRecord>> getAttempts(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'training_attempts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at ASC, id ASC',
    );
    return rows.map(_attemptFromRow).toList(growable: false);
  }

  @override
  Future<TrainingUserProgressRecord?> getUserProgress(int userId) async {
    final db = await _databaseHelper.database;
    return _SqliteTrainingProgressTransaction(db).getUserProgress(userId);
  }

  @override
  Future<List<TrainingActivityProgressRecord>> getActivityProgress(
    int userId,
  ) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'training_activity_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'activity_id ASC',
    );
    return rows.map(_activityProgressFromRow).toList(growable: false);
  }

  @override
  Future<List<TrainingUnlockRecord>> getUnlocks(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'training_unlocks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'activity_id ASC',
    );
    return rows.map(_unlockFromRow).toList(growable: false);
  }

  @override
  Future<int> getDistinctCompletedActivityCount(
    int userId,
    String localDate,
  ) async {
    final db = await _databaseHelper.database;
    return _SqliteTrainingProgressTransaction(
      db,
    ).getDistinctCompletedActivityCount(userId, localDate);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(TrainingProgressTransaction transaction) action,
  ) async {
    final db = await _databaseHelper.database;
    return db.transaction(
      (transaction) => action(_SqliteTrainingProgressTransaction(transaction)),
    );
  }
}

class _SqliteTrainingProgressTransaction
    implements TrainingProgressTransaction {
  const _SqliteTrainingProgressTransaction(this._db);

  final DatabaseExecutor _db;

  @override
  Future<TrainingAttemptRecord?> getAttempt(String attemptId) async {
    final rows = await _db.query(
      'training_attempts',
      where: 'id = ?',
      whereArgs: [attemptId],
      limit: 1,
    );
    return rows.isEmpty ? null : _attemptFromRow(rows.single);
  }

  @override
  Future<bool> insertAttempt(TrainingAttemptRecord attempt) async {
    if (await getAttempt(attempt.id) != null) {
      return false;
    }
    await _db.insert('training_attempts', {
      'id': attempt.id,
      'user_id': attempt.userId,
      'activity_id': attempt.activityId,
      'score': attempt.score,
      'correct_answers': attempt.correctAnswers,
      'total_questions': attempt.totalQuestions,
      'duration_ms': attempt.durationMs,
      'xp_earned': attempt.xpEarned,
      'completed_at': attempt.completedAt,
      'local_date': attempt.localDate,
    });
    return true;
  }

  @override
  Future<TrainingUserProgressRecord?> getUserProgress(int userId) async {
    final rows = await _db.query(
      'training_user_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : _userProgressFromRow(rows.single);
  }

  @override
  Future<void> upsertUserProgress(TrainingUserProgressRecord progress) async {
    await _db.insert('training_user_progress', {
      'user_id': progress.userId,
      'total_xp': progress.totalXp,
      'current_streak': progress.currentStreak,
      'longest_streak': progress.longestStreak,
      'last_training_date': progress.lastTrainingDate,
      'updated_at': progress.updatedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<TrainingActivityProgressRecord?> getActivityProgress(
    int userId,
    String activityId,
  ) async {
    final rows = await _db.query(
      'training_activity_progress',
      where: 'user_id = ? AND activity_id = ?',
      whereArgs: [userId, activityId],
      limit: 1,
    );
    return rows.isEmpty ? null : _activityProgressFromRow(rows.single);
  }

  @override
  Future<void> upsertActivityProgress(
    TrainingActivityProgressRecord progress,
  ) async {
    await _db.insert('training_activity_progress', {
      'user_id': progress.userId,
      'activity_id': progress.activityId,
      'best_score': progress.bestScore,
      'mastery_stars': progress.masteryStars,
      'completion_count': progress.completionCount,
      'first_completed_at': progress.firstCompletedAt,
      'last_completed_at': progress.lastCompletedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<bool> insertUnlock({
    required int userId,
    required String activityId,
    required String unlockedAt,
    required String source,
  }) async {
    final inserted = await _db.insert('training_unlocks', {
      'user_id': userId,
      'activity_id': activityId,
      'unlocked_at': unlockedAt,
      'source': source,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    return inserted != 0;
  }

  @override
  Future<void> insertLegacyScore({
    required int userId,
    required String category,
    required double score,
    required String createdAt,
  }) async {
    await _db.insert('training_scores', {
      'user_id': userId,
      'category': category,
      'score': score,
      'created_at': createdAt,
    });
  }

  @override
  Future<int> getDistinctCompletedActivityCount(
    int userId,
    String localDate,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT COUNT(DISTINCT activity_id) AS count
      FROM training_attempts
      WHERE user_id = ? AND local_date = ?
      ''',
      [userId, localDate],
    );
    return (rows.single['count'] as num).toInt();
  }
}

TrainingAttemptRecord _attemptFromRow(Map<String, Object?> row) =>
    TrainingAttemptRecord(
      id: row['id'] as String,
      userId: row['user_id'] as int,
      activityId: row['activity_id'] as String,
      score: (row['score'] as num?)?.toDouble(),
      correctAnswers: row['correct_answers'] as int?,
      totalQuestions: row['total_questions'] as int?,
      durationMs: row['duration_ms'] as int?,
      xpEarned: row['xp_earned'] as int,
      completedAt: row['completed_at'] as String,
      localDate: row['local_date'] as String,
    );

TrainingUserProgressRecord _userProgressFromRow(Map<String, Object?> row) =>
    TrainingUserProgressRecord(
      userId: row['user_id'] as int,
      totalXp: row['total_xp'] as int,
      currentStreak: row['current_streak'] as int,
      longestStreak: row['longest_streak'] as int,
      lastTrainingDate: row['last_training_date'] as String?,
      updatedAt: row['updated_at'] as String,
    );

TrainingActivityProgressRecord _activityProgressFromRow(
  Map<String, Object?> row,
) => TrainingActivityProgressRecord(
  userId: row['user_id'] as int,
  activityId: row['activity_id'] as String,
  bestScore: (row['best_score'] as num?)?.toDouble(),
  masteryStars: row['mastery_stars'] as int,
  completionCount: row['completion_count'] as int,
  firstCompletedAt: row['first_completed_at'] as String?,
  lastCompletedAt: row['last_completed_at'] as String?,
);

TrainingUnlockRecord _unlockFromRow(Map<String, Object?> row) =>
    TrainingUnlockRecord(
      userId: row['user_id'] as int,
      activityId: row['activity_id'] as String,
      unlockedAt: row['unlocked_at'] as String,
      source: row['source'] as String,
    );
