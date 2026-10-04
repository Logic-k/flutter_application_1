// ─────────────────────────────────────────────────────────────────────────
// 주 행동 버튼 — 핸드오프 §6.2 · 아키텍처 §4 (DS-005)
//
// 한 화면의 주 행동 1개. 높이 56dp(AppTheme.minTapTarget) 이상, 전체 폭.
//   submitting  busy=true → 비활성 + 진행 문구(liveRegion). 스피너는 반복 애니메이션이라 쓰지 않는다.
//   disabled    onPressed=null → 왜 못 누르는지와 어떻게 하면 되는지를 버튼 아래 글자로.
// 눌림 피드백은 PressableScale(full 확대·fadeOnly 투명도·none 즉시)이 3단을 나눈다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../motion/pressable_scale.dart';
import '../../theme.dart';
import '../foundations/spacing.dart';

class MLPrimaryAction extends StatelessWidget {
  const MLPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel = '처리하는 중이에요',
    this.disabledReason,
  });

  final String label;
  final VoidCallback? onPressed;

  /// 제출 중. 입력은 화면이 그대로 들고 있고, 버튼만 막는다.
  final bool busy;
  final String busyLabel;

  /// onPressed가 null일 때 보일 이유 — "필수 동의 2개를 선택하면 다음으로 갈 수 있어요".
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final showReason = onPressed == null && !busy && disabledReason != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PressableScale(
          enabled: enabled,
          child: FilledButton(
            key: const Key('ml-primary-action'),
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppTheme.minTapTarget),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.rBtn)),
              // 제출 중 문구는 읽어야 하는 상태 메시지라 기본 비활성 회색(38%)으로 흐리지 않는다.
              disabledBackgroundColor: busy ? MLColors.primarySoft : null,
              disabledForegroundColor: busy ? MLColors.primaryDeep : null,
            ),
            // 진행 문구는 버튼 노드 안에서 liveRegion — 버튼 이름이 바뀌는 순간 한 번 읽힌다.
            child: busy
                ? Semantics(
                    liveRegion: true,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.hourglass_top_rounded, size: 20),
                      const SizedBox(width: AppSpacing.controlGap),
                      Flexible(child: Text(busyLabel)),
                    ]),
                  )
                // 비활성 이유는 버튼의 hint로도 읽힌다(아래 글자는 중복 낭독을 막으려 제외).
                : Semantics(hint: showReason ? disabledReason : null, child: Text(label)),
          ),
        ),
        if (showReason) ...[
          const SizedBox(height: AppSpacing.controlGap),
          ExcludeSemantics(
            child: Text(
              disabledReason!,
              key: const Key('ml-primary-action-reason'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}
