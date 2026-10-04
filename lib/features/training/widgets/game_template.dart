import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/burst_particles.dart';
import '../../../core/motion/game_feedback.dart';
import '../../../core/motion/motion_settings.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/settings_provider.dart';
import '../../../core/theme.dart';
import '../application/training_completion_ui.dart';
import '../difficulty_provider.dart';

class GameTemplate extends StatefulWidget {
  final String title;
  final String objective;
  final Widget child;
  final int currentStep;
  final int totalSteps;
  final GameCategory? adaptiveCategory;
  final VoidCallback? onExit;

  /// 활동 ID. 주면 목표 카드 왼쪽에 활동 아이콘을 그리고, 허브 코스 노드에서
  /// 이 아이콘으로 이어지는 공유 요소 전환(Hero)이 생긴다.
  final String? activityId;

  /// 게임이 정답·오답을 알리는 통로. 없으면 피드백 계층 없이 예전처럼 그린다.
  final GameFeedbackController? feedback;

  const GameTemplate({
    super.key,
    required this.title,
    required this.objective,
    required this.child,
    required this.currentStep,
    required this.totalSteps,
    this.adaptiveCategory,
    this.onExit,
    this.feedback,
    this.activityId,
  });

  @override
  State<GameTemplate> createState() => _GameTemplateState();
}

