import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/voice_assessment/voice_assessment_blocked_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('음성 진단은 사용 중지 안내만 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: VoiceAssessmentBlockedScreen()),
    );

    expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    expect(find.text('현재 사용할 수 없는 기능입니다'), findsOneWidget);
    expect(find.textContaining('음성 진단 기능을 중지합니다'), findsOneWidget);
  });
}
