import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/ml_widgets.dart';
import '../../core/cs_service.dart';

class NoticeDetailScreen extends StatefulWidget {
  final String noticeId;

  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = CsService.fetchNoticeById(widget.noticeId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MLErrorState(
              onRetry: () => setState(() {
                _future = CsService.fetchNoticeById(widget.noticeId);
              }),
            );
          }
          final n = snapshot.data;
          if (n == null) {
            return const Center(child: Text('공지사항을 찾을 수 없습니다.'));
          }
          final createdAt = DateTime.tryParse(n['created_at'] ?? '');
          final dateStr = createdAt != null
              ? DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(createdAt)
              : '';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n['title'] ?? '',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(dateStr,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: context.scheme.onSurfaceVariant)),
                const Divider(height: 32),
                Text(n['body'] ?? '', style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}
