// ─────────────────────────────────────────────────────────────────────────
// theme.dart  ·  MemoryLink 리디자인 — 방향 A "라벤더 캄"  [확정본]
// 확정값: 강조색 #6C5CE7 · 라이트 기본 · NanumGothic · 둥글기/타이포 기본 배수(1.0)
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

/// 디자인 토큰 — ColorScheme 으로 표현되지 않는 카테고리/상태 색은 여기서 가져다 씁니다.
class MLColors {
  // Brand
  static const Color primary     = Color(0xFF6C5CE7); // 라벤더 (강조)
  static const Color primaryDeep = Color(0xFF5847D6);
  static const Color primarySoft = Color(0xFFECE9FC); // primary container / 연한 틴트

  // Surface
  static const Color bg         = Color(0xFFF1F0FB); // 스캐폴드 배경
  static const Color surface    = Color(0xFFFFFFFF); // 카드
  static const Color surfaceAlt = Color(0xFFF6F5FD); // 보조 카드/입력
  static const Color line       = Color(0xFFECEAF4); // 경계선

  // Text
  static const Color text      = Color(0xFF241F3D);
  static const Color textSoft  = Color(0xFF716C8C);
  static const Color textFaint = Color(0xFFA6A2BC);

  // Category accents (게임/지표 카테고리)
  static const Color calc  = Color(0xFF6C5CE7); // 계산·판단
  static const Color logic = Color(0xFFA66BE8); // 논리·추론
  static const Color mem   = Color(0xFF38C9A6); // 기억·지각 (민트)
  static const Color care  = Color(0xFFFF7AA2); // 스마트 케어
  static const Color read  = Color(0xFFFFB74D); // 읽기/걸음 (앰버)
  static const Color sky   = Color(0xFF5AA9F0);

  // Status (신호등)
  static const Color good = Color(0xFF3FBF8F); // 양호
  static const Color warn = Color(0xFFFFB020); // 보통
  static const Color bad  = Color(0xFFFF6B6B); // 주의

  // Dark mode surfaces
  static const Color dBg         = Color(0xFF15131F);
  static const Color dSurface    = Color(0xFF211D30);
  static const Color dSurfaceAlt = Color(0xFF1A1726);
  static const Color dLine       = Color(0xFF2E2A3D);

  /// 강조 그라디언트 (히어로 카드 등)
  static const LinearGradient grad = LinearGradient(
    colors: [Color(0xFF7C6FF0), Color(0xFF9E7DF6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

class AppTheme {
  // NanumGothic 은 assets/fonts/ 에 이미 번들됨.
  // Pretendard 를 추가하려면 pubspec 에 등록 후 'Pretendard' 로 변경.
  static const String? _fontFamily = 'NanumGothic';

  // 모서리 둥글기 토큰 (확정 둥글기 배수 1.0 기준)
  static const double rCard = 26;
  static const double rBtn  = 14;
  static const double rTile = 16;

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: MLColors.primary,
      brightness: Brightness.light,
      primary: MLColors.primary,
      onPrimary: Colors.white,
      secondary: MLColors.mem,
      surface: MLColors.surface,
      surfaceContainerHighest: MLColors.surfaceAlt,
      error: MLColors.bad,
      outlineVariant: MLColors.line,
    );
    return _base(scheme, scaffold: MLColors.bg, card: MLColors.surface, line: MLColors.line);
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: MLColors.primary,
      brightness: Brightness.dark,
      primary: const Color(0xFF9E8CFF),
      onPrimary: Colors.white,
      secondary: MLColors.mem,
      surface: MLColors.dSurface,
      surfaceContainerHighest: MLColors.dSurfaceAlt,
      error: MLColors.bad,
      outlineVariant: MLColors.dLine,
    );
    return _base(scheme, scaffold: MLColors.dBg, card: MLColors.dSurface, line: MLColors.dLine);
  }

  // ── 공통 빌더 ───────────────────────────────────────────────
  static ThemeData _base(ColorScheme scheme, {required Color scaffold, required Color card, required Color line}) {
    final isLight = scheme.brightness == Brightness.light;
    final onSurf = scheme.onSurface;

    final text = TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: onSurf, letterSpacing: -0.5),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: onSurf, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: onSurf),
      titleMedium: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: onSurf),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurf, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant, height: 1.5),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ).apply(fontFamily: _fontFamily);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: line,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurf,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: _fontFamily, fontSize: 21, fontWeight: FontWeight.w800, color: onSurf, letterSpacing: -0.4),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
          side: BorderSide(color: line),
        ),
        shadowColor: MLColors.primary.withValues(alpha: 0.18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rBtn)),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rBtn)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? MLColors.surfaceAlt : MLColors.dSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(rTile), borderSide: BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(rTile), borderSide: BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(rTile), borderSide: BorderSide(color: scheme.primary, width: 2)),
        prefixIconColor: scheme.primary,
      ),
      // 표준 NavigationBar 를 쓰는 화면용 (플로팅 네비로 교체 전 폴백)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontFamily: _fontFamily, fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
        )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant, size: 25,
        )),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MLColors.text,
        contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
