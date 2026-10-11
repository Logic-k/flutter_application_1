import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/features/training/application/training_attempt_input.dart';
import 'package:flutter_application_1/features/training/application/training_completion_result.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_application_1/features/training/topic_choice_page.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mock_definitions.dart';

class _MockTrainingProgressProvider extends Mock
    implements TrainingProgressProvider {}

void main() {
  late _MockTrainingProgressProvider progress;

  setUpAll(() {
    registerFallbackValue(
      TrainingAttemptInput(
        attemptId: 'fallback',
        userId: 1,
        activityId: 'topic_choice',
        completedAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    progress = _MockTrainingProgressProvider();
    when(() => progress.userId).thenReturn(1);
    when(() => progress.complete(any())).thenAnswer((invocation) async {
      final input =
          invocation.positionalArguments.single as TrainingAttemptInput;
      return TrainingCompletionResult(
        attempt: TrainingAttemptRecord(
          id: input.attemptId,
          userId: input.userId,
          activityId: input.activityId,
          score: input.score,
          correctAnswers: input.correctAnswers,
          totalQuestions: input.totalQuestions,
          durationMs: input.durationMs,
          xpEarned: 40,
          completedAt: input.completedAt.toUtc().toIso8601String(),
          localDate: '2026-07-23',
          completionStatus: input.completionStatus,
          assistanceLevel: input.assistanceLevel,
          sessionContext: input.sessionContext,
          contentVersion: input.contentVersion,
          responseCode: input.responseCode,
        ),
        totalXp: 40,
        level: 1,
        currentStreak: 1,
        longestStreak: 1,
        masteryStars: 0,
        completionCount: 1,
        bestScore: null,
        todayDistinctActivityCount: 1,
        newlyUnlockedActivityIds: const {},
        isDuplicate: false,
        scoreCategory: null,
      );
    });
  });

  Widget subject() => MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(
        value: FakeSettingsProvider(),
      ),
      ChangeNotifierProvider<TrainingProgressProvider>.value(value: progress),
    ],
    child: const MaterialApp(home: TopicChoicePage()),
  );

  Future<void> showSubmitButton(WidgetTester tester) async {
    final button = find.text('활동 기록하기');
    for (var i = 0; i < 4 && button.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pump();
    }
    expect(button, findsOneWidget);
  }

  Future<void> showText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    for (var i = 0; i < 4 && finder.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pump();
    }
    expect(finder, findsOneWidget);
  }

  testWidgets('주제 선택은 점수 없이 도움 수준과 맥락을 기록한다', (tester) async {
    await tester.pumpWidget(subject());
    await tester.tap(find.text('좋아하는 음식'));
    await showText(tester, '말로 설명을 들었어요');
    await tester.tap(find.text('말로 설명을 들었어요'));
    await showSubmitButton(tester);
    await tester.tap(find.text('활동 기록하기'));
    await tester.pump();

    final input =
        verify(() => progress.complete(captureAny())).captured.single
            as TrainingAttemptInput;
    expect(input.activityId, 'topic_choice');
    expect(input.score, isNull);
    expect(input.correctAnswers, isNull);
    expect(input.totalQuestions, isNull);
    expect(input.completionStatus, TrainingCompletionStatus.completed);
    expect(input.assistanceLevel, TrainingAssistanceLevel.verbalPrompt);
    expect(input.sessionContext, TrainingSessionContext.selfPractice);
    expect(input.contentVersion, 'topic_choice_v1');
    expect(input.responseCode, 'meal');
    expect(input.durationMs, isNotNull);
  });

  testWidgets('활동은 안내 질문을 보여주되 자유 대화 내용 입력란은 만들지 않는다', (tester) async {
    await tester.pumpWidget(subject());

    expect(find.text('2. 짧게 떠올려 보기'), findsOneWidget);
    expect(find.textContaining('대화 내용은 앱에 저장하지 않고'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('주제를 고르지 않으면 저장하지 않는다', (tester) async {
    await tester.pumpWidget(subject());
    await showSubmitButton(tester);
    await tester.tap(find.text('활동 기록하기'));
    await tester.pump();

    verifyNever(() => progress.complete(any()));
    expect(find.text('오늘 이야기할 주제를 하나 골라주세요.'), findsOneWidget);
  });
}
