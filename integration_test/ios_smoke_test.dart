// iOS 시뮬레이터 스모크 테스트 (iPhone·iPad 공용)
//
// 실행 방법 (자세한 내용은 ios/BUILD_iOS.md 「iOS 스모크 테스트」):
//   xcrun simctl privacy <UDID> grant motion com.memorylink.app
//   flutter test integration_test/ios_smoke_test.dart -d <UDID>
//
// - IS_EMULATOR 없이 실제 기동 경로(백그라운드 서비스 설정, Firebase 초기화 시도,
//   알림 준비)를 그대로 탄다. GoogleService-Info.plist가 없으면 로컬 전용 모드로 돈다.
// - iOS 시뮬레이터에는 알림 권한을 미리 허용하는 방법이 없다(simctl privacy 미지원).
//   시스템 팝업에 아무도 답하지 않으면 권한 요청 Future가 끝나지 않으므로 알림 권한의
//   "응답"만 대체한다. 나머지 채널 호출은 실제 iOS 플랫폼으로 그대로 보낸다.
// - 'ML_SHOT:<이름>'을 출력한 뒤 몇 초간 화면을 유지한다. 외부에서
//   `xcrun simctl io <UDID> screenshot`으로 시스템 UI(공유 시트 등)까지 캡처하기 위함이다.
// - Android CI(.github/workflows/test.yml)는 실행할 파일을 명시하므로 이 파일은 돌지 않는다.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart' as app;

const _permissionChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');
const _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');
const _codec = StandardMethodCodec();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final skipReason =
      defaultTargetPlatform == TargetPlatform.iOS ? null : 'iOS 전용 스모크 테스트';

  setUpAll(() {
    if (skipReason != null) return;
    _installNotificationPermissionStubs();
  });

  testWidgets('기동: Firebase 설정 없이도 로그인 화면이 뜨고 데모 계정으로 홈에 들어간다',
      skip: skipReason != null, (tester) async {
    await _launchAndLogin(tester, shotPrefix: '01');
    await _shot(tester, '02_home');
  });

  testWidgets('권한 매핑: iOS에서 걸음 권한은 Permission.sensors여야 허용된다',
      skip: skipReason != null, (tester) async {
    // motion 권한은 실행 전에 `simctl privacy grant motion`으로 허용해 둔다.
    // (허용이 빠져 있으면 시스템 팝업이 떠서 응답을 기다리므로 시간 제한을 둔다.)
    const limit = Duration(seconds: 20);
    final activity = await Permission.activityRecognition.request().timeout(limit);
    final sensors = await Permission.sensors.request().timeout(limit);
    debugPrint('ML_RESULT:permission activityRecognition=$activity sensors=$sensors');
    // activityRecognition은 Android 전용이라 iOS에서는 항상 영구 거부로 응답한다.
    expect(activity, PermissionStatus.permanentlyDenied);
    expect(sensors, PermissionStatus.granted);
  });

  testWidgets('만보기: 생활습관 화면의 실시간 보행 측정 스위치가 켜진다',
      skip: skipReason != null, (tester) async {
    await _launchAndLogin(tester);
    unawaited(GoRouter.of(tester.element(find.text('오늘 걸음').first))
        .push('/walking_dashboard'));
    expect(await _pumpUntil(tester, [find.text('실시간 보행 측정')]), isTrue);

    final trackingOn = find.text('측정 중입니다. 걸음 수가 자동으로 반영됩니다.');
    final trackingOff = find.text('스위치를 켜고 신체 활동 권한을 허용해 주세요.');
    final deniedSnack = find.text('실시간 측정을 사용하려면 신체 활동 권한을 허용해 주세요.');
    // 데모 계정은 만보기 설정이 '켜짐'으로 저장돼 있어, 권한이 있으면 진입 시 자동 재개된다.
    // 그 경우 한 번 끈 뒤 다시 켜서 권한 요청 경로(toggleTracking)를 탄다.
    await _pumpUntil(tester, [trackingOn, trackingOff],
        timeout: const Duration(seconds: 10));
    final autoResumed = trackingOn.evaluate().isNotEmpty;
    if (autoResumed) {
      await tester.tap(find.byType(Switch).first);
      await _pumpUntil(tester, [trackingOff], timeout: const Duration(seconds: 10));
    }
    await _shot(tester, '03_walking_before');

    await tester.tap(find.byType(Switch).first);
    await _pumpUntil(tester, [trackingOn, deniedSnack],
        timeout: const Duration(seconds: 20));
    final on = trackingOn.evaluate().isNotEmpty;
    final denied = deniedSnack.evaluate().isNotEmpty;
    await _shot(tester, '04_walking_after');
    debugPrint('ML_RESULT:pedometer autoResumed=$autoResumed '
        'tracking=$on deniedSnackbar=$denied');

    expect(on, isTrue, reason: '권한이 허용된 상태에서 스위치가 켜져야 한다');
  });

  testWidgets('리포트: PDF를 만든 뒤 공유 시트가 오류 없이 열린다',
      skip: skipReason != null, (tester) async {
    await _launchAndLogin(tester);
    unawaited(GoRouter.of(tester.element(find.text('오늘 걸음').first))
        .push('/report_options'));
    expect(await _pumpUntil(tester, [find.text('의료진용 리포트')]), isTrue);

    await tester.tap(find.text('의료진용 리포트'));
    await _pumpFor(tester, const Duration(milliseconds: 400));
    await _tapVisible(tester, '다음'); // 유형 → 위험요인
    expect(await _pumpUntil(tester, [find.text('건너뛰기').hitTestable()]), isTrue);
    await _tapVisible(tester, '다음'); // 위험요인 → 보호자 동반
    expect(await _pumpUntil(tester, [find.text('혼자 했습니다').hitTestable()]),
        isTrue);
    await _tapVisible(tester, '다음'); // 보호자 동반 → 확인
    final shareButton = find.text('PDF 생성 및 공유하기').hitTestable();
    expect(await _pumpUntil(tester, [shareButton]), isTrue);
    await _shot(tester, '05_report_ready');

    await tester.tap(shareButton);
    // 공유 시트가 닫힐 때까지 Share 호출이 끝나지 않으므로 기다리지 않고,
    // 오류 스낵바가 뜨는지만 본다.
    final errorSnack = find.textContaining('리포트 생성 중 오류가 발생했습니다');
    await _pumpUntil(tester, [errorSnack], timeout: const Duration(seconds: 12));
    final hasError = errorSnack.evaluate().isNotEmpty;
    final errorText =
        hasError ? tester.widget<Text>(errorSnack.first).data : null;
    await _shot(tester, '06_report_share');
    debugPrint('ML_RESULT:share error=$hasError ${errorText ?? ''}');
    expect(hasError, isFalse, reason: errorText);
  });
}

