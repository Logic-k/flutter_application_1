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

  testWidgets('네비가 본문 위로 팽창하지 않는다', (tester) async {
    // 탭 높이를 접근성 기준(48dp)에 맞추면서 Container에 alignment를 줬더니
    // 알약이 화면 전체로 팽창해 다른 요소를 전부 가렸다. Container는 alignment가
    // 있으면 부모 제약만큼 커진다. 위젯 테스트는 화면 하나만 pump하므로 이 사고를
    // 놓쳤고 E2E 20개 중 14개가 깨진 뒤에야 드러났다.
    const screen = Size(360, 800);
    await tester.binding.setSurfaceSize(screen);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: FloatingPillNav(currentIndex: 0, onTap: (_) {}),
        ),
      ),
    );

    final navHeight = tester.getSize(find.byType(FloatingPillNav)).height;
    expect(
      navHeight,
      lessThanOrEqualTo(FloatingPillNav.overlayHeight + 24),
      reason: '네비 높이가 ${navHeight}dp — 알약이 본문 위로 팽창했다',
    );
    // 본문을 가리지 않는지도 함께 지킨다.
    expect(navHeight, lessThan(screen.height * 0.25));
  });

  testWidgets('탭 높이가 최소 터치 영역 48dp를 지킨다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingPillNav(currentIndex: 0, onTap: (_) {}),
        ),
      ),
    );

    // 진전이 있는 고령 사용자에게 40dp 탭은 오탭을 유발한다.
    final tabHeight = tester.getSize(find.byType(AnimatedContainer).first).height;
    expect(tabHeight, greaterThanOrEqualTo(48));
  });
}
