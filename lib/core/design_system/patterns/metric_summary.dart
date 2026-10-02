// ─────────────────────────────────────────────────────────────────────────
// 지표 요약 — 핸드오프 §6 · 아키텍처 §3.6 (DS-005)
//
// metric = 라벨 + 값 + 단위 + 해석 + 측정 시각/출처.
// 값 없음(null)은 "측정되지 않음"이고 0은 실제 0이다(DESIGN.md §6.4). 숫자는 tabular figures.
// 데이터 역할이라 값이 튀거나 넘치는 모션(overshoot)을 쓰지 않는다 — 이 위젯은 정지 상태만 그린다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../foundations/spacing.dart';

class MLMetricSummary extends StatelessWidget {
  const MLMetricSummary({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.interpretation,
    this.source,
    this.missingText = '측정되지 않음',
  });

  final String label;

  /// 화면이 이미 포맷한 값("3,500"). null이면 측정 없음 — 0으로 바꾸지 않는다.
  final String? value;
  final String unit;

  /// 숫자의 뜻 — "평소보다 조금 적어요".
  final String? interpretation;

  /// 측정 시각·출처 — "오늘 14:05 · 걸음 센서".
  final String? source;
  final String missingText;

  String get _spoken => [
    value == null ? '$label $missingText' : '$label $value$unit',
    ?interpretation,
    ?source,
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: _spoken,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(height: 4),
          if (value == null)
            Text(missingText, key: const Key('ml-metric-missing'), style: text.bodyLarge)
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 4,
              children: [
                Text(
                  value!,
                  key: const Key('ml-metric-value'),
                  style: text.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                Text(unit, style: text.bodyMedium),
              ],
            ),
          if (interpretation != null) ...[
            const SizedBox(height: AppSpacing.controlGap),
            Text(interpretation!, style: text.bodyLarge),
          ],
          if (source != null) ...[
            const SizedBox(height: 4),
            Text(source!, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}
