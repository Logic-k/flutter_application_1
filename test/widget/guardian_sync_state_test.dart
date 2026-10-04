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
    when(() => user.currentUser).thenReturn({'id': 1, 'username': 'Synthetic user', 'name': '민준'});
    when(() => user.emergencyContact).thenReturn(null);
    when(() => pedometer.todaySteps).thenReturn(5000);
    when(() => sync.isSharingStopped(any())).thenAnswer((_) async => false);
    when(() => sync.getOrCreateToken(any())).thenAnswer((_) async => 'SyntheticLocalToken001');
    when(() => sync.guardianUrl(any())).thenAnswer(
        (call) => 'https://example.invalid/guardian.html?token=${call.positionalArguments.first}');
  });
  Future<GuardianSyncResult> Function() request = () async => const GuardianSyncResult(
    success: false, token: '', isAnomaly: false, error: 'synthetic backend details',
  );
  void stub() => when(() => sync.syncToFirestore(
    userId: any(named: 'userId'), displayName: any(named: 'displayName'),
    todaySteps: any(named: 'todaySteps'),
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
  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label).first);
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
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
    request = () async => const GuardianSyncResult(success: true, token: 'SyntheticLocalToken001', isAnomaly: false); stub();
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
  testWidgets('sync sends the chosen name, not the login id', (tester) async {
    request = () async => const GuardianSyncResult(success: true, token: 'SyntheticLocalToken001', isAnomaly: false); stub();
    await tester.pumpWidget(app()); await tester.pump(); await click(tester);
    verify(() => sync.syncToFirestore(userId: 1, displayName: '민준', todaySteps: 5000)).called(1);
  });
  testWidgets('a rotated link replaces the QR link and tells the user to resend it', (tester) async {
    request = () async => const GuardianSyncResult(
        success: true, token: 'RotatedSyntheticToken9', isAnomaly: false, rotated: true); stub();
    await tester.pumpWidget(app()); await tester.pump(); await click(tester); await tester.pump();
    verify(() => sync.guardianUrl('RotatedSyntheticToken9')).called(1);
    expect(find.textContaining('새로 만들어졌습니다'), findsOneWidget);
  });
  testWidgets('stop sharing asks first, then shows the stopped state', (tester) async {
    when(() => sync.stopSharing(1)).thenAnswer((_) async => true);
    await tester.pumpWidget(app()); await tester.pump();
    await tapButton(tester, '공유 중지');
    expect(find.text('보호자 공유를 중지할까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '공유 중지'));
    await tester.pumpAndSettle();
    verify(() => sync.stopSharing(1)).called(1);
    expect(find.text('보호자 공유가 중지되어 있습니다'), findsOneWidget);
    expect(find.text('다시 공유하기'), findsOneWidget);
    expect(find.text('지금 동기화'), findsNothing);
  });
  testWidgets('cancelling the stop dialog keeps sharing', (tester) async {
    await tester.pumpWidget(app()); await tester.pump();
    await tapButton(tester, '공유 중지');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    verifyNever(() => sync.stopSharing(any()));
    expect(find.text('지금 동기화'), findsOneWidget);
  });
  testWidgets('a failed stop keeps the link and says so', (tester) async {
    when(() => sync.stopSharing(1)).thenAnswer((_) async => false);
    await tester.pumpWidget(app()); await tester.pump();
    await tapButton(tester, '공유 중지');
    await tester.tap(find.widgetWithText(TextButton, '공유 중지'));
    await tester.pumpAndSettle();
    expect(find.textContaining('중지하지 못했습니다'), findsOneWidget);
    expect(find.text('지금 동기화'), findsOneWidget);
  });
  testWidgets('entering while stopped offers to share again', (tester) async {
    when(() => sync.isSharingStopped(1)).thenAnswer((_) async => true);
    when(() => sync.resumeSharing(1)).thenAnswer((_) async => 'ResumedSyntheticToken1');
    await tester.pumpWidget(app()); await tester.pump();
    expect(find.text('보호자 공유가 중지되어 있습니다'), findsOneWidget);
    verifyNever(() => sync.getOrCreateToken(any()));
    await tapButton(tester, '다시 공유하기');
    verify(() => sync.resumeSharing(1)).called(1);
    verify(() => sync.guardianUrl('ResumedSyntheticToken1')).called(1);
    expect(find.text('지금 동기화'), findsOneWidget);
  });
  testWidgets('reissue asks first and switches to the new link', (tester) async {
    when(() => sync.reissue(1)).thenAnswer((_) async => 'ReissuedSyntheticTok12');
    await tester.pumpWidget(app()); await tester.pump();
    await tapButton(tester, '새 링크 만들기');
    expect(find.text('새 링크를 만들까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '새 링크 만들기'));
    await tester.pumpAndSettle();
    verify(() => sync.reissue(1)).called(1);
    verify(() => sync.guardianUrl('ReissuedSyntheticTok12')).called(1);
  });
}
