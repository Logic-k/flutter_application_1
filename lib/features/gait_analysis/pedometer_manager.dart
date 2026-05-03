import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/database_helper.dart';
import '../../core/user_provider.dart';

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
    _initOnStart();
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

  /// 최근 활동량 대비 급격한 감소 감지 (50% 이하 하락 시)
  Future<void> _checkStepAnomaly() async {
    final summary = await getWeeklySummary();
    if (summary.length < 3) return; // 최소 3일 이상의 데이터가 필요

    double avgSteps = summary.map((e) => (e['steps'] as num).toDouble()).reduce((a, b) => a + b) / summary.length;
    
    // 평균 걸음 수가 1000보 이상인 활동적인 상태에서 50% 이하로 감소한 경우
    if (avgSteps > 1000 && _todaySteps < (avgSteps * 0.5)) {
      if (!_isAnomalyDetected) {
        _isAnomalyDetected = true;
        debugPrint('⚠️ 활동량 급감 감지: 평균 ${avgSteps.toInt()}보 -> 현재 $_todaySteps보');
        // 추후 보호자 알림(Push) 연동 지점
      }
    } else {
      _isAnomalyDetected = false;
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
