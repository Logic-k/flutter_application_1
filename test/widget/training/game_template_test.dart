import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/features/training/difficulty_provider.dart';
import 'package:flutter_application_1/features/training/widgets/game_template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockDifficultyProvider extends Mock implements DifficultyProvider {}

class _MockSettingsProvider extends Mock implements SettingsProvider {}

Widget _subject({
  DifficultyProvider? difficultyProvider,
  double textScale = 1,
  GameCategory? adaptiveCategory,
}) {
  final settings = _MockSettingsProvider();
  when(() => settings.voiceGuidanceEnabled).thenReturn(false);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<DifficultyProvider>.value(
        value: difficultyProvider ?? _MockDifficultyProvider(),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: GameTemplate(
          title: '테스트 훈련',
          objective: '테스트 목표',
          currentStep: 2,
          totalSteps: 5,
          adaptiveCategory: adaptiveCategory,
          child: const Text('게임 내용'),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(GameCategory.logic);
  });

  testWidgets('기존 게임 셸과 단계 카운터를 렌더링한다', (tester) async {
    await tester.pumpWidget(_subject());

    expect(find.text('테스트 훈련'), findsOneWidget);
    expect(find.text('테스트 목표'), findsOneWidget);
    expect(find.text('게임 내용'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('카테고리를 지정하지 않으면 목표 시간 배지를 숨긴다', (tester) async {
    await tester.pumpWidget(_subject());

    expect(find.textContaining('목표:'), findsNothing);
    expect(find.text('2 / 5'), findsOneWidget);
  });

  testWidgets('지정한 기억 카테고리의 목표 시간을 정확히 표시한다', (tester) async {
    final difficulty = _MockDifficultyProvider();
    when(() => difficulty.getTargetTime(GameCategory.memory)).thenReturn(3.4);
    when(
      () => difficulty.getTargetTime(GameCategory.perception),
    ).thenReturn(9.9);

    await tester.pumpWidget(
      _subject(
        difficultyProvider: difficulty,
        adaptiveCategory: GameCategory.memory,
      ),
    );

    expect(find.text('목표: 3.4초'), findsOneWidget);
    expect(find.text('목표: 9.9초'), findsNothing);
    verify(() => difficulty.getTargetTime(GameCategory.memory)).called(1);
    verifyNever(() => difficulty.getTargetTime(GameCategory.perception));
  });

  testWidgets('320x640 화면과 1.4 텍스트 배율에서 넘치지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final difficulty = _MockDifficultyProvider();
    when(() => difficulty.getTargetTime(GameCategory.memory)).thenReturn(3.4);

    await tester.pumpWidget(
      _subject(
        difficultyProvider: difficulty,
        adaptiveCategory: GameCategory.memory,
        textScale: 1.4,
      ),
    );

    expect(find.text('목표: 3.4초'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
