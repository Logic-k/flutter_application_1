// ─────────────────────────────────────────────────────────────────────────
// 간격 의미 토큰 — 핸드오프 §5.3 · 아키텍처 §2.3 (DS-004)
//
// 값은 **지금 화면이 쓰는 숫자 그대로**다. 아직 어느 화면도 이 이름을 쓰지 않으므로
// 도입만으로는 시각 변화가 없다. 화면을 옮길 때(G4~G9) 숫자 대신 이 이름을 쓰고,
// 값 조정은 사용자 테스트 뒤 여기 한 곳에서만 한다.
// `test/widget/core/design_tokens_test.dart` 가 초기값을 지킨다.
// ─────────────────────────────────────────────────────────────────────────
import '../../ml_widgets.dart' show FloatingPillNav, MLHeroCard;

abstract final class AppSpacing {
  /// 일반 탭 화면 좌우 — walking·reports·settings·health의 `fromLTRB(22, …)`.
  static const double screenHorizontal = 22;

  /// 폼·상세 화면 좌우 — `EdgeInsets.all(24)` 계열.
  static const double screenHorizontalForm = 24;

  /// AppBar 아래 첫 요소. 문서 범위는 6~8이고 지금 walking·reports·settings 3곳이 6,
  /// health_input 1곳이 8이다. 다수값 6으로 둔다.
  static const double screenTop = 6;

  /// 아이콘-글자, 인라인 컨트롤 사이.
  static const double controlGap = 8;

  /// 같은 섹션 안의 항목 사이.
  static const double itemGap = 12;

  /// 카드 안의 블록 사이.
  static const double contentGap = 16;

  /// 이어지는 카드 사이.
  static const double cardGap = 20;

  /// 섹션 사이.
  static const double sectionGap = 24;

  /// hero 안쪽 — [MLHeroCard] 기본 padding.
  static const double heroPadding = 22;

  /// 탭 화면 마지막 콘텐츠 아래 여백 — 본문 위에 떠 있는 네비에 가리지 않게.
  static const double bottomSafeContent = FloatingPillNav.contentBottomInset;
}
