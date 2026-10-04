import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/core/services/background_service.dart';
import 'package:flutter_application_1/features/gait_analysis/pedometer_manager.dart';
import '../../helpers/mock_definitions.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const native = MethodChannel('id.flutter/background_service/android/method', JSONMethodCodec());
  const events = MethodChannel('id.flutter/background_service/android/event', JSONMethodCodec());
  const notifications = MethodChannel('dexterous.com/flutter/local_notifications');
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  late MockUserProvider user;
  late MockDatabaseHelper db;
  late List<VoidCallback> listeners;
  Map<String, dynamic>? account;
  var enabled = false, running = false, disposed = false;
  var starts = 0, stops = 0;
  PedometerManager? manager;
  Completer<Map<int, int>>? permissionResult;
  setUp(() async {
    FlutterBackgroundServiceAndroid.registerWith();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    user = MockUserProvider(); db = MockDatabaseHelper(); listeners = [];
    account = {'id': 1, 'username': 'Synthetic user'};
    enabled = false; running = false; disposed = false; starts = 0; stops = 0;
    manager = null; permissionResult = null;
    when(() => user.currentUser).thenAnswer((_) => account);
    when(() => user.pedometerEnabled).thenAnswer((_) => enabled);
    when(() => user.weight).thenReturn(null); when(() => user.age).thenReturn(null);
    when(() => user.addListener(any())).thenAnswer((call) => listeners.add(call.positionalArguments.single as VoidCallback));
    when(() => user.removeListener(any())).thenAnswer((call) => listeners.remove(call.positionalArguments.single));
    when(() => user.setPedometerEnabled(any())).thenAnswer((call) async {enabled = call.positionalArguments.single as bool;});
    when(() => db.getTodaySteps(any())).thenAnswer((_) async => null);
    when(() => db.getWeeklySteps(any())).thenAnswer((_) async => []);
    when(() => db.updateDailySteps(any(), any(), any(), any())).thenAnswer((_) async {});
    binding.defaultBinaryMessenger.setMockMethodCallHandler(native, (call) async {
      if (call.method == 'isServiceRunning') return running;
      if (call.method == 'start') {starts++; running = true;}
      if (call.method == 'sendData' && (call.arguments as Map)['method'] == 'stopService') {stops++; running = false;}
      return true;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, (_) async => null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(notifications, (_) async => true);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'requestPermissions') return permissionResult?.future ?? {Permission.activityRecognition.value: 1, Permission.notification.value: 1};
      return 1;
    });
    await PedometerBackgroundService.initializeService();
  });
  tearDown(() async {
    if (!disposed) manager?.dispose();
    await pumpEventQueue();
    for (final channel in [native, events, notifications, permissions]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    }
  });
  void createManager() {manager = PedometerManager(user, db: db);}
  test('existing service is stopped when the saved setting is OFF', () async {
    running = true; createManager(); await pumpEventQueue();
    expect(running, isFalse); expect(stops, greaterThanOrEqualTo(1));
  });
  test('late permission grant cannot undo an explicit OFF', () async {
    createManager(); await pumpEventQueue();
    permissionResult = Completer<Map<int, int>>();
    final enable = manager!.toggleTracking(true); await pumpEventQueue();
    await manager!.toggleTracking(false);
    permissionResult!.complete({Permission.activityRecognition.value: 1, Permission.notification.value: 1});
    await enable; await pumpEventQueue();
    expect(starts, 0); expect(manager!.isTracking, isFalse); expect(enabled, isFalse);
  });
  test('switch to an OFF account stops tracking and rejects late updates', () async {
    enabled = true; createManager(); await pumpEventQueue(); expect(starts, 1);
    account = {'id': 2, 'username': 'Synthetic user B'}; enabled = false;
    for (final callback in List<VoidCallback>.of(listeners)) {callback();}
    await pumpEventQueue();
    final handled = Completer<void>();
    binding.defaultBinaryMessenger.handlePlatformMessage(native.name,
      native.codec.encodeMethodCall(const MethodCall('onReceiveData', {'method': 'update_steps', 'args': {'steps': 99}})),
      (_) => handled.complete());
    await handled.future; await pumpEventQueue();
    expect(running, isFalse); expect(manager!.todaySteps, 0);
    verifyNever(() => db.updateDailySteps(2, any(), any(), any()));
  });
  test('disposing during permission request prevents late start or notify', () async {
    createManager(); await pumpEventQueue();
    permissionResult = Completer<Map<int, int>>();
    final enable = manager!.toggleTracking(true); await pumpEventQueue();
    manager!.dispose(); disposed = true;
    final completion = expectLater(enable, completes);
    permissionResult!.complete({Permission.activityRecognition.value: 1, Permission.notification.value: 1});
    await completion; await pumpEventQueue(); expect(starts, 0);
  });
}
