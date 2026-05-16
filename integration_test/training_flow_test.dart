// 실행 방법: flutter test integration_test/training_flow_test.dart
// (에뮬레이터 또는 실기기 연결 필요)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application_1/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Training Flow E2E', () {
    Future<void> login(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'admin');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    testWidgets('로그인 후 훈련 탭에서 범주화 게임을 시작한다', (tester) async {
      await login(tester);

      // 훈련 탭으로 이동 (두 번째 탭)
      final tabs = find.byType(BottomNavigationBar);
      expect(tabs, findsOneWidget);
      await tester.tap(find.byIcon(Icons.psychology_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 범주화 게임 카드 탭
      if (find.text('범주화 훈련').evaluate().isNotEmpty) {
        await tester.tap(find.text('범주화 훈련'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 게임 화면 확인
        expect(find.text('범주화 훈련'), findsOneWidget);
      }
    });

    testWidgets('범주화 게임에서 정답을 5번 맞히면 훈련 완료 화면이 나타난다', (tester) async {
      await login(tester);

      // 훈련 탭 이동
      await tester.tap(find.byIcon(Icons.psychology_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      if (find.text('범주화 훈련').evaluate().isNotEmpty) {
        await tester.tap(find.text('범주화 훈련'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 정답 5개 순서대로 탭
        final answers = ['과일', '채소', '어류', '육류', '곡류'];
        for (final answer in answers) {
          if (find.text(answer).evaluate().isNotEmpty) {
            await tester.tap(find.text(answer));
            await tester.pump(const Duration(milliseconds: 700));
          }
        }
        await tester.pumpAndSettle();

        expect(find.text('훈련 완료!'), findsOneWidget);
      }
    });
  });
}
