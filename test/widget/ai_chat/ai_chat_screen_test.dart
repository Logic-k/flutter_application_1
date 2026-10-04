import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/ai/ai_chat_service.dart';
import 'package:flutter_application_1/core/ai/ai_provider_interface.dart';
import 'package:flutter_application_1/core/ai/local_fallback_provider.dart';
import 'package:flutter_application_1/features/ai_chat/ai_chat_screen.dart';
import 'package:flutter_application_1/features/ai_chat/models/chat_message.dart';
import '../../helpers/mock_definitions.dart';
import '../../helpers/test_helpers.dart';

class _ChatProvider implements AiProviderInterface {
  final histories = <List<ChatMessage>>[];
  Completer<String>? pendingReply;

  @override
  String get providerName => 'Widget test';

  @override
  Future<String> sendMessage(String userMessage, List<ChatMessage> history) async {
    histories.add(List.of(history));
    if (history.isEmpty) return '오늘은 어떤 하루였나요?';
    return pendingReply?.future ?? Future.value('이야기해 주셔서 감사합니다.');
  }

  @override
  Future<void> dispose() async {}
}

const _speechChannel = MethodChannel('plugin.csdcorp.com/speech_to_text');

Future<void> _recognize(WidgetTester tester, String words) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    _speechChannel.name,
    _speechChannel.codec.encodeMethodCall(MethodCall('textRecognition', jsonEncode({
      'alternates': [{'recognizedWords': words, 'confidence': 0.9}],
      'finalResult': false,
    }))),
    (_) {},
  );
  await tester.pump();
}

