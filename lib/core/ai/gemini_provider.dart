import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_provider_interface.dart';
import '../../features/ai_chat/models/chat_message.dart';

class GeminiProvider implements AiProviderInterface {
  static const _baseUrl = 'https://generativelanguage.googleapis.com';

  static const _systemPromptBase =
      '당신은 MemoryLink의 친근한 AI 대화 도우미입니다. '
      '사용자와 한국어로 자연스럽고 편안하게 대화합니다. '
      '궁금한 것, 일상 이야기, 고민 상담, 정보 요청 등 무엇이든 친절하게 답변합니다. '
      '판단하거나 가르치려 하지 않고 친구처럼 공감하고 도와줍니다. '
      '답변은 3문장 이내로 간결하게 합니다. 영어 단어 사용을 자제합니다. '
      '오늘 날짜, 요일, 시간, 날씨 정보가 아래에 제공되면 이를 활용해 정확하게 답변합니다.';

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

  // 날씨 캐시 (10분 TTL)
  String? _cachedWeather;
  DateTime? _weatherFetchedAt;

  GeminiProvider(this._apiKey);

  @override
  String get providerName => _activeModel;

  /// 현재 날짜·요일·시간 문자열 생성
  static String _buildTimeContext() {
    final now = DateTime.now();
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '[현재 정보] 오늘은 ${now.year}년 ${now.month}월 ${now.day}일 $weekday요일이며, 현재 시각은 $hour시 $minute분입니다.';
  }

  /// wttr.in에서 날씨 조회 (API 키 불필요)
  static Future<String?> _fetchWeather() async {
    try {
      // format: 날씨상태, 체감온도, 습도
      final url = Uri.parse('https://wttr.in/Seoul?format=%C,+%f,+습도+%h&lang=ko');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final raw = response.body.trim();
        if (raw.isNotEmpty && !raw.startsWith('<')) {
          return '[서울 날씨] $raw';
        }
      }
    } catch (e) {
      debugPrint('[GeminiProvider] 날씨 조회 실패 (무시): $e');
    }
    return null;
  }

  /// 날씨 캐시 (10분 유효)
  Future<String?> _getWeatherContext() async {
    final now = DateTime.now();
    if (_cachedWeather != null &&
        _weatherFetchedAt != null &&
        now.difference(_weatherFetchedAt!).inMinutes < 10) {
      return _cachedWeather;
    }
    _cachedWeather = await _fetchWeather();
    _weatherFetchedAt = now;
    return _cachedWeather;
  }

  /// 시간 + 날씨가 포함된 동적 시스템 프롬프트 생성
  Future<String> _buildSystemPrompt() async {
    final timeCtx = _buildTimeContext();
    final weatherCtx = await _getWeatherContext();
    final parts = [_systemPromptBase, timeCtx];
    if (weatherCtx != null) parts.add(weatherCtx);
    return parts.join(' ');
  }

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
    if (_workingEndpoint.isNotEmpty) {
      try {
        return await _callRest(_workingEndpoint, userMessage, history);
      } catch (e) {
        debugPrint('[GeminiProvider] 캐시 실패, 재탐색: $e');
        _workingEndpoint = '';
      }
    }

    final discovered = await listAvailableModels(_apiKey);

    final ordered = <String>[];
    for (final pref in _preferredOrder) {
      if (discovered.contains(pref)) ordered.add(pref);
    }
    for (final m in discovered) {
      if (!ordered.contains(m)) ordered.add(m);
    }

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
    final systemPrompt = await _buildSystemPrompt();

    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
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

    final finishReason = candidate?['finishReason'] as String?;
    if (finishReason == 'MAX_TOKENS') {
      return _trimToLastSentence(parts);
    }

    return parts;
  }

  String _trimToLastSentence(String text) {
    final pattern = RegExp(r'[다요네죠][.!?]|[까나][요?]|[세요][?.]');
    final matches = pattern.allMatches(text);
    if (matches.isEmpty) return text;
    return text.substring(0, matches.last.end).trim();
  }

  @override
  Future<void> dispose() async {
    _workingEndpoint = '';
  }
}