/// 알림 권한 팝업만 우회한다. 다른 호출은 모두 실제 플랫폼으로 전달한다.
void _installNotificationPermissionStubs() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final notification = Permission.notification.value;
  // 채널 프로토콜의 PermissionStatus 정수값 (permission_handler_platform_interface:
  // denied=0, granted=1, restricted=2, limited=3, permanentlyDenied=4, provisional=5).
  const granted = 1;

  messenger.setMockMethodCallHandler(_permissionChannel, (call) async {
    if (call.method == 'requestPermissions') {
      final requested = (call.arguments as List).cast<int>();
      final real = requested.where((p) => p != notification).toList();
      final result = <int, int>{};
      if (real.isNotEmpty) {
        final reply = await _forward(
            messenger, _permissionChannel, MethodCall(call.method, real));
        result.addAll((reply as Map).cast<int, int>());
      }
      if (requested.contains(notification)) result[notification] = granted;
      return result;
    }
    if (call.method == 'checkPermissionStatus' &&
        call.arguments == notification) {
      return granted;
    }
    return _forward(messenger, _permissionChannel, call);
  });

  // 앱 기동 시 알림 플러그인 초기화가 띄우는 권한 팝업을 끈다 (초기화 자체는 실제로 수행).
  messenger.setMockMethodCallHandler(_notificationsChannel, (call) {
    if (call.method == 'initialize' && call.arguments is Map) {
      final args = Map<Object?, Object?>.from(call.arguments as Map);
      for (final key in const [
        'requestAlertPermission',
        'requestSoundPermission',
        'requestBadgePermission',
        'requestProvisionalPermission',
        'requestCriticalPermission',
      ]) {
        if (args.containsKey(key)) args[key] = false;
      }
      return _forward(
          messenger, _notificationsChannel, MethodCall(call.method, args));
    }
    return _forward(messenger, _notificationsChannel, call);
  });
}

Future<Object?> _forward(
  TestDefaultBinaryMessenger messenger,
  MethodChannel channel,
  MethodCall call,
) async {
  final reply = await messenger.delegate
      .send(channel.name, _codec.encodeMethodCall(call));
  return reply == null ? null : _codec.decodeEnvelope(reply);
}

Future<void> _launchAndLogin(WidgetTester tester, {String? shotPrefix}) async {
  // 앞 테스트의 세션이 남아 있으면 자동 로그인되므로 비우고 시작한다.
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  app.main();
  expect(await _pumpUntil(tester, [find.text('사용자 아이디')]), isTrue,
      reason: '로그인 화면이 90초 안에 떠야 한다');
  if (shotPrefix != null) await _shot(tester, '${shotPrefix}_login');

  await tester.enterText(find.byType(TextField).first, 'kim_minjun');
  await tester.enterText(find.byType(TextField).last, 'demo1234');
  await tester.pump();
  await tester.tap(find.text('로그인'));
  expect(await _pumpUntil(tester, [find.text('오늘 걸음')]), isTrue,
      reason: '데모 계정으로 홈에 들어가야 한다');
}

Future<void> _tapVisible(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).hitTestable().first);
  await _pumpFor(tester, const Duration(milliseconds: 700));
}

/// 무한 애니메이션이 있어도 멈추지 않도록 pumpAndSettle 대신 실시간으로 폴링한다.
Future<bool> _pumpUntil(
  WidgetTester tester,
  List<Finder> anyOf, {
  Duration timeout = const Duration(seconds: 90),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (anyOf.any((f) => f.evaluate().isNotEmpty)) return true;
  }
  return false;
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 외부 캡처용 표식을 남기고 화면을 6초간 유지한다.
Future<void> _shot(WidgetTester tester, String name) async {
  debugPrint('ML_SHOT:$name');
  await _pumpFor(tester, const Duration(seconds: 6));
}
