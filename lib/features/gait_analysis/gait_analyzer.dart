import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// 보행 지표 분석기 — 가속도 스트림에서 걸음과 걸음 간격 변동성을 계산한다.
///
/// **이 값은 진단·선별 지표가 아니다.** 걸음 간격이 얼마나 고른지를 보는
/// 활동 기록이며, 임상적으로 합의된 절단값도 없다.
///
/// 근거 문헌(Verghese 등, Einstein Aging Study)의 보행 변동성 값은 GAITRite
/// 압력센서 워크웨이 위에서 표준 프로토콜로 측정한 것이다. 주머니 속 휴대폰
/// 가속도에서 얻은 값을 같은 의미로 제시하면 근거를 과대 적용하는 것이 된다.
/// 그래서 이 클래스는 다음 두 가지를 지킨다.
///
/// 1. 표본이 부족하면 값을 만들지 않고 `null`을 돌려준다.
///    (예전에는 `0.0`을 돌려줘서 "완벽하게 규칙적인 보행"과 구분되지 않았다)
/// 2. 이름을 실제 측정 대상에 맞춘다. 아래 값들은 stride time이 아니라
///    **step interval**(연속한 두 걸음 사이 간격)이다. 스마트폰 가속도 하나로는
///    좌우 발을 구분할 수 없어 stride를 직접 잴 수 없다.
class GaitAnalyzer {
  /// 걸음 감지 임계치 (m/s^2).
  static const double _stepThreshold = 1.0;

  /// 두 걸음 사이 최소 시간 (ms). 한 번의 충격이 여러 걸음으로 세지는 것을 막는다.
  static const int _minStepTimeMs = 300;

  /// 보행으로 볼 수 있는 걸음 간격 상한 (ms). 이보다 길면 멈춤·회전으로 본다.
  static const int _maxStepIntervalMs = 2000;

  /// 변동성을 계산하기 위해 필요한 최소 걸음 간격 수.
  ///
  /// 방법론 연구는 신뢰할 만한 보행 변동성 지표에 50~80 stride가 필요하다고
  /// 본다. stride 하나는 걸음 두 개이므로 100 간격 ≈ 50 stride다.
  /// 편안한 속도로 1분 남짓 걸으면 모인다.
  ///
  /// 예전 값은 5였다. 다섯 개 표본의 변동계수는 통계적으로 의미가 없다.
  static const int minIntervalsForVariability = 100;

  int _stepCount = 0;
  DateTime? _lastStepTime;

  /// 연속한 두 걸음 사이의 시간 간격(ms).
  final List<int> _stepIntervals = [];

  int get stepCount => _stepCount;

  /// 변동성 계산에 쓰인 표본 수. 화면에 함께 보여줘야 값의 신뢰도를 알 수 있다.
  int get intervalSampleCount => _stepIntervals.length;

  /// 변동성을 낼 만큼 표본이 모였는지.
  bool get hasEnoughSamples =>
      _stepIntervals.length >= minIntervalsForVariability;

  /// 목표 표본까지의 진행률 (0.0~1.0).
  double get sampleProgress =>
      (_stepIntervals.length / minIntervalsForVariability).clamp(0.0, 1.0);

  /// 걸음 간격 변동계수(CV, %). 표본이 부족하면 `null`.
  ///
  /// 표본 표준편차(n-1)를 쓴다. 모집단 표준편차(n)는 우리가 가진 것이
  /// 전체 모집단일 때만 맞는데, 여기서는 한 번의 보행에서 뽑은 표본이다.
  double? get stepIntervalCv {
    if (!hasEnoughSamples) return null;

    final n = _stepIntervals.length;
    final mean = _stepIntervals.reduce((a, b) => a + b) / n;
    if (mean <= 0) return null;

    final sumSq = _stepIntervals
        .map((x) => pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b);
    final stdDev = sqrt(sumSq / (n - 1));

    return (stdDev / mean) * 100;
  }

  /// 평균 걸음 간격(ms). 표본이 없으면 `null`.
  double? get averageStepIntervalMs {
    if (_stepIntervals.isEmpty) return null;
    return _stepIntervals.reduce((a, b) => a + b) / _stepIntervals.length;
  }

  /// 새로운 가속도 데이터로 걸음을 감지한다.
  ///
  /// [clock]은 테스트에서 시간을 제어할 때 주입한다.
  bool processEvent(UserAccelerometerEvent event, {DateTime Function()? clock}) {
    final magnitude =
        sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    final now = (clock ?? DateTime.now)();

    if (magnitude <= _stepThreshold) return false;

    final last = _lastStepTime;
    if (last != null &&
        now.difference(last).inMilliseconds <= _minStepTimeMs) {
      return false;
    }

    if (last != null) {
      final interval = now.difference(last).inMilliseconds;
      // 멈춤·회전 구간을 변동성에 넣으면 실제 보행보다 훨씬 불규칙해 보인다.
      if (interval >= _minStepTimeMs && interval <= _maxStepIntervalMs) {
        _stepIntervals.add(interval);
      }
    }

    _stepCount++;
    _lastStepTime = now;
    return true;
  }

  void reset() {
    _stepCount = 0;
    _lastStepTime = null;
    _stepIntervals.clear();
  }

  /// 세션 요약. 값이 없는 항목은 `null`로 남긴다 — 0으로 채우면
  /// "측정되지 않음"과 "0으로 측정됨"이 구분되지 않는다.
  Map<String, dynamic> getSummary() {
    return {
      'total_steps': _stepCount,
      'step_interval_cv': stepIntervalCv,
      'avg_step_interval_ms': averageStepIntervalMs,
      'interval_samples': _stepIntervals.length,
      'has_enough_samples': hasEnoughSamples,
      'assessment_date': DateTime.now().toIso8601String(),
    };
  }
}
