import '../../../core/database_helper.dart';
import '../../../core/user_provider.dart';

enum ReportType { doctor, caregiver }

/// 앱 내부 수행 구간. 표준화 검사의 절단점이 아니다.
///
/// enum 식별자는 그대로 두고 사용자에게 보이는 라벨만 비처방적 표현으로 둔다.
/// '정상'·'전문의 의뢰' 같은 문구는 의학적 판정을 시사해 웰니스 범위를 벗어난다.
enum CognitiveBand { normal, borderline, needsFollowUp, specialistReferral }

extension CognitiveBandExt on CognitiveBand {
  String get label {
    switch (this) {
      case CognitiveBand.normal:
        return '양호';
      case CognitiveBand.borderline:
        return '주의 관찰';
      case CognitiveBand.needsFollowUp:
        return '변화가 관찰됨';
      case CognitiveBand.specialistReferral:
        return '상담 권유';
    }
  }

  /// 앱 안의 수행 구간을 나누는 유일한 기준.
  ///
  /// 이 값들은 규준 표본이나 ROC 분석에서 나온 것이 아니라 앱 내부에서 정한
  /// 구간이다. 예전에는 30점 척도(25/20/14)와 100점 척도(75/55/35) 두 벌이
  /// 서로 다른 기준으로 공존해, 같은 사용자의 종합 밴드와 영역 밴드가 어긋났다.
  static CognitiveBand fromScore(double? score) {
    if (score == null) return CognitiveBand.needsFollowUp;
    if (score >= 75) return CognitiveBand.normal;
    if (score >= 55) return CognitiveBand.borderline;
    if (score >= 35) return CognitiveBand.needsFollowUp;
    return CognitiveBand.specialistReferral;
  }
}

/// 지표를 처음 보여주는 자리마다 함께 붙여야 하는 고지.
///
/// 예전에는 리포트 4페이지 부록에만 있어서, 사용자는 판단 근거보다 점수를
/// 먼저 읽었다. 고령자 대상 서비스에서 고지는 숫자보다 앞서야 한다.
class MedicalDisclaimer {
  MedicalDisclaimer._();

  static const String notDiagnostic = '본 지표는 진단·선별 검사가 아니며 의료기기가 아닙니다.';

  static const String notEquivalent =
      '점수 구간은 앱 내부 기준이며 MMSE·MoCA·CIST 등 표준 검사와 등가성이 검증되지 않았습니다.';

  static const String whereToGo =
      '인지 저하가 의심되면 가까운 치매안심센터 또는 신경과·정신건강의학과 진료를 받으십시오.';

  /// 세 문장을 순서대로. 순서가 곧 읽는 순서다.
  static const List<String> sentences = [
    notDiagnostic,
    notEquivalent,
    whereToGo,
  ];

  static String get joined => sentences.join(' ');
}

class DomainScore {
  final String domainName;
  final double? score; // 0–100, null = 데이터 없음
  final double? prevScore;
  final CognitiveBand band;
  final bool hasData;

  const DomainScore({
    required this.domainName,
    this.score,
    this.prevScore,
    required this.band,
    required this.hasData,
  });

  double? get delta =>
      (score != null && prevScore != null) ? score! - prevScore! : null;
}

class RiskFactors {
  final bool poorSleep;
  final bool depressiveMood;
  final bool hearingDifficulty;
  final bool lowExercise;
  final bool socialIsolation;
  final bool hypertension;
  final bool diabetes;

  const RiskFactors({
    this.poorSleep = false,
    this.depressiveMood = false,
    this.hearingDifficulty = false,
    this.lowExercise = false,
    this.socialIsolation = false,
    this.hypertension = false,
    this.diabetes = false,
  });

  RiskFactors copyWith({
    bool? poorSleep,
    bool? depressiveMood,
    bool? hearingDifficulty,
    bool? lowExercise,
    bool? socialIsolation,
    bool? hypertension,
    bool? diabetes,
  }) {
    return RiskFactors(
      poorSleep: poorSleep ?? this.poorSleep,
      depressiveMood: depressiveMood ?? this.depressiveMood,
      hearingDifficulty: hearingDifficulty ?? this.hearingDifficulty,
      lowExercise: lowExercise ?? this.lowExercise,
      socialIsolation: socialIsolation ?? this.socialIsolation,
      hypertension: hypertension ?? this.hypertension,
      diabetes: diabetes ?? this.diabetes,
    );
  }

  int get checkedCount => [
        poorSleep,
        depressiveMood,
        hearingDifficulty,
        lowExercise,
        socialIsolation,
        hypertension,
        diabetes,
      ].where((v) => v).length;
}

class ClinicalSessionData {
  final String dateLabel; // "MM/DD"
  final double? memory;
  final double? attention;
  final double? executive;
  final double? language;

