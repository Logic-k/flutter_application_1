import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/ml_widgets.dart';
import 'package:flutter_application_1/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('비교 훈련 완료 후 XP가 쌓이고 구구단 과정이 열린다', (tester) async {
    app.main();
    // 저장된 세션이 있으면 홈, 없으면 로그인 화면이 오프닝 뒤에서 나온다(helpers.dart).
    await pumpUntil(
      tester,
      () => tappable(find.text('로그인')) || tappable(find.byType(FloatingPillNav)),
      description: '로그인 화면이나 홈을 누를 수 있는',
    );

    if (find.byType(TextField).evaluate().isNotEmpty) {
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'admin');
      await tester.tap(find.text('로그인'));
      await pumpUntil(tester, () => tappable(find.byType(FloatingPillNav)), description: '홈 하단 탭바가 보이는');
    } else {
      expect(find.textContaining('안녕하세요'), findsOneWidget);
    }

    expect(find.byType(FloatingPillNav), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('인지훈련'));
    await tester.pumpAndSettle();
    expect(find.text('두뇌 트레이닝 센터'), findsOneWidget);

    final multiplicationNode = find.byKey(
      const Key('course-node-multiplication'),
    );
    expect(
      find.descendant(
        of: multiplicationNode,
        matching: find.text('잠김'),
      ),
      findsOneWidget,
    );

    final comparisonNode = find.byKey(const Key('course-node-comparison'));
    await tester.ensureVisible(comparisonNode);
    await tester.tap(comparisonNode);
    await tester.pumpAndSettle();
    expect(find.text('VS'), findsOneWidget);

    for (var step = 0; step < 10; step++) {
      final answer = find.byKey(const Key('comparison-answer-left'));
      expect(answer, findsOneWidget);
      await tester.tap(answer);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('training-result-continue')), findsOneWidget);
    expect(find.textContaining('XP'), findsWidgets);
    await tester.tap(find.byKey(const Key('training-result-continue')));
    await tester.pumpAndSettle();

    expect(find.text('두뇌 트레이닝 센터'), findsOneWidget);
    expect(
      find.descendant(
        of: multiplicationNode,
        matching: find.text('도전 가능'),
      ),
      findsOneWidget,
    );
  });
}
