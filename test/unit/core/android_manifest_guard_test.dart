import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 출시 매니페스트의 권한·조회 결정이 되돌아가지 않게 지킨다(LAUNCH_AUDIT P0-09·P0-12·P0-13).
/// Play 신고(PLAY_CONSOLE.md)는 이 매니페스트를 근거로 답한다.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  bool declares(String permission) =>
      RegExp('<uses-permission[^>]*android:name="$permission"').hasMatch(manifest);

  test('쓰지 않는 Health Connect·고속 센서 권한을 선언하지 않는다', () {
    expect(RegExp('<uses-permission[^>]*android\\.permission\\.health\\.').hasMatch(manifest), isFalse);
    expect(declares('android.permission.HIGH_SAMPLING_RATE_SENSORS'), isFalse);
  });

  test('음성 인식·읽기 엔진을 찾을 수 있게 패키지 조회를 선언한다', () {
    expect(manifest, contains('<action android:name="android.speech.RecognitionService" />'));
    expect(manifest, contains('<action android:name="android.intent.action.TTS_SERVICE" />'));
  });

  test('보호자 웹 링크를 앱이 가로채지 않는다', () {
    expect(manifest, isNot(contains('android:host="memorylink-7af26.web.app"')));
  });
}
