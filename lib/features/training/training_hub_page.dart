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
            Text(
              '오늘의 추천 운동',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '매일 3가지 게임으로 뇌 건강을 지키세요.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            _buildGameCategory(
              theme,
              title: '계산 및 판단력',
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
            const SizedBox(height: 32),
            _buildGameCategory(
              theme,
              title: '논리 및 추론',
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
            const SizedBox(height: 32),
            _buildGameCategory(
              theme,
              title: '기억 및 지각',
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
            const SizedBox(height: 32),
            _buildGameCategory(
              theme,
              title: '스마트 케어',
              games: [
                _GameItem(
                  title: '일상 회상 훈련',
                  description: '오늘의 기억 떠올리기',
                  icon: Icons.favorite_border,
                  color: _getCategoryColor(theme, Colors.pink),
                  route: '/training/recall',
                  level: 1, // 회상은 고정 레벨 또는 별도 로직
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
          ],
        ),
      ),
    );
  }

  Widget _buildGameCategory(ThemeData theme, {required String title, required List<_GameItem> games}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
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
                    const Spacer(),
                    Text(
                      game.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
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
