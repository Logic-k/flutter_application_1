// ─────────────────────────────────────────────────────────────────────────
// 화면 프레임 — 핸드오프 §6 · 아키텍처 §3.2 (DS-005)
//
// 본문 틀(좌우·상하 여백, 최대 폭, 선택적 제목)만 통일한다. Scaffold·AppBar·route는
// 화면이 그대로 갖는다 — back semantics와 route identity를 숨기지 않기 위해서다.
//   isTab       탭 화면이면 떠 있는 네비만큼 하단 여백(bottomSafeContent)을 자동으로 둔다.
//   form        폼·상세면 좌우 24, 아니면 22.
//   scrollable  명시적으로 정한다. 키보드는 Scaffold의 resize가 처리하고, 끌면 내려간다.
//   최대 폭      compact 전체 폭 · medium 720 · expanded 1200, 가운데 정렬.
// 모션은 없다. 첫 진입 안무는 화면별 정책대로 자식에 StaggeredColumn 등을 쓴다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../foundations/layout.dart';
import '../foundations/spacing.dart';

class MLScreenFrame extends StatelessWidget {
  const MLScreenFrame({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.isTab = false,
    this.form = false,
    this.scrollable = true,
    this.controller,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final bool isTab;
  final bool form;
  final bool scrollable;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final horizontal = form ? AppSpacing.screenHorizontalForm : AppSpacing.screenHorizontal;
    final bottom = isTab
        ? AppSpacing.bottomSafeContent
        : AppSpacing.sectionGap + MediaQuery.viewPaddingOf(context).bottom;
    final padding = EdgeInsets.fromLTRB(horizontal, AppSpacing.screenTop, horizontal, bottom);

    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = AppLayout.contentMaxWidthOf(AppLayout.windowClassOf(constraints.maxWidth));
      final content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          key: const Key('ml-screen-frame-content'),
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) Semantics(header: true, child: Text(title!, style: text.headlineSmall)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: text.bodyMedium),
              ],
              if (title != null || subtitle != null) const SizedBox(height: AppSpacing.sectionGap),
              ...children,
            ],
          ),
        ),
      );
      if (!scrollable) return Padding(padding: padding, child: content);
      return SingleChildScrollView(
        controller: controller,
        padding: padding,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: content,
      );
    });
  }
}
