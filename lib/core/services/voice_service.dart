import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.4); // 시니어를 위해 조금 느리게 설정
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// 훈련 시작 안내
  Future<void> speakTrainingStart(String gameName) async {
    await speak('$gameName 훈련을 시작합니다. 준비되셨나요?');
  }

  /// 훈련 성공/격려 안내
  Future<void> speakSuccess() async {
    final phrases = [
      '참 잘하셨습니다!',
      '대단해요! 뇌가 활발해지고 있어요.',
      '오늘 컨디션이 정말 좋으시네요.',
      '꾸준함이 보약입니다. 최고예요!'
    ];
    final phrase = phrases[DateTime.now().millisecond % phrases.length];
    await speak(phrase);
  }

  /// 경고/주의 안내
  Future<void> speakWarning(String message) async {
    await speak('주의가 필요한 단계입니다. $message');
  }
}
