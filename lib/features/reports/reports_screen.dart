import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/user_provider.dart';
import '../../core/database_helper.dart';
import 'widgets/social_ranking_view.dart';
import 'clinical_report_generator.dart';
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
      final history = await _dbHelper.getScoreHistory(user.currentUser!['id']);
      if (mounted) {
        setState(() {
          _scoreHistory = history;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('주간 분석 리포트')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('나의 인지 건강 일기', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildBrainAgeCard(theme, user),
                const SizedBox(height: 32),
                SocialRankingView(
                  userScore: user.memoryScore, 
                  categoryName: '기억력',
                ),
                const SizedBox(height: 32),
                _buildChartCard(theme),
                const SizedBox(height: 32),
                _buildAISummaryCard(theme, user),
                const SizedBox(height: 32),
                _buildActionButtons(context, theme, user),
              ],
            ),
          ),
    );
  }

  Widget _buildBrainAgeCard(ThemeData theme, UserProvider user) {
    // 트렌드 데이터 계산 (현재 점수 vs 직전 점수)
    Map<String, double> trends = _calculateTrends();

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('영역 별 인지 지표', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('각 게임을 통해 측정된 현재의 건강 상태입니다.', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            _buildIndicatorBar(theme, '계산력', user.calculationScore / 100.0, '주의', trends['calculation']),
            _buildIndicatorBar(theme, '논리 추론', user.logicScore / 100.0, '보통', trends['logic']),
            _buildIndicatorBar(theme, '시각 기억', user.memoryScore / 100.0, '양호', trends['memory']),
            _buildIndicatorBar(theme, '집중력', user.attentionScore / 100.0, '주의', trends['attention']),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateTrends() {
    Map<String, double> trends = {};
    const categories = ['calculation', 'logic', 'memory', 'attention'];
    
    for (var cat in categories) {
      final catScores = _scoreHistory.where((s) => s['category'] == cat).toList();
      if (catScores.length >= 2) {
        double latest = (catScores.last['score'] ?? 0).toDouble();
        double previous = (catScores[catScores.length - 2]['score'] ?? 0).toDouble();
        if (previous > 0) {
          trends[cat] = ((latest - previous) / previous) * 100;
        } else {
          trends[cat] = 0;
        }
      } else {
        trends[cat] = 0;
      }
    }
    return trends;
  }

  Widget _buildIndicatorBar(ThemeData theme, String label, double value, String status, double? trend) {
    Color statusColor;
    // 신호등 색상 적용 (시니어 친화적 직관성 강화)
    if (value < 0.45) {
      statusColor = const Color(0xFFF44336); // 위험/주의 (Red)
    } else if (value < 0.75) {
      statusColor = const Color(0xFFFFB300); // 보통 (Yellow/Amber)
    } else {
      statusColor = const Color(0xFF4CAF50); // 양호 (Green)
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  if (trend != null && trend != 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${trend > 0 ? '↑' : '↓'} ${trend.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: trend > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value.clamp(0.05, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [statusColor.withValues(alpha: 0.5), statusColor]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme) {
    // 실데이터 매핑: 최근 7개의 점수 데이터만 시각화
    List<FlSpot> spots = [];
    if (_scoreHistory.isEmpty) {
      // 데이터 없는 경우 0으로 채우기
      for (int i = 0; i < 7; i++) {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    } else {
      int count = _scoreHistory.length > 7 ? 7 : _scoreHistory.length;
      for (int i = 0; i < count; i++) {
        final score = (_scoreHistory[_scoreHistory.length - count + i]['score'] ?? 0).toDouble();
        spots.add(FlSpot(i.toDouble(), score / 10.0)); // 0.0 ~ 10.0 범위로 정규화 가정
      }
    }

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('인지 훈련 점수 추이', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('월', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                Text('화', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                Text('수', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                Text('목', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                Text('금', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                Text('토', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                Text('일', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISummaryCard(ThemeData theme, UserProvider user) {
    return Card(
      color: theme.primaryColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text('AI 분석 요약', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('다음 주 권고 사항', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...ReportAnalyzer.generateRecommendations(
              currentSteps: context.read<PedometerManager>().todaySteps.toDouble(),
              currentMemory: user.memoryScore,
            ).map((rec) => _buildRecommendationItem(theme, rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// 실제 DB 데이터를 기반으로 리포트 파라미터를 구성합니다.
  Future<Map<String, dynamic>> _buildReportParams(UserProvider user) async {
    final pedometer = context.read<PedometerManager>();
    final weeklySteps = await _dbHelper.getWeeklySteps(
        user.currentUser?['id'] ?? 0);

    final avgSteps = weeklySteps.isNotEmpty
        ? weeklySteps
                .map((e) => (e['steps'] as num).toDouble())
                .reduce((a, b) => a + b) /
            weeklySteps.length
        : pedometer.todaySteps.toDouble();

    final age = user.age ?? 65;
    final birthYear = DateTime.now().year - age;
    final birthDate = '$birthYear-01-01';

    final avgScore = (user.calculationScore + user.logicScore +
            user.memoryScore + user.attentionScore) /
        4.0;
    final mmseScore = (avgScore / 100.0 * 30).clamp(0, 30).toInt();
    final gdsLevel = avgScore >= 70 ? 0 : (avgScore >= 40 ? 1 : 2);

    final dailyData = weeklySteps.map((e) {
      final steps = (e['steps'] as num).toInt();
      return {
        'date': e['date'] ?? '',
        'steps': steps,
        'duration': (steps * 0.5 / 60).toInt(),
        'training_score': avgScore.toInt(),
        'achievement': (steps / 10000 * 100).clamp(0, 100).toInt(),
      };
    }).toList();

    return {
      'userName': user.currentUser?['username'] ?? '사용자',
      'birthDate': birthDate,
      'averageSteps': avgSteps.toInt(),
      'gaitStability': (avgScore / 100.0).clamp(0.0, 1.0),
      'mmseScore': mmseScore,
      'gdsLevel': gdsLevel,
      'dailyRoutineData': dailyData,
    };
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, UserProvider user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final params = await _buildReportParams(user);
            final file = await ClinicalReportGenerator.generateStandardReport(
              userName: params['userName'],
              birthDate: params['birthDate'],
              averageSteps: params['averageSteps'],
              gaitStability: params['gaitStability'],
              mmseScore: params['mmseScore'],
              gdsLevel: params['gdsLevel'],
              dailyRoutineData: List<Map<String, dynamic>>.from(
                  params['dailyRoutineData']),
            );

            if (!context.mounted) return;
            await Share.shareXFiles(
              [XFile(file.path)],
              text: 'MemoryLink AI 분석 리포트입니다.',
            );
          },
          icon: const Icon(Icons.share),
          label: const Text('보호자에게 리포트 공유하기'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final params = await _buildReportParams(user);
            await ClinicalReportGenerator.generateStandardReport(
              userName: params['userName'],
              birthDate: params['birthDate'],
              averageSteps: params['averageSteps'],
              gaitStability: params['gaitStability'],
              mmseScore: params['mmseScore'],
              gdsLevel: params['gdsLevel'],
              dailyRoutineData: List<Map<String, dynamic>>.from(
                  params['dailyRoutineData']),
            );

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('표준 리포트 PDF 파일이 생성되었습니다.')),
            );
          },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('상담용 표준 리포트(PDF) 저장'),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ],
    );
  }
}
