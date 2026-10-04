import 'dart:io';

import 'package:flutter_application_1/core/ai/legacy_model_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 온디바이스 AI를 뺀 뒤 예전 모델 파일과 HuggingFace 토큰이 기기에 남지 않는다(LAUNCH_AUDIT P0-11).
void main() {
  test('예전 모델 파일과 HuggingFace 토큰을 지우고 다른 것은 둔다', () async {
    final dir = await Directory.systemTemp.createTemp('legacy_model');
    addTearDown(() => dir.delete(recursive: true));
    for (final name in LegacyOnDeviceModelCleanup.modelFileNames) {
      await File('${dir.path}${Platform.pathSeparator}$name').writeAsString('x');
    }
    final keep = File('${dir.path}${Platform.pathSeparator}profile.jpg')..writeAsStringSync('x');
    SharedPreferences.setMockInitialValues({LegacyOnDeviceModelCleanup.tokenPrefKey: 'hf_secret', 'other': 1});

    await LegacyOnDeviceModelCleanup.run(documentsDirectory: () async => dir);

    for (final name in LegacyOnDeviceModelCleanup.modelFileNames) {
      expect(File('${dir.path}${Platform.pathSeparator}$name').existsSync(), isFalse, reason: name);
    }
    expect(keep.existsSync(), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LegacyOnDeviceModelCleanup.tokenPrefKey), isNull);
    expect(prefs.getInt('other'), 1);
  });
}
