import '../database_helper.dart';

class AnomalyMonitorService {
  final DatabaseHelper _dbHelper;

  AnomalyMonitorService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// 최근 보행 데이터 급락 감지
  Future<Map<String, dynamic>> checkActivityAnomaly(
      int userId, int currentSteps) async {
    final recentData = await _dbHelper.getWeeklySteps(userId);

    if (recentData.length < 3) {
      return {"isAnomaly": false, "avg_steps": 0, "current_steps": currentSteps};
    }

    final stepsList =
        recentData.map((e) => (e['steps'] as num).toDouble()).toList();
    final avgSteps = stepsList.reduce((a, b) => a + b) / stepsList.length;

    final now = DateTime.now();
    bool isAnomaly = false;
    String message = '';

    if (now.hour >= 18 && avgSteps > 1000 && currentSteps < avgSteps * 0.3) {
      isAnomaly = true;
      message = '오늘 평소보다 활동량이 매우 적습니다. 건강 상태를 확인해보세요.';
    }

    return {
      "isAnomaly": isAnomaly,
      "message": message,
      "avg_steps": avgSteps,
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
