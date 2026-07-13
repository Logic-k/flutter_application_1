import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../features/ai_chat/models/chat_message.dart';
import 'ai_provider_interface.dart';
import 'model_download_service.dart';

class ModelNotReadyException implements Exception {
  const ModelNotReadyException();

  @override
  String toString() => '온디바이스 모델이 준비되지 않았습니다. 설정에서 모델을 다운로드해 주세요.';
}

class GemmaLocalProvider implements AiProviderInterface {
  bool _initialized = false;

  @override
  String get providerName => '온디바이스 Gemma';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final path = await ModelDownloadService.modelPath;
    await FlutterGemmaPlugin.instance.init(
      modelPath: path,
      maxTokens: 512,
      temperature: 0.8,
      topK: 40,
    );
    _initialized = true;
    debugPrint('[GemmaLocalProvider] 모델 로드 완료: $path');
  }

  @override
  Future<String> sendMessage(
    String userMessage,
    List<ChatMessage> history,
  ) async {
    final ready = await ModelDownloadService.isModelReady();
    if (!ready) throw const ModelNotReadyException();

    await _ensureInitialized();

    final messages = [
      ...history.map(
        (m) => Message(text: m.text, isUser: m.isUser),
      ),
      Message(text: userMessage, isUser: true),
    ];

    final response = await FlutterGemmaPlugin.instance.getChatResponse(
      messages: messages,
      chatContextLength: 6,
    );
    return response ?? '(응답 없음)';
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
