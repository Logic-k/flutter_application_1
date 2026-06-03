import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'pedometer_manager.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';

class WalkingDashboardScreen extends StatefulWidget {
  const WalkingDashboardScreen({super.key});

  @override
  State<WalkingDashboardScreen> createState() => _WalkingDashboardScreenState();
}

class _WalkingDashboardScreenState extends State<WalkingDashboardScreen> {
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    try {
      final pedometer = context.read<PedometerManager>();
      final data = await pedometer.getWeeklySummary();
      if (mounted) {
        setState(() {
          _weeklyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('대시보드 데이터 로드 오류: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedometer = context.watch<PedometerManager>();
    final progress = (pedometer.todaySteps / 10000).clamp(0.01, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('생활습관'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: MLColors.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: MLColors.line),
            ),
            child: IconButton(
              icon: const Icon(Icons.history_rounded, color: MLColors.textSoft),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('지난 보행 기록을 불러오는 중입니다...'))),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MLColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 원형 게이지
                  MLCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MLRing(
                          value: progress,
                          size: 194,
                          stroke: 17,
                          color: MLColors.primary,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(pedometer.todaySteps.toString(), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                              const Text('/ 10,000 보', style: TextStyle(fontSize: 13, color: MLColors.textSoft, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStepStatus(progress),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. 정밀 분석 CTA
                  GestureDetector(
                    onTap: () => context.push('/precise_gait_analysis'),
                    child: MLHeroCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('보행 정밀 분석', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                SizedBox(height: 4),
                                Text('3분간의 걸음으로 당신의 뇌 건강 패턴을 분석합니다.', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. 오늘의 성과 그리드 (MLMetricCard × 4)
                  MLSectionTitle('오늘의 성과'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.5,
                    children: [
                      MLMetricCard(icon: Icons.directions_walk_rounded, color: MLColors.read, label: '걸음 수', value: pedometer.todaySteps.toString(), unit: '걸음'),
                      MLMetricCard(icon: Icons.map_rounded, color: MLColors.calc, label: '이동 거리', value: pedometer.todayDistance.toStringAsFixed(2), unit: 'km'),
                      MLMetricCard(icon: Icons.local_fire_department_rounded, color: MLColors.bad, label: '소모 칼로리', value: pedometer.todayCalories.toInt().toString(), unit: 'kcal'),
                      MLMetricCard(icon: Icons.timer_rounded, color: MLColors.good, label: '활동 시간', value: '0', unit: '분'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4. 주간 기록 차트
                  MLSectionTitle(
                    '주간 활동 추이',
                    trailing: TextButton(onPressed: () {}, child: const Text('상세보기')),
                  ),
                  MLCard(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(_buildWeeklyBarChart()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStepStatus(double progress) {
    final status = progress < 0.3 ? '조금 더 힘내볼까요!' : progress < 0.7 ? '잘하고 계십니다!' : '목표 달성이 코앞이에요!';
    final color = progress < 0.3 ? MLColors.warn : progress < 0.7 ? MLColors.sky : MLColors.good;
    return MLStatusPill(label: status, color: color);
  }

  BarChartData _buildWeeklyBarChart() {
    final stepMap = <String, int>{};
    for (var row in _weeklyData) {
      stepMap[row['date'] as String] = (row['steps'] ?? 0) as int;
    }

    final groups = <BarChartGroupData>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKey = day.toIso8601String().split('T')[0];
      final steps = (stepMap[dayKey] ?? 0).toDouble();
      groups.add(BarChartGroupData(x: 6 - i, barRods: [
        BarChartRodData(
          toY: steps,
          width: 16,
          color: MLColors.primary,
          borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 12000, color: MLColors.primary.withValues(alpha: 0.10)),
        ),
      ]));
    }

    return BarChartData(
      alignment: BarChartAlignment.spaceEvenly,
      maxY: 12000,
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            const days = ['월', '화', '수', '목', '금', '토', '일'];
            int index = (now.weekday - 1 - (6 - value.toInt())) % 7;
            if (index < 0) index += 7;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(days[index], style: const TextStyle(color: MLColors.textFaint, fontSize: 12, fontWeight: FontWeight.w700)),
            );
          },
        )),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: groups,
    );
  }
}
