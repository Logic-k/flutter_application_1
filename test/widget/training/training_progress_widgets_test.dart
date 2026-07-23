import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training/widgets/course_node.dart';
import 'package:flutter_application_1/features/training/widgets/course_path.dart';
import 'package:flutter_application_1/features/training/widgets/daily_goal_panel.dart';
import 'package:flutter_application_1/features/training/widgets/training_progress_header.dart';
import 'package:flutter_application_1/features/training/widgets/training_result_sheet.dart';

Widget _subject(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 640),
        textScaler: TextScaler.linear(1.4),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('진행 헤더는 레벨과 다음 레벨까지의 경험치를 안내한다', (tester) async {
    await tester.pumpWidget(
      _subject(
        const TrainingProgressHeader(
          level: 3,
          totalXp: 245,
          xpInCurrentLevel: 45,
          xpForNextLevel: 100,
        ),
      ),
    );

    expect(find.text('레벨 3'), findsOneWidget);
    expect(find.text('총 245 XP'), findsOneWidget);
    expect(find.text('다음 레벨까지 55 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('과정 노드는 잠금과 완료 상태를 색상 없이도 표시한다', (tester) async {
    await tester.pumpWidget(
      _subject(
        const Column(
          children: [
            CourseNode(
              title: '구구단 맞추기',
              description: '누가 큰가요?를 먼저 완료해 주세요',
              icon: Icons.grid_3x3_rounded,
              status: CourseNodeStatus.locked,
              masteryStars: 0,
            ),
            CourseNode(
              title: '규칙 찾아보기',
              description: '수열 패턴 파악',
              icon: Icons.psychology_rounded,
              status: CourseNodeStatus.completed,
              masteryStars: 2,
            ),
          ],
        ),
      ),
    );

    expect(find.text('잠김'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.text('완료 · 숙련도 별 2개'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('과정 경로는 노드를 순서대로 배치하고 사용 가능한 노드를 실행한다', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _subject(
        CoursePath(
          nodes: [
            CourseNode(
              title: '누가 큰가요?',
              description: '빠른 수식 비교',
              icon: Icons.calculate_rounded,
              status: CourseNodeStatus.available,
              masteryStars: 0,
              onTap: () => tapped = true,
            ),
            const CourseNode(
              title: '구구단 맞추기',
              description: '기초 연산 훈련',
              icon: Icons.grid_3x3_rounded,
              status: CourseNodeStatus.locked,
              masteryStars: 0,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('누가 큰가요?'));
    expect(tapped, isTrue);
    expect(find.text('도전 가능'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('오늘 목표 패널은 서로 다른 활동 진행 수와 연속 학습을 표시한다', (tester) async {
    await tester.pumpWidget(
      _subject(
        const DailyGoalPanel(
          completedActivities: 2,
          goalActivities: 3,
          streakDays: 4,
        ),
      ),
    );

    expect(find.text('오늘 목표 2/3'), findsOneWidget);
    expect(find.text('4일 연속 학습 중'), findsOneWidget);
    expect(find.text('한 가지 활동만 더 하면 오늘 목표를 달성해요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('결과 시트는 격려, XP, 목표, 숙련, 잠금 해제 순서로 보여준다', (tester) async {
    await tester.pumpWidget(
      _subject(
        TrainingResultSheet(
          encouragement: '차분하게 끝까지 해냈어요.',
          xpEarned: 48,
          todayCompletedActivities: 3,
          todayGoalActivities: 3,
          masteryStars: 2,
          bestScore: 86,
          unlockedActivityName: '구구단 맞추기',
          onContinue: () {},
        ),
      ),
    );

    final labels = <String>[
      '차분하게 끝까지 해냈어요.',
      '+48 XP',
      '오늘 목표 3/3',
      '숙련도 별 2개 · 최고 86점',
      '새 활동 열림: 구구단 맞추기',
    ];
    final tops = labels
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(tops, orderedEquals(tops.toList()..sort()));
    expect(
      tester.getSize(find.byKey(const Key('training-result-continue'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });
}
