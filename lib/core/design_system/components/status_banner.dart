// ─────────────────────────────────────────────────────────────────────────
// 상태 배너 — 핸드오프 §6 · 아키텍처 §3.6 (DS-005)
//
// status = 아이콘 + 라벨 글자 + 짧은 뜻. 색만으로 상태를 전하지 않는다.
// 신호등 면 색(good·warn·bad)은 배경 틴트에만 쓰고, 글자·아이콘은 글자 전용 토큰을 쓴다.
// 오류·면책·도움말 같은 support 역할의 문구가 여기에 들어간다. 모션은 없다
// (배너를 넣고 빼는 전환은 부모가 MLAsyncPanel 등으로 정한다).
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../theme.dart';
import '../foundations/spacing.dart';

enum MLStatusTone { info, success, warning, danger }

class MLStatusBanner extends StatelessWidget {
  const MLStatusBanner({
    super.key,
    required this.tone,
    required this.message,
    this.label,
    this.actionLabel,
    this.onAction,
    this.announce = false,
  });

  final MLStatusTone tone;

  /// 짧은 뜻 — "오늘 걸음 기록을 아직 저장하지 못했어요."
  final String message;

  /// 라벨 글자. 없으면 tone 기본값(안내·완료·주의·확인 필요).
  final String? label;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// true면 나타날 때 스크린리더가 한 번 읽는다(오류·저장 결과).
  final bool announce;

  static String defaultLabelOf(MLStatusTone tone) => switch (tone) {
    MLStatusTone.info => '안내',
    MLStatusTone.success => '완료',
    MLStatusTone.warning => '주의',
    MLStatusTone.danger => '확인 필요',
  };

  /// 글자·아이콘 색. 면 색(good·warn·bad)이 아니라 글자 전용 토큰이다.
  static Color inkOf(MLStatusTone tone) => switch (tone) {
    MLStatusTone.info => MLColors.primaryDeep,
    MLStatusTone.success => MLColors.goodText,
    MLStatusTone.warning => MLColors.warnText,
    MLStatusTone.danger => MLColors.badText,
  };

  static Color _faceOf(MLStatusTone tone) => switch (tone) {
    MLStatusTone.info => MLColors.primarySoft,
    MLStatusTone.success => MLColors.good.withValues(alpha: 0.12),
    MLStatusTone.warning => MLColors.warn.withValues(alpha: 0.14),
    MLStatusTone.danger => MLColors.bad.withValues(alpha: 0.10),
  };

  static IconData _iconOf(MLStatusTone tone) => switch (tone) {
    MLStatusTone.info => Icons.info_outline_rounded,
    MLStatusTone.success => Icons.check_circle_outline_rounded,
    MLStatusTone.warning => Icons.warning_amber_rounded,
    MLStatusTone.danger => Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final ink = inkOf(tone);
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: announce,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.contentGap),
        decoration: BoxDecoration(
          color: _faceOf(tone),
          borderRadius: BorderRadius.circular(AppTheme.rTile),
          border: Border.all(color: ink.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(_iconOf(tone), color: ink, size: 22)),
            const SizedBox(width: AppSpacing.controlGap + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label ?? defaultLabelOf(tone), style: text.bodySmall?.copyWith(color: ink, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(message, style: text.bodyLarge),
                  if (actionLabel != null && onAction != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: ink,
                          textStyle: text.labelLarge,
                          minimumSize: const Size(0, AppTheme.minTapTarget),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(actionLabel!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
