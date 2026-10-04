import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _available = false;

  /// Firebase 초기화 성공 여부.
  /// false면 원격 기능(CS, 보호자 연동, 공유 통계)만 비활성이고
  /// SQLite 기반 로컬 기능은 정상 동작한다.
  static bool get isAvailable => _available;

  /// 초기화 실패가 앱 기동을 막지 않는다.
  /// `google-services.json` 누락·손상, 오프라인 최초 실행 등에서
  /// `Firebase.initializeApp()`이 던지면 로컬 전용 모드로 계속한다.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      _available = false;
      debugPrint('[FirebaseService] 초기화 실패 — 로컬 전용 모드로 계속한다: $e');
    }
  }

  static FirebaseFirestore get db => FirebaseFirestore.instance;

  @visibleForTesting
  static void setAvailableForTest(bool value) => _available = value;
}
