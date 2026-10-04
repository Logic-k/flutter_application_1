// ─────────────────────────────────────────────────────────────────────────
// 폼 섹션 — 핸드오프 §6.2 · 아키텍처 §3.5 (DS-005)
//
// 보이는 제목·설명, 필수/선택은 글자로 표시한다(색만으로 구분하지 않는다).
// 필드 자체(라벨·오류 문구)는 TextField의 InputDecoration이 그리고, 이 위젯은 묶음과 간격만 정한다.
// 컨트롤러는 화면이 갖는다 — 이 위젯은 상태를 만들지 않아 back·resize에도 입력이 남는다.
// 섹션 단위 진입만 허용하고 필드별 stagger는 하지 않는다. 이 위젯 자체는 모션이 없다.
// ─────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../theme.dart';
import '../foundations/spacing.dart';

enum MLFieldRequirement { required, optional }

class MLFormSection extends StatelessWidget {
  const MLFormSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
    this.requirement,
  });

  final String title;
  final String? description;

  /// 섹션 전체가 필수인지 선택인지. null이면 표시하지 않는다(필드마다 다를 때).
  final MLFieldRequirement? requirement;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: text.titleMedium))),
          if (requirement != null) _RequirementTag(requirement!),
        ]),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(description!, style: text.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.contentGap),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.itemGap),
          children[i],
        ],
      ],
    );
  }
}

class _RequirementTag extends StatelessWidget {
  const _RequirementTag(this.requirement);
  final MLFieldRequirement requirement;
  @override
  Widget build(BuildContext context) {
    final isRequired = requirement == MLFieldRequirement.required;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isRequired ? MLColors.primarySoft : context.scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.rChip),
      ),
      child: Text(
        isRequired ? '필수' : '선택',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isRequired ? MLColors.primaryDeep : context.scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
