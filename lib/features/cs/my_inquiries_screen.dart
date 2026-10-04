import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/ml_widgets.dart';
import '../../core/motion/staggered_column.dart';
import '../../core/cs_service.dart';
import '../../core/user_provider.dart';

class MyInquiriesScreen extends StatefulWidget {
  const MyInquiriesScreen({super.key});

  @override
  State<MyInquiriesScreen> createState() => _MyInquiriesScreenState();
}

class _MyInquiriesScreenState extends State<MyInquiriesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  late String _username;

  @override
  void initState() {
    super.initState();
    _username =
        context.read<UserProvider>().currentUser?['username'] as String? ?? '';
    _future = CsService.fetchMyInquiries(_username);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('내 문의 내역')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        // 문의 카드 모양(제목 + 날짜)의 스켈레톤.
        // 로딩 → 내용은 크로스페이드(08 계획 G-05).
        builder: (context, snapshot) => MLLoadSwitcher(
          loading: snapshot.connectionState == ConnectionState.waiting,
          skeleton: const MLSkeletonList(count: 4, leading: false, padding: EdgeInsets.all(16), spacing: 8),
          child: Builder(builder: (context) {
          if (snapshot.hasError) {
            return MLErrorState(
              onRetry: () => setState(() {
                _future = CsService.fetchMyInquiries(_username);
              }),
            );
          }
          final inquiries = snapshot.data ?? [];
          if (inquiries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: context.scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('문의 내역이 없습니다.',
                      style: TextStyle(color: context.scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/cs/inquiry_submit'),
                    child: const Text('문의하기'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = CsService.fetchMyInquiries(_username);
              });
            },
            child: StaggerScope(
              playKey: 'my_inquiries',
              child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: inquiries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final inq = inquiries[index];
                final isAnswered = inq['status'] == 'answered';
                final createdAt =
                    DateTime.tryParse(inq['created_at'] ?? '');
                final dateStr = createdAt != null
                    ? DateFormat('yyyy.MM.dd', 'ko_KR').format(createdAt)
                    : '';
                return StaggerItem(
                  index: index,
                  child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    title: Text(
                      inq['title'] ?? '',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(dateStr,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: context.scheme.onSurfaceVariant)),
                    trailing: _StatusChip(isAnswered: isAnswered),
                    onTap: () =>
                        context.push('/cs/inquiry_detail/${inq['id']}'),
                  ),
                  ),
                );
              },
            ),
            ),
          );
        }),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cs/inquiry_submit'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('새 문의'),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isAnswered;
  const _StatusChip({required this.isAnswered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAnswered
            ? MLColors.good.withValues(alpha: 0.15)
            : MLColors.warn.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.rField),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAnswered ? Icons.check_circle_outline : Icons.hourglass_top,
            size: 14,
            color: isAnswered ? MLColors.goodText : MLColors.warnText,
          ),
          const SizedBox(width: 4),
          Text(
            isAnswered ? '답변 완료' : '답변 대기중',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isAnswered ? MLColors.goodText : MLColors.warnText,
            ),
          ),
        ],
      ),
    );
  }
}
