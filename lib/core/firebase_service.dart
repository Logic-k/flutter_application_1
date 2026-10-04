import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _available = false;

  /// 디버그·프로파일 빌드에서 로컬 Firestore 에뮬레이터에 붙을 호스트.
  ///   flutter run --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
  /// 포트는 firebase.json의 emulators 설정(Firestore 8180)을 따른다. 로그인은 기기의
  /// 익명 세션을 그대로 쓴다(에뮬레이터는 토큰 서명을 검사하지 않고 uid만 읽는다).
  /// 릴리스 빌드는 이 값을 무시한다.
  static const String _emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  static const int firestoreEmulatorPort = 8180;

  /// Firebase 초기화 성공 여부.
  /// false면 원격 기능(CS, 보호자 연동)만 비활성이고
  /// SQLite 기반 로컬 기능은 정상 동작한다.
  static bool get isAvailable => _available;

  /// 초기화가 성공하면 true가 된다. 자동 로그인은 Firebase 초기화(첫 프레임 뒤)보다
  /// 먼저 끝나므로, 로그인 시점에 원격 작업을 하려는 쪽은 이 값을 기다린다.
  static final ValueNotifier<bool> availability = ValueNotifier<bool>(false);

  /// 초기화 실패가 앱 기동을 막지 않는다.
  /// `google-services.json` 누락·손상, 오프라인 최초 실행 등에서
  /// `Firebase.initializeApp()`이 던지면 로컬 전용 모드로 계속한다.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _available = true;
      await _useEmulatorsIfConfigured();
      availability.value = true;
    } catch (e) {
      _available = false;
      debugPrint('[FirebaseService] 초기화 실패 — 로컬 전용 모드로 계속한다: $e');
    }
  }

  /// main()을 거치지 않는 백그라운드 isolate에서 Firebase를 쓰기 전에 부른다.
  /// isolate마다 정적 상태가 따로라 이미 초기화됐는지 여기서 다시 확인한다.
  static Future<bool> ensureInitialized() async {
    if (_available) return true;
    await initialize();
    return _available;
  }

  static Future<void> _useEmulatorsIfConfigured() async {
    if (kReleaseMode || _emulatorHost.isEmpty) return;
    try {
      FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, firestoreEmulatorPort);
      debugPrint('[FirebaseService] 로컬 에뮬레이터 사용: $_emulatorHost');
    } catch (e) {
      // 같은 프로세스의 다른 isolate가 이미 연결했으면 여기서 다시 설정할 수 없다.
      debugPrint('[FirebaseService] 에뮬레이터 설정 건너뜀: $e');
    }
  }

  static FirebaseFirestore get db => FirebaseFirestore.instance;

  @visibleForTesting
  static void setAvailableForTest(bool value) => _available = value;
}
