import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/motion_settings.dart';
import '../../core/motion/pressable_scale.dart';
import '../../core/motion/staggered_column.dart';
import '../../core/theme.dart';
import '../../core/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingGoal? _selectedGoal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용 목적')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 질문 → 선택지 3장이 순서대로 들어온다(08 계획 G-03, 총 380ms).
            StaggeredColumn(
              playKey: 'onboarding_goal',
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Text(
                    '앱을 어떻게\n활용하고 싶으신가요?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildGoalCard(
                  OnboardingGoal.prevention,
                  '예방 중심',
                  '현재 건강하지만 미리 예방하고 싶어요.',
                  Icons.health_and_safety,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildGoalCard(
                    OnboardingGoal.concern,
                    '관심 및 우려',
                    '최근 기억력이 걱정되어 확인하고 싶어요.',
                    Icons.psychology,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildGoalCard(
                    OnboardingGoal.family,
                    '가족 관리',
                    '부모님이나 가족의 건강을 챙기고 싶어요.',
                    Icons.family_restroom,
                  ),
                ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: _selectedGoal != null
                  ? () {
                      context.read<UserProvider>().setGoal(_selectedGoal!);
                      context.push('/assessment');
                    }
                  : null,
              child: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(OnboardingGoal goal, String title, String description, IconData icon) {
    final isSelected = _selectedGoal == goal;
    final theme = Theme.of(context);
    // 선택 표시는 색·불투명도 변화라 움직임 줄이기(fadeOnly)에서도 남긴다.
    final fade = MotionSettings.levelOf(context) == MotionLevel.none
        ? Duration.zero
        : AppMotion.fade;

    return PressableScale(
      child: InkWell(
      onTap: () => setState(() => _selectedGoal = goal),
      borderRadius: BorderRadius.circular(AppTheme.rTile),
      child: AnimatedContainer(
        duration: fade,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.rTile),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.colorScheme.outlineVariant,
            width: 2,
          ),
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.05) : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: isSelected ? theme.primaryColor : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            // 자리를 늘 차지하게 두고 불투명도만 바꾼다 — 선택할 때 글줄이 밀리지 않는다.
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: fade,
              child: Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                semanticLabel: isSelected ? '선택됨' : null,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
