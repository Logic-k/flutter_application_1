import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/user_provider.dart';
import 'diary_provider.dart';

class DiaryBookScreen extends StatefulWidget {
  const DiaryBookScreen({super.key});

  @override
  State<DiaryBookScreen> createState() => _DiaryBookScreenState();
}

class _DiaryBookScreenState extends State<DiaryBookScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId =
        context.read<UserProvider>().currentUser?['id'] as int?;
    if (userId == null) return;
    await context.read<DiaryProvider>().loadAllDiaries(userId);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diaries = context.watch<DiaryProvider>().allDiaries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 모아보기'),
        leading: const BackButton(),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : diaries.isEmpty
              ? _buildEmpty(theme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: diaries.length,
                  itemBuilder: (context, i) =>
                      _DiaryCard(entry: diaries[i]),
                ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            '아직 작성한 일기가 없어요.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 첫 번째 일기를 써보세요!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _DiaryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = entry['date'] as String;
    final content = entry['content'] as String;
    final label = _formatDate(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MLColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: MLColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final d = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.year}년 ${d.month}월 ${d.day}일 (${weekdays[d.weekday - 1]})';
  }
}
