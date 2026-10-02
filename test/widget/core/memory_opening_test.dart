import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/motion/app_motion.dart';
import 'package:flutter_application_1/core/motion/motion_play_log.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart';
import 'package:flutter_application_1/features/opening/memory_opening.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/mock_definitions.dart';

class _FadeOnlySettings extends FakeSettingsProvider {
  @override
  bool get reduceMotion => true;
}

/// 오프닝 층(접근성 식별자가 붙은 Semantics).
Finder _opening() => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.identifier == MemoryOpening.semanticsId,
);

/// 오프닝 아래 앱의 TickerMode.
bool _appTickers(WidgetTester tester) => tester
    .widget<TickerMode>(
      find.ancestor(of: find.text('앱 화면'), matching: find.byType(TickerMode)).first,
    )
    .enabled;

Widget _subject({
  bool start = true,
  bool ready = true,
  bool disable = false,
  bool fadeOnly = false,
}) {
  Widget child = MediaQuery(
    data: MediaQueryData(disableAnimations: disable),
    child: MemoryOpening(
      start: start,
      ready: ready,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Text('앱 화면')),
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

/// 60Hz 프레임으로 [d] 만큼 흘린다. 오프닝 시계는 한 프레임에 최대 50ms 만 흐르므로
/// `pump(긴 시간)` 한 번으로는 넘어가지 않는다.
Future<void> _play(WidgetTester tester, Duration d) async {
  const frame = Duration(microseconds: 16667);
  for (var t = Duration.zero; t < d; t += frame) {
    await tester.pump(frame);
  }
  await tester.pump(); // 부모에 알리는 콜백(다음 프레임)
}

void main() {
  setUp(MotionPlayLog.reset);

  testWidgets('full: 덮는 동안 앱의 접근성 노드와 티커를 막고, 2.4초 뒤 걷힌다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_subject());

    expect(_opening(), findsOneWidget);
    expect(find.bySemanticsLabel('앱 화면'), findsNothing);
    expect(_appTickers(tester), isFalse);
    // 스플래시 → 로그인 로고 이동은 오프닝이 대신한다.
    expect(MotionPlayLog.hasPlayed(LoginScreen.splashPlayKey), isTrue);

    await _play(tester, AppMotion.opening * 0.5);
    expect(_opening(), findsOneWidget);
    expect(_appTickers(tester), isFalse);

    // 가운데가 열리기 시작하면(1.8초) 아래 앱의 진입 안무가 돈다.
    await _play(tester, AppMotion.opening * 0.3);
    expect(_appTickers(tester), isTrue);
    expect(_opening(), findsOneWidget);

    await _play(tester, AppMotion.opening * 0.25);
    expect(_opening(), findsNothing);
    expect(find.bySemanticsLabel('앱 화면'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('full: 긴 프레임 하나(콜드 스타트 초기화)가 장면을 건너뛰게 하지 않는다', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pump();
    await tester.pump(AppMotion.opening * 2); // UI 스레드가 4.8초 막힌 프레임
    await tester.pump();
    expect(_opening(), findsOneWidget);
    expect(_appTickers(tester), isFalse, reason: '벽시계를 따랐다면 이미 끝났다');

    await _play(tester, AppMotion.opening);
    expect(_opening(), findsNothing);
  });

  testWidgets('full: 로그인 확인이 늦으면 정지 화면에서 멈춰 기다리고, 준비되면 이어 간다', (tester) async {
    await tester.pumpWidget(_subject(ready: false));
    await _play(tester, AppMotion.opening);

    expect(_opening(), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse, reason: '기다리는 동안 움직이지 않는다(반복 금지)');

    await tester.pumpWidget(_subject(ready: true));
    expect(tester.hasRunningAnimations, isTrue);
    await _play(tester, AppMotion.opening * 0.3);
    expect(_opening(), findsNothing);
  });

  testWidgets('full: 누르면 가운데가 열리는 구간으로 건너뛴다', (tester) async {
    await tester.pumpWidget(_subject());
    await _play(tester, AppMotion.enter);
    await tester.tap(_opening());

    // 남은 것은 열림 구간(0.6초)뿐이다.
    await _play(tester, AppMotion.opening * 0.26);
    expect(_opening(), findsNothing);
    expect(find.text('앱 화면'), findsOneWidget);
  });

  testWidgets('start 전(설정 읽는 중)에는 스플래시와 같은 정지 화면만 그린다', (tester) async {
    await tester.pumpWidget(_subject(start: false));
    await _play(tester, AppMotion.opening);
    expect(_opening(), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_subject(start: true));
    await _play(tester, AppMotion.opening * 1.05);
    expect(_opening(), findsNothing);
  });

  testWidgets('fadeOnly: 움직이지 않고 기다리다 준비되면 fade 로 사라진다', (tester) async {
    await tester.pumpWidget(_subject(fadeOnly: true, ready: false));
    await _play(tester, AppMotion.opening);
    expect(_opening(), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(AnimatedOpacity), findsOneWidget);

    await tester.pumpWidget(_subject(fadeOnly: true, ready: true));
    await tester.pump();
    expect(_appTickers(tester), isTrue);
    await _play(tester, AppMotion.fade + AppMotion.press);
    expect(_opening(), findsNothing);
  });

  for (final initial in [
    (start: true, ready: true),
    (start: false, ready: true),
    (start: false, ready: false),
  ]) {
    testWidgets('fadeOnly: 초기 start=${initial.start}, ready=${initial.ready}에서도 오프닝을 걷는다',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_subject(
          fadeOnly: true, start: initial.start, ready: initial.ready,
        ));
        if (!initial.start) {
          await tester.pumpWidget(_subject(fadeOnly: true));
        }

        // 마운트 때부터 0이면 애니메이션과 onEnd가 실행되지 않는다.
        expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
        await tester.pump();
        expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);
        expect(_opening(), findsOneWidget);
        expect(_appTickers(tester), isTrue);
        expect(find.bySemanticsLabel('앱 화면'), findsNothing);

        await _play(tester, AppMotion.fade + AppMotion.press);
        expect(_opening(), findsNothing);
        expect(find.bySemanticsLabel('앱 화면'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('fadeOnly: 사라지는 중 화면이 제거돼도 뒤늦은 콜백이 실패하지 않는다', (tester) async {
    await tester.pumpWidget(_subject(fadeOnly: true));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await _play(tester, AppMotion.fade + AppMotion.press);
    expect(tester.takeException(), isNull);
  });

  testWidgets('none: 준비되는 즉시 사라지고 애니메이션이 없다', (tester) async {
    await tester.pumpWidget(_subject(disable: true, ready: false));
    await _play(tester, AppMotion.enter);
    expect(_opening(), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(AnimatedOpacity), findsNothing);

    await tester.pumpWidget(_subject(disable: true, ready: true));
    await tester.pump();
    expect(_opening(), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
