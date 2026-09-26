import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/motion/burst_particles.dart';
import '../../../core/motion/motion_settings.dart';
import '../../../core/theme.dart';

class TrainingResultSheet extends StatefulWidget {
  const TrainingResultSheet({
    super.key,
    required this.encouragement,
    required this.xpEarned,
    required this.todayCompletedActivities,
    required this.todayGoalActivities,
    required this.masteryStars,
    required this.onContinue,
    this.bestScore,
    this.unlockedActivityName,
    this.celebrate = false,
    this.highlight,
  }) : assert(xpEarned >= 0),
       assert(todayCompletedActivities >= 0),
       assert(todayGoalActivities > 0),
       assert(masteryStars >= 0 && masteryStars <= 3);

  final String encouragement;
  final int xpEarned;
  final int todayCompletedActivities;
  final int todayGoalActivities;
  final int masteryStars;
  final int? bestScore;
  final String? unlockedActivityName;
  final VoidCallback onContinue;

  /// 최고 기록·연속 학습·오늘 목표 달성 순간에만 true. 컨페티를 1회 터뜨린다.
  final bool celebrate;

  /// 축하 이유 한 줄(예: "최고 기록을 넘었어요"). 색·효과 없이도 읽히게 글로 준다.
  final String? highlight;

  @override
  State<TrainingResultSheet> createState() => _TrainingResultSheetState();
}

class _TrainingResultSheetState extends State<TrainingResultSheet>
    with TickerProviderStateMixin {
  // 별 3개가 150ms 간격으로 켜지고, 각 별은 200ms 동안 커지며 나타난다(총 500ms).
  late final AnimationController _stars = AnimationController(
    vsync: this,
    duration: AppMotion.fade * 2 + AppMotion.enter,
  );
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: AppMotion.celebrateMax,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MotionSettings.reduceOf(context)) {
      _stars.value = 1;
      return;
    }
    _stars.forward();
    if (widget.celebrate) _confetti.forward();
  }

  @override
  void dispose() {
    _stars.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MotionSettings.reduceOf(context);
    final bestScore = widget.bestScore;
    final masteryText = bestScore == null
        ? '숙련도 별 ${widget.masteryStars}개'
        : '숙련도 별 ${widget.masteryStars}개 · 최고 $bestScore점';
    final highlight = widget.highlight;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Semantics(
              container: true,
              label: '훈련 결과',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    color: theme.colorScheme.primary,
                    size: 36,
                    semanticLabel: '훈련 완료',
                  ),
                  const SizedBox(height: 8),
                  // 숙련도 별. 같은 정보가 아래 "숙련도 별 N개" 줄에 글로 있으므로
                  // 그림은 접근성 트리에서 뺀다(중복 낭독 방지).
                  ExcludeSemantics(
                    child: _MasteryStars(
                      stars: widget.masteryStars,
                      progress: _stars,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.encouragement,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (highlight != null) ...[
                    const SizedBox(height: 10),
                    Center(child: _HighlightChip(label: highlight)),
                  ],
                  const SizedBox(height: 18),
                  // XP 는 0에서 300ms 동안 올라간다. 글자가 매 프레임 바뀌므로
                  // 스크린리더에는 최종 값만 준다.
                  Semantics(
                    label: '+${widget.xpEarned} XP',
                    excludeSemantics: true,
                    child: TweenAnimationBuilder<int>(
                      tween: IntTween(
                        begin: reduce ? widget.xpEarned : 0,
                        end: widget.xpEarned,
                      ),
                      duration: reduce ? Duration.zero : AppMotion.route,
                      curve: Curves.easeOutCubic,
                      builder: (context, xp, _) =>
                          _ResultRow(icon: Icons.bolt_rounded, label: '+$xp XP'),
                    ),
                  ),
                  _ResultRow(
                    icon: Icons.flag_rounded,
                    label:
                        '오늘 목표 ${widget.todayCompletedActivities}/${widget.todayGoalActivities}',
                  ),
                  _ResultRow(icon: Icons.star_rounded, label: masteryText),
                  if (widget.unlockedActivityName != null) ...[
                    _ResultRow(
                      icon: Icons.lock_open_rounded,
                      label: '새 활동 열림: ${widget.unlockedActivityName}',
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const Key('training-result-continue'),
                      onPressed: widget.onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('계속하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.celebrate && !reduce)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 260,
              child: BurstParticles(
                progress: _confetti,
                // 3색 이내(07 계획 §7-2). 권장안의 primaryContainer·onPrimary 는
                // 흰 시트 위에서 거의 보이지 않아 앰버·민트로 바꿨다.
                colors: [
                  theme.colorScheme.primary,
                  MLColors.read,
                  MLColors.good,
                ],
                count: 48,
                maxRadius: 170,
                gravity: 140,
                seed: 11,
              ),
            ),
        ],
      ),
    );
  }
}

/// 별 3개. 얻은 별은 채워지고 순서대로 켜진다. 못 얻은 별은 윤곽만 남는다.
class _MasteryStars extends StatelessWidget {
  const _MasteryStars({required this.stars, required this.progress});

  final int stars;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final muted = context.scheme.onSurfaceVariant.withValues(alpha: 0.35);
    // 전체 500ms(150×2 + 200) 중 i번째 별은 i×150ms 에 시작해 200ms 동안 커진다.
    final stagger = AppMotion.fade.inMilliseconds;
    final grow = AppMotion.enter.inMilliseconds;
    final total = stagger * 2 + grow;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < stars;
        final scale = progress.drive(
          CurveTween(
            curve: Interval(
              i * stagger / total,
              (i * stagger + grow) / total,
              curve: AppMotion.springOut,
            ),
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ScaleTransition(
            scale: earned ? scale : kAlwaysCompleteAnimation,
            child: Icon(
              earned ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 38,
              color: earned ? MLColors.read : muted,
            ),
          ),
        );
      }),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: context.scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 20,
            color: context.scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
