import '../../../core/database_helper.dart';
import '../../../core/user_provider.dart';

enum ReportType { doctor, caregiver }

enum CognitiveBand { normal, borderline, needsFollowUp, specialistReferral }

extension CognitiveBandExt on CognitiveBand {
  String get label {
    switch (this) {
      case CognitiveBand.normal:
        return '정상';
      case CognitiveBand.borderline:
        return '경계선';
      case CognitiveBand.needsFollowUp:
        return '경과 관찰';
      case CognitiveBand.specialistReferral:
        return '전문의 의뢰';
    }
  }
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

  final double mmseEquivalent;
  final double? prevMmseEquivalent;
  final int gdsLevel;

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
    required this.mmseEquivalent,
    this.prevMmseEquivalent,
    required this.gdsLevel,
    required this.averageSteps,
    required this.gaitStability,
    required this.sessionHistory,
    required this.riskFactors,
  });

  // 100점 기준 CognitiveBand 결정
  static CognitiveBand _band(double? score) {
    if (score == null) return CognitiveBand.normal;
    if (score >= 75) return CognitiveBand.normal;
    if (score >= 55) return CognitiveBand.borderline;
    if (score >= 35) return CognitiveBand.needsFollowUp;
    return CognitiveBand.specialistReferral;
  }

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

  // MMSE 환산 (데이터 있는 도메인만 사용)
  static double _computeMmse(Map<String, double?> domains) {
    final values = domains.values.where((v) => v != null).cast<double>().toList();
    if (values.isEmpty) return 0.0;
    final avg = values.reduce((a, b) => a + b) / values.length;
    return (avg / 100.0 * 30).clamp(0.0, 30.0);
  }

  // GDS 레벨 결정 (MMSE 환산 기준)
  static int _gdsFromMmse(double mmse) {
    if (mmse >= 21) return 0;
    if (mmse >= 10) return 1;
    return 2;
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

    final currentMmse = _computeMmse(currentDomains);
    final prevMmse = sessions.length >= 2 ? _computeMmse(prevDomains) : null;

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
      visuospatial: DomainScore(
        domainName: '시공간 지각',
        score: memScore,
        prevScore: prevDomains['memory'],
        band: _band(memScore),
        hasData: memScore != null,
      ),
      mmseEquivalent: currentMmse,
      prevMmseEquivalent: prevMmse,
      gdsLevel: _gdsFromMmse(currentMmse),
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
