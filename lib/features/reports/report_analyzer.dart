// ReportAnalyzer 유틸리티

class ReportAnalyzer {
  static String generateSummary({
    required List<Map<String, dynamic>> scoreHistory,
    required double currentCalculation,
    required double currentLogic,
    required double currentMemory,
    required double currentAttention,
  }) {
    if (scoreHistory.isEmpty) {
      return '훈련 데이터가 아직 부족합니다. 매일 3가지 이상의 게임을 수행하여 인지 건강 리포트를 완성해 보세요!';
    }

    // 1. 성취도 분석
    double avgScore = (currentCalculation + currentLogic + currentMemory + currentAttention) / 4.0;
    String achievementTxt = '';
    if (avgScore > 80) {
      achievementTxt = '현재 매우 우수한 인지 상태를 유지하고 계십니다. ';
    } else if (avgScore > 50) {
      achievementTxt = '꾸준한 훈련으로 건강한 뇌 상태를 관리 중이시네요. ';
    } else {
      achievementTxt = '인지 건강 관리를 위해 조금 더 집중적인 훈련이 필요해 보입니다. ';
    }

    // 2. 강점 영역 찾기
    Map<String, double> scores = {
      '계산력': currentCalculation,
      '논리 추론': currentLogic,
      '시각 기억': currentMemory,
      '집중력': currentAttention,
    };
    var sortedScores = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String strength = sortedScores.first.key;
    String strengthTxt = '특히 $strength 영역에서 뛰어난 능력을 보이고 계십니다. ';

    // 3. 개선 영역 추천
    String weakness = sortedScores.last.key;
    String weaknessTxt = '다음 주에는 $weakness 훈련 비중을 조금 더 높여보시는 건 어떨까요?';

    return '$achievementTxt$strengthTxt$weaknessTxt';
  }

  static List<String> generateRecommendations({
    required double currentSteps,
    required double currentMemory,
  }) {
    List<String> recommendations = [];
    
    if (currentSteps < 5000) {
      recommendations.add('매일 30분 정도의 가벼운 산책 (약 6,000보) 권장');
    } else {
      recommendations.add('현재의 훌륭한 신체 활동량을 계속 유지해 주세요');
    }

    if (currentMemory < 60) {
      recommendations.add('암기 위주의 게임(범주화 훈련 등) 주 3회 수행');
    } else {
      recommendations.add('새로운 단어 배우기나 독서를 통해 어휘력 확장하기');
    }

    recommendations.add('충분한 수면(7시간 이상)으로 기억력 저장 돕기');

    return recommendations;
  }
}
