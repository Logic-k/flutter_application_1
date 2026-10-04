// ─────────────────────────────────────────────────────────────────────────
// 창 크기·본문 폭 토큰 — 핸드오프 §5.3 · 아키텍처 §2.5 (DS-004)
//
// 분기는 기기 종류·방향이 아니라 `LayoutBuilder` 의 maxWidth로 한다. 지금 앱은 전부
// compact(1열, 전체 폭)로 그려지고 아직 이 토큰을 쓰는 화면이 없어 시각 변화가 없다.
// medium·expanded 레이아웃은 G11(DS-021)에서 쓴다.
// ─────────────────────────────────────────────────────────────────────────

enum AppWindowClass { compact, medium, expanded }

abstract final class AppLayout {
  /// 이 폭부터 medium.
  static const double mediumMinWidth = 600;

  /// 이 폭부터 expanded.
  static const double expandedMinWidth = 840;

  /// medium 본문 최대 폭. 문서 범위 640~720 중 상한 — 아직 쓰는 화면이 없어 사용자 판단 대기.
  static const double mediumContentMaxWidth = 720;

  /// expanded 본문 최대 폭.
  static const double expandedContentMaxWidth = 1200;

  /// 이 글자 배율 이상이면 넓은 화면에서도 폼·지표를 1열로 되돌릴 수 있다.
  static const double singleColumnTextScale = 1.4;

  static AppWindowClass windowClassOf(double width) {
    if (width >= expandedMinWidth) return AppWindowClass.expanded;
    if (width >= mediumMinWidth) return AppWindowClass.medium;
    return AppWindowClass.compact;
  }

  /// compact는 폭 제한 없음(전체 폭).
  static double contentMaxWidthOf(AppWindowClass windowClass) => switch (windowClass) {
    AppWindowClass.compact => double.infinity,
    AppWindowClass.medium => mediumContentMaxWidth,
    AppWindowClass.expanded => expandedContentMaxWidth,
  };
}
