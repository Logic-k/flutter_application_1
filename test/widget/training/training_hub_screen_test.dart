import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/training/data/training_progress_repository.dart';
import 'package:flutter_application_1/features/training/domain/training_catalog.dart';
import 'package:flutter_application_1/features/training/training_hub_page.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockTrainingProgressProvider extends Mock
    implements TrainingProgressProvider {}

Widget _buildSubject(
  _MockTrainingProgressProvider progress, {
  double textScale = 1,
}) {
  return ChangeNotifierProvider<TrainingProgressProvider>.value(
    value: progress,
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const TrainingHubScreen(),
    ),
  );
}

void _stubProgress(
  _MockTrainingProgressProvider progress, {
  Set<String> unlocks = initialTrainingActivityIds,
  Map<String, TrainingActivityProgressRecord> activityProgress = const {},
}) {
  when(() => progress.level).thenReturn(1);
  when(() => progress.totalXp).thenReturn(40);
  when(() => progress.todayDistinctActivityCount).thenReturn(2);
  when(() => progress.currentStreak).thenReturn(3);
  when(() => progress.isLoading).thenReturn(false);
  when(() => progress.error).thenReturn(null);
  when(() => progress.activityProgressById).thenReturn(activityProgress);
  when(() => progress.refresh()).thenAnswer((_) async {});
  when(() => progress.isUnlocked(any())).thenAnswer(
    (invocation) => unlocks.contains(invocation.positionalArguments.single),
  );
}

void main() {
  late _MockTrainingProgressProvider progress;

  setUp(() {
    progress = _MockTrainingProgressProvider();
    _stubProgress(progress);
  });

  testWidgets('XP, 오늘 목표, 8개 과정 노드를 표시한다', (tester) async {
    await tester.pumpWidget(_buildSubject(progress));
    await tester.pump();

    expect(find.text('두뇌 트레이닝 센터'), findsOneWidget);
    expect(find.text('레벨 1'), findsOneWidget);
    expect(find.text('오늘 목표 2/3'), findsOneWidget);
    for (final activity in trainingCatalog) {
      expect(find.byKey(Key('course-node-${activity.id}')), findsOneWidget);
    }
  });

  testWidgets('신규 사용자는 5개 활동만 열리고 선행 활동은 잠긴다', (tester) async {
    await tester.pumpWidget(_buildSubject(progress));
    await tester.pump();

    expect(find.text('도전 가능'), findsNWidgets(5));
    expect(find.text('잠김'), findsNWidgets(3));
  });

  testWidgets('잠긴 노드를 누르면 선행 활동을 안내한다', (tester) async {
    await tester.pumpWidget(_buildSubject(progress));
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('course-node-multiplication')),
    );
    await tester.tap(find.byKey(const Key('course-node-multiplication')));
    await tester.pump();

    expect(
      find.text('먼저 누가 큰가요? 활동을 한 번 완료해 보세요.'),
      findsOneWidget,
    );
  });

  testWidgets('완료 활동은 숙련도와 완료 상태를 함께 표시한다', (tester) async {
    _stubProgress(
      progress,
      activityProgress: {
        'comparison': const TrainingActivityProgressRecord(
          userId: 1,
          activityId: 'comparison',
          bestScore: 90,
          masteryStars: 3,
          completionCount: 1,
          firstCompletedAt: '2026-07-23T00:00:00Z',
          lastCompletedAt: '2026-07-23T00:00:00Z',
        ),
      },
    );
    await tester.pumpWidget(_buildSubject(progress));
    await tester.pump();

    expect(find.text('완료 · 숙련도 별 3개'), findsOneWidget);
  });

  testWidgets('320dp와 글자 크기 1.4에서 overflow가 없다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildSubject(progress, textScale: 1.4));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
