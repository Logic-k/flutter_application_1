import 'package:flutter/foundation.dart';

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

  /// 관리자 포털 접근 코드의 SHA-256 다이제스트(소문자 hex).
  ///
  /// 평문 코드를 앱에 넣지 않는다. 예전에는 `'memorylink2024'`가 소스에 그대로
  /// 있었고 릴리스에서도 버전 텍스트 롱프레스로 열려서, APK를 뜯은 사람이라면
  /// 전체 사용자 목록·DAU·위험군 화면에 그대로 들어올 수 있었다.
  ///
  /// 릴리스 빌드는 이 값을 주입해야만 포털이 열린다. 주입하지 않으면
  /// 진입점도 라우트도 존재하지 않는다.
  ///   `flutter build appbundle --dart-define=ADMIN_CODE_SHA256=<digest>`
  /// 다이제스트 생성: `printf '<code>' | sha256sum`
  static const String adminCodeSha256 =
      String.fromEnvironment('ADMIN_CODE_SHA256', defaultValue: '');

  /// 관리자 포털을 노출할지 여부.
  ///
  /// 디버그·프로파일에서는 QA를 위해 항상 열려 있고(개발용 코드 사용),
  /// 릴리스에서는 다이제스트를 주입한 빌드에서만 열린다.
  static bool get isAdminPortalEnabled =>
      !kReleaseMode || adminCodeSha256.isNotEmpty;

  /// 개인정보 처리방침 공개 URL (스토어 등록·설정 화면에서 사용).
  /// Firebase Hosting에 privacy.html을 배포한 뒤 이 값을 실제 URL로 유지한다.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://memorylink-7af26.web.app/privacy.html',
  );
}
