// ─────────────────────────────────────────────────────────────────────────
// [TTA 표준 적용 — 준용] TTAK.KO-08.0057
//   「사회적 약자(정보취약계층)를 위한 무인정보 단말기 사용자 인터페이스 접근성 요구사항」
//
// 적용 지점: 시각 접근성 토큰.
//   - 명도 대비: 본문·보조 텍스트를 WCAG AA(4.5:1) 이상으로 잡았다. 조작 가능한
//     경계선(lineStrong)은 비텍스트 기준 3:1을 넘긴다. 회귀는
//     test/unit/core/theme_contrast_test.dart 가 대비비를 실제로 계산해 차단한다.
//   - 터치 타겟: minTapTarget 56dp. Material 권고 48dp보다 크게 잡은 것은 진전·관절
//     가동범위 저하가 흔한 고령 사용자를 기준으로 삼았기 때문이다.
//
// 준용 고지: 적용 대상이 무인정보 단말기인 표준을 모바일 UI에 준용했다.
// 같은 표준의 문자 크기·음성·촉각 설정은 core/settings_provider.dart 에 적용.
// ─────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────
// theme.dart  ·  MemoryLink 리디자인 — 방향 A "라벤더 캄"  [확정본]
// 확정값: 강조색 #6C5CE7 · 라이트 기본 · Pretendard · 둥글기/타이포 기본 배수(1.0)
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

/// 디자인 토큰.
///
/// **쓰는 규칙** — 이 클래스의 값은 밝기와 무관한 의미색만 화면에서 직접 참조한다.
/// 카테고리 강조색(calc·logic·mem·care·read·sky)과 상태색(good/warn/bad,
/// goodText/warnText/badText), 그라디언트가 그 대상이다.
///
/// 반대로 **표면·텍스트·경계선**(bg·surface·surfaceAlt·line·text·textSoft와
/// primary 계열)은 밝기에 따라 뒤집혀야 하므로 화면에서 직접 쓰지 말고
/// `Theme.of(context).colorScheme` / `textTheme` 으로 가져온다. 위젯이 색을
/// 직접 고르면 스킴을 바꿔도 따라오지 않는다 — 다크 모드가 대비 1.04:1로
/// 깨져 있던 원인이 정확히 이것이었다(main.dart의 themeMode 주석 참조).
/// 이 클래스에 남은 표면·텍스트 값은 테마 정의(_base) 자체가 쓰기 위한 원재료다.
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
  //
  // 접근성 보정 과정에서 textFaint(#5F5B78)가 textSoft(#5E5978)와 채널당 1~2 차이,
  // 대비비 5.98:1 대 6.06:1까지 붙어 버렸다. 화면에서 구분되지 않는 두 값을
  // 두 이름으로 관리하면 한쪽만 고쳐 어긋나기 때문에 textSoft 하나로 합쳤다.
  static const Color text      = Color(0xFF241F3D);
  static const Color textSoft  = Color(0xFF5E5978); // 흰 6.06:1 / bg 5.36:1

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

  // 앱 아이콘(assets/icon/app_icon.png)에서 뽑은 로고 색. 오프닝이 로고를 벡터로 다시 그릴 때만 쓴다.
  static const Color logoNavy     = Color(0xFF3C5A8C); // 바탕 그라데이션 왼쪽 위
  static const Color logoNavyDeep = Color(0xFF1F2D4D); // 바탕 그라데이션 오른쪽 아래
  static const Color logoFacetTop  = Color(0xFFD7E3F8); // 오른쪽 윗면(왼쪽 윗면은 흰색)
  static const Color logoFacetSide = Color(0xFF9FB8E6); // 양 옆면
  static const Color logoFacetFold = Color(0xFF6F8FC4); // 가운데 접힌 면

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

/// 화면에서 색을 꺼내는 표준 경로.
///
/// `Theme.of(context).colorScheme.primary`를 매번 쓰면 삼항 연산자 한 줄에
/// 같은 호출이 두 번 들어가 읽기 어려워진다. 짧게 쓰되 출처는 그대로
/// 테마이므로, 스킴을 바꾸면 화면이 따라온다.
///
///     color: context.scheme.primary
extension MLColorScheme on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
}

class AppTheme {
  // Pretendard(OFL 1.1). assets/fonts/ 에 400·500·600·700·800 다섯 벌이 번들돼 있고
  // pubspec.yaml 이 그 굵기를 그대로 선언한다.
  //
  // 아래 TextTheme 이 쓰는 굵기는 반드시 그 다섯 중 하나여야 한다.
  // 선언에 없는 굵기(예: w900)는 오류를 내지 않고 조용히 가장 가까운 것으로 바뀌므로,
  // 코드가 선언한 위계와 화면에 그려지는 위계가 어긋난다.
  // 나눔고딕(400/700 두 벌)을 쓰던 동안 본문 w600 과 제목 w800 이 똑같이 700 으로
  // 그려져 위계가 크기 한 축으로 붕괴해 있었다. 그래서 서체를 바꾼 것이다.
  static const String _fontFamily = 'Pretendard';

  // ─── 모서리 둥글기 척도 ──────────────────────────────────────
  //
  // 토큰이 셋뿐이라 화면들이 BorderRadius.circular()에 숫자를 직접 넣었고,
  // 그 결과 같은 성격의 요소가 10·11·12로 제각각이 됐다. 실제로 쓰이던 값을
  // 용도별로 묶어 척도로 만든다. 이 척도 밖의 숫자는 쓰지 않는다.
  static const double rBar   = 4;   // 진행 바·게이지처럼 얇은 요소
  static const double rChip  = 8;   // 칩·태그·작은 배지
  static const double rField = 12;  // 입력창·타일 내부 블록
  static const double rBtn   = 14;  // 버튼
  static const double rTile  = 16;  // 타일·아이콘 배경
  static const double rPanel = 20;  // 패널·인라인 시트
  static const double rSheet = 24;  // 바텀시트·큰 다이얼로그
  static const double rCard  = 26;  // 카드 (MLCard·MLHeroCard)
  static const double rPill  = 30;  // 완전한 알약 (하단 네비 등)

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
      // 연보라 면(primaryContainer) 위 글자. 시드가 만드는 기본값을 쓰면 화면들이
      // primary 를 대신 얹어 3.77:1 로 AA 에 못 미쳤다(게임 목표 카드). 4.96:1.
      onPrimaryContainer: MLColors.primaryDeep,
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
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: onSurf, letterSpacing: -0.5),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rBtn)),
      ),

      // 아래 셋은 화면마다 색을 직접 지정하던 것을 테마로 끌어올린 것이다.
      // 리스트 구분선 14곳이 `const Divider()`,
      // 스위치 3곳이 `activeThumbColor: MLColors.primary`,
      // 로딩 인디케이터 5곳이 `CircularProgressIndicator()`
      // 였다. 색을 위젯이 정하면 스킴을 바꿔도 따라오지 않는다.
      dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
