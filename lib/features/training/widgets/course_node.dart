import 'package:flutter/material.dart';

enum CourseNodeStatus { available, locked, completed }

class CourseNode extends StatelessWidget {
  const CourseNode({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.masteryStars,
    this.onTap,
  }) : assert(masteryStars >= 0 && masteryStars <= 3);

  final String title;
  final String description;
  final IconData icon;
  final CourseNodeStatus status;
  final int masteryStars;
  final VoidCallback? onTap;

  String get _statusText => switch (status) {
    CourseNodeStatus.available => '도전 가능',
    CourseNodeStatus.locked => '잠김',
    CourseNodeStatus.completed => '완료 · 숙련도 별 $masteryStars개',
  };

  IconData get _statusIcon => switch (status) {
    CourseNodeStatus.available => Icons.play_circle_fill_rounded,
    CourseNodeStatus.locked => Icons.lock_rounded,
    CourseNodeStatus.completed => Icons.check_circle_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final foreground = status == CourseNodeStatus.locked
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: '$title, $_statusText, $description',
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: foreground, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(description, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(_statusIcon, color: foreground, size: 20),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                _statusText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (enabled) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      semanticLabel: '열기',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
