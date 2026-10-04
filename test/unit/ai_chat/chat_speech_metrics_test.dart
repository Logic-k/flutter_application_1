import 'package:flutter_application_1/features/ai_chat/models/chat_message.dart';
import 'package:flutter_application_1/features/ai_chat/models/chat_speech_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChatMessage message(String text, {
    ChatInputSource source = ChatInputSource.voice,
    Duration? duration = const Duration(seconds: 30),
    bool isUser = true,
    DateTime? timestamp,
  }) => ChatMessage(
    text: text, isUser: isUser, timestamp: timestamp ?? DateTime(2026),
    inputSource: source, speechDuration: duration,
  );

  final sixtyWords = List.generate(60, (i) => '단어${i % 30}').join(' ');

  test('60토큰 / 실제 발화 30초 = 120 WPM, 고유 30종 = TTR .5', () {
    final result = ChatSpeechMetrics.fromMessages([message(sixtyWords)]);
    expect(result.totalWords, 60);
    expect(result.ttr, 0.5);
    expect(result.wpm, 120);
    expect(result.speechDurationSeconds, 30);
  });

  test('AI 문장과 사용자 대기 시간은 지표에 포함하지 않는다', () {
    final result = ChatSpeechMetrics.fromMessages([
      message('AI 인사', isUser: false),
      message(sixtyWords, timestamp: DateTime(2026, 1, 1, 1)),
      message('AI의 긴 응답', isUser: false, timestamp: DateTime(2026, 1, 1, 2)),
    ]);
    expect(result.totalWords, 60);
    expect(result.ttr, 0.5);
    expect(result.wpm, 120);
  });

  test('복수 발화의 실제 시간만 합산하며 1초 미만을 버리지 않는다', () {
    final result = ChatSpeechMetrics.fromMessages([
      message('가 나', duration: const Duration(milliseconds: 500)),
      message('다 라', duration: const Duration(milliseconds: 1500)),
    ]);
    expect(result.speechDurationSeconds, 2);
    expect(result.wpm, 120);
  });

  for (final source in [ChatInputSource.typed, ChatInputSource.editedVoice, ChatInputSource.unknown]) {
    test('$source 입력이 섞이면 TTR은 유지하고 WPM은 산출하지 않는다', () {
      final result = ChatSpeechMetrics.fromMessages([
        message('가 나'), message('가 다', source: source),
      ]);
      expect(result.ttr, 0.75);
      expect(result.wpm, isNull);
      expect(result.speechDurationSeconds, isNull);
    });
  }

  for (final duration in [null, Duration.zero, const Duration(seconds: -1)]) {
    test('발화 시간 $duration 은 미측정이다', () {
      final result = ChatSpeechMetrics.fromMessages([message('가 나', duration: duration)]);
      expect(result.ttr, 1);
      expect(result.wpm, isNull);
    });
  }

  test('빈 전사는 지표 0이 아닌 결측이다', () {
    for (final messages in <List<ChatMessage>>[[], [message('  \n ')], [message('AI', isUser: false)]]) {
      final result = ChatSpeechMetrics.fromMessages(messages);
      expect(result.totalWords, 0);
      expect(result.ttr, isNull);
      expect(result.wpm, isNull);
    }
  });

  test('기존 공백 토큰화와 소문자 비교 및 문장부호를 유지한다', () {
    final result = ChatSpeechMetrics.fromMessages([message(' Hello\t hello\nhello! ')]);
    expect(result.totalWords, 3);
    expect(result.ttr, closeTo(2 / 3, 1e-10));
  });
}
