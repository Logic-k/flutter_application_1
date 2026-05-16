import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'difficulty_provider.dart';

class TrainingHubScreen extends StatelessWidget {
  const TrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diffProvider = context.watch<DifficultyProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('두뇌 트레이닝 센터'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 진행률 배너
            _buildProgressBanner(context, theme, diffProvider),
            const SizedBox(height: 28),
            _buildGameCategory(
              theme,
              title: '계산 및 판단력',
              accentColor: _getCategoryColor(theme, Colors.blue),
              games: [
                _GameItem(
                  title: '누가 큰가요?',
                  description: '빠른 수식 비교',
                  icon: Icons.calculate_outlined,
                  color: _getCategoryColor(theme, Colors.blue),
                  route: '/game/comparison',
                  level: diffProvider.getLevel(GameCategory.calculation),
                ),
                _GameItem(
                  title: '구구단 맞추기',
                  description: '기초 연산 훈련',
                  icon: Icons.grid_3x3,
                  color: _getCategoryColor(theme, Colors.orange),
                  route: '/game/multiplication',
                  level: diffProvider.getLevel(GameCategory.calculation),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildGameCategory(
              theme,
              title: '논리 및 추론',
              accentColor: _getCategoryColor(theme, Colors.purple),
              games: [
                _GameItem(
                  title: '규칙 찾아보기',
                  description: '수열 패턴 파악',
                  icon: Icons.psychology_outlined,
                  color: _getCategoryColor(theme, Colors.purple),
                  route: '/game/sequence',
                  level: diffProvider.getLevel(GameCategory.logic),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildGameCategory(
              theme,
              title: '기억 및 지각',
              accentColor: _getCategoryColor(theme, Colors.teal),
              games: [
                _GameItem(
                  title: '그림 스도쿠',
                  description: '위치 기억 및 배치',
                  icon: Icons.extension_outlined,
                  color: _getCategoryColor(theme, Colors.teal),
                  route: '/game/sudoku',
                  level: diffProvider.getLevel(GameCategory.memory),
                ),
                _GameItem(
                  title: '범주화 훈련',
                  description: '기억 구조화 연습',
                  icon: Icons.category_outlined,
                  color: _getCategoryColor(theme, Colors.indigo),
                  route: '/game/categorization',
                  level: diffProvider.getLevel(GameCategory.memory),
                ),
                _GameItem(
                  title: '같은 모양 찾기',
                  description: '순간 포착 능력',
                  icon: Icons.auto_awesome_motion_outlined,
                  color: _getCategoryColor(theme, Colors.red),
                  route: '/game/shape_match',
                  level: diffProvider.getLevel(GameCategory.perception),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildGameCategory(
              theme,
              title: '스마트 케어',
              accentColor: _getCategoryColor(theme, Colors.pink),
              games: [
                _GameItem(
                  title: '일상 회상 훈련',
                  description: '오늘의 기억 떠올리기',
                  icon: Icons.favorite_border,
                  color: _getCategoryColor(theme, Colors.pink),
                  route: '/training/recall',
                  level: 1,
                ),
                _GameItem(
                  title: '문장 읽기 훈련',
                  description: '소리 내어 정확히 읽기',
                  icon: Icons.record_voice_over_outlined,
                  color: _getCategoryColor(theme, Colors.orange),
                  route: '/game/reading',
                  level: diffProvider.getLevel(GameCategory.perception),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── 상단 진행률 배너 ─────────────────────────────────────────
  Widget _buildProgressBanner(BuildContext context, ThemeData theme, DifficultyProvider diffProvider) {
    final avgLevel = (
      diffProvider.getLevel(GameCategory.calculation) +
      diffProvider.getLevel(GameCategory.logic) +
      diffProvider.getLevel(GameCategory.memory) +
      diffProvider.getLevel(GameCategory.perception)
    ) / 4.0;

    final overallProgress = ((avgLevel - 1) / 9.0).clamp(0.0, 1.0);
    final progressPercent = (overallProgress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                '오늘의 인지훈련',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '매일 3가지 게임으로 뇌 건강을 지키세요.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
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
              Text(
                '종합 $progressPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 게임 카테고리 섹션 ───────────────────────────────────────
  Widget _buildGameCategory(
    ThemeData theme, {
    required String title,
    required List<_GameItem> games,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 색상 왼쪽 테두리 카테고리 헤더
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
            ),
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.80,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return InkWell(
              onTap: () => context.push(game.route),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: theme.brightness == Brightness.light ? 0.05 : 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 아이콘 + 레벨 배지 행
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: game.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(game.icon, color: game.color, size: 28),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Lv.${game.level}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 제목
                    Text(
                      game.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // 설명
                    Text(
                      game.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 레벨 진행 바
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: game.level / 10.0,
                              backgroundColor: game.color.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(game.color),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(game.level / 10.0 * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: game.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getCategoryColor(ThemeData theme, Color baseColor) {
    if (theme.brightness == Brightness.light) {
      return baseColor.withValues(alpha: 0.8);
    } else {
      return Color.lerp(baseColor, Colors.white, 0.4)!;
    }
  }
}

class _GameItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final int level;

  _GameItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    required this.level,
  });
}
