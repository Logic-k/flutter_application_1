import '../../features/ai_chat/models/chat_message.dart';

/// AI 제공자 추상 인터페이스
///
/// Gemini, Claude, 로컬 Fallback 등 어떤 AI 백엔드도
/// 이 인터페이스를 구현하면 AiChatService에 연결할 수 있습니다.
abstract class AiProviderInterface {
  String get providerName;

  /// 메시지를 전송하고 AI 응답 텍스트를 반환합니다.
  /// [history]는 이전 대화 목록 (최신순 아님, 오래된 것부터).
  Future<String> sendMessage(String userMessage, List<ChatMessage> history);

  Future<void> dispose();
}
