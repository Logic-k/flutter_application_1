import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/services/guardian_cloud.dart';
import 'package:flutter_application_1/core/services/guardian_heartbeat.dart';
import 'package:flutter_application_1/core/services/guardian_sync_service.dart';
import 'package:flutter_application_1/core/services/step_anomaly_policy.dart';
import '../../helpers/mock_definitions.dart';

/// 규칙(firestore.rules)과 같은 소유자·존재 판단을 흉내 내는 메모리 저장소.
/// 규칙 자체는 firebase-tests/의 에뮬레이터 테스트가 검증한다.
class _FakeCloud implements GuardianCloud {
  final links = <String, String>{}; // token -> ownerUid
  final views = <String, Map<String, Object?>>{};
  final legacyDeleted = <String>[];
  String currentUid = 'owner-a';
  GuardianCloudError? failNext;
  int writes = 0;

  void _maybeFail() {
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      throw GuardianCloudException(failure);
    }
  }

  void _requireOwner(String token) {
    final owner = links[token];
    if (owner == null) throw const GuardianCloudException(GuardianCloudError.notFound);
    if (owner != currentUid) throw const GuardianCloudException(GuardianCloudError.permissionDenied);
  }

  @override
  Future<void> createLink(String token,
      {required String ownerUid, required DateTime expiresAt, required Map<String, Object?> view}) async {
    _maybeFail();
    if (links.containsKey(token)) throw const GuardianCloudException(GuardianCloudError.permissionDenied);
    links[token] = ownerUid;
    views[token] = {...view, 'expiresAt': expiresAt};
    writes++;
  }

  @override
  Future<void> refreshLink(String token, {required DateTime expiresAt, required Map<String, Object?> view}) async {
    _maybeFail();
    _requireOwner(token);
    views[token] = {...view, 'expiresAt': expiresAt};
    writes++;
  }

  @override
  Future<void> patchView(String token, {required DateTime expiresAt, required Map<String, Object?> fields}) async {
    _maybeFail();
    _requireOwner(token);
    views[token] = {...?views[token], ...fields, 'expiresAt': expiresAt};
    writes++;
  }

  @override
  Future<void> deleteLink(String token) async {
    _maybeFail();
    final owner = links[token];
    if (owner != null && owner != currentUid) {
      throw const GuardianCloudException(GuardianCloudError.permissionDenied);
    }
    links.remove(token);
    views.remove(token);
  }

  @override
  Future<void> deleteLegacyView(String token) async {
    _maybeFail();
    legacyDeleted.add(token);
  }
}

