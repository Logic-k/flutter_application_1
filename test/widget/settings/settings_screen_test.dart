import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/settings/settings_screen.dart';

import '../../helpers/mock_definitions.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    // initState가 SharedPreferences / AiKeyService 를 읽으므로 목 값을 주입한다.
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpWithProviders(tester, const SettingsScreen());
    await tester.pump(); // initState의 async _loadState 완료 반영
  }

  testWidgets('SettingsScreen: 설정 타이틀과 주요 섹션이 표시된다', (tester) async {
    await pump(tester);

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('화면 및 접근성'), findsOneWidget);
    expect(find.text('알림'), findsOneWidget);
    expect(find.text('AI 대화'), findsOneWidget);
    expect(find.text('계정'), findsOneWidget);
    expect(find.text('개인정보 및 데이터'), findsOneWidget);
  });

  testWidgets('SettingsScreen: 글자 크기 세그먼트 버튼이 표시된다', (tester) async {
    await pump(tester);

    expect(find.text('글자 크기'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is SegmentedButton),
      findsOneWidget,
    );
  });

  testWidgets('SettingsScreen: 개인정보 처리방침·로그아웃 행이 존재한다', (tester) async {
    await pump(tester);

    expect(find.text('개인정보 처리방침'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('초기화 성공 후에만 완료 메시지를 표시하고 진행 상태를 갱신한다', (
    tester,
  ) async {
    final user = MockUserProvider();
    final progress = MockTrainingProgressProvider();
    when(() => user.resetMeasurementData()).thenAnswer((_) async {});
    when(() => progress.refresh()).thenAnswer((_) async {});
    await pumpWithProviders(
      tester,
      const SettingsScreen(),
      userProvider: user,
      trainingProgressProvider: progress,
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('측정 데이터 초기화'),
      300,
    );
    await tester.tap(find.text('측정 데이터 초기화'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '초기화'));
    await tester.pumpAndSettle();

    verify(() => user.resetMeasurementData()).called(1);
    verify(() => progress.refresh()).called(1);
    expect(find.text('데이터가 초기화되었습니다.'), findsOneWidget);
    expect(find.text('데이터 초기화'), findsNothing);
  });

  testWidgets('초기화 실패 시 성공 메시지를 표시하지 않고 재시도할 수 있다', (
    tester,
  ) async {
    final user = MockUserProvider();
    final progress = MockTrainingProgressProvider();
    when(() => user.resetMeasurementData()).thenThrow(Exception('disk'));
    await pumpWithProviders(
      tester,
      const SettingsScreen(),
      userProvider: user,
      trainingProgressProvider: progress,
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('측정 데이터 초기화'),
      300,
    );
    await tester.tap(find.text('측정 데이터 초기화'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '초기화'));
    await tester.pumpAndSettle();

    expect(find.text('데이터가 초기화되었습니다.'), findsNothing);
    expect(
      find.text('데이터를 초기화하지 못했습니다. 다시 시도해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('데이터 초기화'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '초기화'), findsOneWidget);
  });
}
