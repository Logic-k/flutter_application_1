/// 활동량 급감 판정의 단일 기준.
///
/// 예전에는 같은 판정이 세 곳에 서로 다르게 구현돼 있었다.
///   - PedometerManager: 평균의 50% 미만, 시간 무관, 기준선에서 오늘 제외
///   - GuardianSyncService: 18시 이후 + 30% 미만, 기준선에 오늘 포함, 표본 검사 없음
///   - AnomalyMonitorService: 18시 이후 + 30% 미만, 기준선에 오늘 포함
///
/// 같은 사용자에게 서로 다른 판정이 나올 수 있어 하나로 통합했다.
/// 정책의 근거는 이렇다:
///
///   * 기준선에서 오늘을 제외한다 — 오늘의 낮은 걸음이 평균을 끌어내려
///     감지가 둔감해지는 것을 막기 위해서다.
///   * 18시 이후에만 판정한다 — 오전의 적은 걸음은 "아직 안 걸은 것"과
///     "활동 급감"을 구분할 수 없어 보호자 오탐 알림이 된다.
///   * 평소 평균이 1,000보를 넘을 때만 판정한다 — 좌식 생활자에게는
///     몇백 보 차이가 의미 없는 변동이라 이상으로 볼 수 없다.
///   * 최소 3일의 기준선이 있어야 판정한다 — 1~2일 평균은 "평소"가 아니다.
library;

/// 활동량 이상 판정 결과.
class StepAnomalyVerdict {
  /// 기준선 대비 오늘 활동량이 현저히 낮은가.
  final bool isAnomaly;

  /// 기준선(오늘 제외) 일평균 걸음 수. 표본 부족으로 미판정이면 0.
  final double baselineAvg;

  /// 판정이 실제로 수행됐는가. 기준선 표본 부족이면 false.
  final bool evaluated;

  const StepAnomalyVerdict({
    required this.isAnomaly,
    required this.baselineAvg,
    required this.evaluated,
  });
}

class StepAnomalyPolicy {
  StepAnomalyPolicy._();

  /// 판정에 필요한 최소 기준 일수 (오늘 제외)
  static const int minBaselineDays = 3;

  /// 이 값 이하의 평소 활동량은 "급감" 판정을 하지 않는다.
  static const double minBaselineAvg = 1000;

  /// 오늘 걸음이 기준 평균의 이 비율 미만이면 이상으로 본다.
  static const double dropRatio = 0.3;

  /// 이 시각(시, 24h) 이후에만 판정한다.
  static const int evaluationStartHour = 18;

  /// `getWeeklySteps` 결과(최근 7일, 오늘 포함 가능, date DESC)에서
  /// 오늘 행을 빼고 기준선 걸음 목록을 만든다.
  static List<double> baselineFromWeeklyRows(
    List<Map<String, dynamic>> rows, {
    DateTime? now,
  }) {
    final today = (now ?? DateTime.now()).toIso8601String().split('T')[0];
    return rows
        .where((e) => e['date'] != today)
        .map((e) => (e['steps'] as num).toDouble())
        .toList();
  }

  /// [baselineSteps]에는 오늘 데이터를 넣지 않는다
  /// ([baselineFromWeeklyRows]를 쓰면 자동으로 제외된다).
  static StepAnomalyVerdict evaluate({
    required int todaySteps,
    required List<double> baselineSteps,
    DateTime? now,
  }) {
    if (baselineSteps.length < minBaselineDays) {
      return const StepAnomalyVerdict(
        isAnomaly: false,
        baselineAvg: 0,
        evaluated: false,
      );
    }
    final avg =
        baselineSteps.reduce((a, b) => a + b) / baselineSteps.length;
    final at = now ?? DateTime.now();
    final isAnomaly = at.hour >= evaluationStartHour &&
        avg > minBaselineAvg &&
        todaySteps < avg * dropRatio;
    return StepAnomalyVerdict(
      isAnomaly: isAnomaly,
      baselineAvg: avg,
      evaluated: true,
    );
  }
}
