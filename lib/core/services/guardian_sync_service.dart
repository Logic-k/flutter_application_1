// ─────────────────────────────────────────────────────────────────────────
// [TTA 표준 적용] TTAK.KO-10.1397-Part4
//   「IoT 기반 위급상황 개인정보 긴급조회 스마트시티 서비스 - 제4부: 데이터 모델」
//
// 적용 지점: 보호자 동기화 문서 스키마(syncToFirestore)와 긴급 알림(syncAnomalyAlert).
//   - 표준의 긴급조회 데이터 모델(대상자 식별자 / 상황 발생 여부·시각 / 최소 필수 항목 /
//     조회 주체 한정)을 Firestore 문서 필드에 매핑했다.
//     대상자 식별자 -> ownerUid·userId, 상황 발생 여부 -> is_anomaly,
//     상황 설명 -> anomaly_message, 최소 필수 항목 -> 활동·인지 요약,
//     조회 주체 한정 -> _generateToken()의 암호학적 난수 16자 토큰.
//   - 평상시에는 활동·인지 요약만 노출하고, 이상 플래그가 참일 때에만 상황 설명과
//     비상연락처(emergency_contact)를 활성화한다. "이상 발생 시 누구에게 무엇을
//     공개하는가"를 임의 판단이 아니라 표준으로 고정해 과잉 공개와 과소 공개를 함께 피한다.
// ─────────────────────────────────────────────────────────────────────────
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_service.dart';
import '../database_helper.dart';
import 'step_anomaly_policy.dart';

class GuardianSyncService {
  final DatabaseHelper _db;
  final FirebaseFirestore? _firestoreOverride;

  static const _tokenPrefKey = 'guardian_token_';
  static const _hostingBase = 'https://memorylink-7af26.web.app';

  GuardianSyncService({DatabaseHelper? db, FirebaseFirestore? firestore})
      : _db = db ?? DatabaseHelper(),
        _firestoreOverride = firestore;

  /// Firebase 초기화에 실패한 로컬 전용 모드(예: iOS에 GoogleService-Info.plist가
  /// 없을 때)에서는 `FirebaseFirestore.instance`가 `[core/no-app]`을 던진다.
  /// 생성자에서 접근하면 보호자 화면이 열리지 않고 이상 알림도 사용자에게 뜨지 않으므로,
  /// 실제 전송 시점(각 메서드의 try 안)에서만 접근해 '전송 실패'로 보고되게 한다.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  String guardianUrl(String token) => '$_hostingBase/guardian.html?token=$token';

  Future<String> getOrCreateToken(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_tokenPrefKey$userId';
    var token = prefs.getString(key);
    if (token == null) {
      token = _generateToken(userId);
      await prefs.setString(key, token);
    }
    return token;
  }

  // 보호자 링크는 URL만 알면 건강 데이터를 열람할 수 있으므로
  // 추측이 어렵도록 암호학적 난수로 16자 토큰을 생성한다.
  String _generateToken(int userId) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<GuardianSyncResult> syncToFirestore({
    required int userId,
    required String userName,
    required int todaySteps,
    String? emergencyContact,
  }) async {
    try {
      final token = await getOrCreateToken(userId);

      final weeklyData = await _db.getWeeklySteps(userId);
      // 날짜 오름차순 정렬 (DB는 DESC 반환)
      final sorted = List<Map<String, dynamic>>.from(weeklyData.reversed);
      final weeklyStepsList = sorted.map((e) => (e['steps'] as num).toInt()).toList();
      final weeklyDateList = sorted.map((e) => e['date'] as String).toList();

      final weeklyAvg = weeklyStepsList.isEmpty
          ? 0
          : (weeklyStepsList.reduce((a, b) => a + b) / weeklyStepsList.length).round();

      // 이상 판정은 StepAnomalyPolicy 단일 기준을 따른다. 기준선에는 오늘을
      // 넣지 않는다 — 오늘 값이 평균을 끌어내려 감지가 둔감해지는 것을 막는다.
      // (weekly_avg_steps 필드는 대시보드 표시용 주간 평균이라 기존 의미 유지)
      final verdict = StepAnomalyPolicy.evaluate(
        todaySteps: todaySteps,
        baselineSteps: StepAnomalyPolicy.baselineFromWeeklyRows(weeklyData),
      );
      final isAnomaly = verdict.isAnomaly;
      final anomalyMessage = isAnomaly
          ? '오늘 평소(평균 ${verdict.baselineAvg.round()}보)보다 활동량이 매우 적습니다 (오늘 $todaySteps보). 안부를 확인해 주세요.'
          : '';

      final scoreHistory = await _db.getScoreHistory(userId);
      // 카테고리별 최신 점수만 추출
      final Map<String, Map<String, dynamic>> latestByCategory = {};
      for (final s in scoreHistory) {
        final cat = s['category'] as String;
        latestByCategory[cat] = {
          'category': cat,
          'score': (s['score'] as num).toDouble(),
          'date': s['created_at'] as String,
        };
      }
      final recentScores = latestByCategory.values.toList();

      await _firestore.collection('guardian_views').doc(token).set({
        'token': token,
        // Security Rules 소유권 판별용 (rules: ownerUid == request.auth.uid)
        'ownerUid': AuthService.uid ?? '',
        'user_name': userName,
        'today_steps': todaySteps,
        'weekly_avg_steps': weeklyAvg,
        'weekly_steps_data': weeklyStepsList,
        'weekly_dates': weeklyDateList,
        'recent_scores': recentScores,
        'is_anomaly': isAnomaly,
        'anomaly_message': anomalyMessage,
        'emergency_contact': emergencyContact ?? '',
        'last_sync': FieldValue.serverTimestamp(),
      });

      // 글로벌 통계 업데이트 (소셜 랭킹용)
      await _updateGlobalStats(recentScores);

      return GuardianSyncResult(
        success: true,
        token: token,
        isAnomaly: isAnomaly,
      );
    } catch (e) {
      return GuardianSyncResult(
        success: false,
        token: '',
        isAnomaly: false,
        error: e.toString(),
      );
    }
  }

