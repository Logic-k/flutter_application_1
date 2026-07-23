import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/training/games/comparison_game.dart';
import 'package:flutter_application_1/features/training/application/training_attempt_input.dart';
import 'package:flutter_application_1/features/training/application/training_completion_result.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_definitions.dart';

class MockTrainingProgressProvider extends Mock
    implements TrainingProgressProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
    registerFallbackValue(
      TrainingAttemptInput(
        attemptId: 'fallback',
        userId: 1,
        activityId: 'comparison',
        completedAt: DateTime(2026),
      ),
    );
  });

  testWidgets('ComparisonGame: VS 텍스트와 선택 카드 2개를 렌더링한다', (tester) async {
    await pumpWithProviders(tester, const ComparisonGame());
    await tester.pump();

    expect(find.text('VS'), findsOneWidget);
    expect(find.byType(InkWell), findsWidgets);
  });

  testWidgets('ComparisonGame: 초기 진행 상태가 "1 / 10"이다', (tester) async {
    await pumpWithProviders(tester, const ComparisonGame());
    await tester.pump();

    expect(find.text('1 / 10'), findsOneWidget);
  });

  testWidgets('ComparisonGame: 카드를 탭하면 "2 / 10"으로 진행한다', (tester) async {
    await pumpWithProviders(tester, const ComparisonGame());
    await tester.pump();

    // 첫 번째 InkWell 탭 (왼쪽 카드)
    final cards = find.byType(InkWell);
    await tester.tap(cards.first);
    await tester.pump();

    expect(find.text('2 / 10'), findsOneWidget);
  });

  testWidgets('ComparisonGame: 10문제 완료 후 진행 기록을 저장하고 결과를 표시한다', (tester) async {
    final mockUser = MockUserProvider();
    final progress = MockTrainingProgressProvider();
    when(() => mockUser.isLoggedIn).thenReturn(true);
    when(() => mockUser.currentUser).thenReturn({
      'id': 1,
      'username': 'testuser',
      'has_completed_onboarding': 1,
    });
    when(() => mockUser.calculationScore).thenReturn(0.0);
    when(() => mockUser.logicScore).thenReturn(0.0);
    when(() => mockUser.memoryScore).thenReturn(0.0);
    when(() => mockUser.attentionScore).thenReturn(0.0);
    when(() => mockUser.pedometerEnabled).thenReturn(false);
    when(() => mockUser.isLoading).thenReturn(false);
    when(() => mockUser.setCognitiveScore(any(), any())).thenReturn(null);
    when(() => progress.complete(any())).thenAnswer((invocation) async {
      final input =
          invocation.positionalArguments.single as TrainingAttemptInput;
      return _resultFor(input);
    });

    await pumpWithProviders(
      tester,
      const ComparisonGame(),
      userProvider: mockUser,
      trainingProgressProvider: progress,
    );
    await tester.pump();

    for (int i = 0; i < 10; i++) {
      await tester.tap(find.byKey(const Key('comparison-answer-left')));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final input =
        verify(() => progress.complete(captureAny())).captured.single
            as TrainingAttemptInput;
    expect(input.activityId, 'comparison');
    expect(input.totalQuestions, 10);
    expect(input.correctAnswers, inInclusiveRange(0, 10));
    expect(input.score, input.correctAnswers! * 10.0);
    expect(find.byKey(const Key('training-result-continue')), findsOneWidget);
  });

  testWidgets('ComparisonGame: 타이틀 "누가 큰가요?"가 표시된다', (tester) async {
    await pumpWithProviders(tester, const ComparisonGame());
    await tester.pump();

    expect(find.text('누가 큰가요?'), findsOneWidget);
  });
}

TrainingCompletionResult _resultFor(TrainingAttemptInput input) {
  return TrainingCompletionResult(
    attempt: TrainingAttemptRecord(
      id: input.attemptId,
      userId: input.userId,
      activityId: input.activityId,
      score: input.score,
      correctAnswers: input.correctAnswers,
      totalQuestions: input.totalQuestions,
      durationMs: input.durationMs,
      xpEarned: 21,
      completedAt: input.completedAt.toIso8601String(),
      localDate: '2026-07-23',
    ),
    totalXp: 21,
    level: 1,
    currentStreak: 1,
    longestStreak: 1,
    masteryStars: 1,
    completionCount: 1,
    bestScore: input.score,
    todayDistinctActivityCount: 1,
    newlyUnlockedActivityIds: const {},
    isDuplicate: false,
    scoreCategory: 'calculation',
  );
}
