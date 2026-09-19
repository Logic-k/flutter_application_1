import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_application_1/features/training/training_history_screen.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockTrainingProgressProvider extends Mock
    implements TrainingProgressProvider {}

TrainingAttemptRecord _attempt({
  required String id,
  String activityId = 'comparison',
  double? score = 80,
  int? correct = 4,
  int? total = 5,
  int? durationMs = 30000,
  int xp = 12,
  String completedAt = '2026-09-18T10:30:00',
  String localDate = '2026-09-18',
}) {
  return TrainingAttemptRecord(
    id: id,
    userId: 1,
    activityId: activityId,
    score: score,
    correctAnswers: correct,
    totalQuestions: total,
    durationMs: durationMs,
    xpEarned: xp,
    completedAt: completedAt,
    localDate: localDate,
  );
}

Widget _buildSubject(_MockTrainingProgressProvider progress) {
  return ChangeNotifierProvider<TrainingProgressProvider>.value(
    value: progress,
    child: const MaterialApp(home: TrainingHistoryScreen()),
  );
}

void main() {
  late _MockTrainingProgressProvider progress;

  setUp(() => progress = _MockTrainingProgressProvider());

  void stubAttempts(List<TrainingAttemptRecord> attempts) {
    when(() => progress.getAttempts()).thenAnswer((_) async => attempts);
  }

  testWidgets('날짜 헤더와 활동명·점수·XP를 표시한다', (tester) async {
    stubAttempts([
      _attempt(id: 'a1', completedAt: '2026-09-18T10:30:00'),
      _attempt(
        id: 'a2',
        activityId: 'shape_match',
        score: 95,
        xp: 18,
        completedAt: '2026-09-19T14:00:00',
        localDate: '2026-09-19',
      ),
    ]);
    await tester.pumpWidget(_buildSubject(progress));
    await tester.pumpAndSettle();

    expect(find.text('나의 훈련 기록'), findsOneWidget);
    // 활동명은 필터 칩과 타일 제목에 각각 표시된다.
    expect(find.text('누가 큰가요?'), findsNWidgets(2));
    expect(find.text('같은 모양 찾기'), findsNWidgets(2));
    expect(find.text('+12 XP'), findsOneWidget);
    expect(find.text('+18 XP'), findsOneWidget);
    // 최신 날짜가 위에 온다 (9월 19일 → 9월 18일 순)
    final topDate = find.textContaining('9월 19일');
    final bottomDate = find.textContaining('9월 18일');
    expect(topDate, findsOneWidget);
    expect(bottomDate, findsOneWidget);
    expect(
      tester.getTopLeft(topDate).dy,
      lessThan(tester.getTopLeft(bottomDate).dy),
    );
  });

  testWidgets('활동이 2종류 이상이면 필터 칩을 표시하고 필터링한다', (tester) async {
    stubAttempts([
      _attempt(id: 'a1', activityId: 'comparison'),
      _attempt(id: 'a2', activityId: 'shape_match'),
    ]);
    await tester.pumpWidget(_buildSubject(progress));
    await tester.pumpAndSettle();

    // 활동명이 칩 라벨과 타일 제목에 중복되므로 개수로 구분한다.
    expect(find.text('누가 큰가요?'), findsNWidgets(2)); // 칩 + 타일
    expect(find.widgetWithText(ChoiceChip, '전체'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '같은 모양 찾기'));
    await tester.pumpAndSettle();

    // 필터 후 '누가 큰가요?'는 칩에만 남는다.
    expect(find.text('누가 큰가요?'), findsOneWidget);
    expect(find.text('같은 모양 찾기'), findsNWidgets(2));
  });

  testWidgets('기록이 없으면 빈 상태 안내를 표시한다', (tester) async {
    stubAttempts(const []);
    await tester.pumpWidget(_buildSubject(progress));
    await tester.pumpAndSettle();

    expect(find.textContaining('아직 완료한 훈련이 없습니다'), findsOneWidget);
  });

  testWidgets('조회 실패 시 오류 상태와 재시도 버튼을 표시한다', (tester) async {
    var callCount = 0;
    when(() => progress.getAttempts()).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) throw StateError('db error');
      return [_attempt(id: 'a1')];
    });
    await tester.pumpWidget(_buildSubject(progress));
    await tester.pumpAndSettle();

    expect(find.textContaining('불러오지 못했습니다'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('누가 큰가요?'), findsOneWidget);
  });
}