  /// 이상 감지 시 Firestore에 경량 업데이트 (전체 동기화 없이 anomaly 필드만 갱신)
  ///
  /// 반환값은 전송 성공 여부다. 예전에는 실패를 catch로 완전히 삼켜서 —
  /// 안전 기능이 조용히 죽으면 보호자는 아무 일 없다고 믿는다 — 호출자가
  /// 실패를 사용자에게 알릴 방법이 없었다.
  Future<bool> syncAnomalyAlert({
    required int userId,
    required String userName,
    required int todaySteps,
    required int weeklyAvg,
    String? emergencyContact,
  }) async {
    try {
      final token = await getOrCreateToken(userId);
      final message =
          '[MemoryLink 안심 알림] $userName 님의 오늘 활동량이 평소(평균 $weeklyAvg보)보다 '
          '현저히 낮은 $todaySteps보에 머물러 있습니다. 안부를 확인해 주시기 바랍니다.';
      await _firestore.collection('guardian_views').doc(token).set({
        'ownerUid': AuthService.uid ?? '',
        'is_anomaly': true,
        'anomaly_message': message,
        'user_name': userName,
        'today_steps': todaySteps,
        'weekly_avg_steps': weeklyAvg,
        'emergency_contact': emergencyContact ?? '',
        'last_sync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[GuardianSync] 이상 알림 전송 실패: $e');
      return false;
    }
  }

  /// 동기화 시 글로벌 통계 EMA 업데이트 (소셜 랭킹용)
  ///
  /// Firestore `global_stats/score_stats` 문서에 카테고리별 평균을
  /// 지수 이동 평균(alpha=0.1)으로 갱신합니다.
  Future<void> _updateGlobalStats(List<Map<String, dynamic>> recentScores) async {
    if (recentScores.isEmpty) return;
    try {
      final ref = _firestore.collection('global_stats').doc('score_stats');
      final snap = await ref.get();

      final Map<String, dynamic> categoryStats =
          snap.exists ? (snap.data()?['category_stats'] as Map<String, dynamic>? ?? {}) : {};

      double overallSum = 0;
      int overallCount = 0;

      for (final s in recentScores) {
        final cat = s['category'] as String? ?? '';
        final score = (s['score'] as num?)?.toDouble() ?? 0.0;
        if (cat.isEmpty || score <= 0) continue;

        final prev = categoryStats[cat] as Map<String, dynamic>?;
        final oldAvg = (prev?['avg'] as num?)?.toDouble() ?? score;
        final newAvg = 0.9 * oldAvg + 0.1 * score;

        categoryStats[cat] = {'avg': newAvg, 'std_dev': prev?['std_dev'] ?? 15.0};
        overallSum += newAvg;
        overallCount++;
      }

      final double overallAvg = overallCount > 0 ? overallSum / overallCount : 65.0;

      await ref.set({
        'avg_score': overallAvg,
        'std_dev': snap.exists ? (snap.data()?['std_dev'] ?? 15.0) : 15.0,
        'category_stats': categoryStats,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // 통계 업데이트 실패는 메인 동기화에 영향 없음
    }
  }
}

class GuardianSyncResult {
  final bool success;
  final String token;
  final bool isAnomaly;
  final String? error;

  const GuardianSyncResult({
    required this.success,
    required this.token,
    required this.isAnomaly,
    this.error,
  });
}
