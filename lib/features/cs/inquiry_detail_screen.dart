import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/cs_service.dart';

class InquiryDetailScreen extends StatelessWidget {
  final int inquiryId;

  const InquiryDetailScreen({super.key, required this.inquiryId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('문의 상세')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: CsService.fetchInquiryDetail(inquiryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('문의 내역을 찾을 수 없습니다.'));
          }
          final createdAt = DateTime.tryParse(data['created_at'] ?? '');
          final dateStr = createdAt != null
              ? DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko_KR').format(createdAt)
              : '';
          final reply = data['reply'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 문의 내용 카드
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? '',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(dateStr,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.grey)),
                        const Divider(height: 20),
                        Text(data['body'] ?? '',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 관리자 답변 섹션
                Row(
                  children: [
                    Icon(Icons.support_agent,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('관리자 답변',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                if (reply != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reply['body'] ?? '',
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          () {
                            final d =
                                DateTime.tryParse(reply['created_at'] ?? '');
                            return d != null
                                ? DateFormat('yyyy.MM.dd HH:mm', 'ko_KR')
                                    .format(d)
                                : '';
                          }(),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '아직 답변이 등록되지 않았습니다.\n빠른 시일 내 답변 드리겠습니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
