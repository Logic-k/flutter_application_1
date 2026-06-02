import 'package:flutter/material.dart';
import 'gait_sensing_service.dart';
import 'gait_analyzer.dart';

/// 보행 세션 상태 관리 프로바이더
/// 
/// [agency-mobile-app-builder]: 사용자가 보행 시작/중지 시 
/// 상태를 관리하고, 실시간 데이터를 UI로 전달합니다.
class GaitProvider with ChangeNotifier {
  final GaitSensingService _sensingService = GaitSensingService();
  final GaitAnalyzer _analyzer = GaitAnalyzer();
  
  bool _isMeasuring = false;
  int _steps = 0;
  double _variability = 0.0;
  final List<double> _liveAccData = []; // 실시간 파형 시각화용 데이터
  
  bool get isMeasuring => _isMeasuring;
  int get steps => _steps;
  double get variability => _variability;
  List<double> get liveAccData => _liveAccData;

  /// 보행 분석 시작
  void startMeasurement() {
    _isMeasuring = true;
    _steps = 0;
    _variability = 0.0;
    _liveAccData.clear();
    _analyzer.reset();
    
    _sensingService.startSensing();
    
    // 가속도 스트림 구독
    _sensingService.accelerometerStream.listen((event) {
      if (!_isMeasuring) return;
      
      // 1. 분석 수행
      final isStep = _analyzer.processEvent(event);
      
      // 2. 파형 데이터 갱신 (최근 50개 샘플 유지)
      _liveAccData.add(event.y); // 주로 수직 방향(y) 파동 데이터 유지
      if (_liveAccData.length > 50) {
        _liveAccData.removeAt(0);
      }
      
      if (isStep) {
        _steps = _analyzer.stepCount;
        _variability = _analyzer.gaitVariability;
      }
      
      notifyListeners();
    });
  }

  /// 보행 분석 중지 및 결과 요약
  Future<Map<String, dynamic>> stopMeasurement({dynamic userId}) async {
    _isMeasuring = false;
    _sensingService.stopSensing();
    final summary = _analyzer.getSummary();
    
    notifyListeners();
    return summary;
  }

  @override
  void dispose() {
    _sensingService.dispose();
    super.dispose();
  }
}
