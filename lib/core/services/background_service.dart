import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 상시 보행 추적 및 보행 바이오마커 수집 백그라운드 서비스
/// 
/// [agency-mobile-app-builder]: 안드로이드 포그라운드 서비스를 통해 
/// 앱이 종료되어도 걸음 수와 보행 파형(가속도)을 측정합니다.
@pragma('vm:entry-point')
class PedometerBackgroundService {
  static const String notificationChannelId = 'pedometer_service_channel';
  static const int notificationId = 888;

  /// 서비스 초기화 (main.dart에서 호출)
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // 알림 채널 설정 (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'MemoryLink 보행 분석',
      description: '실시간 보행 바이오마커 및 걸음 수 측정을 위해 실행 중입니다.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // [agency-mobile-app-builder]: 권한 획득 전에 시작되는 크래시 방지
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'MemoryLink 분석 활성',
        initialNotificationContent: '안전한 보행을 모니터링하고 있습니다...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      final health = Health();
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));
      final authorized = await health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      if (authorized == true) {
        final data = await health.getHealthDataFromTypes(
          startTime: start,
          endTime: now,
          types: [HealthDataType.STEPS],
        );
        if (data.isNotEmpty) {
          final totalSteps = data
              .map((e) => (e.value as NumericHealthValue).numericValue.toInt())
              .fold(0, (a, b) => a + b);
          service.invoke('update_steps', {
            'steps': totalSteps,
            'timestamp': now.toIso8601String(),
          });
        }
      }
    } catch (_) {}
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // [agency-mobile-app-builder]: 안드로이드 14의 5초 시작 제한을 피하기 위해 
    // 즉시 포그라운드 서비스임을 명시적으로 설정합니다.
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    DartPluginRegistrant.ensureInitialized();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    int lastSentSteps = 0;
    List<double> accBuffer = [];

    // Pedometer.stepCountStream은 "기기 부팅 이후 누적 걸음 수"를 준다.
    // 날짜별 기준값(baseline)과의 차분으로 '오늘 걸음'을 계산한다.
    //  - pedo_baseline: 오늘 시작 시점의 누적값
    //  - pedo_offset:   재부팅 등으로 누적값이 리셋되기 전까지 오늘 걸은 걸음
    //  - pedo_date:     baseline이 유효한 날짜 (yyyy-MM-dd)
    //  - pedo_last_today: 마지막으로 계산된 오늘 걸음 (재부팅 복구용, 주기 저장)
    final prefs = await SharedPreferences.getInstance();
    int baseline = prefs.getInt('pedo_baseline') ?? -1;
    int offset = prefs.getInt('pedo_offset') ?? 0;
    String baselineDate = prefs.getString('pedo_date') ?? '';
    int lastPersistedToday = prefs.getInt('pedo_last_today') ?? 0;

    // 1. 만보기 스트림 구독 (센서 부재 대응)
    try {
      Pedometer.stepCountStream.listen((StepCount event) async {
        final int cumulative = event.steps;
        final String today = DateTime.now().toIso8601String().split('T')[0];

        if (baselineDate != today) {
          // 새로운 날: 지금 누적값을 0보 기준으로 삼는다
          baseline = cumulative;
          offset = 0;
          baselineDate = today;
          lastPersistedToday = 0;
          await prefs.setInt('pedo_baseline', baseline);
          await prefs.setInt('pedo_offset', offset);
          await prefs.setString('pedo_date', baselineDate);
          await prefs.setInt('pedo_last_today', 0);
        } else if (baseline < 0) {
          baseline = cumulative;
          await prefs.setInt('pedo_baseline', baseline);
        } else if (cumulative < baseline) {
          // 재부팅으로 누적값이 리셋됨: 리셋 전까지의 오늘 걸음을 offset으로 승계
          offset = lastPersistedToday;
          baseline = cumulative;
          await prefs.setInt('pedo_baseline', baseline);
          await prefs.setInt('pedo_offset', offset);
        }

        final int todaySteps = offset + (cumulative - baseline);

        // 재부팅 복구용 스냅샷 (20보마다 저장해 디스크 쓰기 최소화)
        if (todaySteps - lastPersistedToday >= 20) {
          lastPersistedToday = todaySteps;
          await prefs.setInt('pedo_last_today', todaySteps);
        }

        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            flutterLocalNotificationsPlugin.show(
              id: notificationId,
              title: '보행 모니터링 중',
              body: '오늘 $todaySteps걸음을 걸으셨습니다. 🏃‍♂️',
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelId,
                  'MemoryLink 보행 분석',
                  icon: '@mipmap/ic_launcher',
                  ongoing: true,
                ),
              ),
            );
          }
        }

        // 상태 업데이트 호출 (UI 반영용)
        if ((todaySteps - lastSentSteps).abs() >= 1) {
          service.invoke('update_steps', {
            "steps": todaySteps,
            "timestamp": DateTime.now().toIso8601String(),
          });
          lastSentSteps = todaySteps;
        }
      }, onError: (error) {
        debugPrint('보행 센서 수신 오류 (무시 가능): $error');
      });
    } catch (e) {
      debugPrint('보행 센서 시작 실패: $e');
    }

    // 2. 가속도계 스트림 구독 (보행 바이오마커 분석용)
    userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      double magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
      
      if (magnitude > 0.5) {
        accBuffer.add(magnitude);
        
        if (accBuffer.length >= 50) {
          service.invoke('update_gait_data', {
            "avg_magnitude": accBuffer.reduce((a, b) => a + b) / accBuffer.length,
            "timestamp": DateTime.now().toIso8601String(),
          });
          accBuffer.clear();
        }
      }
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
}
