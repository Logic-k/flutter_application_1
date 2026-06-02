/// 앱 전역 설정 — 빌드 시 dart-define으로 주입된 값을 관리합니다.
///
/// 에뮬레이터:
///   flutter run --dart-define=IS_EMULATOR=true --dart-define=GEMINI_API_KEY=xxx
/// 실기기:
///   flutter run --dart-define=GEMINI_API_KEY=xxx
class AppConfig {
  AppConfig._();

  static const bool isEmulator =
      bool.fromEnvironment('IS_EMULATOR', defaultValue: false);

  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
