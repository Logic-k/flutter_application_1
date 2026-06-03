import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/settings_provider.dart';
import '../../../core/theme.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        VoiceService().speakTrainingStart(title);
      });
    }

    final progress = currentStep / totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onExit ?? () => context.pop(),
        ),
        actions: [
          Consumer<DifficultyProvider>(
            builder: (context, difficulty, _) {
              final targetTime = difficulty.getTargetTime(GameCategory.perception);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: MLColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppTheme.rBtn),
                    ),
                    child: Text(
                      '목표: ${targetTime.toStringAsFixed(1)}초',
                      style: const TextStyle(color: MLColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              );
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text('$currentStep / $totalSteps', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 라벤더 진행 바
          LinearProgressIndicator(
            value: progress,
            backgroundColor: MLColors.primary.withValues(alpha: 0.10),
            valueColor: const AlwaysStoppedAnimation<Color>(MLColors.primary),
            minHeight: 6,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  // 목표 카드 (primarySoft 배경)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MLColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppTheme.rTile),
                    ),
                    child: Text(
                      objective,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w700, color: MLColors.primary),
                    ),
                  ),
                  const SizedBox(height: 28),
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
