import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../gait_analysis/pedometer_manager.dart';
import '../diary/diary_provider.dart';
import '../../core/ai/ai_chat_service.dart';
import '../../core/user_provider.dart';
import '../../core/database_helper.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _todayTrainingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTodayData());
  }

  Future<void> _loadTodayData() async {
    final userId =
        context.read<UserProvider>().currentUser?['id'] as int?;
    if (userId == null) return;
    await context.read<DiaryProvider>().loadMonth(userId, DateTime.now());
    try {
      final count = await DatabaseHelper().getTodayTrainingCount(userId);
      if (mounted) setState(() => _todayTrainingCount = count);
    } catch (e) {
      debugPrint('오늘 훈련 수 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final pedometer = context.watch<PedometerManager>();
    final todayStr = DateFormat('MM월 dd일 EEEE', 'ko_KR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('MemoryLink', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('알림'),
                  content: const Text('새로운 알림이 없습니다.\n매일 훈련을 완료하면 알림을 받을 수 있습니다.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context, userProvider, pedometer, todayStr),
            const SizedBox(height: 20),
            _buildAiAssistantCard(context),
            const SizedBox(height: 20),
            _buildMemoryGardenCard(context, userProvider, pedometer),
            const SizedBox(height: 20),
            _buildWalkingMiniCard(context, pedometer),
            const SizedBox(height: 20),
            _buildTrainingMotivationChip(),
            MLSectionTitle(
              '오늘의 추천 훈련',
              trailing: TextButton(
                onPressed: () => context.push('/training_hub'),
                child: const Text('전체보기'),
              ),
            ),
            _buildRecommendedTraining(context),
            const SizedBox(height: 20),
            _buildBrainHealthCard(context, userProvider),
          ],
        ),
      ),
    );
  }

  // ─── 헤더 히어로 카드 ──────────────────────────────────────────
  Widget _buildHeaderCard(
    BuildContext context,
    UserProvider userProvider,
    PedometerManager pedometer,
    String todayStr,
  ) {
    final stepProgress = (pedometer.todaySteps / 10000).clamp(0.0, 1.0);
    final stepsFormatted = pedometer.todaySteps
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return MLHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(todayStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '안녕하세요,\n${userProvider.currentUser?['username'] ?? '사용자'}님!',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.3),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildQuickStat(
                icon: Icons.directions_walk_rounded,
                label: '오늘 걸음',
                value: '$stepsFormatted보',
                progress: stepProgress,
              )),
              Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(child: _buildQuickStat(
                icon: Icons.psychology_rounded,
                label: '훈련 현황',
                value: '오늘 $_todayTrainingCount개',
                progress: null,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({required IconData icon, required String label, required String value, double? progress}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
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

  // ─── AI 도우미 카드 ───────────────────────────────────────────
  Widget _buildAiAssistantCard(BuildContext context) {
    final isConnected = AiChatService.isUsingAI;
    return MLCard(
      onTap: () => context.push('/ai_chat'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          MLIconTile(
            icon: isConnected ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
            color: MLColors.sky,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 도우미', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  isConnected ? 'Gemini AI와 인지 대화를 시작해보세요' : 'AI와 대화로 인지 건강을 확인해보세요',
                  style: const TextStyle(fontSize: 13, color: MLColors.textSoft),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: MLColors.textFaint, size: 16),
        ],
      ),
    );
  }

  // ─── 오늘의 일기 카드 ─────────────────────────────────────────
  Widget _buildMemoryGardenCard(BuildContext context, UserProvider user, PedometerManager pedometer) {
    final hasTodayEntry = context.watch<DiaryProvider>().hasEntry(DateTime.now());

    return MLCard(
      onTap: () => context.push('/memory_garden'),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          MLRing(
            value: hasTodayEntry ? 1.0 : 0.0,
            size: 60,
            stroke: 6,
            color: MLColors.mem,
            center: Icon(
              hasTodayEntry ? Icons.check_rounded : Icons.edit_note_rounded,
              color: MLColors.mem,
              size: 22,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('오늘의 일기', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  hasTodayEntry ? '오늘 일기를 작성했어요 ✨' : '오늘 하루를 기록해보세요',
                  style: const TextStyle(color: MLColors.textSoft, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: MLColors.textFaint, size: 16),
        ],
      ),
    );
  }

  // ─── 걷기 미니 카드 ───────────────────────────────────────────
  Widget _buildWalkingMiniCard(BuildContext context, PedometerManager pedometer) {
    return GestureDetector(
      onTap: () => context.push('/walking_dashboard'),
      child: MLHeroCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const MLIconTile(icon: Icons.directions_walk_rounded, color: Colors.white, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘의 걸음', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(
                    '${pedometer.todaySteps} / 10,000 걸음',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── 동기부여 칩 ──────────────────────────────────────────────
  Widget _buildTrainingMotivationChip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: MLColors.read.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MLColors.read.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded, color: MLColors.read, size: 18),
            const SizedBox(width: 6),
            const Text('오늘 2개 훈련이 준비되어 있어요!', style: TextStyle(color: MLColors.read, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── 추천 훈련 ────────────────────────────────────────────────
  Widget _buildRecommendedTraining(BuildContext context) {
    return Column(
      children: [
        _buildTrainingItem(
          context: context,
          title: '누가 큰가요?',
          desc: '수식 비교로 판단력 향상',
          icon: Icons.calculate_rounded,
          color: MLColors.calc,
          onTap: () => context.push('/game/comparison'),
        ),
        const SizedBox(height: 12),
        _buildTrainingItem(
          context: context,
          title: '규칙 찾아보기',
          desc: '수열 패턴으로 논리력 강화',
          icon: Icons.psychology_rounded,
          color: MLColors.logic,
          onTap: () => context.push('/game/sequence'),
        ),
      ],
    );
  }

  Widget _buildTrainingItem({
    required BuildContext context,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MLCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          MLIconTile(icon: icon, color: color, size: 50),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(color: MLColors.textSoft, fontSize: 13)),
              ],
            ),
          ),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              minimumSize: const Size(64, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.rBtn)),
            ),
            child: const Text('시작', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ─── 두뇌 건강 분석 카드 ──────────────────────────────────────
  Widget _buildBrainHealthCard(BuildContext context, UserProvider user) {
    final scores = [
      (label: '기억력', score: user.memoryScore, color: MLColors.mem),
      (label: '집중력', score: user.attentionScore, color: MLColors.sky),
      (label: '계산력', score: user.calculationScore, color: MLColors.calc),
      (label: '논리력', score: user.logicScore, color: MLColors.logic),
    ];

    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MLSectionTitle(
            '두뇌 건강 분석',
            trailing: const Icon(Icons.monitor_heart_outlined, color: MLColors.primary, size: 20),
          ),
          ...scores.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildMetricBar(s.label, s.score, s.color),
          )),
          const SizedBox(height: 4),
          Text(
            user.memoryScore > 0 ? '꾸준한 훈련으로 뇌 건강이 유지되고 있습니다!' : '첫 인지 훈련을 시작해보세요!',
            style: const TextStyle(fontSize: 13, color: MLColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(
              score > 0 ? '${score.toInt()}점' : '미측정',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: score > 0 ? color : MLColors.textFaint),
            ),
          ],
        ),
        const SizedBox(height: 7),
        MLProgressBar(value: score > 0 ? score / 100.0 : 0.0, color: color),
      ],
    );
  }
}
