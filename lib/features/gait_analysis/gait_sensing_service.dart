import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// 보행 센싱 서비스
/// 
/// [agency-mobile-app-builder]: 가속도계 및 자이로스코프 데이터를 
/// 실시간으로 획득하여 보행 분석을 위한 기초 데이터를 제공합니다.
class GaitSensingService {
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // 보행 원시 데이터 스트림 (필터링 전)
  final _accelController = StreamController<UserAccelerometerEvent>.broadcast();
  final _gyroController = StreamController<GyroscopeEvent>.broadcast();

  Stream<UserAccelerometerEvent> get accelerometerStream => _accelController.stream;
  Stream<GyroscopeEvent> get gyroscopeStream => _gyroController.stream;

  /// 센싱 시작
  void startSensing() {
    // 중복 구독 방지
    stopSensing();

    // 사용자 가속도계 (중력 보정됨) 구독
    _accelerometerSubscription = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 10), // 100Hz 샘플링
    ).listen((event) {
      if (!_accelController.isClosed) {
        _accelController.add(event);
      }
    });

    // 자이로스코프 (회전) 구독
    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 10),
    ).listen((event) {
      if (!_gyroController.isClosed) {
        _gyroController.add(event);
      }
    });
  }

  /// 센싱 중지
  void stopSensing() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
  }

  /// 리소스 해제
  void dispose() {
    stopSensing();
    _accelController.close();
    _gyroController.close();
  }
}
