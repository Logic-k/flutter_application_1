import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../auth_service.dart';
import '../database_helper.dart';
import '../firebase_service.dart';
import 'guardian_sync_service.dart';

/// '서버에 저장된 내 데이터 삭제'.
///
/// 지금 로그인한 기기 계정이 서버(Firestore)에 남긴 것을 지운다:
/// 보호자 링크(v2 두 문서와 v1 잔존 문서), 1:1 문의와 답변, 예전 난이도 문서.
/// 기기 안의 계정·건강 기록·일기는 지우지 않는다.
///
/// 이 기기에 계정이 하나뿐이면 익명 Firebase 계정도 지운다. 같은 익명 계정을
/// 다른 기기 계정이 함께 쓰는 동안 지우면 그 계정의 보호자 링크가 주인을 잃는다.
class CloudDataDeletionService {
  CloudDataDeletionService({
    GuardianSyncService? guardian,
    DatabaseHelper? db,
    FirebaseFirestore? firestore,
    String? Function()? uidProvider,
    bool Function()? firebaseAvailable,
  })  : _guardian = guardian ?? GuardianSyncService(),
        _db = db ?? DatabaseHelper(),
        _firestoreOverride = firestore,
        _uidProvider = uidProvider ?? (() => AuthService.uid),
        _firebaseAvailable = firebaseAvailable ?? (() => FirebaseService.isAvailable);

  final GuardianSyncService _guardian;
  final DatabaseHelper _db;
  final FirebaseFirestore? _firestoreOverride;
  final String? Function() _uidProvider;
  final bool Function() _firebaseAvailable;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  /// 지운 결과. 실패한 항목 이름을 돌려준다. 다시 실행해도 안전하다.
  Future<CloudDeletionResult> deleteFor({required int userId, required String username}) async {
    final uid = _uidProvider();
    if (!_firebaseAvailable() || uid == null || uid.isEmpty) {
      return const CloudDeletionResult(['서버 연결']);
    }
    final failed = <String>[];
    if (!await _guardian.deleteCloudData(userId)) failed.add('보호자 링크');
    if (!await _deleteInquiries(uid, username)) failed.add('1:1 문의');
    if (!await _deleteLegacyDifficulty(uid, username)) failed.add('예전 난이도 기록');
    if (failed.isEmpty) await _deleteAnonymousAccountIfAlone();
    return CloudDeletionResult(failed);
  }

  Future<bool> _deleteInquiries(String uid, String username) async {
    try {
      final mine = await _firestore
          .collection('inquiries')
          .where('authorUid', isEqualTo: uid)
          .where('username', isEqualTo: username)
          .get();
      for (final inquiry in mine.docs) {
        // 답변을 먼저 지운다. 규칙은 답변 삭제 때 상위 문의의 작성자를 확인한다.
        final replies = await inquiry.reference.collection('replies').get();
        final batch = _firestore.batch();
        for (final reply in replies.docs) {
          batch.delete(reply.reference);
        }
        batch.delete(inquiry.reference);
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint('[CloudDeletion] 문의 삭제 실패: $e');
      return false;
    }
  }

  Future<bool> _deleteLegacyDifficulty(String uid, String username) async {
    try {
      final ref = _firestore.collection('training_difficulty').doc('${uid}_$username');
      if ((await ref.get()).exists) await ref.delete();
      return true;
    } catch (e) {
      debugPrint('[CloudDeletion] 예전 난이도 문서 삭제 실패: $e');
      return false;
    }
  }

  /// 익명 계정 자체에는 데이터가 없다. 지우지 못해도 삭제 실패로 보지 않는다.
  Future<void> _deleteAnonymousAccountIfAlone() async {
    try {
      if (await _db.getTotalUserCount() != 1) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.isAnonymous) return;
      await user.delete();
      // 앱의 다른 원격 기능이 계속 동작하도록 새 익명 세션을 연다.
      await AuthService.ensureSignedIn();
    } catch (e) {
      debugPrint('[CloudDeletion] 익명 계정 삭제 건너뜀: $e');
    }
  }
}

class CloudDeletionResult {
  final List<String> failed;
  const CloudDeletionResult(this.failed);
  bool get success => failed.isEmpty;
}
