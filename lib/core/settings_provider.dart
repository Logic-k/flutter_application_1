import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontSize {
  normal,
  large,
  extraLarge,
}

class SettingsProvider extends ChangeNotifier {
  AppFontSize _fontSize = AppFontSize.normal;
  bool _voiceGuidanceEnabled = true;
  bool _hapticFeedbackEnabled = true;

  AppFontSize get fontSize => _fontSize;
  bool get voiceGuidanceEnabled => _voiceGuidanceEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  
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
}
