import 'package:flutter/foundation.dart';
import 'ai_provider_interface.dart';
import 'ai_key_service.dart';
import 'gemini_provider.dart';
import 'local_fallback_provider.dart';
import '../app_config.dart';
import '../../features/ai_chat/models/chat_message.dart';

/// AI 대화 서비스 — 제공자 교체 지점
///
/// 키 우선순위:
///   1. 사용자가 앱 내 저장한 키 (SharedPreferences)
///   2. --dart-define=GEMINI_API_KEY 빌드 주입 키
///   3. 없으면 LocalFallbackProvider
class AiChatService {
  AiChatService._();

  static AiProviderInterface _provider = LocalFallbackProvider();
  static bool _initialized = false;

  /// 앱 시작 시 한 번 호출 (main.dart)
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _applyBestProvider();
  }

  /// 사용자가 새 API 키를 입력했을 때 호출
  static Future<void> applyApiKey(String key) async {
    // 키 저장 전 ListModels 진단 — 로그로 사용 가능 모델 확인
    final models = await GeminiProvider.listAvailableModels(key);
    if (models.isEmpty) {
      debugPrint('[AiChatService] 경고: ListModels 결과 없음 (키 무효 또는 API 미활성)');
    } else {
      debugPrint('[AiChatService] 사용 가능 모델 ${models.length}개 확인됨');
    }
    await AiKeyService.saveKey(key);
    await _reinitialize();
  }

  /// 사용자가 API 키를 삭제했을 때 호출
  static Future<void> removeApiKey() async {
    await AiKeyService.deleteKey();
    await _reinitialize();
  }

  /// 런타임 제공자 직접 교체 (테스트 또는 설정에서 사용)
  static Future<void> setProvider(AiProviderInterface newProvider) async {
    await _provider.dispose();
    _provider = newProvider;
    debugPrint('[AiChatService] 제공자 교체: ${newProvider.providerName}');
  }

  static String get currentProviderName => _provider.providerName;
  static bool get isUsingAI => _provider is! LocalFallbackProvider;

  /// 메시지 전송 — 내부 제공자에 위임
  static Future<String> chat(
    String userMessage,
    List<ChatMessage> history,
  ) async {
    return _provider.sendMessage(userMessage, history);
  }

  // ─────────────────────────────────────────────
  static Future<void> _reinitialize() async {
    await _provider.dispose();
    _initialized = false;
    await _applyBestProvider();
    _initialized = true;
  }

  static Future<void> _applyBestProvider() async {
    final key = await AiKeyService.resolveKey(
      dartDefineKey: AppConfig.geminiApiKey,
    );

    if (key != null) {
      _provider = GeminiProvider(key);
      debugPrint('[AiChatService] 제공자: ${_provider.providerName}');
    } else {
      _provider = LocalFallbackProvider();
      debugPrint('[AiChatService] API 키 없음 → LocalFallback 사용');
    }
    _initialized = true;
  }
}
