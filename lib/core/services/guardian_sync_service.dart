// ────────────────────────────────────────────────────────────
// [TTA 표준 적용] TTAK.KO-10.1397-Part4
//   「IoT 기반 위급상황 개인정보 긴급조회 스마트시티 서비스 - 제4부: 데이터 모델」
//
// 적용 지점: 보호자 공개 사본 스키마(buildView)와 이상 알림(syncAnomalyAlert).
//   - 표준의 긴급조회 데이터 모델(상황 발생 여부·시각 / 최소 필수 항목 / 조회 주체
//     한정)을 공개 사본 필드에 매핑했다.
//     상황 발생 여부 -> is_anomaly, 상황 설명 -> anomaly_message,
//     발생 시각 -> last_sync·last_heartbeat, 최소 필수 항목 -> 활동·인지 요약,
//     조회 주체 한정 -> 128비트 토큰과 30일 슬라이딩 만료(generateToken, linkLifetime).
//   - 대상자 식별자(소유자 uid)는 공개 사본이 아니라 비공개 링크 문서에만 둔다.
//     전화번호·로그인 아이디는 공개 사본에 넣지 않는다(최소 공개).
// ────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_service.dart';
import '../database_helper.dart';
import 'guardian_cloud.dart';
import 'step_anomaly_policy.dart';

/// 보호자 안심 연결 v2.
///
/// 한 링크는 비공개 링크 문서와 공개 사본 문서 두 개다. 토큰은 128비트 무작위
/// 값이고, 동기화·하트비트가 성공할 때마다 만료일을 [linkLifetime]만큼 민다.
/// 30일 동안 소식이 없으면 링크가 저절로 닫힌다(규칙이 읽기를 거부).
/// 기기의 익명 uid가 바뀌어 예전 링크를 쓸 수 없으면 새 토큰으로 다시 만든다.
class GuardianSyncService {
  GuardianSyncService({
    DatabaseHelper? db,
    GuardianCloud? cloud,
    String? Function()? uidProvider,
    DateTime Function()? clock,
  })  : _db = db ?? DatabaseHelper(),
        _cloud = cloud ?? FirestoreGuardianCloud(),
        _uidProvider = uidProvider ?? (() => AuthService.uid),
        _clock = clock ?? DateTime.now;

  final DatabaseHelper _db;
  final GuardianCloud _cloud;
  final String? Function() _uidProvider;
  final DateTime Function() _clock;

  static const linkLifetime = Duration(days: 30);
  static const maxScores = 4;
  static const maxSteps = 100000;
  static const maxNameLength = 20;
  static const _hostingBase = 'https://memorylink-7af26.web.app';

  // 기기 저장 키 (로컬 사용자 id별)
  static const _tokenKey = 'guardian_v2_token_';
  static const _createdKey = 'guardian_v2_created_';
  static const _stoppedKey = 'guardian_v2_stopped_';
  static const _legacyTokenKey = 'guardian_token_';

  /// 백그라운드 서비스가 하트비트를 보낼 토큰과 이상 판정 기준선.
  /// 로그인한 사용자가 공유 중일 때만 채워진다.
  static const heartbeatTokenKey = 'guardian_hb_token';
  static const heartbeatBaselineKey = 'guardian_hb_baseline';

  static const unavailableMessage = '보호자 연결을 사용할 수 없습니다. 연결 상태를 확인한 뒤 다시 시도해 주세요.';

  String guardianUrl(String token) => '$_hostingBase/guardian.html?token=$token';

