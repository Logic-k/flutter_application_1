import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'CS 관리',
            onPressed: () => context.push('/admin/cs_management'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await context.read<AdminProvider>().logout();
              if (context.mounted) context.go('/admin_login');
            },
          ),
        ],
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => admin.loadDashboardStats(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCards(admin, theme),
                  const SizedBox(height: 20),
                  _buildAtRiskSection(admin, theme, context),
                  const SizedBox(height: 20),
                  _buildAvgScoreChart(admin, theme),
                  const SizedBox(height: 20),
                  _buildUserList(admin, theme, context),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(AdminProvider admin, ThemeData theme) {
    final items = [
      ('전체 회원', admin.totalUsers, Icons.people_outline),
      ('오늘 활성', admin.dauCount, Icons.today_outlined),
      ('주간 활성', admin.newUsersThisWeek, Icons.trending_up),
    ];
    return Row(
      children: items
          .map((item) => Expanded(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 8),
                    child: Column(
                      children: [
                        Icon(item.$3,
                            color: theme.colorScheme.primary, size: 24),
                        const SizedBox(height: 8),
                        Text('${item.$2}',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item.$1,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.grey),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAtRiskSection(
      AdminProvider admin, ThemeData theme, BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(
          Icons.warning_amber_rounded,
          color: admin.atRiskUsers.isEmpty ? Colors.grey : Colors.red[400],
        ),
        title: Text(
          '위험 사용자 알림 (${admin.atRiskUsers.length})',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        children: admin.atRiskUsers.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('위험 감지된 사용자가 없습니다.',
                      style: TextStyle(color: Colors.grey)),
                ),
              ]
            : admin.atRiskUsers
                .map((u) => ListTile(
                      leading:
                          const Icon(Icons.person_outline, color: Colors.red),
                      title: Text(u['username'] as String? ?? ''),
                      subtitle: Text(
                          '${u['category']} ${u['delta_pct']}%',
                          style: const TextStyle(color: Colors.red)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                          '/admin/user_detail/${u['user_id']}'),
                    ))
                .toList(),
      ),
    );
  }

  Widget _buildAvgScoreChart(AdminProvider admin, ThemeData theme) {
    const categories = [
      'calculation', 'logic', 'memory', 'attention',
      'gait_steps', 'gait_variability'
    ];
    const labels = ['계산', '논리', '기억', '집중', '걸음', '보행'];

    final groups = List.generate(categories.length, (i) {
      final score = admin.avgScores[categories[i]] ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: score,
            color: theme.colorScheme.primary,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('카테고리별 평균 점수',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          labels[value.toInt()],
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(
      AdminProvider admin, ThemeData theme, BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('전체 회원 목록',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (admin.allUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('등록된 회원이 없습니다.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...admin.allUsers.map(
              (u) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    (u['username'] as String? ?? '?')[0].toUpperCase(),
                    style:
                        TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                title: Text(u['username'] as String? ?? ''),
                subtitle: Text('나이: ${u['age'] ?? '-'}세'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/admin/user_detail/${u['id']}'),
              ),
            ),
        ],
      ),
    );
  }
}
