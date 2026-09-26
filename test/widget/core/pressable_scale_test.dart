import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/motion/app_motion.dart';
import 'package:flutter_application_1/core/motion/pressable_scale.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/mock_definitions.dart';

class _FadeOnlySettings extends FakeSettingsProvider {
  @override
  bool get reduceMotion => true;
}

double _renderedOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

double _renderedScale(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.descendant(of: find.byType(AnimatedScale), matching: find.byType(Transform)),
  );
  return transform.transform.storage[0];
}

Widget _subject({bool reduce = false, VoidCallback? onTap}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: PressableScale(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: const SizedBox(width: 100, height: 100, key: Key('target')),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('누르는 동안 0.98로 줄고 놓으면 100ms 안에 1.0으로 돌아온다', (tester) async {
    await tester.pumpWidget(_subject());
    expect(_renderedScale(tester), 1.0);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('target'))));
    await tester.pump();
    await tester.pump(AppMotion.press);
    expect(_renderedScale(tester), closeTo(AppMotion.pressScale, 1e-6));

    await gesture.up();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_renderedScale(tester), closeTo(1.0, 1e-6));
  });

  testWidgets('축소 모션이면 애니메이션 없이 첫 프레임에 최종 상태를 그린다', (tester) async {
    await tester.pumpWidget(_subject(reduce: true));

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('target'))));
    await tester.pump();
    expect(_renderedScale(tester), closeTo(AppMotion.pressScale, 1e-6));

    await gesture.up();
    await tester.pump();
    expect(_renderedScale(tester), closeTo(1.0, 1e-6));
  });

  testWidgets('안쪽 제스처를 가로채지 않는다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_subject(onTap: () => taps++));
    await tester.tap(find.byKey(const Key('target')));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('fadeOnly면 크기는 그대로 두고 불투명도로 눌림을 알린다', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: _FadeOnlySettings(),
        child: _subject(),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('target'))));
    await tester.pump();
    await tester.pump(AppMotion.press);
    expect(_renderedScale(tester), closeTo(1.0, 1e-6));
    expect(_renderedOpacity(tester), AppMotion.pressOpacity);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_renderedOpacity(tester), 1.0);
  });
}
