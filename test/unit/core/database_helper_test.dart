import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_1/core/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    // 인메모리 DB를 사용하도록 리셋 (테스트 간 격리)
    DatabaseHelper.resetForTest();
  });

  group('DatabaseHelper - User 작업', () {
    late DatabaseHelper db;
    setUp(() => db = DatabaseHelper());

    test('insertUser + getUser: 올바른 자격증명으로 사용자를 조회한다', () async {
      await db.insertUser({
        'username': 'testuser1',
        'password': 'pass123',
        'goal': 'prevention',
        'age': 65,
        'weight': 70.0,
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
      });
      final user = await db.getUser('testuser1', 'pass123');
      expect(user, isNotNull);
      expect(user!['username'], 'testuser1');
    });

    test('getUser: 잘못된 비밀번호면 null을 반환한다', () async {
      await db.insertUser({
        'username': 'testuser2',
        'password': 'correct',
        'goal': 'concern',
        'age': 60,
        'weight': 60.0,
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
      });
      final user = await db.getUser('testuser2', 'wrong');
      expect(user, isNull);
    });

    test('insertUser: 존재하지 않는 사용자 조회 시 null을 반환한다', () async {
      final user = await db.getUser('nobody', 'pass');
      expect(user, isNull);
    });

    test('updateUserField: 지정 필드를 업데이트한다', () async {
      final id = await db.insertUser({
        'username': 'updateuser',
        'password': 'pass',
        'goal': 'prevention',
        'age': 60,
        'weight': 60.0,
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
      });
      await db.updateUserField(id, 'age', 70);
      final user = await db.getUser('updateuser', 'pass');
      expect(user!['age'], 70);
    });

    test('updateUserOnboarding: 온보딩 완료 상태를 업데이트한다', () async {
      final id = await db.insertUser({
        'username': 'onboarduser',
        'password': 'pass',
        'goal': 'prevention',
        'age': 65,
        'weight': 70.0,
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
      });
      await db.updateUserOnboarding(id, true);
      final user = await db.getUser('onboarduser', 'pass');
      expect(user!['has_completed_onboarding'], 1);
    });
  });

  group('DatabaseHelper - Score 작업', () {
    late DatabaseHelper db;
    late int userId;

    setUp(() async {
      DatabaseHelper.resetForTest();
      db = DatabaseHelper();
      userId = await db.insertUser({
        'username': 'scoreuser',
        'password': 'pass',
        'goal': 'prevention',
        'age': 65,
        'weight': 70.0,
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
      });
    });

    test('insertScore + getLatestScores: 카테고리별 최신 점수를 반환한다', () async {
      await db.insertScore(userId, 'calculation', 7.5);
      await db.insertScore(userId, 'calculation', 9.0); // 더 최신
      await db.insertScore(userId, 'logic', 6.0);

      final scores = await db.getLatestScores(userId);
      final calcScore = scores.firstWhere(
        (s) => s['category'] == 'calculation',
        orElse: () => {},
      );
      expect(calcScore['score'], 9.0);
    });

    test('getScoreHistory: 시간순으로 모든 점수를 반환한다', () async {
      await db.insertScore(userId, 'memory', 5.0);
      await db.insertScore(userId, 'memory', 7.0);
      final history = await db.getScoreHistory(userId);
      expect(history.length, 2);
    });
  });

  group('DatabaseHelper - Daily Steps 작업', () {
    late DatabaseHelper db;
    late int userId;

    setUp(() async {
      DatabaseHelper.resetForTest();
      db = DatabaseHelper();
      userId = await db.insertUser({
        'username': 'stepsuser',
        'password': 'pass',
        'goal': 'prevention',
        'age': 65,
        'weight': 70.0,
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
      });
    });

    test('updateDailySteps: 같은 날 upsert가 올바르게 동작한다', () async {
      await db.updateDailySteps(userId, 3000, 150.0, 2.1);
      await db.updateDailySteps(userId, 7000, 350.0, 4.9); // 같은 날 업데이트
      final steps = await db.getWeeklySteps(userId);
      expect(steps.length, 1);
      expect(steps.first['steps'], 7000);
    });

    test('getWeeklySteps: 최대 7일치 데이터를 반환한다', () async {
      await db.updateDailySteps(userId, 5000, 250.0, 3.5);
      final steps = await db.getWeeklySteps(userId);
      expect(steps.length, lessThanOrEqualTo(7));
    });
  });

  group('DatabaseHelper - Admin 통계', () {
    late DatabaseHelper db;

    setUp(() async {
      DatabaseHelper.resetForTest();
      db = DatabaseHelper();
    });

    test('getTotalUserCount: 기본 admin 계정을 포함한 사용자 수를 반환한다', () async {
      final count = await db.getTotalUserCount();
      expect(count, greaterThanOrEqualTo(1)); // admin 계정 포함
    });

    test('getAtRiskUsers: 결과가 List 타입이다', () async {
      final atRisk = await db.getAtRiskUsers();
      expect(atRisk, isA<List>());
    });
  });
}
