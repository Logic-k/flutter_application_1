import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/ml_widgets.dart';
import '../../core/motion/staggered_column.dart';
import '../../core/cs_service.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = CsService.fetchFaqs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('자주 묻는 질문')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        // 질문 행 모양의 스켈레톤.
        // 로딩 → 내용은 크로스페이드(08 계획 G-05).
        builder: (context, snapshot) => MLLoadSwitcher(
          loading: snapshot.connectionState == ConnectionState.waiting,
          skeleton: const MLSkeletonList(count: 6, leading: false, padding: EdgeInsets.all(20), spacing: 10),
          child: Builder(builder: (context) {
          if (snapshot.hasError) {
            return MLErrorState(
              onRetry: () => setState(() {
                _future = CsService.fetchFaqs();
              }),
            );
          }
          final faqs = snapshot.data ?? [];
          if (faqs.isEmpty) {
            return Center(
              child: Text('등록된 FAQ가 없습니다.',
                  style: TextStyle(color: context.scheme.onSurfaceVariant)),
            );
          }

          // 카테고리별 그룹화
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final faq in faqs) {
            final cat = faq['category'] as String? ?? '기타';
            grouped.putIfAbsent(cat, () => []).add(faq);
          }
          final categoryOrder = ['계정', '훈련', '보행', '기타'];
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) {
              final ai = categoryOrder.indexOf(a);
              final bi = categoryOrder.indexOf(b);
              return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
            });

          // 카테고리 묶음이 순서대로 들어온다(첫 진입 1회).
          return StaggerScope(
            playKey: 'faq_list',
            child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final (i, cat) in sortedKeys.indexed)
                StaggerItem(
                  index: i,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(cat,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ),
                ...grouped[cat]!.map(
                  (faq) => ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    leading: const Icon(Icons.help_outline, size: 20),
                    title: Text(faq['question'] ?? '',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppTheme.rChip),
                        ),
                        child: Text(faq['answer'] ?? '',
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
                    ],
                  ),
                ),
            ],
            ),
          );
        }),
        ),
      ),
    );
  }
}
