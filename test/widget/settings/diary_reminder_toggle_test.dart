import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/ml_widgets.dart';
import 'package:flutter_application_1/core/services/diary_notification_service.dart';
import 'package:flutter_application_1/features/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/fake_diary_reminder_gateway.dart';

/// 설정의 저녁 일기 알림은 기본 꺼짐이고, 켤 때만 권한을 묻는다(LAUNCH_AUDIT P0-04).
void main() {
  late FakeDiaryReminderGateway gateway;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gateway = FakeDiaryReminderGateway();
    DiaryNotificationService.gateway = gateway;
  });

  tearDown(() => DiaryNotificationService.gateway = null);

  Future<Finder> pumpSettings(WidgetTester tester) async {
    await pumpWithProviders(tester, const SettingsScreen());
    await tester.pump();
    final row = find.ancestor(of: find.text('매일 저녁 일기 알림'), matching: find.byType(MLListRow));
    final toggle = find.descendant(of: row, matching: find.byType(Switch));
    await tester.ensureVisible(toggle);
    await tester.pump();
    return toggle;
  }

  testWidgets('일기 알림은 처음에 꺼져 있고 권한을 묻지 않는다', (tester) async {
    final toggle = await pumpSettings(tester);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(gateway.calls, isEmpty);
  });

  testWidgets('켤 때 권한이 거부되면 꺼진 채로 휴대폰 설정을 안내한다', (tester) async {
    gateway.grant = false;
    final toggle = await pumpSettings(tester);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump();
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(find.textContaining('휴대폰 설정에서 MemoryLink 알림을 허용'), findsOneWidget);
  });

  testWidgets('행 글자를 눌러도 켜기를 시도하고, 거부되면 꺼진 채 안내한다', (tester) async {
    gateway.grant = false;
    final toggle = await pumpSettings(tester);
    await tester.tap(find.text('매일 저녁 일기 알림'));
    await tester.pump();
    await tester.pump();
    expect(gateway.calls, ['permission']);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(find.textContaining('휴대폰 설정에서 MemoryLink 알림을 허용'), findsOneWidget);
  });

  testWidgets('권한을 받으면 켜지고 알림을 예약한다', (tester) async {
    final toggle = await pumpSettings(tester);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump();
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(gateway.calls, ['permission', 'schedule']);
  });
}
