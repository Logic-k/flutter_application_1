import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/core/services/guardian_sync_service.dart';
import 'package:flutter_application_1/features/gait_analysis/pedometer_manager.dart';
import 'package:flutter_application_1/features/profile/guardian_link_screen.dart';
import '../helpers/mock_definitions.dart';

class _Sync extends Mock implements GuardianSyncService {}

void main() {
  late _Sync sync;
  late MockUserProvider user;
  late MockPedometerManager pedometer;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sync = _Sync(); user = MockUserProvider(); pedometer = MockPedometerManager();
    when(() => user.currentUser).thenReturn({'id': 1, 'username': 'Synthetic user'});
    when(() => user.emergencyContact).thenReturn(null);
    when(() => pedometer.todaySteps).thenReturn(5000);
    when(() => sync.getOrCreateToken(any())).thenAnswer((_) async => 'SYNTHETICLOCAL01');
    when(() => sync.guardianUrl(any())).thenReturn('https://example.invalid/guardian.html');
  });
  Future<GuardianSyncResult> Function() request = () async => const GuardianSyncResult(
    success: false, token: '', isAnomaly: false, error: 'synthetic backend details',
  );
  void stub() => when(() => sync.syncToFirestore(
    userId: any(named: 'userId'), userName: any(named: 'userName'),
    todaySteps: any(named: 'todaySteps'), emergencyContact: any(named: 'emergencyContact'),
  )).thenAnswer((_) => request());
  Widget app({bool actualService = false, double scale = 1}) => MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: user),
      ChangeNotifierProvider<PedometerManager>.value(value: pedometer),
    ],
    child: MaterialApp(builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ), home: GuardianLinkScreen(syncService: actualService ? null : sync)),
  );
  Future<void> click(WidgetTester tester) async {
    await tester.ensureVisible(find.text('지금 동기화'));
    await tester.tap(find.text('지금 동기화'));
    await tester.pump();
  }
  testWidgets('actual Guardian screen remains usable without Firebase', (tester) async {
    await tester.pumpWidget(app(actualService: true)); await tester.pump();
    expect(find.text('보호자 안심 연결'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await click(tester); await tester.pump();
    expect(find.byIcon(Icons.cloud_done), findsNothing);
  });
  testWidgets('failed sync is not success and does not expose backend details', (tester) async {
    request = () async => const GuardianSyncResult(success: false, token: '', isAnomaly: false,
      error: 'synthetic backend details'); stub();
    await tester.pumpWidget(app()); await tester.pump(); await click(tester);
    expect(find.byIcon(Icons.cloud_done), findsNothing);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.textContaining('synthetic backend details'), findsNothing);
    expect(find.textContaining('다시 시도'), findsOneWidget);
  });
  testWidgets('failed retry preserves the last successful sync time', (tester) async {
    request = () async => const GuardianSyncResult(success: true, token: 'synthetic', isAnomaly: false); stub();
    await tester.pumpWidget(app()); await tester.pump(); await click(tester);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    request = () async => const GuardianSyncResult(success: false, token: '', isAnomaly: false); 
    await click(tester);
    expect(find.text('방금 전 동기화'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsNothing);
  });
  testWidgets('unexpected sync failure clears loading and offers retry', (tester) async {
    request = () async => throw StateError('synthetic failure'); stub();
    await tester.pumpWidget(app()); await tester.pump(); await click(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('동기화 중...'), findsNothing);
    expect(find.text('지금 동기화'), findsOneWidget);
  });
  testWidgets('repeated taps send one request; late completion after leaving is safe', (tester) async {
    final pending = Completer<GuardianSyncResult>(); var calls = 0;
    request = () {calls++; return pending.future;}; stub();
    await tester.pumpWidget(app()); await tester.pump();
    await tester.ensureVisible(find.text('지금 동기화'));
    await tester.tap(find.text('지금 동기화')); await tester.tap(find.text('지금 동기화'));
    await tester.pump(); expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    pending.complete(const GuardianSyncResult(success: true, token: 'synthetic', isAnomaly: false));
    await tester.pump(); expect(tester.takeException(), isNull);
  });
  testWidgets('320dp with large text retains sync status without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(scale: 2)); await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('아직 동기화하지 않았습니다'), findsOneWidget);
  });
}
