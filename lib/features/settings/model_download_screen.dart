import 'package:flutter/material.dart';

import '../../core/ml_widgets.dart';

/// 온디바이스 AI 안내 화면.
///
/// Gemma 온디바이스 모델(flutter_gemma)과 모델 다운로드는 출시 범위에서 뺐다. 네이티브 라이브러리가
/// 16KB 페이지 기기에서 돌지 않고, 미완 기능이 1.5GB 저장 공간과 외부 토큰을 요구했다
/// (LAUNCH_AUDIT P0-11·P0-10). 경로(/ondevice-ai)는 기존 링크와 라우터 계약 때문에 남긴다.
class ModelDownloadScreen extends StatelessWidget {
  const ModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('온디바이스 AI')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
        children: [
          MLCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이번 버전은 온디바이스 AI 모델을 지원하지 않습니다.', style: textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  'AI 대화는 휴대폰 안의 규칙 기반 응답으로 동작하고, 대화 내용을 밖으로 보내지 않습니다. '
                  '예전에 받아 둔 모델 파일이 있으면 앱이 자동으로 지웠습니다.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
