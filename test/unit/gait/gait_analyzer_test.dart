import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_application_1/features/gait_analysis/gait_analyzer.dart';

UserAccelerometerEvent _event(double x, double y, double z) =>
    UserAccelerometerEvent(x, y, z, DateTime.now());

/// 일정한 간격으로 걸음을 [count]번 만든다.
/// 간격이 모두 같으면 변동계수는 0에 수렴한다.
void _walk(
  GaitAnalyzer analyzer, {
  required int count,
  int intervalMs = 500,
  DateTime? start,
}) {
  final base = start ?? DateTime(2026, 5, 11, 12, 0, 0);
  for (var i = 0; i < count; i++) {
    analyzer.processEvent(
      _event(0, 2.0, 0),
      clock: () => base.add(Duration(milliseconds: i * intervalMs)),
    );
  }
}

void main() {
  group('GaitAnalyzer 걸음 감지', () {
    late GaitAnalyzer analyzer;

    setUp(() => analyzer = GaitAnalyzer());

    test('초기 stepCount는 0이다', () {
      expect(analyzer.stepCount, 0);
    });

    test('magnitude > threshold이면 걸음을 감지하고 true를 반환한다', () {
      final detected = analyzer.processEvent(_event(0, 1.5, 0));
      expect(detected, true);
      expect(analyzer.stepCount, 1);
    });

    test('magnitude <= threshold이면 걸음을 감지하지 않는다', () {
      final detected = analyzer.processEvent(_event(0.3, 0.3, 0.3));
      expect(detected, false);
      expect(analyzer.stepCount, 0);
    });

    test('300ms 이내의 두 번째 이벤트는 감지하지 않는다 (debounce)', () {
      final t = DateTime(2026, 5, 11, 12, 0, 0);
      analyzer.processEvent(_event(0, 2.0, 0), clock: () => t);
      final second = analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => t.add(const Duration(milliseconds: 200)));
      expect(second, false);
      expect(analyzer.stepCount, 1);
    });

    test('300ms 이후의 두 번째 이벤트는 별도 걸음으로 감지한다', () {
      final t = DateTime(2026, 5, 11, 12, 0, 0);
      analyzer.processEvent(_event(0, 2.0, 0), clock: () => t);
      final second = analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => t.add(const Duration(milliseconds: 400)));
      expect(second, true);
      expect(analyzer.stepCount, 2);
    });

    test('2초를 넘는 간격은 표본에 넣지 않는다 (멈춤·회전 구간 제외)', () {
      final t = DateTime(2026, 5, 11, 12, 0, 0);
      analyzer.processEvent(_event(0, 2.0, 0), clock: () => t);
      analyzer.processEvent(_event(0, 2.0, 0),
          clock: () => t.add(const Duration(milliseconds: 3000)));
      expect(analyzer.stepCount, 2);
      // 걸음은 세되 변동성 표본으로는 쓰지 않는다.
      expect(analyzer.intervalSampleCount, 0);
    });
  });

  group('걸음 간격 변동성', () {
    late GaitAnalyzer analyzer;

    setUp(() => analyzer = GaitAnalyzer());

    test('표본이 부족하면 값을 만들지 않고 null을 돌려준다', () {
      // 예전에는 0.0을 돌려줘서 "완벽하게 규칙적인 보행"과 구분되지 않았다.
      expect(analyzer.stepIntervalCv, isNull);

      _walk(analyzer, count: 10);
      expect(analyzer.hasEnoughSamples, isFalse);
      expect(analyzer.stepIntervalCv, isNull);
    });

    test('최소 표본은 100개다 (문헌의 50 stride ≈ 100 걸음 간격)', () {
      // 다섯 개 표본의 변동계수는 통계적으로 의미가 없다.
      expect(GaitAnalyzer.minIntervalsForVariability, 100);
    });

    test('표본이 충분해지는 순간부터 값이 나온다', () {
      _walk(analyzer, count: GaitAnalyzer.minIntervalsForVariability);
      // n번 걸으면 간격은 n-1개다.
      expect(analyzer.hasEnoughSamples, isFalse);

      _walk(analyzer, count: GaitAnalyzer.minIntervalsForVariability + 1);
      expect(analyzer.intervalSampleCount,
          greaterThanOrEqualTo(GaitAnalyzer.minIntervalsForVariability));
      expect(analyzer.stepIntervalCv, isNotNull);
    });

    test('간격이 모두 같으면 변동계수는 0이다', () {
      _walk(analyzer, count: 150, intervalMs: 500);
      expect(analyzer.stepIntervalCv, closeTo(0.0, 0.0001));
    });

    test('표본 표준편차(n-1)를 쓴다', () {
      // 간격이 400/600으로 번갈아 나오게 만든다.
      final base = DateTime(2026, 5, 11, 12, 0, 0);
      var t = base;
      analyzer.processEvent(_event(0, 2.0, 0), clock: () => t);
      for (var i = 0; i < 150; i++) {
        t = t.add(Duration(milliseconds: i.isEven ? 400 : 600));
        final captured = t;
        analyzer.processEvent(_event(0, 2.0, 0), clock: () => captured);
      }

      final cv = analyzer.stepIntervalCv!;
      final n = analyzer.intervalSampleCount;
      // 평균 500, 편차 ±100 → 모집단 SD = 100, 표본 SD = 100*sqrt(n/(n-1))
      final populationCv = 100 / 500 * 100;
      final sampleCv = populationCv * (n / (n - 1));
      expect(cv, greaterThan(populationCv));
      expect(cv, closeTo(sampleCv, 0.5));
    });

    test('진행률은 0~1 사이로 유지된다', () {
      expect(analyzer.sampleProgress, 0.0);
      _walk(analyzer, count: 300);
      expect(analyzer.sampleProgress, 1.0);
    });
  });

  group('요약', () {
    late GaitAnalyzer analyzer;

    setUp(() => analyzer = GaitAnalyzer());

    test('필수 키를 모두 포함한다', () {
      final summary = analyzer.getSummary();
      expect(summary.containsKey('total_steps'), true);
      expect(summary.containsKey('step_interval_cv'), true);
      expect(summary.containsKey('avg_step_interval_ms'), true);
      expect(summary.containsKey('interval_samples'), true);
      expect(summary.containsKey('has_enough_samples'), true);
      expect(summary.containsKey('assessment_date'), true);
    });

    test('측정되지 않은 값은 0이 아니라 null이다', () {
      // 0으로 채우면 "측정 안 됨"과 "0으로 측정됨"이 구분되지 않는다.
      final summary = analyzer.getSummary();
      expect(summary['step_interval_cv'], isNull);
      expect(summary['avg_step_interval_ms'], isNull);
      expect(summary['has_enough_samples'], false);
    });

    test('total_steps는 stepCount와 일치한다', () {
      _walk(analyzer, count: 2);
      expect(analyzer.getSummary()['total_steps'], 2);
    });

    test('reset() 후 모든 상태가 초기화된다', () {
      _walk(analyzer, count: 150);
      expect(analyzer.stepIntervalCv, isNotNull);

      analyzer.reset();
      expect(analyzer.stepCount, 0);
      expect(analyzer.intervalSampleCount, 0);
      expect(analyzer.stepIntervalCv, isNull);
    });
  });
}
