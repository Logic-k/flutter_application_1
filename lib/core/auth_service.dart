import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Anonymous Auth 래퍼.
///
/// 앱의 사용자 계정은 로컬 SQLite로 관리하고, Firebase Auth는
/// Firestore Security Rules 통과를 위한 기기 단위 익명 세션으로만 사용한다.
/// 로그인 실패(오프라인 등) 시에도 앱은 로컬 기능으로 계속 동작해야 하므로
/// 모든 실패는 조용히 흡수한다.
class AuthService {
  /// 익명 세션을 보장한다. 이미 로그인돼 있으면 아무것도 하지 않는다.
  /// 실패해도 예외를 던지지 않는다 (Firestore 호출이 개별적으로 실패 처리됨).
  static Future<void> ensureSignedIn() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('AuthService.ensureSignedIn failed (offline?): $e');
    }
  }

  /// 현재 익명 세션의 uid. 미로그인/Firebase 미초기화 상태면 null.
  static String? get uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
}