  /// 128비트 무작위 토큰(base64url 22자).
  static String generateToken([Random? random]) {
    final rand = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static int _clampSteps(int steps) => steps.clamp(0, maxSteps);

  static String anomalyMessage(int todaySteps, double baselineAvg) =>
      '오늘 평소(평균 ${baselineAvg.round()}보)보다 활동량이 매우 적습니다 (오늘 $todaySteps보). 안부를 확인해 주세요.';

  /// 공개 사본에 들어갈 값. 규칙의 허용 목록과 범위(firestore.rules)에 맞춘다.
  static Map<String, Object?> buildView({
    required String displayName,
    required int todaySteps,
    required List<Map<String, dynamic>> weeklyRows,
    required List<Map<String, dynamic>> scoreHistory,
    required StepAnomalyVerdict verdict,
  }) {
    // DB는 날짜 내림차순(최근 7일)으로 준다. 보호자 차트는 오름차순으로 그린다.
    final sorted = weeklyRows.take(7).toList().reversed.toList();
    final steps = sorted.map((e) => _clampSteps((e['steps'] as num).toInt())).toList();
    final dates = sorted.map((e) => e['date'] as String).toList();
    final weeklyAvg = steps.isEmpty ? 0 : (steps.reduce((a, b) => a + b) / steps.length).round();

    // 카테고리별 최신 점수만, 최근 것부터 최대 [maxScores]개.
    final latest = <String, Map<String, Object?>>{};
    for (final s in scoreHistory) {
      final category = s['category'] as String;
      latest[category] = {
        'category': category,
        'score': (s['score'] as num).toDouble(),
        'date': s['created_at'] as String,
      };
    }
    final scores = latest.values.toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    final name = displayName.trim();
    return {
      if (name.isNotEmpty) 'display_name': name.length > maxNameLength ? name.substring(0, maxNameLength) : name,
      'today_steps': _clampSteps(todaySteps),
      'weekly_steps': steps,
      'weekly_dates': dates,
      'weekly_avg': _clampSteps(weeklyAvg),
      'scores': scores.take(maxScores).toList(),
      'is_anomaly': verdict.isAnomaly,
      'anomaly_message': verdict.isAnomaly ? anomalyMessage(todaySteps, verdict.baselineAvg) : '',
    };
  }

  Future<bool> isSharingStopped(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_stoppedKey$userId') ?? false;
  }

  /// 지금 토큰. 없으면 기기 안에서만 새로 만든다(서버 문서는 첫 동기화 때 생긴다).
  Future<String> getOrCreateToken(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_tokenKey$userId';
    var token = prefs.getString(key);
    if (token == null) {
      token = generateToken();
      await prefs.setString(key, token);
      await prefs.remove('$_createdKey$userId');
    }
    return token;
  }

  Future<GuardianSyncResult> syncToFirestore({
    required int userId,
    required String displayName,
    required int todaySteps,
  }) async {
    try {
      final ownerUid = _uidProvider();
      if (ownerUid == null || ownerUid.isEmpty) {
        return const GuardianSyncResult.failure(unavailableMessage);
      }
      if (await isSharingStopped(userId)) {
        return const GuardianSyncResult.failure('보호자 공유가 중지된 상태입니다.');
      }
      final now = _clock();
      final weeklyRows = await _db.getWeeklySteps(userId);
      // 이상 판정은 StepAnomalyPolicy 단일 기준을 따른다. 기준선에는 오늘을 넣지 않는다.
      final baseline = StepAnomalyPolicy.baselineFromWeeklyRows(weeklyRows, now: now);
      final verdict = StepAnomalyPolicy.evaluate(todaySteps: todaySteps, baselineSteps: baseline, now: now);
      final view = buildView(
        displayName: displayName,
        todaySteps: todaySteps,
        weeklyRows: weeklyRows,
        scoreHistory: await _db.getScoreHistory(userId),
        verdict: verdict,
      );
      final published = await _publish(userId, ownerUid, view, now.add(linkLifetime));
      await _deleteLegacy(userId);
      await _setHeartbeatTarget(published.token, baseline);
      return GuardianSyncResult(
        success: true,
        token: published.token,
        isAnomaly: verdict.isAnomaly,
        rotated: published.rotated,
      );
    } catch (e) {
      debugPrint('[GuardianSync] 동기화 실패: $e');
      return GuardianSyncResult.failure(e.toString());
    }
  }

  Future<_Published> _publish(int userId, String ownerUid, Map<String, Object?> view, DateTime expiresAt) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getOrCreateToken(userId);
    final created = prefs.getBool('$_createdKey$userId') ?? false;
    try {
      if (created) {
        await _cloud.refreshLink(token, expiresAt: expiresAt, view: view);
      } else {
        await _createOrAdopt(token, ownerUid, expiresAt, view);
      }
      await prefs.setBool('$_createdKey$userId', true);
      return _Published(token, rotated: false);
    } on GuardianCloudException catch (e) {
      if (!e.needsNewLink) rethrow;
      // 기기의 익명 uid가 바뀌었거나 링크가 지워져 예전 링크를 쓸 수 없다.
      // 새 토큰으로 다시 만들고 QR을 바꾼다. 예전 문서는 만료일이 지나면 닫힌다.
      final fresh = generateToken();
      await prefs.setString('$_tokenKey$userId', fresh);
      await prefs.remove('$_createdKey$userId');
      await _cloud.createLink(fresh, ownerUid: ownerUid, expiresAt: expiresAt, view: view);
      await prefs.setBool('$_createdKey$userId', true);
      return _Published(fresh, rotated: true);
    }
  }

