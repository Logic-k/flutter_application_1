import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/settings_provider.dart';
import '../difficulty_provider.dart';

class GameTemplate extends StatelessWidget {
  final String title;
  final String objective;
  final Widget child;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onExit;

  const GameTemplate({
    super.key,
    required this.title,
    required this.objective,
    required this.child,
    required this.currentStep,
    required this.totalSteps,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.voiceGuidanceEnabled) {
      // 빌드 후 한 번만 음성 안내 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        VoiceService().speakTrainingStart(title);
      });
    }
    
    final theme = Theme.of(context);
    final progress = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onExit ?? () => context.pop(),
        ),
        actions: [
          Consumer<DifficultyProvider>(
            builder: (context, difficulty, _) {
              // 현재 상황에 맞는 목표 시간 표시 (지각 영역 예시, 카테고리는 확장 필요)
              final targetTime = difficulty.getTargetTime(GameCategory.perception);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '목표: ${targetTime.toStringAsFixed(1)}초',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Text(
                '$currentStep / $totalSteps',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            minHeight: 6,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      objective,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
