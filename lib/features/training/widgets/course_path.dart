import 'package:flutter/material.dart';

import 'course_node.dart';

class CoursePath extends StatelessWidget {
  const CoursePath({super.key, required this.nodes});

  final List<CourseNode> nodes;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      label: '인지훈련 과정, 활동 ${nodes.length}개',
      child: Column(
        children: [
          for (var index = 0; index < nodes.length; index++) ...[
            nodes[index],
            if (index < nodes.length - 1)
              ExcludeSemantics(
                child: Container(
                  width: 2,
                  height: 20,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
