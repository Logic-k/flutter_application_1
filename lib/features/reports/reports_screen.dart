import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';
import '../../core/database_helper.dart';
import '../../core/ml_widgets.dart';
import '../../core/motion/staggered_column.dart';
import '../../core/theme.dart';
import 'report_analyzer.dart';
import '../gait_analysis/pedometer_manager.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _scoreHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<UserProvider>();
    if (user.currentUser != null) {
      try {
        final history = await _dbHelper.getScoreHistory(user.currentUser!['id']);
        if (mounted) {
          setState(() {
            _scoreHistory = history;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('ReportsScreen._loadData error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('주간 분석 리포트')),
      body: MLLoadSwitcher(
        loading: _isLoading,
        skeleton: _buildSkeleton(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              22, 6, 22, FloatingPillNav.contentBottomInset),
          // 제목·지표 → 점수 추이 → AI 요약 → 버튼 순(08 계획 G-04). 탭을 처음 열 때 1회.
          child: StaggeredColumn(
            playKey: 'reports',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('나의 인지 건강 일기', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 20),
                        _buildBrainAgeCard(user),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _buildChartCard(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _buildAISummaryCard(user),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _buildActionButtons(context),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  /// 불러오는 동안 실제 배치(제목 → 지표 카드 → 차트 카드)를 닮은 자리를 그린다.
  Widget _buildSkeleton() {
    return Semantics(
      label: '리포트를 불러오는 중',
      excludeSemantics: true,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(22, 6, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MLSkeleton(width: 190, height: 24),
            SizedBox(height: 20),
            MLSkeletonCard(lines: 4, leading: false),
            SizedBox(height: 24),
            MLSkeletonCard(lines: 3, leading: false, height: 200),
          ],
        ),
      ),
    );
  }

  // ─── 인지 지표 카드 ───────────────────────────────────────────
  Widget _buildBrainAgeCard(UserProvider user) {
    final trends = _calculateTrends();
    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MLSectionTitle('영역 별 인지 지표'),
          Text('각 게임의 최근 수행 기록입니다.', style: TextStyle(fontSize: 13, color: context.scheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          _buildIndicatorBar('계산력', user.calculationScore / 100.0, trends['calculation']),
          _buildIndicatorBar('논리 추론', user.logicScore / 100.0, trends['logic']),
          _buildIndicatorBar('시각 기억', user.memoryScore / 100.0, trends['memory']),
          _buildIndicatorBar('집중력', user.attentionScore / 100.0, trends['attention']),
        ],
      ),
    );
  }

  Map<String, double> _calculateTrends() {
    final Map<String, double> trends = {};
    const categories = ['calculation', 'logic', 'memory', 'attention'];
    for (var cat in categories) {
      final catScores = _scoreHistory.where((s) => s['category'] == cat).toList();
      if (catScores.length >= 2) {
        final latest = (catScores.last['score'] ?? 0).toDouble();
        final previous = (catScores[catScores.length - 2]['score'] ?? 0).toDouble();
        trends[cat] = previous > 0 ? ((latest - previous) / previous) * 100 : 0;
      } else {
        trends[cat] = 0;
      }
    }
    return trends;
  }

  Widget _buildIndicatorBar(String label, double value, double? trend) {
    final Color statusColor;
    final String statusLabel;
    if (value < 0.45) {
      statusColor = MLColors.bad;
      statusLabel = '주의';
    } else if (value < 0.75) {
      statusColor = MLColors.warn;
      statusLabel = '보통';
    } else {
      statusColor = MLColors.good;
      statusLabel = '양호';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (trend != null && trend != 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${trend > 0 ? '↑' : '↓'} ${trend.abs().toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: trend > 0 ? MLColors.goodText : MLColors.badText, fontWeight: FontWeight.w800),
                  ),
                ],
              ]),
              MLStatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          MLProgressBar(value: value, color: statusColor),
        ],
      ),
    );
  }

  // ─── 차트 카드 ─────────────────────────────────────────────────
  Widget _buildChartCard() {
    List<FlSpot> spots = [];
    if (_scoreHistory.isEmpty) {
      for (int i = 0; i < 7; i++) {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    } else {
      final count = _scoreHistory.length > 7 ? 7 : _scoreHistory.length;
      for (int i = 0; i < count; i++) {
        final score = (_scoreHistory[_scoreHistory.length - count + i]['score'] ?? 0).toDouble();
        spots.add(FlSpot(i.toDouble(), score / 10.0));
      }
    }

    // 기준선은 실제 최솟값이다(차트가 바닥에서 올라오는 모양).
    final lo = spots.fold<double>(spots.first.y, (m, s) => s.y < m ? s.y : m);
    final hi = spots.fold<double>(spots.first.y, (m, s) => s.y > m ? s.y : m);

    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MLSectionTitle('인지 훈련 점수 추이'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            // 첫 진입에 선이 바닥에서 올라온다. 움직임 줄이기면 처음부터 실제 값.
            child: MLChart(
              playKey: 'reports_score_chart',
              builder: (context, entered, duration, curve) => LineChart(
              duration: duration,
              curve: curve,
              LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: entered ? spots : [for (final s in spots) FlSpot(s.x, lo)],
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: context.scheme.primary,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (s, _) => s.x == spots.last.x,
                    getDotPainter: (s, _, a, b) => FlDotCirclePainter(
                      radius: 5, color: context.scheme.primary, strokeColor: Colors.white, strokeWidth: 2.5),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [context.scheme.primary.withValues(alpha: 0.28), context.scheme.primary.withValues(alpha: 0.0)]),
                  ),
                ),
              ],
              // 기준선 프레임에서도 축 범위가 실제 데이터와 같아야 선이 "자라난다".
              // fl_chart 자동 범위(최솟값~최댓값)와 같은 값이라 최종 모양은 그대로다.
              minY: hi > lo ? lo : null,
              maxY: hi > lo ? hi : null,
            )),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['월', '화', '수', '목', '금', '토', '일']
                .map((d) => Text(d, style: TextStyle(fontSize: 12, color: context.scheme.onSurfaceVariant, fontWeight: FontWeight.w700)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── 자동 요약 카드 (규칙 기반 ReportAnalyzer, 생성형 AI 아님) ─────
  Widget _buildAISummaryCard(UserProvider user) {
    return MLCard(
      soft: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded, color: context.scheme.primary, size: 22),
            const SizedBox(width: 10),
            Text('자동 요약', style: TextStyle(color: context.scheme.primary, fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
          const SizedBox(height: 14),
          Text(
            ReportAnalyzer.generateSummary(
              scoreHistory: _scoreHistory,
              currentCalculation: user.calculationScore,
              currentLogic: user.logicScore,
              currentMemory: user.memoryScore,
              currentAttention: user.attentionScore,
            ),
            style: const TextStyle(height: 1.6, fontSize: 15),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 14),
          const Text('다음 주 권고 사항', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          ...ReportAnalyzer.generateRecommendations(
            currentSteps: context.read<PedometerManager>().todaySteps.toDouble(),
            currentMemory: user.memoryScore,
          ).map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: MLColors.good),
              const SizedBox(width: 8),
              Expanded(child: Text(rec, style: const TextStyle(fontSize: 14))),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => context.push('/report_options'),
          icon: const Icon(Icons.description_outlined),
          label: const Text('임상 리포트 생성하기'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 8),
        Text(
          '의료진용 또는 보호자용 PDF 리포트를 생성하여 상담 시 활용하세요.',
          style: TextStyle(fontSize: 13, color: context.scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
