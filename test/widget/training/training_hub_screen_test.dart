import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/training/training_hub_page.dart';
import 'package:flutter_application_1/features/training/difficulty_provider.dart';
import '../../helpers/mock_definitions.dart';

Widget _buildSubject(MockDifficultyProvider mockDiff) {
  return ChangeNotifierProvider<DifficultyProvider>.value(
    value: mockDiff,
    child: const MaterialApp(home: TrainingHubScreen()),
  );
}

void _stubDifficulty(MockDifficultyProvider m) {
  when(() => m.getLevel(GameCategory.calculation)).thenReturn(1);
  when(() => m.getLevel(GameCategory.logic)).thenReturn(1);
  when(() => m.getLevel(GameCategory.memory)).thenReturn(1);
  when(() => m.getLevel(GameCategory.perception)).thenReturn(1);
}

void main() {
  late MockDifficultyProvider mockDiff;

  setUp(() {
    mockDiff = MockDifficultyProvider();
    _stubDifficulty(mockDiff);
  });

  testWidgets('TrainingHubScreen: 두뇌 트레이닝 센터 타이틀이 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockDiff));
    await tester.pump();

    expect(find.text('두뇌 트레이닝 센터'), findsOneWidget);
  });

  testWidgets('TrainingHubScreen: 계산 및 판단력 카테고리가 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockDiff));
    await tester.pump();

    expect(find.text('계산 및 판단력'), findsOneWidget);
  });

  testWidgets('TrainingHubScreen: 논리 및 추론 카테고리가 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockDiff));
    await tester.pump();

    // SingleChildScrollView는 전체 자식을 빌드하므로 스크롤 없이 위젯 트리에서 찾을 수 있다
    expect(find.text('논리 및 추론'), findsOneWidget);
  });

  testWidgets('TrainingHubScreen: 게임 카드들이 최소 2개 이상 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockDiff));
    await tester.pump();

    // 누가 큰가요, 구구단 맞추기
    expect(find.text('누가 큰가요?'), findsOneWidget);
    expect(find.text('구구단 맞추기'), findsOneWidget);
  });

  testWidgets('TrainingHubScreen: 진행률 배너가 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockDiff));
    await tester.pump();

    // 주간 목표 관련 텍스트 확인 (5/14 또는 주간 등)
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });
}
