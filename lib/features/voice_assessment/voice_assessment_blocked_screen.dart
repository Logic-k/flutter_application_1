import 'package:flutter/material.dart';

import '../../core/theme.dart';

class VoiceAssessmentBlockedScreen extends StatelessWidget {
  const VoiceAssessmentBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('음성 진단')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off_rounded, size: 58, color: MLColors.textSoft),
              SizedBox(height: 18),
              Text(
                '현재 사용할 수 없는 기능입니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10),
              Text(
                '정확도 개선이 완료될 때까지 음성 진단 기능을 중지합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MLColors.textSoft,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
