import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_provider_interface.dart';
import '../../features/ai_chat/models/chat_message.dart';

class GeminiProvider implements AiProviderInterface {
  static const _baseUrl = 'https://generativelanguage.googleapis.com';

  static const _systemPrompt =
      '당신은 MemoryLink의 친근한 AI 대화 도우미입니다. '
      '사용자와 한국어로 자연스럽고 편안하게 대화합니다. '
      '궁금한 것, 일상 이야기, 고민 상담, 정보 요청 등 무엇이든 친절하게 답변합니다. '
      '판단하거나 가르치려 하지 않고 친구처럼 공감하고 도와줍니다. '
      '답변은 3문장 이내로 간결하게 합니다. 영어 단어 사용을 자제합니다.';

  // 선호 모델 순서 (자동 발견 모델에 적용)
  static const _preferredOrder = [
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash-lite-001',
    'gemini-2.0-flash',
    'gemini-2.0-flash-001',
    'gemini-1.5-flash',
    'gemini-1.5-flash-001',
    'gemini-1.5-flash-8b',
    'gemini-1.0-pro',
  ];

  final String _apiKey;
  String _workingEndpoint = '';
  String _activeModel = 'Gemini';

  GeminiProvider(this._apiKey);

  @override
  String get providerName => _activeModel;

  /// API 키로 사용 가능한 모델 목록을 조회합니다.
  static Future<List<String>> listAvailableModels(String apiKey) async {
    final url = Uri.parse('$_baseUrl/v1beta/models?key=$apiKey');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint('[GeminiProvider] ListModels 실패: HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final models = (data['models'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      final result = <String>[];
      for (final m in models) {
        final name = (m['name'] as String? ?? '').replaceFirst('models/', '');
        final methods = (m['supportedGenerationMethods'] as List<dynamic>?)?.cast<String>() ?? [];
        // thinking/preview 모델 제외 (사고 과정이 응답에 노출됨)
        final isThinking = name.contains('thinking') || name.contains('learnlm');
        if (methods.contains('generateContent') && !isThinking) {
          result.add(name);
        }
      }
      debugPrint('[GeminiProvider] ListModels 결과 (${result.length}개): $result');
      return result;
    } catch (e) {
      debugPrint('[GeminiProvider] ListModels 오류: $e');
      return [];
    }
  }

  @override
  Future<String> sendMessage(String userMessage, List<ChatMessage> history) async {
    // 캐시된 엔드포인트 우선 시도
    if (_workingEndpoint.isNotEmpty) {
      try {
        return await _callRest(_workingEndpoint, userMessage, history);
      } catch (e) {
        debugPrint('[GeminiProvider] 캐시 실패, 재탐색: $e');
        _workingEndpoint = '';
      }
    }

    // ListModels로 실제 사용 가능한 모델 탐색
    final discovered = await listAvailableModels(_apiKey);

    // 선호 순서로 정렬
    final ordered = <String>[];
    for (final pref in _preferredOrder) {
      if (discovered.contains(pref)) ordered.add(pref);
    }
    for (final m in discovered) {
      if (!ordered.contains(m)) ordered.add(m);
    }

    // 탐색 실패 시 하드코딩 fallback
    if (ordered.isEmpty) {
      debugPrint('[GeminiProvider] 모델 자동 탐색 실패, 기본 목록으로 시도');
      ordered.addAll(_preferredOrder);
    }

    for (final model in ordered) {
      final endpoint = '$_baseUrl/v1beta/models/$model';
      try {
        final result = await _callRest(endpoint, userMessage, history);
        _workingEndpoint = endpoint;
        _activeModel = model;
        debugPrint('[GeminiProvider] 성공: $model');
        return result;
      } catch (e) {
        debugPrint('[GeminiProvider] 실패 [$model]: $e');
      }
    }

    return '죄송해요, 잠시 연결이 어렵네요. 다시 한번 말씀해 주시겠어요?';
  }

  Future<String> _callRest(
    String endpoint,
    String userMessage,
    List<ChatMessage> history,
  ) async {
    final url = Uri.parse('$endpoint:generateContent?key=$_apiKey');

    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': _systemPrompt}
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': '네, 무엇이든 편하게 물어보세요!'}
        ],
      },
      ...history.map((m) => {
            'role': m.isUser ? 'user' : 'model',
            'parts': [
              {'text': m.text}
            ],
          }),
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      },
    ];

    final body = json.encode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
      },
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final candidate = data['candidates']?[0] as Map<String, dynamic>?;

    // thought == true 파트(사고 과정) 제거, 실제 응답 텍스트만 추출
    final parts = (candidate?['content']?['parts'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .where((p) => p['thought'] != true)
            .map((p) => p['text'] as String? ?? '')
            .where((t) => t.isNotEmpty)
            .join('\n')
            .trim() ??
        '';

    if (parts.isEmpty) {
      throw Exception('응답 내용이 비어 있습니다: ${response.body}');
    }

    // MAX_TOKENS로 잘린 경우 마지막 완성 문장까지 반환
    final finishReason = candidate?['finishReason'] as String?;
    if (finishReason == 'MAX_TOKENS') {
      return _trimToLastSentence(parts);
    }

    return parts;
  }

  // 마지막 완성 문장(한국어 종결 패턴)까지 잘라 반환
  String _trimToLastSentence(String text) {
    final pattern = RegExp(r'[다요네죠][.!?]|[까나][요?]|[세요][?.]');
    final matches = pattern.allMatches(text);
    if (matches.isEmpty) return text;
    final lastMatch = matches.last;
    return text.substring(0, lastMatch.end).trim();
  }

  @override
  Future<void> dispose() async {
    _workingEndpoint = '';
  }
}
