enum ChatInputSource { unknown, typed, voice, editedVoice }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatInputSource inputSource;

  /// 실제 사용자 발화 구간의 길이. 청취 제한이나 대화 경과 시간이 아니다.
  final Duration? speechDuration;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.inputSource = ChatInputSource.unknown,
    this.speechDuration,
  });
}