class _GameTemplateState extends State<GameTemplate>
    with TickerProviderStateMixin {
  // 배지: 150ms 나타남 → 1.4초 머묾 → 150ms 사라짐.
  late final AnimationController _badge = AnimationController(
    vsync: this,
    duration: AppMotion.fade * 2 + AppMotion.feedbackHold,
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: AppMotion.burst,
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: AppMotion.fade,
  );
  late final Animation<double> _badgeOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 150),
    TweenSequenceItem(tween: ConstantTween(1), weight: 1400),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 150),
  ]).animate(_badge);

  GameFeedbackEvent? _shown;

  @override
  void initState() {
    super.initState();
    widget.feedback?.addListener(_onFeedback);
    _badge.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _shown = null);
      }
    });
    // 시작 안내는 게임 진입 시 1회만 발화한다.
    // (build에서 호출하면 문제를 풀 때마다 리빌드되어 반복 발화됨)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<SettingsProvider>().voiceGuidanceEnabled) {
        VoiceService().speakTrainingStart(widget.title);
      }
    });
  }

  @override
  void didUpdateWidget(GameTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedback != widget.feedback) {
      oldWidget.feedback?.removeListener(_onFeedback);
      widget.feedback?.addListener(_onFeedback);
    }
  }

  @override
  void dispose() {
    widget.feedback?.removeListener(_onFeedback);
    _badge.dispose();
    _burst.dispose();
    _shake.dispose();
    super.dispose();
  }

  /// 눈(배지·파티클·흔들림) + 손(햅틱) + 귀(효과음) 세 겹으로 한 번에 알린다.
  /// 고령자 포인팅 성능은 오디오+촉각 조건에서 가장 높았다(07 계획 §1.3).
  void _onFeedback() {
    final event = widget.feedback?.event;
    if (event == null || !mounted) return;
    final correct = event.kind == GameFeedbackKind.correct;
    final reduce = MotionSettings.reduceOf(context, listen: false);

    if (context.read<SettingsProvider>().hapticFeedbackEnabled) {
      unawaited(
        (correct ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact())
            .catchError((Object _) {}),
      );
    }
    unawaited(
      correct
          ? SoundService.instance.playCorrect()
          : SoundService.instance.playWrong(),
    );

    setState(() => _shown = event);
    _badge.forward(from: 0);
    if (reduce) return;
    if (correct) {
      _burst.forward(from: 0);
    } else {
      _shake.forward(from: 0);
    }
  }

  Widget _objectiveContent(BuildContext context, String objective) {
    final text = Text(
      objective,
      textAlign: widget.activityId == null ? TextAlign.center : TextAlign.start,
      style: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w700, color: context.scheme.onPrimaryContainer),
    );
    final id = widget.activityId;
    if (id == null) return text;
    // 허브 코스 노드의 아이콘 타일(52dp)이 날아와 이 자리(44dp)에 앉는다.
    return Row(
      children: [
        Hero(
          tag: trainingActivityHeroTag(id),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.rChip),
            ),
            child: Icon(trainingActivityIcon(id), color: context.scheme.primary, size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final objective = widget.objective;
    final currentStep = widget.currentStep;
    final totalSteps = widget.totalSteps;
    final adaptiveCategory = widget.adaptiveCategory;
    final onExit = widget.onExit;
    final child = widget.child;

    final progress = currentStep / totalSteps;
    final level = MotionSettings.levelOf(context);
    // 이동·확대·파티클은 full 에서만. 배지 페이드는 불투명도 변화라 fadeOnly 에서도 남긴다.
    final reduce = level != MotionLevel.full;
    final shown = _shown;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          // tooltip이 없으면 TalkBack이 이 버튼을 "버튼"이라고만 읽는다.
          // Flutter는 tooltip을 그대로 Semantics label로 노출한다.
          tooltip: '훈련 그만두기',
          onPressed: onExit ?? () => context.pop(),
        ),
        actions: [
          if (adaptiveCategory != null)
            Consumer<DifficultyProvider>(
              builder: (context, difficulty, _) {
                final targetTime = difficulty.getTargetTime(adaptiveCategory);
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: context.scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.rBtn),
                      ),
                      child: Text(
                        '목표: ${targetTime.toStringAsFixed(1)}초',
                        style: TextStyle(
                          // primary(#6C5CE7)를 primaryContainer 위에 얹으면
                          // 3.77:1로 AA에 못 미친다. 같은 계열의 더 어두운 값을 쓴다.
                          color: context.scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
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
      body: Stack(
        children: [
          Column(
            children: [
              // 라벤더 진행 바. 문항이 넘어갈 때 값이 점프하지 않고 200ms 동안 차오른다.
              // 처음 그릴 때는 begin 이 없어 애니메이션 없이 곧바로 현재 값이다.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress),
                duration: reduce ? Duration.zero : AppMotion.enter,
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: context.scheme.primary.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(context.scheme.primary),
                  minHeight: 6,
                ),
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
                          color: context.scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppTheme.rTile),
                        ),
                        child: _objectiveContent(context, objective),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        // 오답이면 놀이 영역이 좌우로 ±4px 두 번 흔들린다.
                        child: AnimatedBuilder(
                          animation: _shake,
                          child: child,
                          builder: (context, child) {
                            final t = _shake.value;
                            final dx = t == 0 || t == 1
                                ? 0.0
                                : math.sin(t * 4 * math.pi) * 4 * (1 - t);
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (shown != null) ...[
            if (shown.kind == GameFeedbackKind.correct && !reduce)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 150,
                child: BurstParticles(
                  progress: _burst,
                  colors: [MLColors.good, context.scheme.primary, MLColors.read],
                ),
              ),
            Positioned(
              top: 40,
              left: 24,
              right: 24,
              child: IgnorePointer(
                child: Center(
                  child: FadeTransition(
                    opacity: level == MotionLevel.none
                        ? kAlwaysCompleteAnimation
                        : _badgeOpacity,
                    child: _FeedbackBadge(
                      key: ValueKey('game-feedback-${shown.serial}'),
                      event: shown,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 정답·오답 배지. 색 + 아이콘 + 문구 세 겹(DESIGN.md §5).
/// 흰 글자는 goodText 4.84:1, badText 5.62:1 로 AA 를 넘는다.
class _FeedbackBadge extends StatelessWidget {
  const _FeedbackBadge({super.key, required this.event});

  final GameFeedbackEvent event;

  @override
  Widget build(BuildContext context) {
    final correct = event.kind == GameFeedbackKind.correct;
    final color = correct ? MLColors.goodText : MLColors.badText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.rPill),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              event.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
