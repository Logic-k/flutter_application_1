import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/assessment/assessment_screen.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import '../../helpers/mock_definitions.dart';

Widget _buildSubject(MockUserProvider mockUser) {
  return ChangeNotifierProvider<UserProvider>.value(
    value: mockUser,
    child: const MaterialApp(home: AssessmentScreen()),
  );
}

void main() {
  late MockUserProvider mockUser;

  setUp(() {
    mockUser = MockUserProvider();
    when(() => mockUser.setSurveyAnswer(any(), any())).thenReturn(null);
  });

  testWidgets('AssessmentScreen: 첫 번째 질문과 1/10 타이틀이 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.pump();

    expect(find.text('자가 체크 (1/10)'), findsOneWidget);
    expect(find.text('당신의 기억력에 문제가 있습니까?'), findsOneWidget);
  });

  testWidgets('AssessmentScreen: 진행률 표시줄이 초기에 10%(1/10)로 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.pump();

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, closeTo(0.1, 0.01));
  });

  testWidgets('AssessmentScreen: 예 / 아니오 버튼이 모두 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.pump();

    expect(find.text('예'), findsOneWidget);
    expect(find.text('아니오'), findsOneWidget);
  });

  testWidgets('AssessmentScreen: 예 버튼 탭 시 setSurveyAnswer(0, 1)이 호출된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.pump();

    await tester.tap(find.text('예'));
    await tester.pumpAndSettle();

    verify(() => mockUser.setSurveyAnswer(0, 1)).called(1);
  });

  testWidgets('AssessmentScreen: 아니오 버튼 탭 시 setSurveyAnswer(0, 0)이 호출된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.pump();

    await tester.tap(find.text('아니오'));
    await tester.pumpAndSettle();

    verify(() => mockUser.setSurveyAnswer(0, 0)).called(1);
  });

  testWidgets('AssessmentScreen: 예 탭 후 두 번째 질문으로 넘어간다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.pump();

    await tester.tap(find.text('예'));
    await tester.pumpAndSettle();

    expect(find.text('자가 체크 (2/10)'), findsOneWidget);
    expect(find.text('당신의 기억력이 10년 전보다 나빠졌습니까?'), findsOneWidget);
  });

  testWidgets('AssessmentScreen: 3페이지까지 답변 후 타이틀이 3/10으로 갱신된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.pump();

    for (int i = 0; i < 2; i++) {
      await tester.tap(find.text('예'));
      await tester.pumpAndSettle();
    }

    expect(find.text('자가 체크 (3/10)'), findsOneWidget);
  });
}
