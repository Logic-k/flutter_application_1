import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training/games/categorization_game.dart';

// CategorizationGame은 Provider 의존성이 없으므로 MaterialApp만으로 충분
Widget _subject() => const MaterialApp(home: CategorizationGame());

void main() {
  testWidgets('CategorizationGame: 첫 문제로 "사과"를 렌더링한다', (tester) async {
    await tester.pumpWidget(_subject());
    expect(find.text('사과'), findsOneWidget);
  });

  testWidgets('CategorizationGame: 첫 문제의 선택지 3개를 렌더링한다', (tester) async {
    await tester.pumpWidget(_subject());
    expect(find.text('과일'), findsOneWidget);
    expect(find.text('채소'), findsOneWidget);
    expect(find.text('곡류'), findsOneWidget);
  });

  testWidgets('CategorizationGame: 올바른 답("과일")을 탭하면 정답 SnackBar를 표시한다',
      (tester) async {
    await tester.pumpWidget(_subject());
    await tester.tap(find.text('과일'));
    await tester.pump();

    expect(find.text('정답입니다! (+20점)'), findsOneWidget);

    // 600ms 딜레이 타이머 소진 후 테스트 종료
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('CategorizationGame: 틀린 답("채소")을 탭하면 오답 SnackBar를 표시한다',
      (tester) async {
    await tester.pumpWidget(_subject());
    await tester.tap(find.text('채소'));
    await tester.pump();

    expect(find.text('아쉽네요. 다음 문제를 풀어보세요.'), findsOneWidget);

    // 600ms 딜레이 타이머 소진 후 테스트 종료
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('CategorizationGame: 600ms 후 다음 문제("시금치")로 넘어간다', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.tap(find.text('과일')); // 정답
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('시금치'), findsOneWidget);
  });

  testWidgets('CategorizationGame: 5문제 완료 후 "훈련 완료!" 화면을 표시한다',
      (tester) async {
    await tester.pumpWidget(_subject());

    // 각 문제 정답 순서대로 탭
    final correctAnswers = ['과일', '채소', '어류', '육류', '곡류'];
    for (final answer in correctAnswers) {
      await tester.pump();
      await tester.tap(find.text(answer));
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pumpAndSettle();

    expect(find.text('훈련 완료!'), findsOneWidget);
  });

  testWidgets('CategorizationGame: 진행 바(LinearProgressIndicator)가 표시된다',
      (tester) async {
    await tester.pumpWidget(_subject());
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