Future<void> _closeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // SpeechToText.stop schedules its final-result timeout during dispose.
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ChatProvider provider;
  late MockUserProvider user;
  late List<MethodCall> speechCalls;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = _ChatProvider();
    user = MockUserProvider();
    speechCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_speechChannel, (call) async {
      speechCalls.add(call);
      return switch (call.method) {
        'initialize' || 'has_permission' || 'listen' => true,
        'locales' => <String>['ko_KR:한국어'],
        _ => null,
      };
    });
    await AiChatService.setProvider(provider);
  });

  tearDown(() async {
    await AiChatService.setProvider(LocalFallbackProvider());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_speechChannel, null);
  });

  Future<void> openScreen(WidgetTester tester) async {
    await pumpWithProviders(tester, const AiChatScreen(), userProvider: user);
    await tester.pumpAndSettle();
    expect(find.text('오늘은 어떤 하루였나요?'), findsOneWidget);
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.send));
    await tester.pumpAndSettle();
  }

  Future<void> expectUnavailableResult(WidgetTester tester) async {
    await tester.tap(find.text('대화 종료'));
    await tester.pumpAndSettle();

    expect(find.text('종합 점수: 측정 불가'), findsOneWidget);
    expect(find.textContaining('발화 속도(WPM): 측정 불가'), findsOneWidget);
    expect(find.textContaining('휴지 비율: 측정 불가'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, '결과 저장하기');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.tap(save);
    await tester.pump();
    verifyNever(() => user.setCognitiveScore(any(), any()));
  }

  testWidgets('직접 입력의 TTR은 표시하지만 음성 점수를 저장하지 않는다', (tester) async {
    await openScreen(tester);
    await tester.enterText(find.byType(TextField), '오늘 오늘 산책했다');
    await send(tester);

    final message = provider.histories.last.where((m) => m.isUser).single;
    expect(message.text, '오늘 오늘 산책했다');
    expect(message.inputSource, ChatInputSource.typed);
    expect(message.speechDuration, isNull);
    expect(find.text('오늘 오늘 산책했다'), findsOneWidget);
    await expectUnavailableResult(tester);
    expect(find.textContaining('어휘 다양성(TTR): 66.7% (텍스트 기준)'), findsOneWidget);
    expect(find.textContaining('텍스트 분량: 3개 공백 토큰'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await _closeScreen(tester);
  });

  testWidgets('사용자 대화가 없으면 종료 결과와 저장을 만들지 않는다', (tester) async {
    await openScreen(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await send(tester);
    await tester.tap(find.text('대화 종료'));
    await tester.pumpAndSettle();

    expect(provider.histories, hasLength(1));
    expect(find.text('먼저 한 마디 이상 대화해 주세요.'), findsOneWidget);
    expect(find.text('종합 점수: 측정 불가'), findsNothing);
    expect(find.text('결과 저장하기'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    verifyNever(() => user.setCognitiveScore(any(), any()));
    await _closeScreen(tester);
  });

  testWidgets('320x720 화면에서도 측정 불가 결과와 저장 버튼이 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openScreen(tester);
    await tester.enterText(find.byType(TextField), '오늘 친구와 산책했어요');
    await send(tester);
    await expectUnavailableResult(tester);

    expect(tester.takeException(), isNull);
    final saveRect = tester.getRect(find.widgetWithText(FilledButton, '결과 저장하기'));
    expect(saveRect.left, greaterThanOrEqualTo(0));
    expect(saveRect.right, lessThanOrEqualTo(320));
    expect(saveRect.bottom, lessThanOrEqualTo(720));
    await _closeScreen(tester);
  });

  testWidgets('AI 응답 대기 중에는 종료와 전송 및 입력이 비활성화된다', (tester) async {
    await openScreen(tester);
    provider.pendingReply = Completer<String>();
    await tester.enterText(find.byType(TextField), '산책을 했어요');
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.send));
    await tester.pump();

    expect(find.text('AI가 생각 중...'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, '대화 종료')).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.widgetWithIcon(FilledButton, Icons.send)).onPressed, isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
    await tester.tap(find.text('대화 종료'));
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.send));
    await tester.pump();
    expect(provider.histories, hasLength(2));
    expect(find.text('결과 저장하기'), findsNothing);
    verifyNever(() => user.setCognitiveScore(any(), any()));

    provider.pendingReply!.complete('산책은 즐거우셨나요?');
    await tester.pumpAndSettle();
    expect(find.text('산책은 즐거우셨나요?'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, '대화 종료')).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(find.widgetWithIcon(FilledButton, Icons.send)).onPressed, isNotNull);
    await _closeScreen(tester);
  });

  testWidgets('음성 입력은 출처를 유지하고 늦은 인식 결과는 다음 입력에 섞이지 않는다', (tester) async {
    await openScreen(tester);
    await tester.tap(find.byTooltip('음성으로 입력'));
    await tester.pump();
    expect(speechCalls.any((call) => call.method == 'listen'), true);
    await _recognize(tester, '오늘 공원에서 걸었어요');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '오늘 공원에서 걸었어요');
    await send(tester);

    final voice = provider.histories.last.where((m) => m.isUser).single;
    expect(voice.inputSource, ChatInputSource.voice);
    expect(voice.speechDuration, isNull);
    await _recognize(tester, '뒤늦게 도착한 음성');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

    await tester.enterText(find.byType(TextField), '이번에는 직접 입력했어요');
    await send(tester);
    expect(provider.histories.last.where((m) => m.isUser).last.inputSource, ChatInputSource.typed);
    await expectUnavailableResult(tester);
    await _closeScreen(tester);
  });

  testWidgets('인식된 문장을 수정하면 수정 음성으로 기록하고 시간 지표를 만들지 않는다', (tester) async {
    await openScreen(tester);
    await tester.tap(find.byTooltip('음성으로 입력'));
    await tester.pump();
    await _recognize(tester, '공원에 갔어요');
    await tester.enterText(find.byType(TextField), '친구와 공원에 갔어요');
    await _recognize(tester, '수정 이후의 늦은 음성');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '친구와 공원에 갔어요');
    await send(tester);

    final message = provider.histories.last.where((m) => m.isUser).single;
    expect(message.text, '친구와 공원에 갔어요');
    expect(message.inputSource, ChatInputSource.editedVoice);
    expect(message.speechDuration, isNull);
    await expectUnavailableResult(tester);
    await _closeScreen(tester);
  });
}
