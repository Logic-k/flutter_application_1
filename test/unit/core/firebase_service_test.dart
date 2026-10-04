import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FirebaseService.setAvailableForTest(false));

  group('FirebaseService 초기화 가드', () {
    // 테스트 바인딩에는 firebase_core 플랫폼 채널이 없으므로
    // Firebase.initializeApp()이 던진다 = 설정 파일 누락과 같은 실패 경로다.
    test('초기화가 실패해도 예외를 전파하지 않는다', () async {
      await expectLater(FirebaseService.initialize(), completes);
    });

    test('초기화 실패 후 isAvailable은 false로 남는다', () async {
      await FirebaseService.initialize();
      expect(
        FirebaseService.isAvailable,
        isFalse,
        reason: '원격 기능은 비활성이어야 하지만 앱 기동은 계속되어야 한다',
      );
    });
  });
}
