import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../gait_analysis/pedometer_manager.dart';
import '../../core/user_provider.dart';
import 'widgets/diet_recommendation_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final pedometer = context.watch<PedometerManager>();
    final todayStr = DateFormat('MM월 dd일 EEEE', 'ko_KR').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text('MemoryLink', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('알림'),
                  content: const Text('새로운 알림이 없습니다.\n매일 훈련을 완료하면 알림을 받을 수 있습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 인사말 및 날짜
            Text(todayStr, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '안녕하세요, ${userProvider.currentUser?['username'] ?? '사용자'}님!\n오늘도 뇌 건강을 챙겨볼까요?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            
            // 신규: 오늘의 식단 추천
            const DietRecommendationCard(),
            
            const SizedBox(height: 32),
            
            // 2. 기억의 정원 (시각적 성장 시스템)
            _buildMemoryGardenCard(context, theme, userProvider, pedometer),
            
            const SizedBox(height: 32),
            
            // 3. 걷기 미니 대시보드
            InkWell(
              onTap: () => context.push('/walking_dashboard'),
              borderRadius: BorderRadius.circular(24),
              child: _buildWalkingMiniCard(context, pedometer, theme),
            ),
            
            const SizedBox(height: 32),
            
            // 3. 오늘의 추천 훈련
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '오늘의 추천 훈련',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push('/training_hub'),
                  child: const Text('전체보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendedTraining(context, theme),
            
            const SizedBox(height: 32),
            
            // 4. 두뇌 건강 분석
            Text(
              '두뇌 건강 분석',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildReportSummaryCard(userProvider, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkingMiniCard(BuildContext context, PedometerManager pedometer, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withValues(alpha: 0.8), theme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.directions_walk, color: theme.colorScheme.onPrimary, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘의 걸음', style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.7), fontSize: 14)),
                Text(
                  '${pedometer.todaySteps} / 10,000 걸음',
                  style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onPrimary, size: 16),
        ],
      ),
    );
  }

  Widget _buildRecommendedTraining(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildTrainingItem(
          theme: theme,
          title: '누가 큰가요?',
          desc: '수식 비교로 판단력 향상',
          icon: Icons.calculate_outlined,
          color: theme.brightness == Brightness.light ? Colors.blue.shade700 : Colors.blueAccent,
          onTap: () => context.push('/game/comparison'),
        ),
        const SizedBox(height: 12),
        _buildTrainingItem(
          theme: theme,
          title: '규칙 찾아보기',
          desc: '수열 패턴으로 논리력 강화',
          icon: Icons.psychology_outlined,
          color: theme.brightness == Brightness.light ? Colors.purple.shade700 : Colors.purpleAccent,
          onTap: () => context.push('/game/sequence'),
        ),
      ],
    );
  }

  Widget _buildTrainingItem({
    required ThemeData theme,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  desc,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 28),
        ],
      ),
    );
  }

  Widget _buildReportSummaryCard(UserProvider user, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(theme, '기억력', user.memoryScore.toInt().toString(), theme.brightness == Brightness.light ? Colors.orange.shade700 : Colors.orangeAccent),
              _buildMetric(theme, '집중력', user.attentionScore.toInt().toString(), theme.brightness == Brightness.light ? Colors.blue.shade700 : Colors.blueAccent),
              _buildMetric(theme, '계산력', user.calculationScore.toInt().toString(), theme.brightness == Brightness.light ? Colors.green.shade700 : Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user.memoryScore > 0 ? '꾸준한 훈련으로 뇌 건강이 유지되고 있습니다!' : '첫 고인지 훈련을 시작해보세요!',
            style: TextStyle(fontSize: 14, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(ThemeData theme, String label, String score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(score, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMemoryGardenCard(BuildContext context, ThemeData theme, UserProvider user, PedometerManager pedometer) {
    double stepProgress = (pedometer.todaySteps / 10000).clamp(0.0, 1.0);
    double cognitiveProgress = ((user.calculationScore + user.logicScore + user.memoryScore + user.attentionScore) / 400.0).clamp(0.0, 1.0);
    double totalProgress = (stepProgress + cognitiveProgress) / 2.0;

    return InkWell(
      onTap: () => context.push('/memory_garden'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: totalProgress,
                    strokeWidth: 6,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ),
                Icon(Icons.local_florist, color: theme.primaryColor, size: 28),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('나의 기억의 정원', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    totalProgress >= 0.8 ? '정원이 활기차게 피어났습니다!' : '정성과 노력으로 정원을 가꾸어보세요',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
}
