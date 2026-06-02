import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database_helper.dart';
import '../../core/user_provider.dart';
import '../../core/services/guardian_sync_service.dart';

/// 만보기 매니저 (상태 관리)
/// 
/// [agency-mobile-app-builder]: 백그라운드 서비스와 UI 간의 
/// 상태를 중계하고, 동백전 스타일의 지표를 계산합니다.
class PedometerManager with ChangeNotifier {
  final UserProvider _userProvider;
  final _dbHelper = DatabaseHelper();
  
  int _todaySteps = 0;
  double _todayCalories = 0.0;
  double _todayDistance = 0.0;
  bool _isTracking = false;

  int get todaySteps => _todaySteps;
  double get todayCalories => _todayCalories;
  double get todayDistance => _todayDistance;
  bool get isTracking => _isTracking;

  PedometerManager(this._userProvider) {
    _userProvider.addListener(_onUserChanged);
    _initOnStart();
  }

  void _onUserChanged() {
    if (_userProvider.currentUser != null) {
      _loadTodayStepsFromDB();
    } else {
      _todaySteps = 0;
      _todayCalories = 0.0;
      _todayDistance = 0.0;
      notifyListeners();
    }
  }

  Future<void> _loadTodayStepsFromDB() async {
    if (_userProvider.currentUser == null) return;
    final userId = _userProvider.currentUser!['id'] as int;
    final todayData = await _dbHelper.getTodaySteps(userId);
    if (todayData != null) {
      _todaySteps = (todayData['steps'] as num).toInt();
      _todayCalories = (todayData['calories'] as num).toDouble();
      _todayDistance = (todayData['distance'] as num).toDouble();
      notifyListeners();
    } else {
      _todaySteps = 0;
      _todayCalories = 0.0;
      _todayDistance = 0.0;
      notifyListeners();
    }
  }

  Future<void> _initOnStart() async {
    _isTracking = _userProvider.pedometerEnabled;
    
    if (_isTracking) {
      // 앱 시작 시 추적이 켜져있다면 권한부터 확인
      final activityStatus = await Permission.activityRecognition.status;
      final notificationStatus = await Permission.notification.status;
      
      if (activityStatus.isGranted && notificationStatus.isGranted) {
        _startServiceDirectly();
      } else {
        // 권한이 없다면 팝업 요청
        await toggleTracking(true);
      }
    }
    _listenToBackgroundService();
  }

  Future<void> _startServiceDirectly() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
  }

  void _listenToBackgroundService() {
    FlutterBackgroundService().on('update_steps').listen((event) {
      if (event != null && event['steps'] != null) {
        _updateMetrics(event['steps'] as int);
      }
    });
  }

  void _updateMetrics(int steps) {
    _todaySteps = steps;
    _todayDistance = (_todaySteps * 0.7) / 1000.0;
    
    final double weight = _userProvider.weight ?? 60.0;
    final int age = _userProvider.age ?? 40;
    final ageFactor = (100 - age) / 100.0;
    _todayCalories = _todaySteps * 0.04 * (weight / 60.0) * ageFactor;

    if (_userProvider.currentUser != null) {
      _dbHelper.updateDailySteps(
        _userProvider.currentUser!['id'],
        _todaySteps,
        _todayCalories,
        _todayDistance,
      );
      _checkStepAnomaly(); // 이상 징후 감지 실행
    }
    notifyListeners();
  }

  bool _isAnomalyDetected = false;
  bool get isAnomalyDetected => _isAnomalyDetected;

  static const _guardianChannelId = 'guardian_alert_channel';
  static const _guardianNotificationId = 999;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// 최근 활동량 대비 급격한 감소 감지 (50% 이하 하락 시)
  Future<void> _checkStepAnomaly() async {
    final summary = await getWeeklySummary();
    if (summary.length < 3) return;

    final avgSteps = summary
            .map((e) => (e['steps'] as num).toDouble())
            .reduce((a, b) => a + b) /
        summary.length;

    if (avgSteps > 1000 && _todaySteps < (avgSteps * 0.5)) {
      if (!_isAnomalyDetected) {
        _isAnomalyDetected = true;
        debugPrint('⚠️ 활동량 급감 감지: 평균 ${avgSteps.toInt()}보 -> 현재 $_todaySteps보');
        await _triggerGuardianAlert(avgSteps.toInt());
      }
    } else {
      _isAnomalyDetected = false;
    }
  }

  /// 이상 감지 시 Firestore 동기화 + 로컬 알림 표시
  Future<void> _triggerGuardianAlert(int avgSteps) async {
    final user = _userProvider.currentUser;
    if (user == null) return;

    final userId = user['id'] as int;
    final userName = (user['username'] as String?) ?? '사용자';
    final emergencyContact = _userProvider.emergencyContact;

    // 1. Firestore에 이상 감지 상태 저장 (보호자 웹 대시보드에 경고 표시)
    GuardianSyncService().syncAnomalyAlert(
      userId: userId,
      userName: userName,
      todaySteps: _todaySteps,
      weeklyAvg: avgSteps,
      emergencyContact: emergencyContact,
    );

    // 2. 로컬 알림 채널 생성 및 알림 표시
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _guardianChannelId,
          '보호자 이상 알림',
          description: '활동량 급감 감지 시 보호자에게 알릴 수 있습니다.',
          importance: Importance.high,
        ));

    final smsPayload = emergencyContact != null && emergencyContact.isNotEmpty
        ? 'sms:$emergencyContact'
        : '';

    await _localNotifications.show(
      id: _guardianNotificationId,
      title: '활동량 이상 감지',
      body: '평소보다 활동량이 크게 줄었습니다. 탭하여 보호자에게 문자를 보내세요.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _guardianChannelId,
          '보호자 이상 알림',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
        ),
      ),
      payload: smsPayload,
    );
  }

  /// 알림 탭 시 SMS 앱 실행 (앱 진입점에서 호출 필요)
  Future<void> handleNotificationTap(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    final uri = Uri.tryParse(payload);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// 추적 시작 (백그라운드 서비스 실행)
  Future<void> toggleTracking(bool enabled) async {
    if (enabled) {
      // [agency-mobile-app-builder]: 안드로이드 13+ 대응을 위해 알림 권한도 함께 요청
      Map<Permission, PermissionStatus> statuses = await [
        Permission.activityRecognition,
        Permission.notification,
      ].request();

      if (statuses[Permission.activityRecognition] != PermissionStatus.granted ||
          statuses[Permission.notification] != PermissionStatus.granted) {
        debugPrint('필수 권한(보행 또는 알림)이 거부되었습니다.');
        _isTracking = false;
        notifyListeners();
        return;
      }
    }

    _isTracking = enabled;
    await _userProvider.setPedometerEnabled(enabled);
    
    final service = FlutterBackgroundService();
    if (enabled) {
      bool isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
      }
      // UI 전용 스트림은 제거하고 백그라운드 이벤트(update_steps)만 사용합니다.
    } else {
      service.invoke('stopService');
    }
    notifyListeners();
  }

  /// 백그라운드에서 전달된 원본 데이터를 받아서 지표 계산 및 DB 저장
  /// (기존 _startTracking을 대체하는 안정적인 수신부)


  /// 주간 데이터 요약 (그래프용)
  Future<List<Map<String, dynamic>>> getWeeklySummary() async {
    if (_userProvider.currentUser == null) return [];
    try {
      return await _dbHelper.getWeeklySteps(_userProvider.currentUser!['id']);
    } catch (e) {
      debugPrint('주간 데이터 로드 실패: $e');
      return [];
    }
  }
}