  const ClinicalSessionData({
    required this.dateLabel,
    this.memory,
    this.attention,
    this.executive,
    this.language,
  });
}

class ClinicalReportData {
  final String userName;
  final int age;
  final DateTime assessmentDate;
  final String assessmentPeriod;
  final bool caregiverPresent;
  final String? medications;
  final ReportType reportType;

  final DomainScore memory;
  final DomainScore attention;
  final DomainScore executive;
  final DomainScore language;
  final DomainScore visuospatial;

  /// MemoryLink 인지활동 지수 (0~100). 측정된 영역 점수의 평균이다.
  ///
  /// 예전에는 이 값을 30점 만점으로 선형 변환해 'MMSE 환산 점수'라는 이름으로
  /// 인쇄했다. MMSE는 배타적 저작권 대상이고(국내 치매안심센터도 2021년 CIST로
  /// 전환), 등가성 검증 없는 환산은 표준 척도의 이름만 빌리는 것이라 타당도와
  /// 저작권 문제를 동시에 만든다. 자체 척도를 자체 이름으로 쓴다.
  final double activityIndex;
  final double? prevActivityIndex;

  final int averageSteps;
  final double gaitStability;

  final List<ClinicalSessionData> sessionHistory;
  final RiskFactors riskFactors;

  const ClinicalReportData({
    required this.userName,
    required this.age,
    required this.assessmentDate,
    required this.assessmentPeriod,
    required this.caregiverPresent,
    this.medications,
    required this.reportType,
    required this.memory,
    required this.attention,
    required this.executive,
    required this.language,
    required this.visuospatial,
    required this.activityIndex,
    this.prevActivityIndex,
    required this.averageSteps,
    required this.gaitStability,
    required this.sessionHistory,
    required this.riskFactors,
  });

  /// 데이터가 없는 영역은 밴드를 매기지 않는다.
  /// 측정하지 않은 영역을 '양호'로 칠하면 없는 근거를 만드는 셈이다.
  static CognitiveBand _band(double? score) =>
      score == null ? CognitiveBand.normal : CognitiveBandExt.fromScore(score);

  // DB 저장 값 → 0-100 정규화
  // calculation/logic/attention: 0-10 저장 → × 10
  // memory: >10이면 이미 0-100, ≤10이면 × 10
  // perception: 그대로 (100 또는 null)
  static double _normalize(String category, double raw) {
    if (category == 'memory') {
      return raw > 10 ? raw : raw * 10;
    }
    if (category == 'perception') return raw;
    return (raw * 10).clamp(0, 100);
  }

  // 세션 히스토리에서 도메인 평균 점수 추출 (정규화 포함)
  static Map<String, double?> _extractDomains(
      Map<String, double> sessionRaw) {
    final calc = sessionRaw['calculation'];
    final logic = sessionRaw['logic'];
    final mem = sessionRaw['memory'];
    final att = sessionRaw['attention'];
    final perc = sessionRaw['perception'];

    final calcN = calc != null ? _normalize('calculation', calc) : null;
    final logicN = logic != null ? _normalize('logic', logic) : null;
    final memN = mem != null ? _normalize('memory', mem) : null;
    final attN = att != null ? _normalize('attention', att) : null;
    final percN = perc != null ? _normalize('perception', perc) : null;

    double? execN;
    if (calcN != null && logicN != null) {
      execN = (calcN + logicN) / 2.0;
    } else if (calcN != null) {
      execN = calcN;
    } else if (logicN != null) {
      execN = logicN;
    }

    return {
      'memory': memN,
      'attention': attN,
      'executive': execN,
      'language': percN,
    };
  }

  /// MemoryLink 인지활동 지수 — 측정된 영역 점수의 평균(0~100).
  ///
  /// 측정하지 않은 영역은 평균에서 제외한다. 0으로 치면 아직 해보지 않은
  /// 훈련 때문에 점수가 깎여, 안 한 것과 못 한 것을 구분할 수 없게 된다.
  ///
  /// 원 척도를 그대로 쓴다. 30점 만점으로 환산하던 예전 방식은 표준 척도를
  /// 연상시키는 것 외에 아무 정보도 더하지 않았다.
  static double computeActivityIndex(Map<String, double?> domains) {
    final values = domains.values.whereType<double>().toList();
    if (values.isEmpty) return 0.0;
    final avg = values.reduce((a, b) => a + b) / values.length;
    return avg.clamp(0.0, 100.0);
  }

