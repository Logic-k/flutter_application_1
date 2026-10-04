// ─────────────────────────────────────────────────────────────────────────
// [TTA 표준 적용 — 준용] TTAK.KO-08.0057
//   「사회적 약자(정보취약계층)를 위한 무인정보 단말기 사용자 인터페이스 접근성 요구사항」
//
// 적용 지점: 접근성 설정 3종.
//   - 문자 크기 조절 -> AppFontSize 3단계(1.0 / 1.2 / 1.4배)
//   - 음성 안내      -> _voiceGuidanceEnabled (기본 활성, VoiceService 연동)
//   - 촉각 대체 피드백 -> _hapticFeedbackEnabled (기본 활성)
//
// 준용 고지: 본 표준의 적용 대상은 무인정보 단말기(키오스크)이나, 요구사항 항목이
//   고령자 모바일 UI에도 그대로 유효하여 준용했다. 인지저하 위험군은 곧 디지털
//   취약계층이므로 앱의 진입 장벽 자체가 서비스 실패 원인이 되기 때문이다.
//
// 같은 표준의 대비·터치타겟 요구사항은 core/theme.dart 에 적용.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/sound_service.dart';
import 'services/voice_service.dart';

enum AppFontSize {
  normal,
  large,
  extraLarge,
}

class SettingsProvider extends ChangeNotifier {
  AppFontSize _fontSize = AppFontSize.normal;
  bool _voiceGuidanceEnabled = true;
  bool _hapticFeedbackEnabled = true;
  // 움직임 줄이기: 기본 꺼짐. 플랫폼 신호(Android 애니메이션 제거·iOS 동작 줄이기)와
  // OR 로 합쳐지므로(core/motion/motion_settings.dart) 켜는 쪽으로만 작용한다.
  bool _reduceMotion = false;
  // 효과음: 기본 켜짐(07 계획 §7 결정 1 권장안). 각 소리는 300ms 이내.
  bool _soundEffectsEnabled = true;

  AppFontSize get fontSize => _fontSize;
  bool get voiceGuidanceEnabled => _voiceGuidanceEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get reduceMotion => _reduceMotion;
  bool get soundEffectsEnabled => _soundEffectsEnabled;

  // 저장된 설정을 다 읽었는가. 오프닝은 이 값이 true 가 된 뒤에 모션 단계를 정한다
  // — 먼저 정하면 "움직임 줄이기"를 켠 사용자도 첫 순간 전체 모션을 보게 된다.
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  double get textScaleFactor {
    switch (_fontSize) {
      case AppFontSize.normal: return 1.0;
      case AppFontSize.large: return 1.2;
      case AppFontSize.extraLarge: return 1.4;
    }
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSizeIndex = prefs.getInt('font_size') ?? 0;
    _fontSize = AppFontSize.values[fontSizeIndex];
    _voiceGuidanceEnabled = prefs.getBool('voice_guidance') ?? true;
    _hapticFeedbackEnabled = prefs.getBool('haptic_feedback') ?? true;
    _reduceMotion = prefs.getBool('reduce_motion') ?? false;
    _soundEffectsEnabled = prefs.getBool('sound_effects') ?? true;
    VoiceService.voiceEnabled = _voiceGuidanceEnabled;
    SoundService.soundEnabled = _soundEffectsEnabled;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setFontSize(AppFontSize size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('font_size', size.index);
    notifyListeners();
  }

  Future<void> setVoiceGuidance(bool enabled) async {
    _voiceGuidanceEnabled = enabled;
    // 게임 등에서 직접 호출하는 VoiceService에도 즉시 반영
    VoiceService.voiceEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_guidance', enabled);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_feedback', enabled);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool enabled) async {
    _reduceMotion = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduce_motion', enabled);
    notifyListeners();
  }

  Future<void> setSoundEffects(bool enabled) async {
    _soundEffectsEnabled = enabled;
    SoundService.soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_effects', enabled);
    notifyListeners();
  }
}
