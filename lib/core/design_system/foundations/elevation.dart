// ─────────────────────────────────────────────────────────────────────────
// 그림자 의미 토큰 — 아키텍처 §2.4 (DS-004)
//
// 네 역할만 둔다. 값은 **지금 위젯이 그리는 그림자 그대로**라 도입만으로는 시각 변화가 없다.
// blur·glass·neumorphism은 넣지 않는다.
// `test/widget/core/design_tokens_test.dart` 가 현재 위젯과 같은 값인지 지킨다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

abstract final class AppElevation {
  /// 그림자 없음, outline으로 구분 — `MLCard(soft: true)`.
  static const List<BoxShadow> flat = [];

  /// 일반 interactive 카드의 약한 단일 그림자 — `MLCard` 현재 값.
  /// DESIGN.md §5는 "검정이 아니라 배경 색조 그림자"를 요구하지만 지금 값은 검정 5%다.
  /// 시각 변화 0이 DS-004의 조건이라 그대로 옮겼다. 색조 전환은 사용자 결정 뒤 여기서 한다.
  static final List<BoxShadow> raised = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8)),
  ];

  /// 화면당 1개인 hero의 primary 톤 그림자 — `MLHeroCard` 현재 값.
  static List<BoxShadow> hero(Color primary) => [
    BoxShadow(color: primary.withValues(alpha: 0.30), blurRadius: 30, offset: const Offset(0, 12)),
  ];

  /// 네비·시트 전용, 본문 카드에는 쓰지 않는다 — `FloatingPillNav` 현재 값.
  static List<BoxShadow> floating(Color primary) => [
    BoxShadow(color: primary.withValues(alpha: 0.28), blurRadius: 30, offset: const Offset(0, 12)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
  ];
}
