import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/gait_analysis/pedometer_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS는 CoreMotion 권한(Permission.sensors)으로 걸음 측정을 요청한다', () {
    // iOS에는 ACTIVITY_RECOGNITION이 없어 permission_handler가 항상 영구 거부로
    // 응답한다. 이 값을 쓰면 iOS에서 만보기 스위치가 절대 켜지지 않는다.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(PedometerManager.activityPermission, Permission.sensors);
  });

  test('Android는 기존대로 ACTIVITY_RECOGNITION을 요청한다', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(PedometerManager.activityPermission, Permission.activityRecognition);
  });
}
