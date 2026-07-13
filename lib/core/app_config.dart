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

  /// 개인정보 처리방침 공개 URL (스토어 등록·설정 화면에서 사용).
  /// Firebase Hosting에 privacy.html을 배포한 뒤 이 값을 실제 URL로 유지한다.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://memorylink-7af26.web.app/privacy.html',
  );
}
