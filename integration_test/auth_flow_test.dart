// 실행 방법: flutter test integration_test/auth_flow_test.dart
// (에뮬레이터 또는 실기기 연결 필요)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/ml_widgets.dart';
import 'package:flutter_application_1/main.dart' as app;

import 'helpers.dart';

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
      // 오프닝이 걷히고 로그인 버튼을 실제로 누를 수 있을 때까지 기다린다(helpers.dart).
      await pumpUntil(tester, () => tappable(find.text('로그인')), description: '로그인 버튼을 누를 수 있는');

      // 로딩 완료 후 로그인 화면 확인
      expect(find.text('MemoryLink'), findsOneWidget);
      expect(find.text('사용자 아이디'), findsOneWidget);
    });

    testWidgets('admin/admin으로 로그인 후 홈 화면으로 이동한다', (tester) async {
      app.main();
      await pumpUntil(tester, () => tappable(find.text('로그인')), description: '로그인 버튼을 누를 수 있는');

      // 로그인 자격증명 입력
      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'admin');
      await tester.tap(find.text('로그인'));
      await pumpUntil(tester, () => tappable(find.byType(FloatingPillNav)), description: '홈 하단 탭바가 보이는');
      // 홈의 진입 안무와 첫 데이터 읽기가 끝날 때까지 둔다. 다음 테스트의 app.main()이 이 화면의
      // 프로바이더를 정리한 뒤에 읽기가 끝나면 '정리된 DiaryProvider 사용' 오류가 난다.
      await tester.pumpAndSettle();

      // admin 은 온보딩을 마친 시드 계정이라 동의 화면이 아니라 홈('/')으로 간다.
      // 하단 탭바에서 홈 탭이 선택된 채로 열리고, 로그인 입력 칸은 사라진다.
      expect(find.byType(FloatingPillNav), findsOneWidget);
      final homeTab = find.descendant(
        of: find.byType(FloatingPillNav),
        matching: find.bySemanticsLabel('홈'),
      );
      expect(tester.getSemantics(homeTab), isSemantics(label: '홈', isSelected: true));
      expect(find.text('사용자 아이디'), findsNothing);
    });

    testWidgets('잘못된 자격증명으로 로그인 시 에러 메시지가 표시된다', (tester) async {
      app.main();
      await pumpUntil(tester, () => tappable(find.text('로그인')), description: '로그인 버튼을 누를 수 있는');

      await tester.enterText(find.byType(TextField).first, 'wronguser');
      await tester.enterText(find.byType(TextField).last, 'wrongpass');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
    });
  });
}
