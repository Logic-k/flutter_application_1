import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/ml_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('비활성 하단 탭도 접근성 라벨로 선택할 수 있다', (tester) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingPillNav(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    final trainingTab = find.bySemanticsLabel('인지훈련');
    expect(trainingTab, findsOneWidget);

    await tester.tap(trainingTab);
    expect(selectedIndex, 1);
  });

  testWidgets('309dp 화면에서 선택 라벨이 레이아웃을 넘지 않는다', (tester) async {
    tester.view.physicalSize = const Size(309, 668);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingPillNav(
            currentIndex: 1,
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
