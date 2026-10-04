import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/design_system/foundations/elevation.dart';
import 'package:flutter_application_1/core/design_system/foundations/layout.dart';
import 'package:flutter_application_1/core/design_system/foundations/spacing.dart';
import 'package:flutter_application_1/core/ml_widgets.dart';
import 'package:flutter_application_1/core/theme.dart';

// DS-004 foundation 토큰 (핸드오프 §5.3·§10 G2).
//
// 토큰 도입은 시각 변화가 없어야 한다. 그래서 초기값을 문서 표와, 그림자는 지금 위젯이
// 실제로 그리는 값과 비교한다. 값 조정은 사용자 테스트 근거와 함께 이 테스트를 고쳐서 한다.

Future<BoxDecoration> _decorationOf(WidgetTester tester, Widget child, Type owner) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: Center(child: child)),
  ));
  final decorated = tester.widgetList<Container>(
    find.descendant(of: find.byType(owner), matching: find.byType(Container)),
  ).map((c) => c.decoration).whereType<BoxDecoration>();
  return decorated.firstWhere((d) => d.boxShadow != null || owner == MLCard);
}

Color _primary(WidgetTester tester) => Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary;

void main() {
  group('AppSpacing', () {
    test('초기값은 핸드오프 §5.3 표 그대로다', () {
      expect(AppSpacing.screenHorizontal, 22);
      expect(AppSpacing.screenHorizontalForm, 24);
      expect(AppSpacing.screenTop, 6);
      expect(AppSpacing.controlGap, 8);
      expect(AppSpacing.itemGap, 12);
      expect(AppSpacing.contentGap, 16);
      expect(AppSpacing.cardGap, 20);
      expect(AppSpacing.sectionGap, 24);
      expect(AppSpacing.heroPadding, 22);
    });

    test('hero 안쪽과 탭 하단 여백은 지금 위젯 값에 묶여 있다', () {
      expect(const MLHeroCard(child: SizedBox()).padding, const EdgeInsets.all(AppSpacing.heroPadding));
      expect(AppSpacing.bottomSafeContent, FloatingPillNav.contentBottomInset);
    });
  });

  group('AppElevation — 지금 위젯이 그리는 그림자와 같다', () {
    testWidgets('raised = MLCard', (tester) async {
      final decoration = await _decorationOf(tester, const MLCard(child: SizedBox()), MLCard);
      expect(decoration.boxShadow, AppElevation.raised);
    });

    testWidgets('flat = MLCard(soft) — 그림자 없음', (tester) async {
      final decoration =
          await _decorationOf(tester, const MLCard(soft: true, child: SizedBox()), MLCard);
      expect(decoration.boxShadow, isNull);
      expect(AppElevation.flat, isEmpty);
    });

    testWidgets('hero = MLHeroCard', (tester) async {
      final decoration = await _decorationOf(tester, const MLHeroCard(child: SizedBox()), MLHeroCard);
      expect(decoration.boxShadow, AppElevation.hero(_primary(tester)));
    });

    testWidgets('floating = FloatingPillNav', (tester) async {
      final decoration = await _decorationOf(
        tester, FloatingPillNav(currentIndex: 0, onTap: (_) {}), FloatingPillNav,
      );
      expect(decoration.boxShadow, AppElevation.floating(_primary(tester)));
    });
  });

  group('AppLayout', () {
    test('창 크기 경계는 600·840', () {
      expect(AppLayout.windowClassOf(320), AppWindowClass.compact);
      expect(AppLayout.windowClassOf(599.9), AppWindowClass.compact);
      expect(AppLayout.windowClassOf(600), AppWindowClass.medium);
      expect(AppLayout.windowClassOf(839.9), AppWindowClass.medium);
      expect(AppLayout.windowClassOf(840), AppWindowClass.expanded);
    });

    test('본문 최대 폭 — compact는 제한 없음, medium 720, expanded 1200', () {
      expect(AppLayout.contentMaxWidthOf(AppWindowClass.compact), double.infinity);
      expect(AppLayout.contentMaxWidthOf(AppWindowClass.medium), 720);
      expect(AppLayout.contentMaxWidthOf(AppWindowClass.expanded), 1200);
      expect(AppLayout.singleColumnTextScale, 1.4);
    });
  });
}
