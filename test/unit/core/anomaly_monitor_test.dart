import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/core/services/anomaly_monitor_service.dart';
import '../../helpers/mock_definitions.dart';

void main() {
  late MockDatabaseHelper mockDb;
  late AnomalyMonitorService service;

  setUp(() {
    mockDb = MockDatabaseHelper();
    service = AnomalyMonitorService(dbHelper: mockDb);
  });

  group('AnomalyMonitorService.checkActivityAnomaly', () {
    test('데이터가 3개 미만이면 isAnomaly: false를 반환한다', () async {
      when(() => mockDb.getWeeklySteps(any())).thenAnswer(
        (_) async => [
          {'steps': 5000, 'date': '2026-05-10'},
          {'steps': 6000, 'date': '2026-05-09'},
        ],
      );
      final result = await service.checkActivityAnomaly(1, 500);
      expect(result['isAnomaly'], false);
    });

    test('데이터가 3개 이상이고 조건 미충족이면 isAnomaly: false를 반환한다', () async {
      when(() => mockDb.getWeeklySteps(any())).thenAnswer(
        (_) async => [
          {'steps': 5000, 'date': '2026-05-10'},
          {'steps': 5000, 'date': '2026-05-09'},
          {'steps': 5000, 'date': '2026-05-08'},
        ],
      );
      // currentSteps = 4000 → 4000 >= 5000 * 0.3 = 1500 → 비이상
      final result = await service.checkActivityAnomaly(
        1, 4000,
        clock: () => DateTime(2026, 5, 11, 20, 0, 0), // 20시
      );
      expect(result['isAnomaly'], false);
    });

    test('18시 이후이고 현재 걸음 < 평균의 30%면 isAnomaly: true를 반환한다', () async {
      when(() => mockDb.getWeeklySteps(any())).thenAnswer(
        (_) async => [
          {'steps': 5000, 'date': '2026-05-10'},
          {'steps': 5000, 'date': '2026-05-09'},
          {'steps': 5000, 'date': '2026-05-08'},
        ],
      );
      // avg = 5000, currentSteps = 100 (2%) < 30%
      final result = await service.checkActivityAnomaly(
        1, 100,
        clock: () => DateTime(2026, 5, 11, 20, 0, 0), // 20시 (>=18)
      );
      expect(result['isAnomaly'], true);
      expect(result['message'], isNotEmpty);
    });

    test('18시 이전이면 조건 미달로 isAnomaly: false를 반환한다', () async {
      when(() => mockDb.getWeeklySteps(any())).thenAnswer(
        (_) async => [
          {'steps': 5000, 'date': '2026-05-10'},
          {'steps': 5000, 'date': '2026-05-09'},
          {'steps': 5000, 'date': '2026-05-08'},
        ],
      );
      final result = await service.checkActivityAnomaly(
        1, 50,
        clock: () => DateTime(2026, 5, 11, 10, 0, 0), // 10시 (<18)
      );
      expect(result['isAnomaly'], false);
    });

    test('결과 Map에 avg_steps와 current_steps 키가 포함된다', () async {
      when(() => mockDb.getWeeklySteps(any())).thenAnswer(
        (_) async => [
          {'steps': 5000, 'date': '2026-05-10'},
          {'steps': 5000, 'date': '2026-05-09'},
          {'steps': 5000, 'date': '2026-05-08'},
        ],
      );
      final result = await service.checkActivityAnomaly(
        1, 3000,
        clock: () => DateTime(2026, 5, 11, 10, 0, 0),
      );
      expect(result.containsKey('avg_steps'), true);
      expect(result.containsKey('current_steps'), true);
    });
  });

  group('AnomalyMonitorService.generateGuardianAlert', () {
    test('알림 메시지에 사용자 이름이 포함된다', () {
      final alert = service.generateGuardianAlert('홍길동', {
        'avg_steps': 5000.0,
        'current_steps': 500,
      });
      expect(alert, contains('홍길동'));
    });

    test('알림 메시지에 평균 걸음수가 포함된다', () {
      final alert = service.generateGuardianAlert('김철수', {
        'avg_steps': 8000.0,
        'current_steps': 200,
      });
      expect(alert, contains('8000'));
    });

    test('알림 메시지에 현재 걸음수가 포함된다', () {
      final alert = service.generateGuardianAlert('이영희', {
        'avg_steps': 6000.0,
        'current_steps': 300,
      });
      expect(alert, contains('300'));
    });
  });
}
