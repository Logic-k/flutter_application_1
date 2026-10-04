import 'package:flutter_application_1/core/services/diary_notification_service.dart';

/// 알림 플러그인 대신 호출 순서만 기록하는 가짜.
class FakeDiaryReminderGateway implements DiaryReminderGateway {
  bool grant = true;
  final calls = <String>[];

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return grant;
  }

  @override
  Future<void> schedule() async => calls.add('schedule');

  @override
  Future<void> cancel() async => calls.add('cancel');
}