  Future<void> _createOrAdopt(String token, String ownerUid, DateTime expiresAt, Map<String, Object?> view) async {
    try {
      await _cloud.createLink(token, ownerUid: ownerUid, expiresAt: expiresAt, view: view);
    } on GuardianCloudException catch (e) {
      // 앞선 시도가 서버에는 반영됐는데 기기 기록 전에 끊긴 경우, 이미 내 링크면 갱신으로 잇는다.
      if (e.code != GuardianCloudError.permissionDenied) rethrow;
      await _cloud.refreshLink(token, expiresAt: expiresAt, view: view);
    }
  }

  /// v1(16자 토큰) 시절 공개 문서를 지운다. 예전 정상 문서에 남은 전화번호도 함께 사라진다.
  Future<bool> _deleteLegacy(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString('$_legacyTokenKey$userId');
    if (legacy == null) return true;
    try {
      await _cloud.deleteLegacyView(legacy);
    } on GuardianCloudException catch (e) {
      // 연결 문제면 다음 동기화 때 다시 시도한다. 소유자가 달라 지울 수 없으면 포기한다.
      if (!e.needsNewLink) return false;
    } catch (_) {
      return false;
    }
    await prefs.remove('$_legacyTokenKey$userId');
    return true;
  }

  /// 이미 공유 중인 링크에만 경고를 올린다. 공유를 시작하지 않았으면 보호자 문서를 만들지 않는다.
  Future<GuardianAlertResult> syncAnomalyAlert({
    required int userId,
    required int todaySteps,
    required int weeklyAvg,
  }) async {
    try {
      final ownerUid = _uidProvider();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('$_tokenKey$userId');
      final shared = token != null &&
          (prefs.getBool('$_createdKey$userId') ?? false) &&
          !(prefs.getBool('$_stoppedKey$userId') ?? false);
      if (!shared) return GuardianAlertResult.notSharing;
      if (ownerUid == null || ownerUid.isEmpty) return GuardianAlertResult.failed;
      await _cloud.patchView(token, expiresAt: _clock().add(linkLifetime), fields: {
        'today_steps': _clampSteps(todaySteps),
        'is_anomaly': true,
        'anomaly_message': anomalyMessage(todaySteps, weeklyAvg.toDouble()),
      });
      return GuardianAlertResult.sent;
    } catch (e) {
      debugPrint('[GuardianSync] 이상 알림 전송 실패: $e');
      return GuardianAlertResult.failed;
    }
  }

