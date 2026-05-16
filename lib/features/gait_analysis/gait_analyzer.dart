import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// 보행 지표 분석기
/// 
/// [agency-ai-engineer]: 실시간 가속도 데이터에서 피크 검출을 통해 
/// 걸음 수와 보행 주기를 계산하고, 치매 전조 증상인 보행 변동성을 추출합니다.
class GaitAnalyzer {
  static const double _stepThreshold = 1.0; // 걸음 감지 임계치 (m/s^2)
  static const int _minStepTimeMs = 300; // 두 걸음 사이의 최소 시간 (ms)
  
  int _stepCount = 0;
  DateTime? _lastStepTime;
  final List<int> _strideTimes = []; // 걸음 사이의 시간 간격 (ms)
  
  int get stepCount => _stepCount;
  
  /// 보행 변동성 (Gait Variability) 계산
  /// 표준 편차 / 평균 (CV: Coefficient of Variation)
  double get gaitVariability {
    if (_strideTimes.length < 5) return 0.0;
    
    final double mean = _strideTimes.reduce((a, b) => a + b) / _strideTimes.length;
    final double variance = _strideTimes
        .map((x) => pow(x - mean, 2))
        .reduce((a, b) => a + b) / _strideTimes.length;
    final double stdDev = sqrt(variance);
    
    return (stdDev / mean) * 100; // 백분율로 반환
  }

  /// 새로운 가속도 데이터를 통한 걸음 감지
  /// [event]: 필터링된 가속도 이벤트
  /// [clock]: 테스트에서 시간을 제어할 때 주입. 기본값은 DateTime.now
  bool processEvent(UserAccelerometerEvent event, {DateTime Function()? clock}) {
    // 3축 가속도의 벡터 크기 (Magnitude) 계산
    final double magnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    final DateTime now = (clock ?? DateTime.now)();

    // 임계치 초과 및 최소 간격 경과 확인
    if (magnitude > _stepThreshold) {
      if (_lastStepTime == null || 
          now.difference(_lastStepTime!).inMilliseconds > _minStepTimeMs) {
        
        if (_lastStepTime != null) {
          final int strideTime = now.difference(_lastStepTime!).inMilliseconds;
          // 비정상적인 간격 (0.3s ~ 2.0s 사이만 기록)
          if (strideTime >= 300 && strideTime <= 2000) {
            _strideTimes.add(strideTime);
          }
        }
        
        _stepCount++;
        _lastStepTime = now;
        return true; // 새로운 걸음 감지됨
      }
    }
    return false;
  }

  /// 보행 분석 초기화
  void reset() {
    _stepCount = 0;
    _lastStepTime = null;
    _strideTimes.clear();
  }

  /// 최종 분석 결과 요약
  Map<String, dynamic> getSummary() {
    return {
      'total_steps': _stepCount,
      'gait_variability': gaitVariability,
      'avg_stride_time': _strideTimes.isEmpty 
          ? 0 
          : _strideTimes.reduce((a, b) => a + b) / _strideTimes.length,
      'assessment_date': DateTime.now().toIso8601String(),
    };
  }
}
