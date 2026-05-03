import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
            const Text(
              '앱을 어떻게\n활용하고 싶으신가요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildGoalCard(
              OnboardingGoal.prevention,
              '예방 중심',
              '현재 건강하지만 미리 예방하고 싶어요.',
              Icons.health_and_safety,
            ),
            const SizedBox(height: 16),
            _buildGoalCard(
              OnboardingGoal.concern,
              '관심 및 우려',
              '최근 기억력이 걱정되어 확인하고 싶어요.',
              Icons.psychology,
            ),
            const SizedBox(height: 16),
            _buildGoalCard(
              OnboardingGoal.family,
              '가족 관리',
              '부모님이나 가족의 건강을 챙기고 싶어요.',
              Icons.family_restroom,
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

    return InkWell(
      onTap: () => setState(() => _selectedGoal = goal),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
            if (isSelected) Icon(Icons.check_circle, color: theme.primaryColor),
          ],
        ),
      ),
    );
  }
}
