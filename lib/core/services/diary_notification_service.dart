import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// 매일 저녁 일기 알림 (LAUNCH_AUDIT P0-04).
///
/// 사용자가 설정에서 켤 때만 동작한다(기본 꺼짐). 켜는 순간에 알림 권한을 묻고,
/// 앱을 열 때마다 저장된 선택대로 예약하거나 지운다. 몇 분 늦어도 되는 알림이라
/// 정확한 알람 권한 없이 inexactAllowWhileIdle로 예약한다.
class DiaryNotificationService {
  DiaryNotificationService._();

  static const prefKey = 'diary_reminder_enabled';
  static const int _notifId = 777;
  static const String _channelId = 'diary_reminder_channel';
  static const String _channelName = '일기 알림';

  static DiaryReminderGateway? _gateway;

  /// 앱 시작 때 알림 플러그인과 연결하고 채널을 만든다.
  static Future<void> configure(FlutterLocalNotificationsPlugin plugin) async {
    _gateway = PluginDiaryReminderGateway(plugin);
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: '매일 저녁 일기 작성을 알려드립니다.',
          importance: Importance.defaultImportance,
        ));
  }

  @visibleForTesting
  static set gateway(DiaryReminderGateway? value) => _gateway = value;

  static Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(prefKey) ?? false;

  /// 켜기: 권한을 받으면 저장하고 예약한다. 권한이 없으면 아무것도 바꾸지 않는다.
  static Future<DiaryReminderResult> enable() async {
    final gateway = _gateway;
    if (gateway == null) return DiaryReminderResult.unavailable;
    if (!await gateway.requestPermission()) return DiaryReminderResult.permissionDenied;
    await (await SharedPreferences.getInstance()).setBool(prefKey, true);
    await gateway.schedule();
    return DiaryReminderResult.enabled;
  }

  static Future<void> disable() async {
    await (await SharedPreferences.getInstance()).setBool(prefKey, false);
    await _gateway?.cancel();
  }

  /// 앱을 열 때: 저장된 선택대로 예약하거나 지운다. 권한은 묻지 않는다.
  static Future<void> applySavedPreference() async {
    final gateway = _gateway;
    if (gateway == null) return;
    if (await isEnabled()) {
      await gateway.schedule();
    } else {
      await gateway.cancel();
    }
  }
}

enum DiaryReminderResult { enabled, permissionDenied, unavailable }

/// 알림 플러그인 경계. 테스트는 가짜로 바꿔 끼운다.
abstract class DiaryReminderGateway {
  Future<bool> requestPermission();
  Future<void> schedule();
  Future<void> cancel();
}

class PluginDiaryReminderGateway implements DiaryReminderGateway {
  PluginDiaryReminderGateway(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // Android 12 이하에는 알림 런타임 권한이 없어 null이 올 수 있다.
        return await android.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[DiaryNotif] 알림 권한 요청 실패: $e');
      return false;
    }
  }

  @override
  Future<void> schedule() async {
    try {
      await _plugin.cancel(id: DiaryNotificationService._notifId);
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: DiaryNotificationService._notifId,
        title: '오늘의 일기',
        body: '오늘 하루를 기억의 정원에 기록해보세요 ✏️',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            DiaryNotificationService._channelId,
            DiaryNotificationService._channelName,
            icon: '@mipmap/ic_launcher',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        // 정확한 알람 권한(SCHEDULE_EXACT_ALARM) 없이 예약한다. 몇 분 늦을 수 있다.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[DiaryNotif] 일기 알림 예약 실패: $e');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _plugin.cancel(id: DiaryNotificationService._notifId);
    } catch (_) {}
  }
}
