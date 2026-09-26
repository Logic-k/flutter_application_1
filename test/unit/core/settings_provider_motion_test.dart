import 'package:flutter_application_1/core/services/sound_service.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('움직임 줄이기는 기본 꺼짐, 효과음은 기본 켜짐이다', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await Future<void>.delayed(Duration.zero);
    expect(settings.reduceMotion, isFalse);
    expect(settings.soundEffectsEnabled, isTrue);
  });

  test('두 설정은 저장되고 효과음 토글은 SoundService에 즉시 반영된다', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.setReduceMotion(true);
    await settings.setSoundEffects(false);

    expect(settings.reduceMotion, isTrue);
    expect(settings.soundEffectsEnabled, isFalse);
    expect(SoundService.soundEnabled, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reduce_motion'), isTrue);
    expect(prefs.getBool('sound_effects'), isFalse);

    await settings.setSoundEffects(true);
    expect(SoundService.soundEnabled, isTrue);
  });
}
