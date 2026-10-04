// ─────────────────────────────────────────────────────────────────────────
// 비동기 상태 패널 — 핸드오프 §6.1 · 아키텍처 §3.4 (DS-005)
//
// 받은 상태만 그린다. 불러오기·재시도 로직은 화면의 Provider/Service가 그대로 갖는다.
//   loading    무엇을 불러오는지 + 레이아웃 모양의 정적 스켈레톤
//   empty      값이 없는 이유 + 첫 행동
//   error      쉬운 설명 + 다시 시도 또는 대안 (error를 empty로 바꾸지 않는다)
//   content    실제 데이터
//   refreshing content를 그대로 두고 작은 표시만 얹는다(위치를 밀지 않는다)
// 상태 문구는 liveRegion으로 한 번 알린다. 전환은 full·fadeOnly에서 150ms 크로스페이드,
// none에서 즉시. 스피너·shimmer 같은 반복 애니메이션은 쓰지 않는다(DESIGN.md §4).
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../ml_widgets.dart' show MLSkeletonCard;
import '../../motion/app_motion.dart';
import '../../motion/motion_settings.dart';
import '../../theme.dart';
import '../foundations/spacing.dart';

enum MLAsyncStatus { loading, empty, error, content }

class MLAsyncPanel extends StatelessWidget {
  const MLAsyncPanel({
    super.key,
    required this.status,
    required this.loadingLabel,
    required this.emptyMessage,
    required this.child,
    this.skeleton,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.errorMessage = '일시적인 문제로 불러오지 못했어요.',
    this.onRetry,
    this.fallbackLabel,
    this.onFallback,
    this.refreshing = false,
  }) : assert(
         status != MLAsyncStatus.error || onRetry != null || onFallback != null,
         'error 상태는 다시 시도 또는 대안 중 하나가 있어야 한다(핸드오프 §6.1)',
       );

  final MLAsyncStatus status;

  /// 무엇을 불러오는지 — "걸음 기록을 불러오는 중".
  final String loadingLabel;

  /// 실제 레이아웃 모양의 스켈레톤. 없으면 카드 한 장 모양.
  final Widget? skeleton;

  /// 값이 없는 이유 — "아직 오늘 기록이 없어요".
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  /// 사용자에게 보일 쉬운 설명. 예외 문자열·스택을 넣지 않는다.
  final String errorMessage;

  /// 같은 서비스 호출을 다시 부른다. 데이터 의미를 바꾸지 않는다.
  final VoidCallback? onRetry;
  final String? fallbackLabel;
  final VoidCallback? onFallback;

  /// content를 유지한 채 다시 불러오는 중.
  final bool refreshing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration =
        MotionSettings.levelOf(context) == MotionLevel.none ? Duration.zero : AppMotion.fade;
    return AnimatedSwitcher(
      duration: duration,
      // 가운데가 아니라 시작점 정렬 — 폭이 정해진 content가 화면에 옮겨졌을 때 가운데로 모이지 않게.
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(
        key: ValueKey(status),
        child: switch (status) {
          MLAsyncStatus.loading => _Loading(label: loadingLabel, skeleton: skeleton),
          MLAsyncStatus.empty => _Message(
            key: const Key('ml-async-empty'),
            icon: Icons.inbox_outlined,
            message: emptyMessage,
            primaryLabel: emptyActionLabel,
            onPrimary: onEmptyAction,
          ),
          MLAsyncStatus.error => _Message(
            key: const Key('ml-async-error'),
            icon: Icons.cloud_off_outlined,
            message: errorMessage,
            primaryLabel: onRetry == null ? null : '다시 시도',
            onPrimary: onRetry,
            secondaryLabel: fallbackLabel,
            onSecondary: onFallback,
          ),
          MLAsyncStatus.content => _Content(refreshing: refreshing, duration: duration, child: child),
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label, this.skeleton});
  final String label;
  final Widget? skeleton;
  @override
  Widget build(BuildContext context) => Column(
    key: const Key('ml-async-loading'),
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(container: true, liveRegion: true, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
      const SizedBox(height: AppSpacing.itemGap),
      ExcludeSemantics(child: skeleton ?? const MLSkeletonCard(lines: 2)),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });
  final IconData icon;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final hasPrimary = primaryLabel != null && onPrimary != null;
    final hasSecondary = secondaryLabel != null && onSecondary != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sectionGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 48, color: context.scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.itemGap),
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ),
          if (hasPrimary || hasSecondary) const SizedBox(height: AppSpacing.contentGap),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.controlGap,
            runSpacing: AppSpacing.controlGap,
            children: [
              if (hasPrimary)
                FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, AppTheme.minTapTarget)),
                  child: Text(primaryLabel!),
                ),
              if (hasSecondary)
                // 테마 TextButton(primary·14px)은 라벤더 배경 위에서 4.3:1이라 AA 미달이다.
                TextButton(
                  onPressed: onSecondary,
                  style: TextButton.styleFrom(
                    foregroundColor: MLColors.primaryDeep,
                    textStyle: Theme.of(context).textTheme.labelLarge,
                    minimumSize: const Size(0, AppTheme.minTapTarget),
                  ),
                  child: Text(secondaryLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.refreshing, required this.duration, required this.child});
  final bool refreshing;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    key: const Key('ml-async-content'),
    // content가 표시보다 짧아도 표시가 잘리지 않게.
    clipBehavior: Clip.none,
    children: [
      child,
      // 표시는 content 위에 얹는다 — 공간을 새로 잡으면 content가 밀린다.
      Positioned(
        top: 0,
        right: 0,
        child: AnimatedSwitcher(
          duration: duration,
          child: refreshing ? const _RefreshingChip() : const SizedBox.shrink(),
        ),
      ),
    ],
  );
}

class _RefreshingChip extends StatelessWidget {
  const _RefreshingChip();
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: '새로 고치는 중',
    excludeSemantics: true,
    child: Container(
      key: const Key('ml-async-refreshing'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.rChip),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sync_rounded, size: 14, color: context.scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text('새로 고치는 중', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
      ]),
    ),
  );
}
