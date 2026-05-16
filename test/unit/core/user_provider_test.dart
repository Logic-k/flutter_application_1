import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import '../../helpers/mock_definitions.dart';

void main() {
  late MockDatabaseHelper mockDb;
  late UserProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDb = MockDatabaseHelper();
    provider = UserProvider(dbHelper: mockDb);
  });

  group('UserProvider - login', () {
    test('올바른 자격증명으로 로그인 시 true를 반환하고 currentUser가 설정된다', () async {
      when(() => mockDb.getUser('alice', 'pass123')).thenAnswer(
        (_) async => {
          'id': 1,
          'username': 'alice',
          'password': 'pass123',
          'has_completed_onboarding': 1,
          'pedometer_enabled': 0,
          'age': 65,
          'weight': 70.0,
          'blood_type': null,
          'medications': null,
          'emergency_contact': null,
        },
      );
      when(() => mockDb.recordDauIfNeeded(any())).thenAnswer((_) async {});
      when(() => mockDb.getLatestScores(any())).thenAnswer((_) async => []);

      final result = await provider.login('alice', 'pass123');
      expect(result, true);
      expect(provider.isLoggedIn, true);
      expect(provider.currentUser?['username'], 'alice');
    });

    test('잘못된 자격증명으로 로그인 시 false를 반환하고 로그인 상태가 유지되지 않는다', () async {
      when(() => mockDb.getUser(any(), any())).thenAnswer((_) async => null);

      final result = await provider.login('wrong', 'wrong');
      expect(result, false);
      expect(provider.isLoggedIn, false);
    });

    test('logout 후 currentUser가 null이 되고 isLoggedIn이 false가 된다', () async {
      when(() => mockDb.getUser(any(), any())).thenAnswer(
        (_) async => {
          'id': 1,
          'username': 'bob',
          'password': 'pass',
          'has_completed_onboarding': 1,
          'pedometer_enabled': 0,
          'age': 60,
          'weight': 65.0,
          'blood_type': null,
          'medications': null,
          'emergency_contact': null,
        },
      );
      when(() => mockDb.recordDauIfNeeded(any())).thenAnswer((_) async {});
      when(() => mockDb.getLatestScores(any())).thenAnswer((_) async => []);

      await provider.login('bob', 'pass');
      expect(provider.isLoggedIn, true);

      await provider.logout();
      expect(provider.isLoggedIn, false);
      expect(provider.currentUser, isNull);
    });
  });

  group('UserProvider - setCognitiveScore', () {
    test('카테고리별 점수가 올바르게 저장된다', () {
      provider.setCognitiveScore('calculation', 8.0, persist: false);
      provider.setCognitiveScore('logic', 6.0, persist: false);
      provider.setCognitiveScore('memory', 7.0, persist: false);
      provider.setCognitiveScore('attention', 5.0, persist: false);

      expect(provider.calculationScore, 8.0);
      expect(provider.logicScore, 6.0);
      expect(provider.memoryScore, 7.0);
      expect(provider.attentionScore, 5.0);
    });

    test('persist: false이면 DB insertScore를 호출하지 않는다', () {
      provider.setCognitiveScore('calculation', 9.0, persist: false);
      verifyNever(() => mockDb.insertScore(any(), any(), any()));
    });

    test('totalAssessmentScore는 인지 점수 4개의 평균을 반영한다', () {
      // surveyScore = 0 (surveyAnswers 없음), cognitiveAvg = (8+6+7+5)/4 = 6.5
      // totalAssessmentScore = (0 + 6.5) / 2 = 3.25
      provider.setCognitiveScore('calculation', 8.0, persist: false);
      provider.setCognitiveScore('logic', 6.0, persist: false);
      provider.setCognitiveScore('memory', 7.0, persist: false);
      provider.setCognitiveScore('attention', 5.0, persist: false);

      expect(provider.totalAssessmentScore, closeTo(3.25, 0.01));
    });
  });

  group('UserProvider - register', () {
    test('register 성공 시 insertUser를 호출하고 자동 로그인한다', () async {
      when(() => mockDb.insertUser(any())).thenAnswer((_) async => 1);
      when(() => mockDb.getUser(any(), any())).thenAnswer(
        (_) async => {
          'id': 1,
          'username': 'newuser',
          'password': 'pw',
          'has_completed_onboarding': 0,
          'pedometer_enabled': 0,
          'age': 60,
          'weight': 60.0,
          'blood_type': null,
          'medications': null,
          'emergency_contact': null,
        },
      );
      when(() => mockDb.recordDauIfNeeded(any())).thenAnswer((_) async {});
      when(() => mockDb.getLatestScores(any())).thenAnswer((_) async => []);

      final result = await provider.register('newuser', 'pw', 'prevention', 60, 60.0);
      expect(result, true);
      verify(() => mockDb.insertUser(any())).called(1);
      expect(provider.isLoggedIn, true);
    });

    test('insertUser 실패 시 false를 반환한다', () async {
      when(() => mockDb.insertUser(any())).thenThrow(Exception('DB error'));

      final result = await provider.register('dupuser', 'pw', 'concern', 55, 55.0);
      expect(result, false);
    });
  });
}
