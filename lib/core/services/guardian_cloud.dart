import 'package:cloud_firestore/cloud_firestore.dart';

/// 보호자 링크 v2의 클라우드 저장소 경계.
///
/// 비공개 링크(guardian_links/{token})와 공개 사본(guardian_views/{token})을
/// 항상 한 batch로 다룬다. 규칙이 공개 사본의 소유권을 비공개 링크로 확인하고,
/// 두 문서의 만료일이 같기를 요구하기 때문이다(firestore.rules).
/// Firestore 인스턴스는 실제로 쓸 때까지 건드리지 않는다 — Firebase가 초기화되지
/// 않은 빌드에서도 화면과 서비스를 만들 수 있어야 한다.
abstract class GuardianCloud {
  /// 새 링크: 비공개 링크와 공개 사본을 함께 만든다.
  Future<void> createLink(String token,
      {required String ownerUid, required DateTime expiresAt, required Map<String, Object?> view});

  /// 기존 링크: 만료일을 밀고 공개 사본을 통째로 바꾼다.
  Future<void> refreshLink(String token,
      {required DateTime expiresAt, required Map<String, Object?> view});

  /// 하트비트·이상 알림: 공개 사본의 일부 필드만 바꾸고 만료일을 민다.
  Future<void> patchView(String token,
      {required DateTime expiresAt, required Map<String, Object?> fields});

  /// 공유 중지: 두 문서를 지운다.
  Future<void> deleteLink(String token);

  /// v1(16자 토큰) 시절 공개 문서를 지운다.
  Future<void> deleteLegacyView(String token);
}

enum GuardianCloudError { permissionDenied, notFound, unavailable, other }

class GuardianCloudException implements Exception {
  final GuardianCloudError code;
  final String message;
  const GuardianCloudException(this.code, [this.message = '']);

  /// uid가 바뀌었거나(소유자 불일치) 링크가 사라져 새 토큰이 필요한 실패.
  bool get needsNewLink =>
      code == GuardianCloudError.permissionDenied || code == GuardianCloudError.notFound;

  @override
  String toString() => 'GuardianCloudException($code)';
}

class FirestoreGuardianCloud implements GuardianCloud {
  FirestoreGuardianCloud({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;
  FirebaseFirestore get _db => _override ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _link(String token) =>
      _db.collection('guardian_links').doc(token);
  DocumentReference<Map<String, dynamic>> _view(String token) =>
      _db.collection('guardian_views').doc(token);

  @override
  Future<void> createLink(String token,
      {required String ownerUid, required DateTime expiresAt, required Map<String, Object?> view}) {
    final expiry = Timestamp.fromDate(expiresAt);
    return _commit((batch) {
      batch.set(_link(token), {
        'ownerUid': ownerUid,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiry,
        'schema': 2,
      });
      batch.set(_view(token), _fullView(view, expiry));
    });
  }

  @override
  Future<void> refreshLink(String token,
      {required DateTime expiresAt, required Map<String, Object?> view}) {
    final expiry = Timestamp.fromDate(expiresAt);
    return _commit((batch) {
      batch.update(_link(token), {'expiresAt': expiry});
      batch.set(_view(token), _fullView(view, expiry));
    });
  }

  @override
  Future<void> patchView(String token,
      {required DateTime expiresAt, required Map<String, Object?> fields}) {
    final expiry = Timestamp.fromDate(expiresAt);
    return _commit((batch) {
      batch.update(_link(token), {'expiresAt': expiry});
      batch.update(_view(token), {
        ...fields,
        'last_heartbeat': FieldValue.serverTimestamp(),
        'expiresAt': expiry,
      });
    });
  }

  @override
  Future<void> deleteLink(String token) => _commit((batch) {
        batch.delete(_view(token));
        batch.delete(_link(token));
      });

  @override
  Future<void> deleteLegacyView(String token) => _guard(() => _view(token).delete());

  Map<String, Object?> _fullView(Map<String, Object?> view, Timestamp expiry) => {
        ...view,
        'schema': 2,
        'last_sync': FieldValue.serverTimestamp(),
        'last_heartbeat': FieldValue.serverTimestamp(),
        'expiresAt': expiry,
      };

  Future<void> _commit(void Function(WriteBatch batch) build) => _guard(() {
        final batch = _db.batch();
        build(batch);
        return batch.commit();
      });

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException catch (e) {
      throw GuardianCloudException(_map(e.code), e.message ?? '');
    }
  }

  static GuardianCloudError _map(String code) {
    switch (code) {
      case 'permission-denied':
        return GuardianCloudError.permissionDenied;
      case 'not-found':
        return GuardianCloudError.notFound;
      case 'unavailable':
      case 'deadline-exceeded':
        return GuardianCloudError.unavailable;
      default:
        return GuardianCloudError.other;
    }
  }
}
