import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/services/background_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const serviceChannel = MethodChannel('id.flutter/background_service/android/method', JSONMethodCodec());
  const eventChannel = MethodChannel('id.flutter/background_service/android/event', JSONMethodCodec());
  const notificationChannel = MethodChannel('dexterous.com/flutter/local_notifications');
  test('configure sends explicit boot opt-out and never starts the service', () async {
    FlutterBackgroundServiceAndroid.registerWith();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    Map<dynamic, dynamic>? configuration;
    var starts = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(serviceChannel, (call) async {
      if (call.method == 'configure') configuration = call.arguments as Map;
      if (call.method == 'start') starts++;
      return true;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(eventChannel, (_) async => null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(notificationChannel, (_) async => true);
    addTearDown(() {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(serviceChannel, null);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(eventChannel, null);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(notificationChannel, null);
    });
    await PedometerBackgroundService.initializeService();
    expect(configuration, isNotNull);
    expect(configuration!['auto_start'], isFalse);
    expect(configuration!['auto_start_on_boot'], isFalse);
    expect(starts, 0);
  });
}
