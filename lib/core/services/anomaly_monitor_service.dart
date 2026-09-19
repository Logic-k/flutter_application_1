import '../database_helper.dart';
import 'step_anomaly_policy.dart';

class AnomalyMonitorService {
  final DatabaseHelper _dbHelper;

  AnomalyMonitorService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// 최근 보행 데이터 급락 감지
  /// [clock]: 테스트에서 시간을 제어할 때 주입. 기본값은 DateTime.now
  ///
  /// 판정 기준은 [StepAnomalyPolicy]가 유일한 출처다. 예전에는 이 함수가
  /// 오늘 걸음을 기준선 평균에 포함시켰다 — 오늘 값이 평균을 끌어내려
  /// PedometerManager·GuardianSyncService와 다른 판정이 나왔다.
  Future<Map<String, dynamic>> checkActivityAnomaly(
      int userId, int currentSteps, {DateTime Function()? clock}) async {
    final recentData = await _dbHelper.getWeeklySteps(userId);
    final now = (clock ?? DateTime.now)();
    final verdict = StepAnomalyPolicy.evaluate(
      todaySteps: currentSteps,
      baselineSteps:
          StepAnomalyPolicy.baselineFromWeeklyRows(recentData, now: now),
      now: now,
    );

    return {
      "isAnomaly": verdict.isAnomaly,
      "message": verdict.isAnomaly
          ? '오늘 평소보다 활동량이 매우 적습니다. 건강 상태를 확인해보세요.'
          : '',
      "avg_steps": verdict.baselineAvg,
      "current_steps": currentSteps,
    };
  }

  /// 보호자 알림 문자 생성
  String generateGuardianAlert(
      String userName, Map<String, dynamic> anomalyData) {
    return '[MemoryLink 안심 알림]\n'
        '$userName 님의 오늘 활동량이 평소(평균 ${(anomalyData['avg_steps'] as double).toInt()}보)보다 '
        '현저히 낮은 ${anomalyData['current_steps']}보에 머물러 있습니다. '
        '안부를 확인해 주시기 바랍니다.';
  }
}
