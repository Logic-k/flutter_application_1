import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/services/step_anomaly_policy.dart';

void main() {
  // 판정 시각 고정용 — 테스트가 실행되는 실제 시각에 결과가 달라지지 않게 한다.
  DateTime at(int hour) => DateTime(2026, 9, 19, hour);

  group('StepAnomalyPolicy.evaluate', () {
    test('기준선이 3일 미만이면 미판정(evaluated=false, isAnomaly=false)', () {
      final v = StepAnomalyPolicy.evaluate(
        todaySteps: 10,
        baselineSteps: [5000, 5000],
        now: at(20),
      );
      expect(v.evaluated, false);
      expect(v.isAnomaly, false);
      expect(v.baselineAvg, 0);
    });

    test('18시 이전이면 걸음이 아주 적어도 이상이 아니다', () {
      final v = StepAnomalyPolicy.evaluate(
        todaySteps: 10,
        baselineSteps: [5000, 5000, 5000],
        now: at(10),
      );
      expect(v.evaluated, true);
      expect(v.isAnomaly, false);
    });

    test('17시와 18시 경계 — 18시부터 판정한다', () {
      final before = StepAnomalyPolicy.evaluate(
        todaySteps: 10,
        baselineSteps: [5000, 5000, 5000],
        now: at(17),
      );
      final atSix = StepAnomalyPolicy.evaluate(
        todaySteps: 10,
        baselineSteps: [5000, 5000, 5000],
        now: at(18),
      );
      expect(before.isAnomaly, false);
      expect(atSix.isAnomaly, true);
    });

    test('18시 이후 + 오늘 < 기준 평균의 30%이면 이상', () {
      final v = StepAnomalyPolicy.evaluate(
        todaySteps: 100, // 5000의 2%
        baselineSteps: [5000, 5000, 5000],
        now: at(20),
      );
      expect(v.isAnomaly, true);
      expect(v.baselineAvg, 5000);
    });

    test('정확히 30%는 이상이 아니다 (미만 조건)', () {
      final v = StepAnomalyPolicy.evaluate(
        todaySteps: 1500, // 5000의 정확히 30%
        baselineSteps: [5000, 5000, 5000],
        now: at(20),
      );
      expect(v.isAnomaly, false);
    });

    test('평소 평균이 1,000보 이하면 판정하지 않는다', () {
      final v = StepAnomalyPolicy.evaluate(
        todaySteps: 10,
        baselineSteps: [900, 900, 900],
        now: at(20),
      );
      expect(v.evaluated, true);
      expect(v.isAnomaly, false);
    });

    test('조건 미충족이면 isAnomaly=false이지만 기준 평균은 채운다', () {
      final v = StepAnomalyPolicy.evaluate(
        todaySteps: 4000,
        baselineSteps: [5000, 5000, 5000],
        now: at(20),
      );
      expect(v.isAnomaly, false);
      expect(v.baselineAvg, 5000);
    });
  });

  group('StepAnomalyPolicy.baselineFromWeeklyRows', () {
    test('오늘 날짜 행은 기준선에서 제외한다', () {
      final now = DateTime(2026, 9, 19, 20);
      final rows = [
        {'steps': 100, 'date': '2026-09-19'}, // 오늘 — 제외돼야 함
        {'steps': 5000, 'date': '2026-09-18'},
        {'steps': 6000, 'date': '2026-09-17'},
      ];
      final baseline =
          StepAnomalyPolicy.baselineFromWeeklyRows(rows, now: now);
      expect(baseline, [5000.0, 6000.0]);
    });

    test('오늘 행이 없으면 전부 기준선이다', () {
      final now = DateTime(2026, 9, 19, 20);
      final rows = [
        {'steps': 5000, 'date': '2026-09-18'},
        {'steps': 6000, 'date': '2026-09-17'},
      ];
      expect(
        StepAnomalyPolicy.baselineFromWeeklyRows(rows, now: now).length,
        2,
      );
    });
  });
}
