import 'package:flutter/services.dart';

/// 정답·오답·완료 효과음.
///
/// 전용 에셋(각 ≤300ms, 06 힉스필드 계획 §1.2 `seed_audio` 파이프라인)이 준비되기 전까지는
/// 플랫폼 클릭음으로 폴백한다. KWCAG 5.4.2: 자동 재생 소리는 3초 안에 끝나야 한다.
/// 설정 "효과음"이 꺼져 있으면 아무 소리도 내지 않는다.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  /// [SettingsProvider.setSoundEffects] 가 즉시 반영한다(VoiceService.voiceEnabled 와 같은 패턴).
  static bool soundEnabled = true;

  Future<void> playCorrect() => _play();

  Future<void> playWrong() => _play();

  Future<void> playComplete() => _play();

  Future<void> _play() async {
    if (!soundEnabled) return;
    // 소리는 부가 채널이다. 플랫폼이 재생을 못 해도 훈련 흐름을 끊지 않는다.
    try {
      await SystemSound.play(SystemSoundType.click);
    } on PlatformException {
      // 무시
    } on MissingPluginException {
      // 위젯 테스트·데스크톱처럼 플랫폼 채널이 없는 환경
    }
  }
}
