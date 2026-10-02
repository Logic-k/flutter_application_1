import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_1/core/database_helper.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/features/training/data/sqlite_training_progress_repository.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_application_1/features/training/domain/training_catalog.dart';

// DS-003 데이터 보존 계약 (핸드오프 §3-6·§4.4).
//
// "측정 데이터 초기화"는 대상 사용자의 7개 테이블만 비우고 훈련 진행을 초기 상태로
// 다시 만든다. users·diary_entries·daily_active_users, 다른 사용자의 모든 행,
// SharedPreferences(세션·설정·보호자 토큰)는 그대로 남아야 한다.

const _resetTables = [
  'training_attempts', 'training_activity_progress', 'training_unlocks',
  'training_user_progress', 'training_scores', 'daily_steps', 'health_logs',
];
const _keptTables = ['users', 'diary_entries', 'daily_active_users'];

const _username = 'reset_target';
const _password = 'preservation-fixture-password';

String get _today => DateTime.now().toIso8601String().split('T')[0];

/// 대상 사용자의 행(users는 자기 행, 나머지는 user_id 기준). [others]면 대상 외 전부.
Future<List<Map<String, Object?>>> _rows(
  DatabaseHelper helper,
  String table,
  int userId, {
  bool others = false,
}) async {
  final db = await helper.database;
  final column = table == 'users' ? 'id' : 'user_id';
  return db.query(
    table,
    where: others ? '$column IS NOT ?' : '$column = ?',
    whereArgs: [userId],
    orderBy: 'rowid',
  );
}

/// 10개 테이블 전부에 대상 사용자의 행을 만든다.
Future<int> _seedTarget(DatabaseHelper helper) async {
  final userId = await helper.insertUser({
    'username': _username,
    'password': _password,
    'goal': 'prevention',
    'age': 72,
    'weight': 61.5,
    'has_completed_onboarding': 1,
    'pedometer_enabled': 1,
  });
  await helper.insertScore(userId, 'calculation', 80);
  await helper.insertScore(userId, 'memory', 65);
  await helper.updateDailySteps(userId, 4200, 150.0, 3.1);
  await helper.upsertHealthLog(userId: userId, date: _today, sleepHours: 7.0, dietScore: 2);
  await helper.recordDauIfNeeded(userId);
  await helper.upsertDiary(userId, _today, '오늘은 공원을 한 바퀴 걸었다.');

  const at = '2026-09-28T10:00:00.000+09:00';
  await SqliteTrainingProgressRepository(helper).transaction((t) async {
    await t.insertAttempt(TrainingAttemptRecord(
      id: 'ds003-attempt', userId: userId, activityId: 'comparison', score: 80,
      correctAnswers: 8, totalQuestions: 10, durationMs: 1000, xpEarned: 48,
      completedAt: at, localDate: '2026-09-28',
    ));
    await t.upsertActivityProgress(TrainingActivityProgressRecord(
      userId: userId, activityId: 'comparison', bestScore: 80, masteryStars: 2,
      completionCount: 1, firstCompletedAt: at, lastCompletedAt: at,
    ));
    await t.upsertUserProgress(TrainingUserProgressRecord(
      userId: userId, totalXp: 48, currentStreak: 1, longestStreak: 1,
      lastTrainingDate: '2026-09-28', updatedAt: at,
    ));
    // 선행 과정을 마쳐 새로 열린 활동 — 초기화하면 다시 잠겨야 한다.
    await t.insertUnlock(
      userId: userId, activityId: 'multiplication', unlockedAt: at, source: 'prerequisite',
    );
  });
  return userId;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late int userId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DatabaseHelper.resetForTest();
    helper = DatabaseHelper();
    userId = await _seedTarget(helper);
  });

  tearDown(DatabaseHelper.closeForTest);

  test('초기화는 대상 사용자의 7개 테이블을 비우고 훈련 진행만 초기 상태로 다시 만든다', () async {
    // 지울 행이 실제로 있어야 isEmpty 검증이 의미를 갖는다.
    for (final table in _resetTables) {
      expect(await _rows(helper, table, userId), isNotEmpty, reason: table);
    }
    expect(
      (await _rows(helper, 'training_unlocks', userId)).map((r) => r['activity_id']),
      contains('multiplication'),
    );

    await helper.resetUserMeasurementData(userId);

    for (final table in [
      'training_attempts', 'training_activity_progress', 'training_scores',
      'daily_steps', 'health_logs',
    ]) {
      expect(await _rows(helper, table, userId), isEmpty, reason: table);
    }
    final unlocks = await _rows(helper, 'training_unlocks', userId);
    expect(unlocks.map((r) => r['activity_id']).toSet(), initialTrainingActivityIds);
    final progress = await _rows(helper, 'training_user_progress', userId);
    expect(progress, hasLength(1));
    expect(progress.single['total_xp'], 0);
    expect(progress.single['current_streak'], 0);
    expect(progress.single['longest_streak'], 0);
    expect(progress.single['last_training_date'], isNull);
  });

  test('초기화는 대상 사용자의 계정·일기·접속 기록을 그대로 둔다', () async {
    final before = {
      for (final table in _keptTables) table: await _rows(helper, table, userId),
    };
    for (final table in _keptTables) {
      expect(before[table], isNotEmpty, reason: table);
    }

    await helper.resetUserMeasurementData(userId);

    for (final table in _keptTables) {
      expect(await _rows(helper, table, userId), before[table], reason: table);
    }
    expect(await helper.getUser(_username, _password), isNotNull, reason: '로그인 자격 유지');
  });

  test('초기화는 다른 사용자(debug 시드 계정)의 10개 테이블 행을 하나도 바꾸지 않는다', () async {
    final tables = [..._resetTables, ..._keptTables];
    final before = {
      for (final table in tables) table: await _rows(helper, table, userId, others: true),
    };
    // 시드 계정이 있어야 격리 검증이 의미를 갖는다(점수 240행 등).
    expect(before['users'], isNotEmpty);
    expect(before['training_scores'], isNotEmpty);
    expect(before['daily_steps'], isNotEmpty);
    expect(before['diary_entries'], isNotEmpty);

    await helper.resetUserMeasurementData(userId);

    for (final table in tables) {
      expect(
        await _rows(helper, table, userId, others: true), before[table], reason: table,
      );
    }
  });

  test('UserProvider.resetMeasurementData는 로그인 상태와 SharedPreferences를 그대로 둔다', () async {
    SharedPreferences.setMockInitialValues({
      'font_size': 2,
      'voice_guidance': false,
      'haptic_feedback': true,
      'reduce_motion': true,
      'sound_effects': false,
      'diary_reminder_enabled': true,
      'gemini_api_key': 'not-a-real-gemini-key',
      'hf_token': 'hf-token',
      'guardian_token_$userId': 'a1b2c3d4e5f6a7b8',
    });
    final provider = UserProvider(dbHelper: helper);
    expect(await provider.login(_username, _password), isTrue);

    final prefs = await SharedPreferences.getInstance();
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    expect(before, containsPair('session_token', isA<String>()));

    await provider.resetMeasurementData();

    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    expect(provider.isLoggedIn, isTrue);
    expect(provider.currentUser?['id'], userId);
    expect(await helper.getScoreHistory(userId), isEmpty, reason: '실제로 초기화는 일어났다');
  });
}
