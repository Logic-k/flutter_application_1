import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/reports/report_analyzer.dart';

void main() {
  final fakeHistory = [
    {'category': 'calculation', 'score': 7.0, 'created_at': '2026-05-01'},
  ];

  group('ReportAnalyzer.generateSummary', () {
    test('scoreHistory가 비어있으면 데이터 부족 메시지를 반환한다', () {
      final result = ReportAnalyzer.generateSummary(
        scoreHistory: [],
        currentCalculation: 0,
        currentLogic: 0,
        currentMemory: 0,
        currentAttention: 0,
      );
      expect(result, contains('훈련 데이터가 아직 부족합니다'));
    });

    test('평균 점수 > 80이면 "매우 우수한" 메시지를 포함한다', () {
      final result = ReportAnalyzer.generateSummary(
        scoreHistory: fakeHistory,
        currentCalculation: 85,
        currentLogic: 85,
        currentMemory: 85,
        currentAttention: 85,
      );
      expect(result, contains('매우 우수한'));
    });

    test('평균 점수 50~80이면 "꾸준한 훈련" 메시지를 포함한다', () {
      final result = ReportAnalyzer.generateSummary(
        scoreHistory: fakeHistory,
        currentCalculation: 60,
        currentLogic: 60,
        currentMemory: 60,
        currentAttention: 60,
      );
      expect(result, contains('꾸준한 훈련'));
    });

    test('평균 점수 <= 50이면 "집중적인 훈련" 메시지를 포함한다', () {
      final result = ReportAnalyzer.generateSummary(
        scoreHistory: fakeHistory,
        currentCalculation: 30,
        currentLogic: 30,
        currentMemory: 30,
        currentAttention: 30,
      );
      expect(result, contains('집중적인 훈련'));
    });

    test('계산력이 가장 높은 점수면 강점으로 계산력을 식별한다', () {
      final result = ReportAnalyzer.generateSummary(
        scoreHistory: fakeHistory,
        currentCalculation: 90,
        currentLogic: 40,
        currentMemory: 40,
        currentAttention: 40,
      );
      expect(result, contains('계산력'));
    });

    test('집중력이 가장 낮은 점수면 개선 영역으로 집중력을 식별한다', () {
      final result = ReportAnalyzer.generateSummary(
        scoreHistory: fakeHistory,
        currentCalculation: 90,
        currentLogic: 90,
        currentMemory: 90,
        currentAttention: 20,
      );
      expect(result, contains('집중력'));
    });
  });

  group('ReportAnalyzer.generateRecommendations', () {
    test('steps < 5000이면 산책 권장 항목을 포함한다', () {
      final recs = ReportAnalyzer.generateRecommendations(
        currentSteps: 3000,
        currentMemory: 80,
      );
      expect(recs.any((r) => r.contains('산책')), true);
    });

    test('steps >= 5000이면 활동 유지 권장 항목을 포함한다', () {
      final recs = ReportAnalyzer.generateRecommendations(
        currentSteps: 7000,
        currentMemory: 80,
      );
      expect(recs.any((r) => r.contains('유지')), true);
    });

    test('memory < 60이면 범주화 훈련 권장 항목을 포함한다', () {
      final recs = ReportAnalyzer.generateRecommendations(
        currentSteps: 6000,
        currentMemory: 40,
      );
      expect(recs.any((r) => r.contains('범주화 훈련')), true);
    });

    test('항상 수면 권장 항목을 포함한다', () {
      final recs = ReportAnalyzer.generateRecommendations(
        currentSteps: 7000,
        currentMemory: 70,
      );
      expect(recs.any((r) => r.contains('수면')), true);
    });
  });
}
