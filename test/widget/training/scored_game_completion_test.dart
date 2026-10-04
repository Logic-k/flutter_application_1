import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/voice_service.dart';
import 'package:flutter_application_1/features/training/application/training_attempt_input.dart';
import 'package:flutter_application_1/features/training/application/training_completion_result.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_application_1/features/training/games/comparison_game.dart';
import 'package:flutter_application_1/features/training/games/multiplication_game.dart';
import 'package:flutter_application_1/features/training/games/sequence_game.dart';
import 'package:flutter_application_1/features/training/games/shape_match_game.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockTrainingProgressProvider extends Mock
    implements TrainingProgressProvider {}

void main() {
  setUpAll(() {
    VoiceService.voiceEnabled = false;
    registerFallbackValue(
      TrainingAttemptInput(
        attemptId: 'fallback',
        userId: 1,
        activityId: 'comparison',
        completedAt: DateTime(2026),
      ),
    );
  });

  testWidgets('MultiplicationGame: 마지막 답변은 multiplication 완료 기록을 한 번 저장한다', (
    tester,
  ) async {
    final progress = MockTrainingProgressProvider();
    when(() => progress.complete(any())).thenAnswer((invocation) async {
      return _resultFor(_inputFrom(invocation), 'calculation');
    });
    await _pumpGame(tester, const MultiplicationGame(), progress);

    await _finishGame(
      tester,
      answerKey: const Key('multiplication-answer-0'),
      totalQuestions: 10,
    );

    final input = _capturedInput(progress);
    expect(input.activityId, 'multiplication');
    expect(input.totalQuestions, 10);
    expect(input.score, input.correctAnswers! * 10.0);
    expect(find.byKey(const Key('training-result-continue')), findsOneWidget);
  });

  testWidgets('SequenceGame: 마지막 답변은 sequence 완료 기록을 한 번 저장한다', (tester) async {
    final progress = MockTrainingProgressProvider();
    when(() => progress.complete(any())).thenAnswer((invocation) async {
      return _resultFor(_inputFrom(invocation), 'logic');
    });
    await _pumpGame(tester, const SequenceGame(), progress);

    await _finishGame(
      tester,
      answerKey: const Key('sequence-answer-0'),
      totalQuestions: 5,
    );

    final input = _capturedInput(progress);
    expect(input.activityId, 'sequence');
    expect(input.totalQuestions, 5);
    expect(input.score, input.correctAnswers! * 20.0);
    expect(find.byKey(const Key('training-result-continue')), findsOneWidget);
  });

  testWidgets('ShapeMatchGame: 마지막 답변은 shape_match 완료 기록을 한 번 저장한다', (
    tester,
  ) async {
    final progress = MockTrainingProgressProvider();
    when(() => progress.complete(any())).thenAnswer((invocation) async {
      return _resultFor(_inputFrom(invocation), 'attention');
    });
    await _pumpGame(tester, const ShapeMatchGame(), progress);

    await _finishGame(
      tester,
      answerKey: const Key('shape-match-answer-0'),
      totalQuestions: 10,
    );

    final input = _capturedInput(progress);
    expect(input.activityId, 'shape_match');
    expect(input.totalQuestions, 10);
    expect(input.score, input.correctAnswers! * 10.0);
    expect(find.byKey(const Key('training-result-continue')), findsOneWidget);
  });

  testWidgets('ComparisonGame: 저장 실패 후 같은 시도만 재전송한다', (tester) async {
    final progress = MockTrainingProgressProvider();
    var callCount = 0;
    when(() => progress.complete(any())).thenAnswer((invocation) async {
      callCount++;
      final input = _inputFrom(invocation);
      if (callCount == 1) {
        throw StateError('temporary failure');
      }
      return _resultFor(input, 'calculation');
    });
    await _pumpGame(tester, const ComparisonGame(), progress);

    await _finishGame(
      tester,
      answerKey: const Key('comparison-answer-left'),
      totalQuestions: 10,
      settle: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('기록을 저장하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    final disabledAnswer = tester.widget<InkWell>(
      find.byKey(const Key('comparison-answer-left')),
    );
    expect(disabledAnswer.onTap, isNull);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => progress.complete(captureAny()),
    ).captured.cast<TrainingAttemptInput>();
    expect(captured, hasLength(2));
    expect(captured[1].attemptId, captured[0].attemptId);
    expect(captured[1].score, captured[0].score);
    expect(find.byKey(const Key('training-result-continue')), findsOneWidget);
  });
}

Future<void> _pumpGame(
  WidgetTester tester,
  Widget game,
  TrainingProgressProvider progress,
) async {
  await tester.binding.setSurfaceSize(const Size(500, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpWithProviders(tester, game, trainingProgressProvider: progress);
  await tester.pump();
}

Future<void> _finishGame(
  WidgetTester tester, {
  required Key answerKey,
  required int totalQuestions,
  bool settle = true,
}) async {
  for (var index = 0; index < totalQuestions; index++) {
    await tester.tap(find.byKey(answerKey).first);
    await tester.pump();
  }
  if (settle) {
    await tester.pumpAndSettle();
  }
}

TrainingAttemptInput _capturedInput(MockTrainingProgressProvider progress) {
  return verify(() => progress.complete(captureAny())).captured.single
      as TrainingAttemptInput;
}

TrainingAttemptInput _inputFrom(Invocation invocation) {
  return invocation.positionalArguments.single as TrainingAttemptInput;
}

TrainingCompletionResult _resultFor(
  TrainingAttemptInput input,
  String scoreCategory,
) {
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
    scoreCategory: scoreCategory,
  );
}