  static Future<ClinicalReportData> fromProviders({
    required UserProvider user,
    required DatabaseHelper db,
    required ReportType reportType,
    required RiskFactors riskFactors,
    required bool caregiverPresent,
  }) async {
    final userId = user.currentUser!['id'] as int;
    final age = user.age ?? 65;
    final medications = user.medications;
    final userName = user.currentUser!['username'] as String? ?? '사용자';

    // 세션별 점수 히스토리 로드
    final sessions = await db.getScoreHistoryGroupedBySession(userId);

    // 현재 세션, 직전 세션 분리
    Map<String, double> currentRaw = {};
    Map<String, double> prevRaw = {};
    if (sessions.isNotEmpty) {
      currentRaw = sessions.last.values.first;
    }
    if (sessions.length >= 2) {
      prevRaw = sessions[sessions.length - 2].values.first;
    }

    final currentDomains = _extractDomains(currentRaw);
    final prevDomains = _extractDomains(prevRaw);

    final currentIndex = computeActivityIndex(currentDomains);
    final prevIndex =
        sessions.length >= 2 ? computeActivityIndex(prevDomains) : null;

    // 도메인별 DomainScore 객체 생성
    final memScore = currentDomains['memory'];
    final attScore = currentDomains['attention'];
    final execScore = currentDomains['executive'];
    final langScore = currentDomains['language'];

    // 걸음 데이터
    final weeklySteps = await db.getWeeklySteps(userId);
    int avgSteps = 0;
    if (weeklySteps.isNotEmpty) {
      final total = weeklySteps
          .map((r) => (r['steps'] as int?) ?? 0)
          .reduce((a, b) => a + b);
      avgSteps = (total / weeklySteps.length).round();
    }

    // 보행 안정성 (걸음수 기반 추정: 6000보 이상 = 1.0)
    final gaitStability = (avgSteps / 6000.0).clamp(0.0, 1.0);

    // 추이 차트용 세션 히스토리 (최근 8개)
    final chartSessions = sessions.length > 8
        ? sessions.sublist(sessions.length - 8)
        : sessions;
    final sessionHistory = chartSessions.map((s) {
      final dateKey = s.keys.first;
      final raw = s.values.first;
      final d = _extractDomains(raw);
      final label = _formatDateLabel(dateKey);
      return ClinicalSessionData(
        dateLabel: label,
        memory: d['memory'],
        attention: d['attention'],
        executive: d['executive'],
        language: d['language'],
      );
    }).toList();

    // 검사 기간 계산
    String period = '';
    if (sessions.isNotEmpty) {
      final firstDate = sessions.first.keys.first;
      final lastDate = sessions.last.keys.first;
      period = '$firstDate ~ $lastDate';
    } else {
      final now = DateTime.now();
      period = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    // 운동 부족 자동 감지
    final autoLowExercise = avgSteps < 3000;
    final adjustedRisk = riskFactors.copyWith(
      lowExercise: riskFactors.lowExercise || autoLowExercise,
    );

    return ClinicalReportData(
      userName: userName,
      age: age,
      assessmentDate: DateTime.now(),
      assessmentPeriod: period,
      caregiverPresent: caregiverPresent,
      medications: medications,
      reportType: reportType,
      memory: DomainScore(
        domainName: '기억력',
        score: memScore,
        prevScore: prevDomains['memory'],
        band: _band(memScore),
        hasData: memScore != null,
      ),
      attention: DomainScore(
        domainName: '주의집중력',
        score: attScore,
        prevScore: prevDomains['attention'],
        band: _band(attScore),
        hasData: attScore != null,
      ),
      executive: DomainScore(
        domainName: '실행기능',
        score: execScore,
        prevScore: prevDomains['executive'],
        band: _band(execScore),
        hasData: execScore != null,
      ),
      language: DomainScore(
        domainName: '언어능력',
        score: langScore,
        prevScore: prevDomains['language'],
        band: _band(langScore),
        hasData: langScore != null,
      ),
      // 시공간 지각은 아직 별도 측정 경로가 없다. 예전에는 기억력 점수를 그대로
      // 복제해 두 행이 항상 같은 값으로 인쇄됐는데, 측정하지 않은 영역에
      // 숫자를 채워 넣는 것은 근거를 만들어내는 것이다. 데이터 없음으로 둔다.
      visuospatial: const DomainScore(
        domainName: '시공간 지각',
        score: null,
        prevScore: null,
        band: CognitiveBand.normal,
        hasData: false,
      ),
      activityIndex: currentIndex,
      prevActivityIndex: prevIndex,
      averageSteps: avgSteps,
      gaitStability: gaitStability,
      sessionHistory: sessionHistory,
      riskFactors: adjustedRisk,
    );
  }

  static String _formatDateLabel(String isoDate) {
    try {
      final parts = isoDate.split('-');
      if (parts.length >= 3) {
        return '${parts[1]}/${parts[2]}';
      }
    } catch (_) {}
    return isoDate;
  }
}
