import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/gait_analysis/gait_analyzer.dart';
import 'package:flutter_application_1/features/gait_analysis/gait_provider.dart';
import 'package:flutter_application_1/features/gait_analysis/widgets/gait_session_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 센서를 건드리지 않고 표시 상태만 검증하기 위한 대역.
class _FakeGaitProvider extends ChangeNotifier implements GaitProvider {
  @override
  bool isMeasuring;
  @override
  int steps;
  @override
  double? stepIntervalCv;
  @override
  int sampleCount;
  @override
  Map<String, dynamic>? lastSummary;

  _FakeGaitProvider({
    this.isMeasuring = false,
    this.steps = 0,
    this.stepIntervalCv,
    this.sampleCount = 0,
    this.lastSummary,
  });

  @override
  double get sampleProgress =>
      (sampleCount / GaitAnalyzer.minIntervalsForVariability).clamp(0.0, 1.0);

  @override
  bool get hasEnoughSamples =>
      sampleCount >= GaitAnalyzer.minIntervalsForVariability;

  @override
  List<double> get liveAccData => const [];

  @override
  void startMeasurement() {
    isMeasuring = true;
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> stopMeasurement({dynamic userId}) async {
    isMeasuring = false;
    notifyListeners();
    return {};
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _FakeGaitProvider provider) async {
  await tester.binding.setSurfaceSize(const Size(360, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<GaitProvider>.value(
        value: provider,
        child: const Scaffold(
          body: SingleChildScrollView(child: GaitSessionCard()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('측정 전에는 시작 버튼과 안내를 보여준다', (tester) async {
    await _pump(tester, _FakeGaitProvider());

    expect(find.text('측정 시작하기'), findsOneWidget);
    expect(find.text('평소 속도로 1~2분 곧게 걸어 주세요.'), findsOneWidget);
  });

  testWidgets('진단이 아니라는 고지가 항상 붙어 있다', (tester) async {
    await _pump(tester, _FakeGaitProvider());
    // 이 지표는 임상 절단값이 없다. 고지가 사라지면 숫자만 남는다.
    expect(find.textContaining('진단이 아닙니다'), findsOneWidget);
  });

  testWidgets('측정 중에는 진행률과 남은 안내를 보여준다', (tester) async {
    await _pump(tester, _FakeGaitProvider(
      isMeasuring: true,
      steps: 30,
      sampleCount: 29,
    ));

    expect(find.text('30보 걸었어요'), findsOneWidget);
    expect(find.textContaining('조금만 더 걸어'), findsOneWidget);
    expect(find.text('측정 마치기'), findsOneWidget);
  });

  testWidgets('표본이 차면 멈춰도 된다고 알려준다', (tester) async {
    await _pump(tester, _FakeGaitProvider(
      isMeasuring: true,
      steps: 140,
      sampleCount: 139,
    ));
    expect(find.textContaining('이제 멈추셔도 됩니다'), findsOneWidget);
  });

  testWidgets('표본이 부족한 채 끝내면 숫자를 만들지 않는다', (tester) async {
    // 근거 조건에 못 미치는 값을 보여주면 사용자는 뜻을 모른 채 숫자만 기억한다.
    await _pump(tester, _FakeGaitProvider(
      steps: 40,
      sampleCount: 39,
      stepIntervalCv: null,
      lastSummary: const {'total_steps': 40},
    ));

    expect(find.text('아직 값을 낼 만큼 걷지 않으셨어요'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('다시 측정하기'), findsOneWidget);
  });

  testWidgets('표본이 충분하면 값과 표본 수를 함께 보여준다', (tester) async {
    await _pump(tester, _FakeGaitProvider(
      steps: 160,
      sampleCount: 159,
      stepIntervalCv: 4.23,
      lastSummary: const {'total_steps': 160},
    ));

    expect(find.text('4.2'), findsOneWidget);
    // 값만 있고 표본 수가 없으면 신뢰도를 판단할 수 없다.
    expect(find.textContaining('표본 159개'), findsOneWidget);
  });

  testWidgets('판정 문구를 쓰지 않는다', (tester) async {
    await _pump(tester, _FakeGaitProvider(
      steps: 160,
      sampleCount: 159,
      stepIntervalCv: 12.0,
      lastSummary: const {'total_steps': 160},
    ));

    for (final banned in ['정상', '위험', '주의 필요', '이상', '비정상']) {
      expect(find.textContaining(banned), findsNothing,
          reason: '"$banned"은 임상 판정을 시사한다');
    }
  });
}
