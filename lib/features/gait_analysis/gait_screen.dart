import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'pedometer_manager.dart';

class GaitScreen extends StatefulWidget {
  const GaitScreen({super.key});

  @override
  State<GaitScreen> createState() => _GaitScreenState();
}

class _GaitScreenState extends State<GaitScreen> {
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoadingChart = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final pedometer = context.read<PedometerManager>();
    final data = await pedometer.getWeeklySummary();
    if (mounted) {
      setState(() {
        _weeklyData = data;
        _isLoadingChart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pedometer = context.watch<PedometerManager>();

    // 걸음 수 기준 활동 시간 추정 (보행 속도: 약 100보/분)
    final int activityMinutes = (pedometer.todaySteps / 100).floor();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('보행 건강 진단',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상시 추적 토글
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_run,
                      color: theme.primaryColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('상시 보행 추적',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          pedometer.isTracking
                              ? '알림바에서 실시간 확인 중'
                              : '기능을 켜서 걸음 수를 관리해보세요',
                          style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: pedometer.isTracking,
                    onChanged: (value) => pedometer.toggleTracking(value),
                    activeThumbColor: theme.primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('오늘의 성과',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMetricsGrid(theme, pedometer, activityMinutes),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('주간 분석',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.push('/walking_dashboard'),
                  child: const Text('상세보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWeeklyChart(theme, pedometer),

            const SizedBox(height: 48),
            _buildManualAnalysisCard(context, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
      ThemeData theme, PedometerManager pedometer, int activityMinutes) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(theme, '걸음 수',
            pedometer.todaySteps.toString(), '걸음', Colors.orange),
        _buildMetricCard(theme, '이동 거리',
            pedometer.todayDistance.toStringAsFixed(2), 'Km', Colors.blue),
        _buildMetricCard(theme, '소모 칼로리',
            pedometer.todayCalories.toInt().toString(), 'Kcal', Colors.red),
        _buildMetricCard(theme, '활동 시간',
            activityMinutes.toString(), '분', Colors.green),
      ],
    );
  }

  Widget _buildMetricCard(ThemeData theme, String title, String value,
      String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
              const SizedBox(width: 4),
              Text(unit,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(ThemeData theme, PedometerManager pedometer) {
    if (_isLoadingChart) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // DB 데이터를 요일별로 정렬 (최신 7일)
    final today = DateTime.now();
    final Map<String, double> stepsByDate = {};
    for (final row in _weeklyData) {
      final date = row['date'] as String? ?? '';
      stepsByDate[date] = (row['steps'] as num).toDouble();
    }

    // 오늘 포함 최근 7일 데이터 생성
    List<(String label, double steps)> chartData = [];
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final dayLabel = ['월', '화', '수', '목', '금', '토', '일'][day.weekday - 1];
      final isToday = i == 0;
      final steps = isToday ? pedometer.todaySteps.toDouble() : (stepsByDate[dateKey] ?? 0);
      chartData.add((dayLabel, steps));
    }

    final double maxSteps = chartData
        .map((e) => e.$2)
        .fold(10000.0, (a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxSteps * 1.2,
          barGroups: chartData.asMap().entries.map((entry) {
            return _makeGroupData(entry.key, entry.value.$2, theme.primaryColor);
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= chartData.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      chartData[idx].$1,
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: y > 0
              ? color.withValues(alpha: 0.8)
              : color.withValues(alpha: 0.2),
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildManualAnalysisCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          theme.primaryColor,
          theme.primaryColor.withValues(alpha: 0.8)
        ]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('정밀 보행 분석',
              style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '3분간 직접 걸으며 보행의 안정성(변동성)을 측정합니다. 정기적인 정밀 분석은 치매 조기 발견에 도움이 됩니다.',
            style: TextStyle(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/precise_gait_analysis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('지금 정밀 분석 시작하기',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
