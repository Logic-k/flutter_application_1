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
      final aliceRow = {
        'id': 1,
        'username': 'alice',
        'has_completed_onboarding': 1,
        'pedometer_enabled': 0,
        'age': 65,
        'weight': 70.0,
        'blood_type': null,
        'medications': null,
        'emergency_contact': null,
      };
      when(() => mockDb.getUser('alice', 'pass123'))
          .thenAnswer((_) async => aliceRow);
      when(() => mockDb.getUserById(1)).thenAnswer((_) async => aliceRow);
      when(() => mockDb.setSessionToken(any(), any())).thenAnswer((_) async {});
      when(() => mockDb.recordDauIfNeeded(any())).thenAnswer((_) async {});
      when(() => mockDb.getLatestScores(any())).thenAnswer((_) async => []);

      final result = await provider.login('alice', 'pass123');
      expect(result, true);
      expect(provider.isLoggedIn, true);
      expect(provider.currentUser?['username'], 'alice');
      // 로그인 시 세션 토큰이 발급되어야 한다 (비밀번호는 저장하지 않음)
      verify(() => mockDb.setSessionToken(1, any(that: isNotNull))).called(1);
    });

    test('잘못된 자격증명으로 로그인 시 false를 반환하고 로그인 상태가 유지되지 않는다', () async {
      when(() => mockDb.getUser(any(), any())).thenAnswer((_) async => null);

      final result = await provider.login('wrong', 'wrong');
      expect(result, false);
      expect(provider.isLoggedIn, false);
    });

    test('logout 후 currentUser가 null이 되고 세션 토큰이 무효화된다', () async {
      final bobRow = {
        'id': 1,
        'username': 'bob',
        'has_completed_onboarding': 1,
        'pedometer_enabled': 0,
        'age': 60,
        'weight': 65.0,
        'blood_type': null,
        'medications': null,
        'emergency_contact': null,
      };
      when(() => mockDb.getUser(any(), any())).thenAnswer((_) async => bobRow);
      when(() => mockDb.getUserById(1)).thenAnswer((_) async => bobRow);
      when(() => mockDb.setSessionToken(any(), any())).thenAnswer((_) async {});
      when(() => mockDb.recordDauIfNeeded(any())).thenAnswer((_) async {});
      when(() => mockDb.getLatestScores(any())).thenAnswer((_) async => []);

      await provider.login('bob', 'pass');
      expect(provider.isLoggedIn, true);

      await provider.logout();
      expect(provider.isLoggedIn, false);
      expect(provider.currentUser, isNull);
      // 로그아웃 시 DB의 세션 토큰이 null로 초기화되어야 한다
      verify(() => mockDb.setSessionToken(1, null)).called(1);
    });

    test('계정 전환 시 이전 사용자의 음성 점수가 남지 않는다', () async {
      final firstUser = {
        'id': 1,
        'username': 'first',
        'has_completed_onboarding': 1,
        'pedometer_enabled': 0,
        'age': 65,
        'weight': 70.0,
        'blood_type': null,
        'medications': null,
        'emergency_contact': null,
      };
      final secondUser = {...firstUser, 'id': 2, 'username': 'second'};

      when(() => mockDb.getUser('first', 'pass'))
          .thenAnswer((_) async => firstUser);
      when(() => mockDb.getUser('second', 'pass'))
          .thenAnswer((_) async => secondUser);
      when(() => mockDb.getUserById(1)).thenAnswer((_) async => firstUser);
      when(() => mockDb.getUserById(2)).thenAnswer((_) async => secondUser);
      when(() => mockDb.setSessionToken(any(), any())).thenAnswer((_) async {});
      when(() => mockDb.recordDauIfNeeded(any())).thenAnswer((_) async {});
      when(() => mockDb.getLatestScores(1)).thenAnswer(
        (_) async => [
          {'category': 'voice', 'score': 88.0},
        ],
      );
      when(() => mockDb.getLatestScores(2)).thenAnswer((_) async => []);

      await provider.login('first', 'pass');
      expect(provider.voiceScore, 88.0);

      await provider.login('second', 'pass');
      expect(provider.voiceScore, 0.0);
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

    test('totalAssessmentScore: 인지 점수(0-100)가 높을수록 위험도가 낮아진다', () {
      // cognitiveAvg = (80+60+70+50)/4 = 65 → cognitiveRisk = 1 - 0.65 = 0.35
      // surveyRisk = 0 (설문 없음) → total = (0 + 0.35) / 2 = 0.175
      provider.setCognitiveScore('calculation', 80.0, persist: false);
      provider.setCognitiveScore('logic', 60.0, persist: false);
      provider.setCognitiveScore('memory', 70.0, persist: false);
      provider.setCognitiveScore('attention', 50.0, persist: false);

      expect(provider.totalAssessmentScore, closeTo(0.175, 0.01));
    });

    test('totalAssessmentScore: 인지 점수가 없으면 설문 위험도만 사용한다', () {
      // 10문항 중 "예" 5개 → surveyRisk = 0.5
      for (int i = 0; i < 10; i++) {
        provider.setSurveyAnswer(i, i < 5 ? 1 : 0);
      }
      expect(provider.totalAssessmentScore, closeTo(0.5, 0.01));
    });

    test('totalAssessmentScore: 결과는 항상 0.0~1.0 범위다', () {
      for (int i = 0; i < 10; i++) {
        provider.setSurveyAnswer(i, 1);
      }
      provider.setCognitiveScore('memory', 0.0, persist: false);
      final score = provider.totalAssessmentScore;
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });
  });

  group('UserProvider - register', () {
    test('register 성공 시 insertUser를 호출하고 자동 로그인한다', () async {
      final newUserRow = {
        'id': 1,
        'username': 'newuser',
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
        'age': 60,
        'weight': 60.0,
        'blood_type': null,
        'medications': null,
        'emergency_contact': null,
      };
      when(() => mockDb.insertUser(any())).thenAnswer((_) async => 1);
      when(() => mockDb.getUser(any(), any()))
          .thenAnswer((_) async => newUserRow);
      when(() => mockDb.getUserById(1)).thenAnswer((_) async => newUserRow);
      when(() => mockDb.setSessionToken(any(), any())).thenAnswer((_) async {});
      when(() => mockDb.recordDauIfNeeded(any())).thenAnswer((_) async {});
      when(() => mockDb.getLatestScores(any())).thenAnswer((_) async => []);

      final result = await provider.register('newuser', '새사용자', 'pw', 'prevention', 60, 60.0);
      expect(result, true);
      verify(() => mockDb.insertUser(any())).called(1);
      expect(provider.isLoggedIn, true);
      // 신규 가입자는 온보딩 미완료 상태여야 한다 (동의 화면으로 유도)
      expect(provider.hasCompletedOnboarding, false);
    });

    test('insertUser 실패 시 false를 반환한다', () async {
      when(() => mockDb.insertUser(any())).thenThrow(Exception('DB error'));

      final result = await provider.register('dupuser', '중복사용자', 'pw', 'concern', 55, 55.0);
      expect(result, false);
    });
  });
}
