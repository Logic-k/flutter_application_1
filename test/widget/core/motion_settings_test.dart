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

  // 08 계획 G-01 — 세 신호(Android 애니메이션 제거 · iOS 동작 줄이기 · 앱 설정) 8조합.
  // Android 제거는 OS 전체를 끈 것이라 none, 나머지 둘은 페이드를 남기는 fadeOnly.
  const cases = <(bool, bool, bool, MotionLevel)>[
    (false, false, false, MotionLevel.full),
    (false, false, true, MotionLevel.fadeOnly),
    (false, true, false, MotionLevel.fadeOnly),
    (false, true, true, MotionLevel.fadeOnly),
    (true, false, false, MotionLevel.none),
    (true, false, true, MotionLevel.none),
    (true, true, false, MotionLevel.none),
    (true, true, true, MotionLevel.none),
  ];
  for (final (disable, iosReduce, app, expected) in cases) {
    testWidgets(
      'levelOf: 애니메이션 제거=$disable · iOS 동작 줄이기=$iosReduce · 앱 설정=$app → ${expected.name}',
      (tester) async {
        if (iosReduce) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(reduceMotion: true);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
        }
        MotionLevel? level;
        bool? reduce;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disable),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ChangeNotifierProvider<SettingsProvider>.value(
                value: _ReduceMotionSettings(app),
                child: Builder(
                  builder: (context) {
                    level = MotionSettings.levelOf(context);
                    reduce = MotionSettings.reduceOf(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );
        expect(level, expected);
        // 기존 호출부의 reduceOf 는 "full 이 아님"과 같다.
        expect(reduce, expected != MotionLevel.full);
      },
    );
  }
}
