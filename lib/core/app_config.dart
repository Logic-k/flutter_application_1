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

  /// 생성형 AI(Gemini·온디바이스 모델)를 쓸지 여부.
  ///
  /// 출시 빌드는 기본으로 끈다. 구글 플레이 AI 생성 콘텐츠 정책(인앱 신고),
  /// 앱에 든 키의 노출, 무료 등급 Gemini 약관(입력이 제품 개선에 쓰일 수 있음)이
  /// 정리되기 전까지 규칙 기반 대화만 쓴다. 디버그·프로파일 빌드는 개발용으로 켜 둔다.
  ///   켜기: `--dart-define=ENABLE_GENERATIVE_AI=true`
  static const bool isGenerativeAiEnabled =
      bool.fromEnvironment('ENABLE_GENERATIVE_AI', defaultValue: !kReleaseMode);

  /// 앱 관리자 화면에서 공지·FAQ·문의 답변을 쓸지 여부.
  ///
  /// 규칙은 관리자 쓰기에 Custom Claim(admin=true)을 요구하는데 부여 체계가 없다.
  /// 그동안 운영 콘텐츠는 Firebase 콘솔에서 관리하고, 앱의 관리 화면은 안내만 한다.
  ///   켜기: `--dart-define=ENABLE_ADMIN_CLOUD_WRITE=true`
  static const bool isAdminCloudWriteEnabled =
      bool.fromEnvironment('ENABLE_ADMIN_CLOUD_WRITE', defaultValue: false);

  /// 개인정보 처리방침 공개 URL (스토어 등록·설정 화면에서 사용).
  /// Firebase Hosting에 privacy.html을 배포한 뒤 이 값을 실제 URL로 유지한다.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://memorylink-7af26.web.app/privacy.html',
  );
}
