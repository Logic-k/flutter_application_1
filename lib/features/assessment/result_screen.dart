import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';

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
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '이 결과는 "의학적 진단"이 아니며 관찰 지표일 뿐입니다. 자세한 진단은 전문의와 상담하세요.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                context.go('/');
              },
              child: const Text('홈 화면으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}
