import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/notification_tap_router.dart';
import 'package:flutter_application_1/features/gait_analysis/guardian_alert_sms_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

/// 활동량 이상 알림을 누르면 보낼 문자를 먼저 보여 주고, 확인해야 문자 앱을 연다(LAUNCH_AUDIT P0-04).
void main() {
  Future<List<Uri>> open(WidgetTester tester, {required String? phone}) async {
    final launched = <Uri>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showGuardianAlertSmsDialog(context, phone: phone, launch: (uri) async {
                launched.add(uri);
                return true;
              }),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return launched;
  }

  testWidgets('받는 사람과 내용을 보여 주고, 확인해야 문자 앱을 연다', (tester) async {
    final launched = await open(tester, phone: '010-1234-5678');
    expect(find.text('받는 사람: 010-1234-5678'), findsOneWidget);
    expect(find.text('내용: $guardianAlertSmsBody'), findsOneWidget);
    expect(launched, isEmpty);

    await tester.tap(find.text('문자 앱 열기'));
    await tester.pumpAndSettle();
    expect(launched.single.scheme, 'sms');
    expect(launched.single.path, '010-1234-5678');
    expect(launched.single.queryParameters['body'], guardianAlertSmsBody);
  });

  testWidgets('닫으면 문자 앱을 열지 않는다', (tester) async {
    final launched = await open(tester, phone: '010-1234-5678');
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(launched, isEmpty);
    expect(find.text('보호자에게 문자 보내기'), findsNothing);
  });

  testWidgets('비상 연락처가 없으면 등록 방법을 안내한다', (tester) async {
    await open(tester, phone: '  ');
    expect(find.textContaining('등록된 비상 연락처가 없습니다'), findsOneWidget);
    expect(find.text('문자 앱 열기'), findsNothing);
  });

  test('알림 payload에는 종류만 싣고, 꺼내면 비운다', () {
    NotificationTapRouter.handle('');
    expect(NotificationTapRouter.pending.value, isNull);
    NotificationTapRouter.handle(NotificationTapRouter.guardianAlertPayload);
    expect(NotificationTapRouter.take(), 'guardian_alert');
    expect(NotificationTapRouter.pending.value, isNull);
  });
}