  /// 공유 중지: 서버의 두 문서를 지우고 기기의 토큰을 버린다.
  /// 연결 문제로 지우지 못하면 false를 돌려주고 상태를 바꾸지 않는다.
  Future<bool> stopSharing(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('$_tokenKey$userId');
    final created = prefs.getBool('$_createdKey$userId') ?? false;
    if (token != null && created) {
      try {
        await _cloud.deleteLink(token);
      } on GuardianCloudException catch (e) {
        // 소유자가 달라 지울 수 없는 링크는 만료일이 지나면 닫힌다.
        if (!e.needsNewLink) return false;
      } catch (_) {
        return false;
      }
    }
    await prefs.remove('$_tokenKey$userId');
    await prefs.remove('$_createdKey$userId');
    await prefs.setBool('$_stoppedKey$userId', true);
    if (token != null && prefs.getString(heartbeatTokenKey) == token) {
      await _clearHeartbeat(prefs);
    }
    return true;
  }

  /// 다시 공유하기: 중지 상태를 풀고 새 토큰을 만든다.
  Future<String> resumeSharing(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_stoppedKey$userId');
    return getOrCreateToken(userId);
  }

  /// 새 링크 만들기: 예전 링크를 끊고 새 토큰을 만든다. 끊지 못하면 null.
  Future<String?> reissue(int userId) async {
    if (!await stopSharing(userId)) return null;
    return resumeSharing(userId);
  }

  /// '서버에 저장된 내 데이터 삭제'의 보호자 부분: v2 링크와 v1 잔존 문서를 지운다.
  Future<bool> deleteCloudData(int userId) async {
    final stopped = await stopSharing(userId);
    final legacy = await _deleteLegacy(userId);
    return stopped && legacy;
  }

  /// 계정 삭제 뒤: 이 계정의 보호자 연결 기록을 기기에서 지운다. 서버 문서는 그 전에 지운다.
  static Future<void> forgetLocalState(SharedPreferences prefs, int userId) async {
    final token = prefs.getString('$_tokenKey$userId');
    for (final key in [_tokenKey, _createdKey, _stoppedKey, _legacyTokenKey]) {
      await prefs.remove('$key$userId');
    }
    if (token != null && prefs.getString(heartbeatTokenKey) == token) {
      await _clearHeartbeat(prefs);
    }
  }

  /// 로그인 사용자가 바뀌면 하트비트 대상을 그 사용자의 링크로 바꾼다(없으면 비운다).
  Future<void> activateHeartbeatFor(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await _clearHeartbeat(prefs);
      return;
    }
    final token = prefs.getString('$_tokenKey$userId');
    final shared = token != null &&
        (prefs.getBool('$_createdKey$userId') ?? false) &&
        !(prefs.getBool('$_stoppedKey$userId') ?? false);
    if (!shared) {
      await _clearHeartbeat(prefs);
      return;
    }
    if (prefs.getString(heartbeatTokenKey) != token) {
      // 다른 사용자의 기준선이 섞이지 않게 비운다. 다음 동기화 때 다시 채워진다.
      await prefs.remove(heartbeatBaselineKey);
      await prefs.setString(heartbeatTokenKey, token);
    }
  }

  Future<void> _setHeartbeatTarget(String token, List<double> baseline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(heartbeatTokenKey, token);
    await prefs.setString(heartbeatBaselineKey, jsonEncode(baseline));
  }

  static Future<void> _clearHeartbeat(SharedPreferences prefs) async {
    await prefs.remove(heartbeatTokenKey);
    await prefs.remove(heartbeatBaselineKey);
  }
}

class _Published {
  final String token;
  final bool rotated;
  const _Published(this.token, {required this.rotated});
}

enum GuardianAlertResult { sent, notSharing, failed }

class GuardianSyncResult {
  final bool success;
  final String token;
  final bool isAnomaly;

  /// 예전 링크를 쓸 수 없어 새 토큰을 만들었다. 보호자에게 새 QR을 보내야 한다.
  final bool rotated;
  final String? error;

  const GuardianSyncResult({
    required this.success,
    required this.token,
    required this.isAnomaly,
    this.rotated = false,
    this.error,
  });

  const GuardianSyncResult.failure(String this.error)
      : success = false,
        token = '',
        isAnomaly = false,
        rotated = false;
}
