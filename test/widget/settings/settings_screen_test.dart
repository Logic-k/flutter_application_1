import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/settings/settings_screen.dart';

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
}
