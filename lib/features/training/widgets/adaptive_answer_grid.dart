import 'dart:math';

import 'package:flutter/material.dart';

/// 보기 격자를 "남은 공간"에 맞춰 배치한다.
///
/// `GridView(shrinkWrap: true)`는 가용 높이와 무관하게 고유 높이를 잡기 때문에
/// 작은 화면이나 큰 글자 배율에서 하단 보기가 잘려 문항을 풀 수 없게 된다.
/// 이 위젯은 주어진 제약 안에서 셀 크기를 직접 계산해 항상 들어맞게 한다.
///
/// 반드시 높이가 제한된 부모(`Expanded` 등) 안에서 사용한다.
class AdaptiveAnswerGrid extends StatelessWidget {
  final int itemCount;
  final int columns;
  final double spacing;

  /// 셀의 가로/세로 비. 1.0이면 정사각형.
  final double childAspectRatio;

  final Widget Function(BuildContext context, int index) itemBuilder;

  const AdaptiveAnswerGrid({
    super.key,
    required this.itemCount,
    required this.columns,
    required this.itemBuilder,
    this.spacing = 16,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = (itemCount / columns).ceil();
        final availableWidth =
            constraints.maxWidth - spacing * (columns - 1);
        final availableHeight =
            constraints.maxHeight - spacing * (rows - 1);

        // 폭 기준과 높이 기준 중 작은 쪽을 택해야 양방향 모두 들어맞는다.
        final cellWidth = min(
          availableWidth / columns,
          (availableHeight / rows) * childAspectRatio,
        );
        final cellHeight = cellWidth / childAspectRatio;

        if (cellWidth <= 0 || cellHeight <= 0) {
          return const SizedBox.shrink();
        }

        return Center(
          child: SizedBox(
            width: cellWidth * columns + spacing * (columns - 1),
            height: cellHeight * rows + spacing * (rows - 1),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            ),
          ),
        );
      },
    );
  }
}
