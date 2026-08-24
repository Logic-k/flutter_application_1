import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ml_widgets.dart';
import '../../../core/theme.dart';
import '../gait_analyzer.dart';
import '../gait_provider.dart';

/// 걸음 간격 변동성을 재는 세션 카드.
///
/// 이 지표는 **진단이 아니다.** 걸음 간격이 얼마나 고른지를 보는 활동 기록이며,
/// 임상적으로 합의된 절단값이 없다. 그래서 이 카드는 다음을 지킨다.
///
/// - 표본이 목표에 못 미치면 **숫자를 만들지 않고** 진행률만 보여준다.
///   근거 문헌이 요구하는 표본에 못 미치는 값을 보여주면, 사용자는 그것이
///   무엇을 뜻하는지 모른 채 숫자만 기억한다.
/// - '정상/위험' 같은 판정 문구를 쓰지 않는다.
/// - 무엇을 어떻게 쟀는지(표본 수·측정 조건)를 값과 함께 보여준다.
class GaitSessionCard extends StatelessWidget {
  const GaitSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final gait = context.watch<GaitProvider>();

    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MLIconTile(
                icon: Icons.timeline_rounded,
                color: gait.isMeasuring ? MLColors.good : MLColors.sky,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('걸음 간격 살펴보기',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('평소 속도로 1~2분 곧게 걸어 주세요.',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (gait.isMeasuring)
            _MeasuringBody(gait: gait)
          else
            _IdleBody(gait: gait),
          const SizedBox(height: 14),
          Text(
            '이 값은 걸음이 얼마나 고른지를 보는 활동 기록이며 진단이 아닙니다. '
            '평지에서 평소 속도로 걸을 때에만 의미가 있습니다.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasuringBody extends StatelessWidget {
  final GaitProvider gait;

  const _MeasuringBody({required this.gait});

  @override
  Widget build(BuildContext context) {
    final soft = context.scheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${gait.steps}보 걸었어요',
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            Text('${(gait.sampleProgress * 100).round()}%',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: soft)),
          ],
        ),
        const SizedBox(height: 10),
        MLProgressBar(value: gait.sampleProgress, color: MLColors.good),
        const SizedBox(height: 8),
        Text(
          gait.hasEnoughSamples
              ? '충분히 걸으셨어요. 이제 멈추셔도 됩니다.'
              : '조금만 더 걸어 주세요. 걸음이 고른지 보려면 100걸음쯤 필요해요.',
          style: TextStyle(fontSize: 13, color: soft),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => context.read<GaitProvider>().stopMeasurement(),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('측정 마치기'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppTheme.minTapTarget),
          ),
        ),
      ],
    );
  }
}

class _IdleBody extends StatelessWidget {
  final GaitProvider gait;

  const _IdleBody({required this.gait});

  @override
  Widget build(BuildContext context) {
    final soft = context.scheme.onSurfaceVariant;
    final cv = gait.stepIntervalCv;
    final done = gait.lastSummary != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (done) ...[
          if (cv != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(cv.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Text('%', style: TextStyle(fontSize: 16, color: soft)),
              ],
            ),
            const SizedBox(height: 2),
            Text('걸음 간격의 흔들림 (${gait.steps}보 · 표본 ${gait.sampleCount}개)',
                style: TextStyle(fontSize: 13, color: soft)),
          ] else ...[
            // 값을 만들어내지 않는다. 표본이 부족하면 부족하다고 말한다.
            Text('아직 값을 낼 만큼 걷지 않으셨어요',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              '${gait.steps}보 걸으셨습니다. '
              '걸음이 고른지 보려면 ${GaitAnalyzer.minIntervalsForVariability}걸음 정도가 필요해요.',
              style: TextStyle(fontSize: 13, height: 1.45, color: soft),
            ),
          ],
          const SizedBox(height: 14),
        ],
        OutlinedButton.icon(
          onPressed: () => context.read<GaitProvider>().startMeasurement(),
          icon: const Icon(Icons.directions_walk_rounded),
          label: Text(done ? '다시 측정하기' : '측정 시작하기'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppTheme.minTapTarget),
          ),
        ),
      ],
    );
  }
}
