import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/gait_analysis/pedometer_manager.dart';
import 'package:flutter_application_1/features/gait_analysis/walking_dashboard_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/gait_analysis/gait_provider.dart';

import '../../helpers/mock_definitions.dart';

Widget _buildSubject(MockPedometerManager pedometer) {
  // 생활습관 탭에 걸음 간격 측정 카드가 들어가면서 GaitProvider가 필요해졌다.
  // 실제 인스턴스를 쓰되 startMeasurement를 부르지 않으므로 센서는 켜지지 않는다.
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PedometerManager>.value(value: pedometer),
      ChangeNotifierProvider<GaitProvider>(create: (_) => GaitProvider()),
    ],
    child: const MaterialApp(home: WalkingDashboardScreen()),
  );
}

void main() {
  late MockPedometerManager pedometer;

  setUp(() {
    pedometer = MockPedometerManager();
    when(() => pedometer.todaySteps).thenReturn(0);
    when(() => pedometer.todayCalories).thenReturn(0);
    when(() => pedometer.todayDistance).thenReturn(0);
    when(() => pedometer.isTracking).thenReturn(false);
    when(() => pedometer.getWeeklySummary()).thenAnswer((_) async => []);
    when(() => pedometer.refreshTracking()).thenAnswer((_) async {});
    when(() => pedometer.toggleTracking(any())).thenAnswer((_) async {});
  });

  testWidgets('생활습관 탭에서 실시간 보행 측정을 켤 수 있다', (tester) async {
    await tester.pumpWidget(_buildSubject(pedometer));
    await tester.pumpAndSettle();

    expect(find.text('실시간 보행 측정'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    verify(() => pedometer.toggleTracking(true)).called(1);
  });
}
