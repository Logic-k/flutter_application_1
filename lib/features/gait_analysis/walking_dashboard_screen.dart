import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'pedometer_manager.dart';

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pedometer = context.watch<PedometerManager>();
    
    // 목표 달성률 계산 (예: 10,000보 기준)
    final double progress = (pedometer.todaySteps / 10000).clamp(0.01, 1.0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('생활습관', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), 
              shape: BoxShape.circle, 
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))
            ),
            child: IconButton(
              icon: Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant), 
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('지난 보행 기록을 불러오는 중입니다...')));
              }
            ),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  
                  // 1. 프리미엄 원형 게이지 섹션
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: theme.primaryColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 16,
                                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  pedometer.todaySteps.toString(),
                                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                                ),
                                Text('/ 10,000 보', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildStepStatus(theme, progress),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. 정밀 분석 CTA 카드
                  _buildPreciseAnalysisCTA(context, theme),

                  const SizedBox(height: 24),
                  
                  // 3. 거리, 시간, 칼로리 요약
                  Row(
                    children: [
                      _buildStatCard(theme, '거리', '${pedometer.todayDistance.toStringAsFixed(1)}km', Icons.map_outlined, theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      _buildStatCard(theme, '칼로리', '${pedometer.todayCalories.toInt()}kcal', Icons.local_fire_department_outlined, theme.colorScheme.error),
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  // 4. 오늘의 상세 지표
                  Text('오늘의 성과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  _buildMetricsGrid(theme, pedometer),

                  const SizedBox(height: 32),
                  
                  // 5. 주간 기록 그래프
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('주간 활동 추이', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                      TextButton(onPressed: () {}, child: const Text('상세보기')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyChart(theme, pedometer),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }



  Widget _buildMetricsGrid(ThemeData theme, PedometerManager pedometer) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(theme, '걸음 수', pedometer.todaySteps.toString(), '걸음', Colors.orange),
        _buildMetricCard(theme, '이동 거리', pedometer.todayDistance.toStringAsFixed(2), 'Km', Colors.blue),
        _buildMetricCard(theme, '소모 칼로리', pedometer.todayCalories.toInt().toString(), 'Kcal', Colors.red),
        _buildMetricCard(theme, '활동 시간', '0', '분', Colors.green),
      ],
    );
  }

  Widget _buildMetricCard(ThemeData theme, String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepStatus(ThemeData theme, double progress) {
    String status = progress < 0.3 ? '조금 더 힘내볼까요? ⚡' : progress < 0.7 ? '잘하고 계십니다! 👍' : '목표 달성이 코앞이에요! 🎉';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _buildPreciseAnalysisCTA(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () => context.push('/precise_gait_analysis'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('보행 정밀 분석', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '3분간의 걸음으로 당신의 뇌 건강 패턴을 분석합니다.',
                    style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.onPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onPrimary, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(ThemeData theme, PedometerManager pedometer) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(_buildWeeklyBarChart(theme, pedometer)),
    );
  }

  BarChartData _buildWeeklyBarChart(ThemeData theme, PedometerManager pedometer) {
    // 실데이터 매핑 및 누락일 0 채우기
    Map<String, int> stepMap = {};
    for (var row in _weeklyData) {
      stepMap[row['date']] = row['steps'] ?? 0;
    }

    List<BarChartGroupData> groups = [];
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      String dayKey = day.toIso8601String().split('T')[0];
      int steps = stepMap[dayKey] ?? 0;
      groups.add(_makeGroupData(6 - i, steps.toDouble(), theme.primaryColor));
    }

    return BarChartData(
      alignment: BarChartAlignment.spaceEvenly,
      maxY: 12000,
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['월', '화', '수', '목', '금', '토', '일'];
              DateTime now = DateTime.now();
              int index = (now.weekday - 1 - (6 - value.toInt())) % 7;
              if (index < 0) index += 7;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(days[index], style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: groups,
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 14,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 12000, color: color.withValues(alpha: 0.1)),
        ),
      ],
    );
  }
}