const _allowedViewKeys = {
  'display_name', 'today_steps', 'weekly_steps', 'weekly_dates', 'weekly_avg',
  'scores', 'is_anomaly', 'anomaly_message', 'expiresAt',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDatabaseHelper db;
  late _FakeCloud cloud;
  var now = DateTime(2026, 10, 3, 10);
  var uid = 'owner-a';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = MockDatabaseHelper();
    cloud = _FakeCloud();
    now = DateTime(2026, 10, 3, 10);
    uid = 'owner-a';
    when(() => db.getWeeklySteps(1)).thenAnswer((_) async => [
          {'date': '2026-10-03', 'steps': 5000},
          {'date': '2026-10-02', 'steps': 6000},
        ]);
    when(() => db.getScoreHistory(1)).thenAnswer((_) async => [
          {'category': 'memory', 'score': 72.0, 'created_at': '2026-10-03'},
        ]);
  });

  GuardianSyncService service() => GuardianSyncService(
        db: db,
        cloud: cloud,
        uidProvider: () => uid,
        clock: () => now,
      );

  Future<GuardianSyncResult> sync({int steps = 5000}) =>
      service().syncToFirestore(userId: 1, displayName: '민준', todaySteps: steps);

  test('Firebase 없이 서비스를 만들고 128비트 토큰을 기기에서 만든다', () async {
    expect(Firebase.apps, isEmpty);
    final token = await GuardianSyncService(db: db).getOrCreateToken(1);
    expect(token, matches(RegExp(r'^[A-Za-z0-9_-]{22}$')));
    expect(Firebase.apps, isEmpty);
  });

  test('익명 uid가 없으면 건강 기록을 읽지도 보내지도 않는다', () async {
    final result = await GuardianSyncService(db: db, cloud: cloud, uidProvider: () => null)
        .syncToFirestore(userId: 1, displayName: '민준', todaySteps: 5000);
    expect(result.success, isFalse);
    expect(cloud.writes, 0);
    verifyNever(() => db.getWeeklySteps(any()));
    verifyNever(() => db.getScoreHistory(any()));
  });

  test('첫 동기화는 비공개 링크와 허용 필드만 담은 공개 사본을 만든다', () async {
    final result = await sync();
    expect(result.success, isTrue);
    expect(result.rotated, isFalse);
    expect(cloud.links[result.token], 'owner-a');
    final view = cloud.views[result.token]!;
    expect(_allowedViewKeys.containsAll(view.keys), isTrue, reason: '${view.keys}');
    expect(view.containsKey('ownerUid'), isFalse);
    expect(view.containsKey('emergency_contact'), isFalse);
    expect(view['display_name'], '민준');
    expect(view['today_steps'], 5000);
    expect(view['weekly_steps'], [6000, 5000]);
    expect(view['expiresAt'], now.add(GuardianSyncService.linkLifetime));
  });

  test('다시 동기화하면 같은 링크의 만료일을 민다', () async {
    final first = await sync();
    now = now.add(const Duration(days: 10));
    final second = await sync(steps: 6200);
    expect(second.token, first.token);
    expect(second.rotated, isFalse);
    expect(cloud.views[first.token]!['expiresAt'], now.add(GuardianSyncService.linkLifetime));
    expect(cloud.views[first.token]!['today_steps'], 6200);
  });

  test('익명 uid가 바뀌어 쓰기가 거부되면 새 토큰으로 다시 만들고 알린다', () async {
    final first = await sync();
    uid = 'owner-b';
    cloud.currentUid = 'owner-b';
    final second = await sync();
    expect(second.success, isTrue);
    expect(second.rotated, isTrue);
    expect(second.token, isNot(first.token));
    expect(cloud.links[second.token], 'owner-b');
    expect(await service().getOrCreateToken(1), second.token);
  });

  test('링크가 다른 곳에서 지워졌으면(not-found) 새 링크를 만든다', () async {
    final first = await sync();
    cloud.links.clear();
    final second = await sync();
    expect(second.rotated, isTrue);
    expect(cloud.links.keys, [second.token]);
    expect(second.token, isNot(first.token));
  });

  test('연결 실패는 실패로 돌려주고 토큰을 바꾸지 않는다', () async {
    final first = await sync();
    cloud.failNext = GuardianCloudError.unavailable;
    final second = await sync();
    expect(second.success, isFalse);
    expect(await service().getOrCreateToken(1), first.token);
  });

  test('v1 토큰의 예전 공개 문서를 지우고 기기에서 잊는다', () async {
    SharedPreferences.setMockInitialValues({'guardian_token_1': 'ABCDEFGH12345678'});
    await sync();
    expect(cloud.legacyDeleted, ['ABCDEFGH12345678']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('guardian_token_1'), isNull);
  });

  test('이상 알림은 이미 공유 중인 링크에만 올리고 전화번호를 넣지 않는다', () async {
    final before = await service().syncAnomalyAlert(userId: 1, todaySteps: 100, weeklyAvg: 5000);
    expect(before, GuardianAlertResult.notSharing);
    expect(cloud.writes, 0);

    final shared = await sync();
    final after = await service().syncAnomalyAlert(userId: 1, todaySteps: 100, weeklyAvg: 5000);
    expect(after, GuardianAlertResult.sent);
    final view = cloud.views[shared.token]!;
    expect(view['is_anomaly'], isTrue);
    expect(view['today_steps'], 100);
    expect(view.containsKey('emergency_contact'), isFalse);
  });

  test('공유 중지는 두 문서를 지우고 다시 공유하기 전까지 동기화를 막는다', () async {
    final shared = await sync();
    expect(await service().stopSharing(1), isTrue);
    expect(cloud.links, isEmpty);
    expect(cloud.views, isEmpty);
    expect(await service().isSharingStopped(1), isTrue);
    expect((await sync()).success, isFalse);

    final resumed = await service().resumeSharing(1);
    expect(resumed, isNot(shared.token));
    final again = await sync();
    expect(again.success, isTrue);
    expect(again.token, resumed);
  });

  test('연결 실패로 공유를 중지하지 못하면 상태를 그대로 둔다', () async {
    final shared = await sync();
    cloud.failNext = GuardianCloudError.unavailable;
    expect(await service().stopSharing(1), isFalse);
    expect(await service().isSharingStopped(1), isFalse);
    expect(cloud.links.containsKey(shared.token), isTrue);
  });

  test('새 링크 만들기는 예전 링크를 끊고 새 토큰을 준다', () async {
    final shared = await sync();
    final fresh = await service().reissue(1);
    expect(fresh, isNotNull);
    expect(fresh, isNot(shared.token));
    expect(cloud.links.containsKey(shared.token), isFalse);
    expect(await service().isSharingStopped(1), isFalse);
  });

  test('하트비트 대상은 로그인해 공유 중인 사용자의 링크만 가리킨다', () async {
    final shared = await sync();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(GuardianSyncService.heartbeatTokenKey), shared.token);
    expect(prefs.getString(GuardianSyncService.heartbeatBaselineKey), '[6000.0]');

    await service().activateHeartbeatFor(null);
    expect(prefs.getString(GuardianSyncService.heartbeatTokenKey), isNull);

    await service().activateHeartbeatFor(1);
    expect(prefs.getString(GuardianSyncService.heartbeatTokenKey), shared.token);

    await service().stopSharing(1);
    await service().activateHeartbeatFor(1);
    expect(prefs.getString(GuardianSyncService.heartbeatTokenKey), isNull);
  });

  group('백그라운드 하트비트', () {
    Future<bool> beat(int steps) => GuardianHeartbeat.send(
          steps,
          cloud: cloud,
          uidProvider: () => uid,
          clock: () => now,
          ensureFirebase: () async => true,
        );

    test('공유 중이 아니면 아무것도 보내지 않는다', () async {
      expect(await beat(3000), isFalse);
      expect(cloud.writes, 0);
    });

    test('화면 없이 오늘 걸음 수를 올리고 만료일을 민다', () async {
      final shared = await sync();
      now = now.add(const Duration(hours: 3));
      expect(await beat(7300), isTrue);
      final view = cloud.views[shared.token]!;
      expect(view['today_steps'], 7300);
      expect(view['expiresAt'], now.add(GuardianSyncService.linkLifetime));
    });

    test('저녁에 기준선보다 크게 줄면 같은 정책으로 이상을 표시한다', () async {
      when(() => db.getWeeklySteps(1)).thenAnswer((_) async => [
            {'date': '2026-10-03', 'steps': 100},
            {'date': '2026-10-02', 'steps': 6000},
            {'date': '2026-10-01', 'steps': 5000},
            {'date': '2026-09-30', 'steps': 7000},
          ]);
      final shared = await sync(steps: 100);
      now = DateTime(2026, 10, 3, 19);
      expect(await beat(300), isTrue);
      final view = cloud.views[shared.token]!;
      expect(view['is_anomaly'], isTrue);
      expect(view['anomaly_message'], contains('300보'));
    });

    test('익명 세션이 없으면 새로 만들지 않고 건너뛴다', () async {
      await sync();
      uid = '';
      final writesBefore = cloud.writes;
      expect(await beat(3000), isFalse);
      expect(cloud.writes, writesBefore);
    });
  });

  test('공개 사본 값은 규칙 범위에 맞춘다', () {
    final view = GuardianSyncService.buildView(
      displayName: '가' * 25,
      todaySteps: 250000,
      weeklyRows: [
        for (var i = 0; i < 9; i++) {'date': '2026-09-${20 + i}', 'steps': -5},
      ],
      scoreHistory: [
        for (var i = 0; i < 6; i++) {'category': 'c$i', 'score': 50.0, 'created_at': '2026-10-0$i'},
      ],
      verdict: const StepAnomalyVerdict(isAnomaly: false, baselineAvg: 0, evaluated: false),
    );
    expect((view['display_name'] as String).length, GuardianSyncService.maxNameLength);
    expect(view['today_steps'], GuardianSyncService.maxSteps);
    expect(view['weekly_steps'], hasLength(7));
    expect((view['weekly_steps'] as List).every((s) => s == 0), isTrue);
    expect(view['scores'], hasLength(GuardianSyncService.maxScores));
    expect(view['anomaly_message'], '');
  });
}
