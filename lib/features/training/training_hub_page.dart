import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'difficulty_provider.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';

class TrainingHubScreen extends StatelessWidget {
  const TrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final diffProvider = context.watch<DifficultyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('두뇌 트레이닝 센터')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBanner(diffProvider),
            const SizedBox(height: 24),
            _buildGameCategory(
              context,
              title: '계산 및 판단력',
              accentColor: MLColors.calc,
              games: [
                _GameItem(title: '누가 큰가요?', description: '빠른 수식 비교', icon: Icons.calculate_rounded, color: MLColors.calc, route: '/game/comparison', level: diffProvider.getLevel(GameCategory.calculation)),
                _GameItem(title: '구구단 맞추기', description: '기초 연산 훈련', icon: Icons.grid_3x3_rounded, color: MLColors.calc, route: '/game/multiplication', level: diffProvider.getLevel(GameCategory.calculation)),
              ],
            ),
            const SizedBox(height: 24),
            _buildGameCategory(
              context,
              title: '논리 및 추론',
              accentColor: MLColors.logic,
              games: [
                _GameItem(title: '규칙 찾아보기', description: '수열 패턴 파악', icon: Icons.psychology_rounded, color: MLColors.logic, route: '/game/sequence', level: diffProvider.getLevel(GameCategory.logic)),
              ],
            ),
            const SizedBox(height: 24),
            _buildGameCategory(
              context,
              title: '기억 및 지각',
              accentColor: MLColors.mem,
              games: [
                _GameItem(title: '그림 스도쿠', description: '위치 기억 및 배치', icon: Icons.extension_rounded, color: MLColors.mem, route: '/game/sudoku', level: diffProvider.getLevel(GameCategory.memory)),
                _GameItem(title: '범주화 훈련', description: '기억 구조화 연습', icon: Icons.category_rounded, color: MLColors.mem, route: '/game/categorization', level: diffProvider.getLevel(GameCategory.memory)),
                _GameItem(title: '같은 모양 찾기', description: '순간 포착 능력', icon: Icons.auto_awesome_motion_rounded, color: MLColors.sky, route: '/game/shape_match', level: diffProvider.getLevel(GameCategory.perception)),
              ],
            ),
            const SizedBox(height: 24),
            _buildGameCategory(
              context,
              title: '스마트 케어',
              accentColor: MLColors.care,
              games: [
                _GameItem(title: '일상 회상 훈련', description: '오늘의 기억 떠올리기', icon: Icons.favorite_rounded, color: MLColors.care, route: '/training/recall', level: 1),
                _GameItem(title: '문장 읽기 훈련', description: '소리 내어 정확히 읽기', icon: Icons.record_voice_over_rounded, color: MLColors.read, route: '/game/reading', level: diffProvider.getLevel(GameCategory.perception)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 상단 진행률 히어로 배너 ──────────────────────────────────
  Widget _buildProgressBanner(DifficultyProvider diffProvider) {
    final avgLevel = (
      diffProvider.getLevel(GameCategory.calculation) +
      diffProvider.getLevel(GameCategory.logic) +
      diffProvider.getLevel(GameCategory.memory) +
      diffProvider.getLevel(GameCategory.perception)
    ) / 4.0;
    final overallProgress = ((avgLevel - 1) / 9.0).clamp(0.0, 1.0);
    final progressPercent = (overallProgress * 100).toInt();

    return MLHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('오늘의 인지훈련', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          Text('매일 3가지 게임으로 뇌 건강을 지키세요.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('종합 $progressPercent%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 게임 카테고리 섹션 ───────────────────────────────────────
  Widget _buildGameCategory(
    BuildContext context, {
    required String title,
    required Color accentColor,
    required List<_GameItem> games,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accentColor, width: 4)),
            color: accentColor.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: accentColor)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.80,
          ),
          itemCount: games.length,
          itemBuilder: (context, i) {
            final g = games[i];
            return MLGameCard(
              icon: g.icon,
              color: g.color,
              title: g.title,
              desc: g.description,
              level: g.level,
              onTap: () => context.push(g.route),
            );
          },
        ),
      ],
    );
  }
}

class _GameItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final int level;
  const _GameItem({required this.title, required this.description, required this.icon, required this.color, required this.route, required this.level});
}
