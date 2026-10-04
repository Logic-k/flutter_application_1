import 'chat_message.dart';

class ChatSpeechMetrics {
  final String text;
  final int totalWords;
  final double? ttr;
  final double? speechDurationSeconds;
  final double? wpm;

  const ChatSpeechMetrics._({
    required this.text, required this.totalWords, required this.ttr,
    required this.speechDurationSeconds, required this.wpm,
  });

  factory ChatSpeechMetrics.fromMessages(Iterable<ChatMessage> messages) {
    final userMessages = messages.where((m) => m.isUser).toList();
    final text = userMessages.map((m) => m.text).join(' ');
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final hasTiming = userMessages.isNotEmpty && userMessages.every((m) =>
        m.text.trim().isNotEmpty && m.inputSource == ChatInputSource.voice &&
        m.speechDuration != null && m.speechDuration!.inMicroseconds > 0);
    final seconds = hasTiming ? userMessages.fold<int>(
        0, (sum, m) => sum + m.speechDuration!.inMicroseconds) / 1000000 : null;
    return ChatSpeechMetrics._(
      text: text,
      totalWords: words.length,
      ttr: words.isEmpty ? null : words.map((w) => w.toLowerCase()).toSet().length / words.length,
      speechDurationSeconds: seconds,
      wpm: words.isNotEmpty && seconds != null ? words.length / seconds * 60 : null,
    );
  }
}
