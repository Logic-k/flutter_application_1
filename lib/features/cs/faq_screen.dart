import 'package:flutter/material.dart';
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('불러오기 실패: ${snapshot.error}'));
          }
          final faqs = snapshot.data ?? [];
          if (faqs.isEmpty) {
            return const Center(
              child: Text('등록된 FAQ가 없습니다.',
                  style: TextStyle(color: Colors.grey)),
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

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final cat in sortedKeys) ...[
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(faq['answer'] ?? '',
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
