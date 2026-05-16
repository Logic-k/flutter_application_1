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
            // 1. 그라디언트 헤더 카드 (인사 + 오늘 현황)
            _buildHeaderCard(context, theme, userProvider, pedometer, todayStr),

            const SizedBox(height: 24),

            // 신규: 오늘의 식단 추천
            const DietRecommendationCard(),

            const SizedBox(height: 24),

            // 2. 기억의 정원 (시각적 성장 시스템)
            _buildMemoryGardenCard(context, theme, userProvider, pedometer),

            const SizedBox(height: 24),

            // 3. 걷기 미니 대시보드
            InkWell(
              onTap: () => context.push('/walking_dashboard'),
              borderRadius: BorderRadius.circular(24),
              child: _buildWalkingMiniCard(context, pedometer, theme),
            ),

            const SizedBox(height: 24),

            // 동기부여 칩
            _buildTrainingMotivationChip(theme),

            // 4. 오늘의 추천 훈련
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
            const SizedBox(height: 12),
            _buildRecommendedTraining(context, theme),

            const SizedBox(height: 24),

            // 5. 두뇌 건강 분석 (진행 바 시각화)
            _buildBrainHealthCard(userProvider, theme),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── 헤더 카드 ───────────────────────────────────────────────
  Widget _buildHeaderCard(
    BuildContext context,
    ThemeData theme,
    UserProvider userProvider,
    PedometerManager pedometer,
    String todayStr,
  ) {
    final stepProgress = (pedometer.todaySteps / 10000).clamp(0.0, 1.0);
    final stepsFormatted = pedometer.todaySteps
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            todayStr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '안녕하세요,\n${userProvider.currentUser?['username'] ?? '사용자'}님!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  icon: Icons.directions_walk,
                  label: '오늘 걸음',
                  value: '$stepsFormatted보',
                  progress: stepProgress,
                ),
              ),
              Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: _buildQuickStat(
                  icon: Icons.psychology,
                  label: '훈련 현황',
                  value: '오늘 2개',
                  progress: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    double? progress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 동기부여 칩 ──────────────────────────────────────────────
  Widget _buildTrainingMotivationChip(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded, color: Colors.orange.shade700, size: 18),
            const SizedBox(width: 6),
            Text(
              '오늘 2개 훈련이 준비되어 있어요!',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 걷기 미니 카드 ───────────────────────────────────────────
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

  // ─── 추천 훈련 ────────────────────────────────────────────────
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
            FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                minimumSize: const Size(72, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('시작', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 두뇌 건강 분석 카드 (진행 바) ───────────────────────────
  Widget _buildBrainHealthCard(UserProvider user, ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;
    final scores = [
      (label: '기억력', score: user.memoryScore, color: isLight ? Colors.orange.shade600 : Colors.orangeAccent),
      (label: '집중력', score: user.attentionScore, color: isLight ? Colors.blue.shade600 : Colors.blueAccent),
      (label: '계산력', score: user.calculationScore, color: isLight ? Colors.green.shade600 : Colors.greenAccent),
      (label: '논리력', score: user.logicScore, color: isLight ? Colors.purple.shade600 : Colors.purpleAccent),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                '두뇌 건강 분석',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...scores.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildMetricBar(theme, s.label, s.score, s.color),
              )),
          const SizedBox(height: 4),
          Text(
            user.memoryScore > 0
                ? '꾸준한 훈련으로 뇌 건강이 유지되고 있습니다!'
                : '첫 인지 훈련을 시작해보세요!',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(ThemeData theme, String label, double score, Color color) {
    final double progress = (score / 100.0).clamp(0.0, 1.0);
    final int displayScore = score.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              score > 0 ? '$displayScore점' : '미측정',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: score > 0 ? color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score > 0 ? progress : 0.0,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  // ─── 기억의 정원 카드 ─────────────────────────────────────────
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
