import 'dart:io';

import 'package:flutter_application_1/core/database_helper.dart';
import 'package:flutter_application_1/core/services/account_deletion_service.dart';
import 'package:flutter_application_1/core/services/cloud_data_deletion_service.dart';
import 'package:flutter_application_1/core/services/diary_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// '계정과 모든 데이터 삭제' (LAUNCH_AUDIT P0-07).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper db;
  late Directory documents;
  late Directory temporary;

  setUp(() async {
    DatabaseHelper.resetForTest();
    db = DatabaseHelper();
    SharedPreferences.setMockInitialValues({});
    documents = await Directory.systemTemp.createTemp('ml_docs');
    temporary = await Directory.systemTemp.createTemp('ml_tmp');
  });

  tearDown(() async {
    await documents.delete(recursive: true);
    await temporary.delete(recursive: true);
  });

  Future<int> addUser(String username) => db.insertUser({
        'username': username,
        'password': 'pw-$username',
        'goal': 'prevention',
        'age': 70,
        'weight': 60.0,
        'has_completed_onboarding': 1,
        'pedometer_enabled': 0,
      });

  Future<void> addRecords(int userId) async {
    final raw = await db.database;
    final now = DateTime.now().toIso8601String();
    await raw.insert('training_scores', {'user_id': userId, 'category': 'memory', 'score': 70.0, 'created_at': now});
    await raw.insert('daily_steps', {'user_id': userId, 'steps': 3000, 'date': '2026-10-03'});
    await raw.insert('daily_active_users', {'user_id': userId, 'date': '2026-10-03'});
    await raw.insert('diary_entries',
        {'user_id': userId, 'date': '2026-10-03', 'content': '일기', 'created_at': now, 'updated_at': now});
    await raw.insert('health_logs', {'user_id': userId, 'date': '2026-10-03', 'created_at': now, 'updated_at': now});
    await raw.insert('training_attempts', {
      'id': 'attempt-$userId', 'user_id': userId, 'activity_id': 'memory_cards',
      'xp_earned': 1, 'completed_at': now, 'local_date': '2026-10-03',
    });
  }

  /// user_id 열이 있는 모든 표에서 이 계정의 행 수.
  Future<int> rowsOf(int userId) async {
    final raw = await db.database;
    var total = 0;
    final tables = await raw.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name != 'users'");
    for (final t in tables) {
      final name = t['name'] as String;
      final columns = await raw.rawQuery('PRAGMA table_info("$name")');
      if (columns.any((c) => c['name'] == 'user_id')) {
        final rows = await raw.rawQuery('SELECT COUNT(*) AS n FROM "$name" WHERE user_id = ?', [userId]);
        total += rows.first['n'] as int;
      }
    }
    return total;
  }

  AccountDeletionService service({bool cloudOk = true}) => AccountDeletionService(
        db: db,
        deleteCloud: ({required int userId, required String username}) async =>
            CloudDeletionResult(cloudOk ? const [] : const ['서버 연결']),
        documentsDirectory: () async => documents,
        temporaryDirectory: () async => temporary,
      );

  test('DB: 그 계정의 모든 표 기록과 계정 행을 지우고, 다른 계정은 남긴다', () async {
    final kim = await addUser('kim');
    final lee = await addUser('lee');
    await addRecords(kim);
    await addRecords(lee);
    final leeRows = await rowsOf(lee);
    expect(await rowsOf(kim), greaterThan(6));

    await db.deleteUserAccount(kim);

    expect(await rowsOf(kim), 0);
    expect(await db.getUserById(kim), isNull);
    expect(await rowsOf(lee), leeRows);
    expect(await db.getUserById(lee), isNotNull);
  });

  test('서버 기록을 못 지우면 기기 기록을 지우지 않는다', () async {
    final kim = await addUser('kim');
    await addRecords(kim);
    SharedPreferences.setMockInitialValues({'guardian_v2_token_$kim': 'token'});
    var stopped = false;

    final result = await service(cloudOk: false)
        .deleteAccount(userId: kim, username: 'kim', stopTracking: () async => stopped = true);

    expect(result.status, AccountDeletionStatus.cloudFailed);
    expect(result.failed, ['서버 연결']);
    expect(stopped, isTrue);
    expect(await db.getUserById(kim), isNotNull);
    expect((await SharedPreferences.getInstance()).getString('guardian_v2_token_$kim'), 'token');
  });

  test('성공하면 이 계정의 설정 키·프로필 사진·리포트 PDF를 지우고 다른 계정 것은 둔다', () async {
    final kim = await addUser('kim');
    final lee = await addUser('lee');
    await addRecords(kim);
    final photo = File('${documents.path}${Platform.pathSeparator}profile_1.jpg')..writeAsStringSync('x');
    final report = File('${temporary.path}${Platform.pathSeparator}${AccountDeletionService.reportFilePrefix}1.pdf')
      ..writeAsStringSync('x');
    final otherTemp = File('${temporary.path}${Platform.pathSeparator}other.txt')..writeAsStringSync('x');
    SharedPreferences.setMockInitialValues({
      'guardian_v2_token_$kim': 'token-kim',
      'guardian_v2_created_$kim': true,
      'guardian_v2_stopped_$kim': true,
      'guardian_token_$kim': 'legacy',
      'guardian_hb_token': 'token-kim',
      AccountDeletionService.profileImageKey(kim): photo.path,
      'difficulty_levels_kim': '{}',
      'guardian_v2_token_$lee': 'token-lee',
      'difficulty_levels_lee': '{}',
    });

    final result = await service().deleteAccount(userId: kim, username: 'kim');

    expect(result.status, AccountDeletionStatus.deleted);
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'guardian_v2_token_$kim', 'guardian_v2_created_$kim', 'guardian_v2_stopped_$kim', 'guardian_token_$kim',
      'guardian_hb_token', AccountDeletionService.profileImageKey(kim), 'difficulty_levels_kim',
    ]) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(prefs.getString('guardian_v2_token_$lee'), 'token-lee');
    expect(prefs.getString('difficulty_levels_lee'), '{}');
    expect(photo.existsSync(), isFalse);
    expect(report.existsSync(), isFalse);
    expect(otherTemp.existsSync(), isTrue);
    expect(await db.getUserById(lee), isNotNull);
  });

  test('앱 폴더 밖에 있는 사진(갤러리 원본)은 지우지 않는다', () async {
    final kim = await addUser('kim');
    final outside = await Directory.systemTemp.createTemp('ml_gallery');
    addTearDown(() => outside.delete(recursive: true));
    final original = File('${outside.path}${Platform.pathSeparator}photo.jpg')..writeAsStringSync('x');
    SharedPreferences.setMockInitialValues({AccountDeletionService.profileImageKey(kim): original.path});

    await service().deleteAccount(userId: kim, username: 'kim');

    expect(original.existsSync(), isTrue);
  });

  test('마지막 계정을 지우면 이 기기의 일기 알림도 끈다', () async {
    final kim = await addUser('kim');
    // 디버그 빌드 DB는 데모 계정을 미리 넣으므로, 먼저 지워 kim을 마지막 계정으로 만든다.
    final raw = await db.database;
    for (final other in await raw.query('users', columns: ['id'], where: 'id != ?', whereArgs: [kim])) {
      await db.deleteUserAccount(other['id'] as int);
    }
    SharedPreferences.setMockInitialValues({DiaryNotificationService.prefKey: true});

    await service().deleteAccount(userId: kim, username: 'kim');

    expect(await DiaryNotificationService.isEnabled(), isFalse);
  });
}
