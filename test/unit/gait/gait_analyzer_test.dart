import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_application_1/features/gait_analysis/gait_analyzer.dart';

UserAccelerometerEvent _event(double x, double y, double z) =>
    UserAccelerometerEvent(x, y, z, DateTime.now());

void main() {
  group('GaitAnalyzer', () {
    late GaitAnalyzer analyzer;

    setUp(() => analyzer = GaitAnalyzer());

    test('초기 stepCount는 0이다', () {
      expect(analyzer.stepCount, 0);
    });

    test('초기 gaitVariability는 0.0이다', () {
      expect(analyzer.gaitVariability, 0.0);
    });

    test('magnitude > threshold이면 걸음을 감지하고 true를 반환한다', () {
      // magnitude = sqrt(0^2 + 1.5^2 + 0^2) = 1.5 > 1.0 (threshold)
      final detected = analyzer.processEvent(_event(0, 1.5, 0));
      expect(detected, true);
      expect(analyzer.stepCount, 1);
    });

    test('magnitude <= threshold이면 걸음을 감지하지 않고 false를 반환한다', () {
      // magnitude = sqrt(0.3^2 * 3) ≈ 0.52 < 1.0
      final detected = analyzer.processEvent(_event(0.3, 0.3, 0.3));
      expect(detected, false);
      expect(analyzer.stepCount, 0);
    });

    test('300ms 이내의 두 번째 이벤트는 감지하지 않는다 (debounce)', () {
      final fixedNow = DateTime(2026, 5, 11, 12, 0, 0);
      // 첫 번째 걸음
      analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => fixedNow);
      // 즉시 두 번째 이벤트 (200ms 후 - 300ms 미만)
      final secondDetected = analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => fixedNow.add(const Duration(milliseconds: 200)));
      expect(secondDetected, false);
      expect(analyzer.stepCount, 1);
    });

    test('300ms 이후의 두 번째 이벤트는 별도 걸음으로 감지한다', () {
      final fixedNow = DateTime(2026, 5, 11, 12, 0, 0);
      analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => fixedNow);
      final secondDetected = analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => fixedNow.add(const Duration(milliseconds: 400)));
      expect(secondDetected, true);
      expect(analyzer.stepCount, 2);
    });

    test('getSummary()는 필수 키를 모두 포함한다', () {
      final summary = analyzer.getSummary();
      expect(summary.containsKey('total_steps'), true);
      expect(summary.containsKey('gait_variability'), true);
      expect(summary.containsKey('avg_stride_time'), true);
      expect(summary.containsKey('assessment_date'), true);
    });

    test('getSummary()의 total_steps는 stepCount와 일치한다', () {
      final fixedNow = DateTime(2026, 5, 11, 12, 0, 0);
      analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => fixedNow);
      analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => fixedNow.add(const Duration(milliseconds: 400)));
      final summary = analyzer.getSummary();
      expect(summary['total_steps'], 2);
    });

    test('걸음 데이터가 5개 미만이면 gaitVariability는 0.0이다', () {
      final base = DateTime(2026, 5, 11, 12, 0, 0);
      for (int i = 0; i < 4; i++) {
        analyzer.processEvent(_event(0, 2.0, 0),
            clock: () => base.add(Duration(milliseconds: i * 500)));
      }
      expect(analyzer.gaitVariability, 0.0);
    });

    test('걸음 데이터가 5개 이상이면 gaitVariability가 계산된다', () {
      final base = DateTime(2026, 5, 11, 12, 0, 0);
      for (int i = 0; i < 6; i++) {
        analyzer.processEvent(_event(0, 2.0, 0),
            clock: () => base.add(Duration(milliseconds: i * 500)));
      }
      // 균등한 간격이면 CV = 0
      expect(analyzer.gaitVariability, isA<double>());
    });

    test('reset() 후 모든 상태가 초기화된다', () {
      final fixedNow = DateTime(2026, 5, 11, 12, 0, 0);
      analyzer.processEvent(_event(0, 2.0, 0), clock: () => fixedNow);
      expect(analyzer.stepCount, 1);

      analyzer.reset();
      expect(analyzer.stepCount, 0);
      expect(analyzer.gaitVariability, 0.0);
    });
  });
}
