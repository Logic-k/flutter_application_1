import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';
import '../reports/models/clinical_report_data.dart' show MedicalDisclaimer;

class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final score = provider.totalAssessmentScore;
    final theme = Theme.of(context);
    
    String feedback;
    Color scoreColor;

    if (score < 0.3) {
      feedback = '인지 건강이 매우 양호합니다. 꾸준한 루틴으로 유지해보세요!';
      scoreColor = theme.brightness == Brightness.light ? Colors.green.shade700 : Colors.greenAccent.shade400;
    } else if (score < 0.6) {
      feedback = '약간의 주의가 필요합니다. 인지 훈련 빈도를 높이는 것을 권장합니다.';
      scoreColor = theme.brightness == Brightness.light ? Colors.orange.shade800 : Colors.orangeAccent;
    } else {
      feedback = '기억력 저하의 신호가 감지되었습니다. 치매안심센터 방문 상담을 권유드립니다.';
      scoreColor = theme.colorScheme.error;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('검사 결과'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text('현재 나의 인지 건강 상태', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 8),
              ),
              child: Text(
                '${(score * 100).toInt()}%',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: scoreColor),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            // 고지는 점수보다 앞서야 한다는 원칙이지만, 이 화면은 원형 점수가
            // 시선을 먼저 끄는 구조라 바로 아래에 붙여 같은 화면 안에 둔다.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in MedicalDisclaimer.sentences)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 고지에서 "치매안심센터를 찾아가라"고 안내해 놓고 갈 길을 알려주지
            // 않으면 권유가 행동으로 이어지지 않는다. 점수와 무관하게 항상
            // 노출한다 — 점수가 낮을 때만 보여주면 그 자체가 판정 신호가 된다.
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/dementia_centers'),
              icon: const Icon(Icons.place_outlined),
              label: const Text('가까운 치매안심센터 찾기'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                // 초기 평가까지 마쳤으므로 온보딩 완료 처리
                // (라우터가 더 이상 /consent로 리다이렉트하지 않음)
                await context.read<UserProvider>().completeOnboarding();
                if (context.mounted) context.go('/');
              },
              child: const Text('홈 화면으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}
