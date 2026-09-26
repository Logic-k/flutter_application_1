import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/motion/burst_particles.dart';
import 'package:flutter_application_1/core/motion/game_feedback.dart';
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
  GameFeedbackController? feedback,
  bool reduceMotion = false,
  String? activityId,
}) {
  final settings = _MockSettingsProvider();
  when(() => settings.voiceGuidanceEnabled).thenReturn(false);
  when(() => settings.hapticFeedbackEnabled).thenReturn(false);
  when(() => settings.reduceMotion).thenReturn(reduceMotion);

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
          feedback: feedback,
          activityId: activityId,
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

  testWidgets('정답 신호는 체크 배지·문구·파티클을 한 번 보여주고 사라진다', (tester) async {
    final feedback = GameFeedbackController();
    addTearDown(feedback.dispose);
    await tester.pumpWidget(_subject(feedback: feedback));

    feedback.correct('정답입니다');
    await tester.pump();

    expect(find.text('정답입니다'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byType(BurstParticles), findsOneWidget);

    // 반복 재생이 없으므로 pumpAndSettle 이 끝나야 한다.
    await tester.pumpAndSettle();
    expect(find.text('정답입니다'), findsNothing);
  });

  testWidgets('오답 신호는 X 배지와 정답 안내를 보여주고 파티클은 없다', (tester) async {
    final feedback = GameFeedbackController();
    addTearDown(feedback.dispose);
    await tester.pumpWidget(_subject(feedback: feedback));

    feedback.wrong('아쉬워요 · 정답은 42');
    await tester.pump();

    expect(find.text('아쉬워요 · 정답은 42'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.byType(BurstParticles), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('움직임 줄이기면 배지가 첫 프레임부터 완전히 보이고 파티클이 없다', (
    tester,
  ) async {
    final feedback = GameFeedbackController();
    addTearDown(feedback.dispose);
    await tester.pumpWidget(_subject(feedback: feedback, reduceMotion: true));

    feedback.correct('정답입니다');
    await tester.pump();

    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('정답입니다'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
    expect(find.byType(BurstParticles), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('활동 ID를 주면 목표 카드에 허브에서 이어지는 Hero 아이콘을 그린다', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(activityId: 'comparison'));

    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'training-activity-comparison');
    expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);
    expect(find.text('테스트 목표'), findsOneWidget);
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
