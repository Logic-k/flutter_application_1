import 'ai_provider_interface.dart';
import '../../features/ai_chat/models/chat_message.dart';

/// 오프라인 / API 키 없을 때 사용하는 로컬 Fallback 제공자.
///
/// 미리 정의된 질문 배열에서 순서대로 응답합니다.
/// 인터넷 없이도 기본 대화 흐름을 유지합니다.
class LocalFallbackProvider implements AiProviderInterface {
  int _turnIndex = 0;

  static const _questions = [
    '안녕하세요! 오늘 기분은 어떠세요? 오늘 하루 어떻게 보내고 계신가요?',
    '좋으시군요! 최근에 맛있게 드신 음식이 있으셨나요? 어떤 음식이었는지 이야기해 주세요.',
    '맛있겠네요! 요즘 즐겨 보시는 TV 프로그램이나 좋아하는 취미가 있으신가요?',
    '그렇군요! 가장 기억에 남는 여행이나 나들이 경험이 있으시면 이야기해 주세요.',
    '정말 좋은 기억이네요! 오늘 대화 잘 하셨어요. 앞으로도 건강하게 지내세요! 😊',
  ];

  @override
  String get providerName => 'LocalFallback';

  @override
  Future<String> sendMessage(String userMessage, List<ChatMessage> history) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final response = _questions[_turnIndex.clamp(0, _questions.length - 1)];
    if (_turnIndex < _questions.length - 1) _turnIndex++;
    return response;
  }

  @override
  Future<void> dispose() async {
    _turnIndex = 0;
  }
}
