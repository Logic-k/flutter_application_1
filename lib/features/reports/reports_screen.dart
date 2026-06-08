import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';
import '../../core/database_helper.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';
import 'widgets/social_ranking_view.dart';
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MLColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('나의 인지 건강 일기', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  _buildBrainAgeCard(user),
                  const SizedBox(height: 24),
                  SocialRankingView(userScore: user.memoryScore, categoryName: '기억력'),
                  const SizedBox(height: 24),
                  _buildChartCard(),
                  const SizedBox(height: 24),
                  _buildAISummaryCard(user),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
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
          const Text('각 게임을 통해 측정된 현재의 건강 상태입니다.', style: TextStyle(fontSize: 13, color: MLColors.textSoft)),
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
                    style: TextStyle(fontSize: 11, color: trend > 0 ? MLColors.good : MLColors.bad, fontWeight: FontWeight.w800),
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

    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MLSectionTitle('인지 훈련 점수 추이'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: MLColors.primary,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (s, _) => s.x == spots.last.x,
                    getDotPainter: (s, _, a, b) => FlDotCirclePainter(
                      radius: 5, color: MLColors.primary, strokeColor: Colors.white, strokeWidth: 2.5),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [MLColors.primary.withValues(alpha: 0.28), MLColors.primary.withValues(alpha: 0.0)]),
                  ),
                ),
              ],
            )),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['월', '화', '수', '목', '금', '토', '일']
                .map((d) => Text(d, style: const TextStyle(fontSize: 12, color: MLColors.textFaint, fontWeight: FontWeight.w700)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── AI 요약 카드 ──────────────────────────────────────────────
  Widget _buildAISummaryCard(UserProvider user) {
    return MLCard(
      soft: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: MLColors.primary, size: 22),
            const SizedBox(width: 10),
            const Text('AI 분석 요약', style: TextStyle(color: MLColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
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
          const Divider(color: MLColors.line),
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
        const Text(
          '의료진용 또는 보호자용 PDF 리포트를 생성하여 상담 시 활용하세요.',
          style: TextStyle(fontSize: 13, color: MLColors.textSoft),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
