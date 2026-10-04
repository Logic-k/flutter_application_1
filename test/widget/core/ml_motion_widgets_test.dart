import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/ml_widgets.dart';
import 'package:flutter_application_1/core/motion/app_motion.dart';
import 'package:flutter_application_1/core/motion/motion_play_log.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/mock_definitions.dart';

class _FadeOnlySettings extends FakeSettingsProvider {
  @override
  bool get reduceMotion => true;
}

enum _Level { full, fadeOnly, none }

Widget _host(Widget child, {_Level level = _Level.full, bool tickers = true}) {
  Widget tree = MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: level == _Level.none),
      child: TickerMode(enabled: tickers, child: Scaffold(body: child)),
    ),
  );
  if (level == _Level.fadeOnly) {
    tree = ChangeNotifierProvider<SettingsProvider>.value(
      value: _FadeOnlySettings(),
      child: tree,
    );
  }
  return tree;
}

/// MLChart 가 builder 에 넘긴 값을 기록한다.
class _ChartProbe {
  final entered = <bool>[];
  final durations = <Duration>[];

  Widget build({String playKey = 'chart'}) => MLChart(
    playKey: playKey,
    builder: (context, entered, duration, curve) {
      this.entered.add(entered);
      durations.add(duration);
      return Text(entered ? '실데이터' : '기준선');
    },
  );
}

void main() {
  setUp(MotionPlayLog.reset);

  group('MLChart', () {
    testWidgets('full: 첫 프레임은 기준선, 다음 프레임에 실데이터로 바뀌며 duration 은 enter', (
      tester,
    ) async {
      final probe = _ChartProbe();
      await tester.pumpWidget(_host(probe.build()));
      expect(probe.entered.first, isFalse);
      expect(probe.durations.first, AppMotion.enter);

      await tester.pump();
      expect(probe.entered.last, isTrue);
      expect(find.text('실데이터'), findsOneWidget);
    });

    testWidgets('fadeOnly: 처음부터 실데이터이고 fl_chart 보간도 끈다(duration 0)', (
      tester,
    ) async {
      final probe = _ChartProbe();
      await tester.pumpWidget(_host(probe.build(), level: _Level.fadeOnly));
      expect(probe.entered, everyElement(isTrue));
      expect(probe.durations, everyElement(Duration.zero));
    });

    testWidgets('none: 처음부터 실데이터이고 duration 0', (tester) async {
      final probe = _ChartProbe();
      await tester.pumpWidget(_host(probe.build(), level: _Level.none));
      expect(probe.entered, everyElement(isTrue));
      expect(probe.durations, everyElement(Duration.zero));
    });

    testWidgets('같은 playKey 는 두 번째부터 곧바로 실데이터다', (tester) async {
      await tester.pumpWidget(_host(_ChartProbe().build()));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());

      final second = _ChartProbe();
      await tester.pumpWidget(_host(second.build()));
      expect(second.entered, everyElement(isTrue));
    });

    testWidgets('숨은 탭(TickerMode 꺼짐)은 기준선으로 기다렸다가 보이는 순간 자란다', (
      tester,
    ) async {
      final probe = _ChartProbe();
      await tester.pumpWidget(_host(probe.build(), tickers: false));
      await tester.pump();
      expect(probe.entered.last, isFalse);

      await tester.pumpWidget(_host(probe.build(), tickers: true));
      await tester.pump();
      expect(probe.entered.last, isTrue);
    });
  });

  group('MLCountUp', () {
    Widget counter({String? playKey, int value = 120}) => MLCountUp(
      value: value,
      playKey: playKey,
      builder: (context, v) => Text('$v'),
    );

    testWidgets('full + playKey: 0 에서 올라가 enter 뒤 최종 값', (tester) async {
      await tester.pumpWidget(_host(counter(playKey: 'steps')));
      expect(find.text('0'), findsOneWidget);
      await tester.pump(AppMotion.enter);
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('fadeOnly 와 none 은 첫 프레임부터 최종 값', (tester) async {
      await tester.pumpWidget(_host(counter(playKey: 'a'), level: _Level.fadeOnly));
      expect(find.text('120'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_host(counter(playKey: 'b'), level: _Level.none));
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('playKey 가 없으면 처음엔 그대로, 값이 바뀔 때만 이전 값에서 올라간다', (
      tester,
    ) async {
      await tester.pumpWidget(_host(counter(value: 10)));
      expect(find.text('10'), findsOneWidget);

      await tester.pumpWidget(_host(counter(value: 20)));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = int.parse(
        (tester.widget<Text>(find.byType(Text)).data)!,
      );
      expect(mid, inExclusiveRange(10, 20));
      await tester.pump(AppMotion.enter);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('semanticsLabel 을 주면 스크린리더에는 최종 값만 준다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MLCountUp(
            value: 300,
            playKey: 'label',
            semanticsLabel: '300 걸음',
            builder: (context, v) => Text('$v'),
          ),
        ),
      );
      expect(find.bySemanticsLabel('300 걸음'), findsOneWidget);
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('스켈레톤', () {
    testWidgets('MLSkeletonList 는 스피너 없이 카드 모양 자리를 그리고 "불러오는 중"으로 읽힌다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const MLSkeletonList(count: 3)));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(MLSkeletonCard), findsNWidgets(3));
      expect(find.bySemanticsLabel('불러오는 중'), findsOneWidget);
      // 반복 애니메이션(shimmer)이 없어야 한다.
      expect(tester.hasRunningAnimations, isFalse);
      handle.dispose();
    });

    testWidgets('shrinkWrap 이면 다른 스크롤 뷰 안에서도 그릴 수 있다', (tester) async {
      await tester.pumpWidget(
        _host(
          const SingleChildScrollView(
            child: Column(children: [MLSkeletonList(count: 2, shrinkWrap: true)]),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(MLSkeletonCard), findsNWidgets(2));
    });

    Widget switcher(bool loading, {_Level level = _Level.full}) => _host(
      MLLoadSwitcher(
        loading: loading,
        skeleton: const MLSkeletonList(count: 1),
        child: const Text('내용'),
      ),
      level: level,
    );

    testWidgets('MLLoadSwitcher: full·fadeOnly 는 fade(150ms) 크로스페이드', (tester) async {
      for (final level in [_Level.full, _Level.fadeOnly]) {
        await tester.pumpWidget(switcher(true, level: level));
        await tester.pumpWidget(switcher(false, level: level));
        await tester.pump(const Duration(milliseconds: 75));
        // 전환 중에는 스켈레톤과 내용이 함께 있다.
        expect(find.byType(MLSkeletonCard), findsOneWidget, reason: '$level');
        expect(find.text('내용'), findsOneWidget);
        await tester.pump(AppMotion.fade);
        expect(find.byType(MLSkeletonCard), findsNothing, reason: '$level');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('MLLoadSwitcher: none 은 pump 1회로 바로 바뀐다', (tester) async {
      await tester.pumpWidget(switcher(true, level: _Level.none));
      await tester.pumpWidget(switcher(false, level: _Level.none));
      await tester.pump();
      expect(find.byType(MLSkeletonCard), findsNothing);
      expect(find.text('내용'), findsOneWidget);
    });
  });
}
