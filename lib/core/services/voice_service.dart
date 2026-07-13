import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  /// 사용자 설정(음성 안내 on/off). SettingsProvider가 동기화한다.
  /// 모든 발화가 이 플래그를 거치므로 설정이 꺼져 있으면 어떤 화면에서도
  /// TTS가 재생되지 않는다.
  static bool voiceEnabled = true;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(0.65);
    await _flutterTts.setPitch(0.95);

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!voiceEnabled) return;
    if (!_isInitialized) await init();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// 훈련 시작 안내
  Future<void> speakTrainingStart(String gameName) async {
    await speak('$gameName을 시작할게요. 천천히 해보세요.');
  }

  /// 훈련 성공/격려 안내
  Future<void> speakSuccess() async {
    final phrases = [
      '잘 하셨어요! 오늘도 뇌가 건강해지고 있어요.',
      '정말 훌륭해요. 꾸준함이 최고의 보약입니다.',
      '좋아요! 이 속도라면 충분해요.',
      '멋지게 해내셨어요. 다음에도 함께해요.'
    ];
    final phrase = phrases[DateTime.now().millisecond % phrases.length];
    await speak(phrase);
  }

  /// 경고/주의 안내
  Future<void> speakWarning(String message) async {
    await speak('조심해서 천천히 해보세요. $message');
  }
}
