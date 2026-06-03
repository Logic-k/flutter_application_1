import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class DiaryNotificationService {
  static const int _notifId = 777;
  static const String _channelId = 'diary_reminder_channel';
  static const String _channelName = '일기 알림';

  static Future<void> initialize(FlutterLocalNotificationsPlugin plugin) async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '매일 저녁 일기 작성을 알려드립니다.',
      importance: Importance.defaultImportance,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> scheduleDailyReminder(
      FlutterLocalNotificationsPlugin plugin) async {
    try {
      await plugin.cancel(id: _notifId);

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        19,
        0,
        0,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const notifDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon: '@mipmap/ic_launcher',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // 정확한 알림 예약 시도, 실패 시 부정확 모드로 fallback
      try {
        await plugin.zonedSchedule(
          id: _notifId,
          title: '오늘의 일기',
          body: '오늘 하루를 기억의 정원에 기록해보세요 ✏️',
          scheduledDate: scheduledDate,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        // exact alarm 권한 없음 → inexact로 재시도 (5~15분 오차 허용)
        debugPrint('[DiaryNotif] exact alarm not permitted, falling back to inexact: $e');
        await plugin.zonedSchedule(
          id: _notifId,
          title: '오늘의 일기',
          body: '오늘 하루를 기억의 정원에 기록해보세요 ✏️',
          scheduledDate: scheduledDate,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      debugPrint('[DiaryNotif] scheduleDailyReminder failed: $e');
    }
  }

  static Future<void> cancelReminder(
      FlutterLocalNotificationsPlugin plugin) async {
    try {
      await plugin.cancel(id: _notifId);
    } catch (_) {}
  }
}
