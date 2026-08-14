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
  static const Color line       = Color(0xFFECEAF4); // 장식용 경계선 (대비 요건 없음)

  /// 조작 가능한 영역의 경계선. 입력 필드·선택지 카드처럼 "여기를 누르면 된다"를
  /// 알리는 유일한 단서인 곳에 쓴다. 흰 배경 3.75:1 / bg 3.32:1 로
  /// WCAG 1.4.11(비텍스트 3:1)을 넘긴다. [line]은 1.19:1이라 이 용도로 쓸 수 없다.
  static const Color lineStrong = Color(0xFF8480A4);

  // Text
  // 대비비는 흰 카드(#FFFFFF)와 스캐폴드 배경(#F1F0FB) 양쪽에서 WCAG AA 4.5:1을
  // 넘도록 잡았다. 이전 값(textSoft #716C8C = bg 위 4.40:1,
  // textFaint #A6A2BC = 2.18:1)은 저시력 고령 사용자에게 읽히지 않았다.
  static const Color text      = Color(0xFF241F3D);
  static const Color textSoft  = Color(0xFF5E5978); // 흰 6.06:1 / bg 5.36:1
  static const Color textFaint = Color(0xFF5F5B78); // 흰 5.98:1 / bg 5.29:1

  // Category accents (게임/지표 카테고리)
  static const Color calc  = Color(0xFF6C5CE7); // 계산·판단
  static const Color logic = Color(0xFFA66BE8); // 논리·추론
  static const Color mem   = Color(0xFF38C9A6); // 기억·지각 (민트)
  static const Color care  = Color(0xFFFF7AA2); // 스마트 케어
  static const Color read  = Color(0xFFFFB74D); // 읽기/걸음 (앰버)
  static const Color sky   = Color(0xFF5AA9F0);

  // Status (신호등) — 아래 3색은 **면(배경·아이콘 틴트·차트)** 전용이다.
  // 밝아서 흰 글자를 얹으면 1.7~2.8:1 밖에 안 나온다.
  static const Color good = Color(0xFF3FBF8F); // 양호
  static const Color warn = Color(0xFFFFB020); // 보통
  static const Color bad  = Color(0xFFFF6B6B); // 주의

  // 같은 의미를 **글자·아이콘**으로 쓸 때의 색. 흰 배경/연한 배경 위에서
  // AA 4.5:1을 넘긴다. 상태 문구를 신호등 원색으로 쓰면 읽히지 않는다.
  static const Color goodText = Color(0xFF1F7A56); // 흰 4.84:1
  static const Color warnText = Color(0xFF8A5A00); // 흰 6.05:1
  static const Color badText  = Color(0xFFC62828); // 흰 5.62:1

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

  /// 최소 터치 타겟 높이(dp).
  /// WCAG 2.2 SC 2.5.8은 24px를 하한으로 두고 Material은 48dp를 권고하지만,
  /// 진전·관절 가동범위 저하가 흔한 고령 사용자를 기준으로 56dp를 쓴다.
  static const double minTapTarget = 56;

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
    // 조작 가능한 영역의 경계. 다크에서는 배경이 어두워 밝은 쪽으로 올려야 한다.
    final fieldBorder = isLight ? MLColors.lineStrong : const Color(0xFF7C77A0);

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
          minimumSize: const Size(88, minTapTarget),
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
          minimumSize: const Size(88, minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rBtn)),
          elevation: 0,
        ),
      ),
      // OutlinedButton 테마가 없으면 M3 기본값(StadiumBorder r20 / 14px)으로 떨어져
      // 같은 Row 안의 FilledButton과 높이·모서리·굵기가 눈에 띄게 어긋난다.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          minimumSize: const Size(88, minTapTarget),
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rBtn)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w800),
          minimumSize: const Size(64, minTapTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? MLColors.surfaceAlt : MLColors.dSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        // 입력 필드 경계는 장식이 아니라 "여기에 입력한다"는 유일한 단서다.
        // 장식용 line(1.19:1)이 아니라 lineStrong(3.75:1)을 쓴다.
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(rTile), borderSide: BorderSide(color: fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(rTile), borderSide: BorderSide(color: fieldBorder)),
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
