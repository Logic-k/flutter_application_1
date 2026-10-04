import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/training/difficulty_provider.dart';
import '../database_helper.dart';
import 'cloud_data_deletion_service.dart';
import 'diary_notification_service.dart';
import 'guardian_sync_service.dart';

/// '계정과 모든 데이터 삭제' (LAUNCH_AUDIT P0-07).
///
/// 순서: 걸음 측정 멈춤 → 서버 데이터(보호자 링크·문의·예전 난이도, 기기 계정이 하나면 익명 계정)
/// → 이 기기 계정과 기록(DB 한 트랜잭션) → 이 계정의 기기 설정 키·프로필 사진·리포트 PDF.
///
/// 서버 삭제가 실패하면 기기 기록을 지우지 않는다. 보호자 토큰 같은 기기 쪽 연결 정보를 먼저
/// 지우면 서버 문서를 다시 찾을 수 없기 때문이다. 같은 계정으로 다시 실행해도 안전하다.
class AccountDeletionService {
  AccountDeletionService({
    DatabaseHelper? db,
    Future<CloudDeletionResult> Function({required int userId, required String username})? deleteCloud,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? temporaryDirectory,
  })  : _db = db ?? DatabaseHelper(),
        _deleteCloud = deleteCloud ?? CloudDataDeletionService().deleteFor,
        _documentsDirectory = documentsDirectory ?? getApplicationDocumentsDirectory,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final DatabaseHelper _db;
  final Future<CloudDeletionResult> Function({required int userId, required String username}) _deleteCloud;
  final Future<Directory> Function() _documentsDirectory;
  final Future<Directory> Function() _temporaryDirectory;

  /// 프로필 사진 경로 저장 키. 내 정보·정보 수정 화면과 같은 키다.
  static String profileImageKey(int userId) => 'profile_image_path_$userId';

  /// 리포트 PDF는 공유용 임시 파일로 이 이름으로 만든다(clinical_report_generator.dart).
  static const reportFilePrefix = 'MemoryLink_Clinical_';

  Future<AccountDeletionResult> deleteAccount({
    required int userId,
    required String username,
    Future<void> Function()? stopTracking,
  }) async {
    if (stopTracking != null) {
      try {
        await stopTracking();
      } catch (e) {
        debugPrint('[AccountDeletion] 걸음 측정 중지 실패(계속 진행): $e');
      }
    }

    final cloud = await _deleteCloud(userId: userId, username: username);
    if (!cloud.success) {
      return AccountDeletionResult(AccountDeletionStatus.cloudFailed, failed: cloud.failed);
    }

    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(profileImageKey(userId));
    try {
      await _db.deleteUserAccount(userId);
    } catch (e) {
      debugPrint('[AccountDeletion] 기기 기록 삭제 실패: $e');
      return const AccountDeletionResult(AccountDeletionStatus.localFailed);
    }

    await GuardianSyncService.forgetLocalState(prefs, userId);
    await prefs.remove(profileImageKey(userId));
    await prefs.remove(DifficultyProvider.prefKeyFor(username));
    if (await _db.getTotalUserCount() == 0) {
      // 남은 계정이 없으면 이 기기의 일기 알림도 끈다.
      await DiaryNotificationService.disable();
    }
    await _deleteFiles(imagePath);
    return const AccountDeletionResult(AccountDeletionStatus.deleted);
  }

  Future<void> _deleteFiles(String? imagePath) async {
    // 프로필 사진은 앱 문서 폴더에 복사해 둔 것만 지운다. 갤러리 원본은 건드리지 않는다.
    try {
      if (imagePath != null && imagePath.isNotEmpty) {
        final documents = (await _documentsDirectory()).path;
        final file = File(imagePath);
        if (p.isWithin(documents, file.path) && await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('[AccountDeletion] 프로필 사진 삭제 실패: $e');
    }
    try {
      final temp = await _temporaryDirectory();
      await for (final entity in temp.list()) {
        final name = p.basename(entity.path);
        if (entity is File && name.startsWith(reportFilePrefix) && name.endsWith('.pdf')) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('[AccountDeletion] 리포트 임시 파일 삭제 실패: $e');
    }
  }
}

enum AccountDeletionStatus { deleted, cloudFailed, localFailed }

class AccountDeletionResult {
  const AccountDeletionResult(this.status, {this.failed = const []});

  final AccountDeletionStatus status;

  /// 서버에서 지우지 못한 항목 이름.
  final List<String> failed;
}
