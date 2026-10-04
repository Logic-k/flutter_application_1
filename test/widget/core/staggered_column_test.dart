import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/motion/app_motion.dart';
import 'package:flutter_application_1/core/motion/motion_play_log.dart';
import 'package:flutter_application_1/core/motion/staggered_column.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/mock_definitions.dart';

class _FadeOnlySettings extends FakeSettingsProvider {
  @override
  bool get reduceMotion => true;
}

/// 자식 i 의 불투명도.
double _opacity(WidgetTester tester, int i) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text('항목 $i'), matching: find.byType(Opacity)).first,
    )
    .opacity;

/// 자식 i 의 세로 이동량.
double _offsetY(WidgetTester tester, int i) => tester
    .widget<Transform>(
      find.ancestor(of: find.text('항목 $i'), matching: find.byType(Transform)).first,
    )
    .transform
    .getTranslation()
    .y;

Widget _subject({
  int count = 4,
  bool disable = false,
  bool fadeOnly = false,
  bool tickers = true,
  String playKey = 'test',
}) {
  Widget child = MediaQuery(
    data: MediaQueryData(disableAnimations: disable),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: TickerMode(
        enabled: tickers,
        child: StaggeredColumn(
          playKey: playKey,
          children: [for (var i = 0; i < count; i++) Text('항목 $i')],
        ),
      ),
    ),
  );
  if (fadeOnly) {
    child = ChangeNotifierProvider<SettingsProvider>.value(
      value: _FadeOnlySettings(),
      child: child,
    );
  }
  return child;
}

void main() {
  setUp(MotionPlayLog.reset);

  test('자식 4개의 안무는 400ms 상한 안이다', () {
    expect(StaggerScope.totalFor(4), lessThanOrEqualTo(AppMotion.choreographyMax));
    expect(StaggerScope.totalFor(4), AppMotion.enter + AppMotion.stagger * 3);
  });

  testWidgets('full: t=0 은 전부 투명, 중간에는 앞 자식이 먼저, 400ms 에는 전부 최종 상태', (
    tester,
  ) async {
    await tester.pumpWidget(_subject());
    for (var i = 0; i < 4; i++) {
      expect(_opacity(tester, i), 0, reason: '항목 $i t=0');
      expect(_offsetY(tester, i), StaggerItem.offsetDp);
    }

    await tester.pump(const Duration(milliseconds: 150));
    // 0번은 150/200 지점, 3번은 아직 시작 전(180ms 에 시작).
    expect(_opacity(tester, 0), greaterThan(_opacity(tester, 1)));
    expect(_opacity(tester, 1), greaterThan(_opacity(tester, 2)));
    expect(_opacity(tester, 3), 0);

    await tester.pump(const Duration(milliseconds: 250));
    for (var i = 0; i < 4; i++) {
      expect(_opacity(tester, i), 1, reason: '항목 $i t=400ms');
      expect(_offsetY(tester, i), 0);
    }
  });

  testWidgets('none(Android 애니메이션 제거)은 pump 1회로 최종 상태다', (tester) async {
    await tester.pumpWidget(_subject(disable: true));
    for (var i = 0; i < 4; i++) {
      expect(_opacity(tester, i), 1);
      expect(_offsetY(tester, i), 0);
    }
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('fadeOnly 는 이동 없이 함께 페이드하고 150ms 에 끝난다', (tester) async {
    await tester.pumpWidget(_subject(fadeOnly: true));
    for (var i = 0; i < 4; i++) {
      expect(_offsetY(tester, i), 0);
    }
    await tester.pump(const Duration(milliseconds: 75));
    expect(_opacity(tester, 0), greaterThan(0));
    expect(_opacity(tester, 3), _opacity(tester, 0));
    for (var i = 0; i < 4; i++) {
      expect(_offsetY(tester, i), 0);
    }
    await tester.pump(const Duration(milliseconds: 75));
    for (var i = 0; i < 4; i++) {
      expect(_opacity(tester, i), 1);
    }
  });

  testWidgets('같은 playKey 는 앱 실행 동안 한 번만 재생한다', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_subject());
    expect(_opacity(tester, 3), 1);
  });

  testWidgets('TickerMode 가 꺼져 있으면 예외 없이 최종 상태로 그리고, 켜지는 순간 재생한다', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(tickers: false));
    expect(tester.takeException(), isNull);
    expect(_opacity(tester, 0), 1);

    await tester.pumpWidget(_subject(tickers: true));
    expect(_opacity(tester, 0), 0);
    await tester.pump(AppMotion.choreographyMax);
    expect(_opacity(tester, 3), 1);
  });

  testWidgets('자식이 5개면 400ms 상한 assert 에 걸린다', (tester) async {
    await tester.pumpWidget(_subject(count: 5));
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('StaggerScope 밖의 StaggerItem 은 그대로 그린다', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: StaggerItem(index: 0, child: Text('항목 0')),
      ),
    );
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('StaggerScope 는 slots 를 넘는 index 를 마지막 칸과 함께 들인다', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StaggerScope(
          playKey: 'list',
          slots: 2,
          child: Column(
            children: [
              for (var i = 0; i < 5; i++) StaggerItem(index: i, child: Text('항목 $i')),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester, 4), _opacity(tester, 1));
    await tester.pump(StaggerScope.totalFor(2));
    expect(_opacity(tester, 4), 1);
  });
}
