import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gemini API 키를 기기 로컬(SharedPreferences)에 저장·조회합니다.
///
/// 우선순위:
///   1. 사용자가 앱 내에서 직접 입력한 키 (SharedPreferences)
///   2. 빌드 시 --dart-define=GEMINI_API_KEY=xxx 로 주입된 키
///   3. 키 없음 → LocalFallbackProvider
class AiKeyService {
  static const _prefKey = 'gemini_api_key';

  AiKeyService._();

  /// 저장된 사용자 키 조회 (없으면 null)
  static Future<String?> getStoredKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_prefKey);
    return (key != null && key.isNotEmpty) ? key : null;
  }

  /// 사용자 키 저장
  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key.trim());
    debugPrint('[AiKeyService] API 키 저장 완료');
  }

  /// 사용자 키 삭제
  static Future<void> deleteKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    debugPrint('[AiKeyService] API 키 삭제 완료');
  }

  /// 유효한 키가 있는지 확인 (사용자 키 또는 dart-define 키)
  static Future<bool> hasValidKey({String dartDefineKey = ''}) async {
    final stored = await getStoredKey();
    return (stored != null) || dartDefineKey.isNotEmpty;
  }

  /// 최종 사용할 키 반환 (사용자 키 우선)
  static Future<String?> resolveKey({String dartDefineKey = ''}) async {
    final stored = await getStoredKey();
    if (stored != null) return stored;
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    return null;
  }
}
