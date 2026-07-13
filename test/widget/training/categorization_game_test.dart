import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/features/training/difficulty_provider.dart';
import 'package:flutter_application_1/features/training/games/categorization_game.dart';
import '../../helpers/mock_definitions.dart';

// 게임의 easy 문제풀(레벨 1-3)과 동일한 단어→정답 카테고리 매핑.
// 문제가 랜덤으로 출제되므로 화면의 단어를 찾아 정답을 역산한다.
const Map<String, String> _categoryOf = {
  '사과': '과일', '배': '과일', '포도': '과일', '딸기': '과일', '복숭아': '과일',
  '수박': '과일', '오렌지': '과일', '귤': '과일', '바나나': '과일', '감': '과일',
  '시금치': '채소', '당근': '채소', '양파': '채소', '배추': '채소', '감자': '채소',
  '고구마': '채소', '오이': '채소', '호박': '채소', '마늘': '채소', '상추': '채소',
  '고등어': '어류', '갈치': '어류', '참치': '어류', '연어': '어류', '멸치': '어류',
  '소고기': '육류', '돼지고기': '육류', '닭고기': '육류',
  '쌀': '곡류', '보리': '곡류', '밀': '곡류', '옥수수': '곡류',
  '우유': '유제품', '치즈': '유제품', '요거트': '유제품',
};

String _currentWord() {
  for (final word in _categoryOf.keys) {
    if (find.text(word).evaluate().isNotEmpty) return word;
  }
  fail('화면에서 문제 단어를 찾을 수 없습니다.');
}

List<String> _currentOptions() {
  return find
      .descendant(
        of: find.byType(OutlinedButton),
        matching: find.byType(Text),
      )
      .evaluate()
      .map((e) => (e.widget as Text).data!)
      .toList();
}

void main() {
  late MockUserProvider mockUser;
  late MockDifficultyProvider mockDifficulty;

  setUpAll(() {
    registerFallbackValue(GameCategory.logic);
  });

  setUp(() {
    mockUser = MockUserProvider();
    mockDifficulty = MockDifficultyProvider();
    // 레벨 1 → easy 문제풀, 3지선다
    when(() => mockDifficulty.getLevel(any())).thenReturn(1);
    when(() => mockDifficulty.getTargetTime(any())).thenReturn(5.0);
    when(() => mockDifficulty.updatePerformance(any(), any(),
        responseTime: any(named: 'responseTime'))).thenAnswer((_) async {});
  });

  Widget subject() => MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: mockUser),
          ChangeNotifierProvider<DifficultyProvider>.value(
              value: mockDifficulty),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: FakeSettingsProvider()),
        ],
        child: const MaterialApp(home: CategorizationGame()),
      );

  testWidgets('CategorizationGame: 제목과 난이도 배지를 렌더링한다', (tester) async {
    await tester.pumpWidget(subject());

    expect(find.text('범주화 훈련'), findsOneWidget);
    expect(find.text('초급 (Lv.1)'), findsOneWidget);
  });

  testWidgets('CategorizationGame: 문제 단어와 선택지 3개를 렌더링한다', (tester) async {
    await tester.pumpWidget(subject());

    final word = _currentWord();
    final options = _currentOptions();
    expect(options.length, 3);
    expect(options, contains(_categoryOf[word]));
  });

  testWidgets('CategorizationGame: 올바른 답을 탭하면 정답 SnackBar를 표시한다',
      (tester) async {
    await tester.pumpWidget(subject());

    final word = _currentWord();
    await tester.tap(find.text(_categoryOf[word]!));
    await tester.pump();

    expect(find.text('정답입니다!'), findsOneWidget);

    // 다음 문제 딜레이(700ms) 및 SnackBar 타이머 소진
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
  });

  testWidgets('CategorizationGame: 틀린 답을 탭하면 오답 SnackBar를 표시한다',
      (tester) async {
    await tester.pumpWidget(subject());

    final word = _currentWord();
    final wrong =
        _currentOptions().firstWhere((o) => o != _categoryOf[word]);
    await tester.tap(find.text(wrong));
    await tester.pump();

    expect(find.text('아쉽네요. 다음 문제를 풀어보세요.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
  });

  testWidgets('CategorizationGame: 정답 후 700ms 뒤 다음 문제로 넘어간다', (tester) async {
    await tester.pumpWidget(subject());

    expect(find.textContaining('1 / 10'), findsOneWidget);

    final word = _currentWord();
    await tester.tap(find.text(_categoryOf[word]!));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('2 / 10'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('CategorizationGame: 10문제 완료 후 결과 화면과 점수를 표시한다',
      (tester) async {
    await tester.pumpWidget(subject());

    for (int i = 0; i < 10; i++) {
      final word = _currentWord();
      await tester.tap(find.text(_categoryOf[word]!));
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.pumpAndSettle();

    expect(find.text('훈련 완료!'), findsOneWidget);
    expect(find.text('10문제 중 10개 정답'), findsOneWidget);
    // logic 점수는 0-100 스케일로 저장된다 (10/10 정답 → 100.0)
    verify(() => mockUser.setCognitiveScore('logic', 100.0)).called(1);
  });

  testWidgets('CategorizationGame: 진행 바(LinearProgressIndicator)가 표시된다',
      (tester) async {
    await tester.pumpWidget(subject());

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
