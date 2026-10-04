import 'package:flutter_application_1/core/services/diary_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_diary_reminder_gateway.dart';

void main() {
  late FakeDiaryReminderGateway gateway;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gateway = FakeDiaryReminderGateway();
    DiaryNotificationService.gateway = gateway;
  });

  tearDown(() => DiaryNotificationService.gateway = null);

  test('사용자가 켜지 않았으면 앱을 열 때 예약하지 않고 지운다', () async {
    await DiaryNotificationService.applySavedPreference();
    expect(gateway.calls, ['cancel']);
    expect(await DiaryNotificationService.isEnabled(), isFalse);
  });

  test('켜 둔 사용자는 앱을 열 때 권한을 묻지 않고 다시 예약한다', () async {
    SharedPreferences.setMockInitialValues({DiaryNotificationService.prefKey: true});
    await DiaryNotificationService.applySavedPreference();
    expect(gateway.calls, ['schedule']);
  });

  test('켤 때 권한을 묻고, 거부되면 아무것도 바꾸지 않는다', () async {
    gateway.grant = false;
    expect(await DiaryNotificationService.enable(), DiaryReminderResult.permissionDenied);
    expect(gateway.calls, ['permission']);
    expect(await DiaryNotificationService.isEnabled(), isFalse);
  });

  test('권한을 받으면 저장하고 예약한다', () async {
    expect(await DiaryNotificationService.enable(), DiaryReminderResult.enabled);
    expect(gateway.calls, ['permission', 'schedule']);
    expect(await DiaryNotificationService.isEnabled(), isTrue);
  });

  test('끄면 저장하고 예약을 지운다', () async {
    SharedPreferences.setMockInitialValues({DiaryNotificationService.prefKey: true});
    await DiaryNotificationService.disable();
    expect(gateway.calls, ['cancel']);
    expect(await DiaryNotificationService.isEnabled(), isFalse);
  });

  test('알림을 준비하지 못한 빌드에서는 켜지 않는다', () async {
    DiaryNotificationService.gateway = null;
    expect(await DiaryNotificationService.enable(), DiaryReminderResult.unavailable);
    expect(await DiaryNotificationService.isEnabled(), isFalse);
  });
}
