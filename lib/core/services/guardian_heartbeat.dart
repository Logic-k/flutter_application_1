import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_service.dart';
import 'guardian_cloud.dart';
import 'guardian_sync_service.dart';
import 'step_anomaly_policy.dart';

/// 보호자 하트비트. 백그라운드 걸음 서비스가 1시간마다 부른다.
///
/// 앱 화면이 꺼져 있어도, 공유 중인 공개 사본의 오늘 걸음 수와 마지막 소식 시각을
/// 갱신하고 링크 만료일을 민다. 그래서 보호자 웹이 '소식 없음'을 판단할 수 있다.
/// 마지막 동기화 때 저장한 기준선이 있으면 같은 [StepAnomalyPolicy]로 이상도 판정한다.
/// 어떤 실패도 걸음 측정 서비스를 멈추지 않는다.
class GuardianHeartbeat {
  GuardianHeartbeat._();

  static const interval = Duration(hours: 1);
  static const firstDelay = Duration(minutes: 2);
  static Timer? _first;
  static Timer? _periodic;

  static void start(int Function() todaySteps) {
    stop();
    _first = Timer(firstDelay, () => unawaited(send(todaySteps())));
    _periodic = Timer.periodic(interval, (_) => unawaited(send(todaySteps())));
  }

  static void stop() {
    _first?.cancel();
    _periodic?.cancel();
    _first = null;
    _periodic = null;
  }

  /// 한 번 보낸다. 보낼 대상이 없거나 실패하면 false.
  static Future<bool> send(
    int todaySteps, {
    GuardianCloud? cloud,
    String? Function()? uidProvider,
    DateTime Function()? clock,
    Future<bool> Function()? ensureFirebase,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 화면 isolate가 바꾼 공유 상태를 읽으려면 캐시를 다시 불러와야 한다.
      await prefs.reload();
      final token = prefs.getString(GuardianSyncService.heartbeatTokenKey);
      if (token == null) return false;
      if (!await (ensureFirebase ?? FirebaseService.ensureInitialized)()) return false;
      // 백그라운드에서는 새 익명 계정을 만들지 않는다. 화면이 만든 세션만 쓴다.
      final uid = (uidProvider ?? _currentUid)();
      if (uid == null || uid.isEmpty) return false;

      final now = (clock ?? DateTime.now)();
      final fields = <String, Object?>{
        'today_steps': todaySteps.clamp(0, GuardianSyncService.maxSteps),
      };
      final baseline = _decodeBaseline(prefs.getString(GuardianSyncService.heartbeatBaselineKey));
      if (baseline != null) {
        final verdict = StepAnomalyPolicy.evaluate(todaySteps: todaySteps, baselineSteps: baseline, now: now);
        if (verdict.evaluated) {
          fields['is_anomaly'] = verdict.isAnomaly;
          fields['anomaly_message'] =
              verdict.isAnomaly ? GuardianSyncService.anomalyMessage(todaySteps, verdict.baselineAvg) : '';
        }
      }
      await (cloud ?? FirestoreGuardianCloud())
          .patchView(token, expiresAt: now.add(GuardianSyncService.linkLifetime), fields: fields);
      return true;
    } catch (e) {
      debugPrint('[GuardianHeartbeat] 전송 실패(다음 주기에 다시 시도): $e');
      return false;
    }
  }

  static String? _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static List<double>? _decodeBaseline(String? raw) {
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return null;
    }
  }
}
