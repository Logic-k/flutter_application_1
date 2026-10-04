// 실행 방법: flutter test integration_test/auth_flow_test.dart
// (에뮬레이터 또는 실기기 연결 필요)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/ml_widgets.dart';
import 'package:flutter_application_1/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow E2E', () {
    // 세 테스트 모두 로그인 화면에서 시작해야 한다. 앞 테스트가 저장한 세션이
    // SharedPreferences에 남아 있으면 자동 로그인으로 홈이 떠버려서
    // 입력 필드를 찾지 못하고 `Bad state: No element`로 깨진다.
    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('앱 시작 시 로그인 화면이 표시된다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 로딩 완료 후 로그인 화면 확인
      expect(find.text('MemoryLink'), findsOneWidget);
      expect(find.text('사용자 아이디'), findsOneWidget);
    });

    testWidgets('admin/admin으로 로그인 후 홈 화면으로 이동한다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 로그인 자격증명 입력
      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'admin');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 홈 화면의 하단 탭바 확인 (BottomNavigationBar → FloatingPillNav로 교체됨)
      expect(find.byType(FloatingPillNav), findsOneWidget);
    });

    testWidgets('잘못된 자격증명으로 로그인 시 에러 메시지가 표시된다', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(TextField).first, 'wronguser');
      await tester.enterText(find.byType(TextField).last, 'wrongpass');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
    });
  });
}
