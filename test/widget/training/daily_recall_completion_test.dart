import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/features/training/application/training_attempt_input.dart';
import 'package:flutter_application_1/features/training/daily_recall_page.dart';
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
        activityId: 'daily_recall',
        completedAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    progress = _MockTrainingProgressProvider();
    when(() => progress.userId).thenReturn(1);
    when(
      () => progress.complete(any()),
    ).thenAnswer((_) async => throw StateError('write failed'));
  });

  Widget subject() => MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(
        value: FakeSettingsProvider(),
      ),
      ChangeNotifierProvider<TrainingProgressProvider>.value(value: progress),
    ],
    child: const MaterialApp(home: DailyRecallPage()),
  );

  testWidgets('일상 회상은 점수 없이 같은 완료 시도를 재전송한다', (tester) async {
    await tester.pumpWidget(subject());

    for (var index = 0; index < 5; index++) {
      await tester.enterText(find.byType(TextField), '회상 답변 ${index + 1}');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
    }

    final firstInput =
        verify(() => progress.complete(captureAny())).captured.single
            as TrainingAttemptInput;
    expect(firstInput.activityId, 'daily_recall');
    expect(firstInput.score, isNull);
    expect(firstInput.correctAnswers, isNull);
    expect(firstInput.totalQuestions, isNull);
    expect(firstInput.durationMs, isNotNull);
    expect(find.text('기록을 저장하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('회상 답변 5'), findsOneWidget);

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump();

    final retriedInput =
        verify(() => progress.complete(captureAny())).captured.single
            as TrainingAttemptInput;
    expect(retriedInput.attemptId, firstInput.attemptId);
    expect(retriedInput.completedAt, firstInput.completedAt);
  });
}
