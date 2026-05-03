import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/database_helper.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _db = DatabaseHelper();
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _scores = [];
  List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await _db.getAllUsers();
    final user = users.firstWhere(
      (u) => u['id'] == widget.userId,
      orElse: () => {},
    );
    final scores = await _db.getScoreHistoryForUser(widget.userId);
    final steps = await _db.getWeeklySteps(widget.userId);
    if (mounted) {
      setState(() {
        _user = user.isEmpty ? null : user;
        _scores = scores;
        _steps = steps;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?['username'] as String? ?? '사용자 상세'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileCard(user, theme),
                const SizedBox(height: 16),
                _buildScoreChart(theme),
                const SizedBox(height: 16),
                _buildStepsChart(theme),
              ],
            ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('프로필',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Divider(),
            _infoRow('나이', '${user['age'] ?? '-'}세'),
            _infoRow('목표', _goalLabel(user['goal'] as String?)),
            _infoRow('혈액형', user['blood_type'] as String? ?? '-'),
            _infoRow('비상연락처', user['emergency_contact'] as String? ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 13))),
            Text(value, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );

  String _goalLabel(String? goal) => switch (goal) {
        'prevention' => '예방',
        'concern' => '관리',
        'family' => '가족 지원',
        _ => '-',
      };

  Widget _buildScoreChart(ThemeData theme) {
    const catColors = {
      'calculation': Colors.blue,
      'logic': Colors.purple,
      'memory': Colors.orange,
      'attention': Colors.green,
    };
    final Map<String, List<FlSpot>> lines = {};
    for (int i = 0; i < _scores.length; i++) {
      final row = _scores[i];
      final cat = row['category'] as String? ?? '';
      if (catColors.containsKey(cat)) {
        lines.putIfAbsent(cat, () => [])
            .add(FlSpot(i.toDouble(), (row['score'] as num).toDouble()));
      }
    }

    final bars = catColors.entries
        .where((e) => lines.containsKey(e.key))
        .map((e) => LineChartBarData(
              spots: lines[e.key]!,
              isCurved: true,
              color: e.value,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('인지 점수 이력',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: catColors.entries
                  .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 12, height: 12, color: e.value),
                        const SizedBox(width: 4),
                        Text(_catLabel(e.key),
                            style: const TextStyle(fontSize: 11)),
                      ]))
                  .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: bars.isEmpty
                  ? const Center(
                      child: Text('점수 기록이 없습니다.',
                          style: TextStyle(color: Colors.grey)))
                  : LineChart(LineChartData(
                      lineBarsData: bars,
                      titlesData: const FlTitlesData(
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                    )),
            ),
          ],
        ),
      ),
    );
  }

  String _catLabel(String cat) => switch (cat) {
        'calculation' => '계산',
        'logic' => '논리',
        'memory' => '기억',
        'attention' => '집중',
        _ => cat,
      };

  Widget _buildStepsChart(ThemeData theme) {
    final groups = List.generate(_steps.length, (i) {
      final s = (_steps[i]['steps'] as int? ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: s,
            color: theme.colorScheme.secondary,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 7일 걸음 수',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: groups.isEmpty
                  ? const Center(
                      child: Text('걸음 기록이 없습니다.',
                          style: TextStyle(color: Colors.grey)))
                  : BarChart(BarChartData(
                      barGroups: groups,
                      titlesData: const FlTitlesData(
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                    )),
            ),
          ],
        ),
      ),
    );
  }
}
