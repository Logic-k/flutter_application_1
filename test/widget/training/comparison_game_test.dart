import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/features/training/games/comparison_game.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_definitions.dart';

void main() {
  setUpAll(() {
    // setCognitiveScore는 void이므로 미리 fallback 등록
    registerFallbackValue('');
    registerFallbackValue(0.0);
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

  testWidgets('ComparisonGame: 10문제 완료 후 결과 다이얼로그가 표시된다', (tester) async {
    final mockUser = MockUserProvider();
    when(() => mockUser.isLoggedIn).thenReturn(true);
    when(() => mockUser.currentUser)
        .thenReturn({'id': 1, 'username': 'testuser', 'has_completed_onboarding': 1});
    when(() => mockUser.calculationScore).thenReturn(0.0);
    when(() => mockUser.logicScore).thenReturn(0.0);
    when(() => mockUser.memoryScore).thenReturn(0.0);
    when(() => mockUser.attentionScore).thenReturn(0.0);
    when(() => mockUser.pedometerEnabled).thenReturn(false);
    when(() => mockUser.isLoading).thenReturn(false);
    when(() => mockUser.setCognitiveScore(any(), any())).thenReturn(null);

    await pumpWithProviders(
      tester,
      const ComparisonGame(),
      userProvider: mockUser,
    );
    await tester.pump();

    // 10번 탭하여 게임 완료
    for (int i = 0; i < 10; i++) {
      final cards = find.byType(InkWell);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pump();
      }
    }
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('계산 훈련 완료!'), findsOneWidget);
  });

  testWidgets('ComparisonGame: 타이틀 "누가 큰가요?"가 표시된다', (tester) async {
    await pumpWithProviders(tester, const ComparisonGame());
    await tester.pump();

    expect(find.text('누가 큰가요?'), findsOneWidget);
  });
}
