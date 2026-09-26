import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/motion/motion_settings.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/mock_definitions.dart';

class _ReduceMotionSettings extends FakeSettingsProvider {
  _ReduceMotionSettings(this._reduce);
  final bool _reduce;
  @override
  bool get reduceMotion => _reduce;
}

Widget _probe(ValueSetter<bool> onBuild, {SettingsProvider? settings}) {
  final child = Builder(
    builder: (context) {
      onBuild(MotionSettings.reduceOf(context));
      return const SizedBox.shrink();
    },
  );
  if (settings == null) return child;
  return ChangeNotifierProvider<SettingsProvider>.value(
    value: settings,
    child: child,
  );
}

void main() {
  testWidgets('세 신호가 모두 꺼져 있으면 축소 모션이 아니다', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(home: _probe((v) => result = v, settings: _ReduceMotionSettings(false))),
    );
    expect(result, isFalse);
  });

  testWidgets('MediaQuery.disableAnimations(Android 애니메이션 제거)만으로 축소 모션이 된다', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _probe((v) => result = v),
        ),
      ),
    );
    expect(result, isTrue);
  });

  testWidgets('iOS reduceMotion 플래그만으로 축소 모션이 된다', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    bool? result;
    await tester.pumpWidget(MaterialApp(home: _probe((v) => result = v)));
    expect(result, isTrue);
  });

  testWidgets('앱 설정 "움직임 줄이기"만으로 축소 모션이 된다', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(home: _probe((v) => result = v, settings: _ReduceMotionSettings(true))),
    );
    expect(result, isTrue);
  });

  testWidgets('SettingsProvider가 없어도 예외 없이 플랫폼 신호만 본다', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(home: _probe((v) => result = v)));
    expect(result, isFalse);
  });
}
