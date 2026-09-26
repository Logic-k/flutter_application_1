import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/ml_widgets.dart';
import '../../core/motion/staggered_column.dart';
import '../../core/cs_service.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = CsService.fetchNotices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        // 공지 카드 모양(제목 + 두 줄 본문)의 스켈레톤.
        // 로딩 → 내용은 크로스페이드(08 계획 G-05).
        builder: (context, snapshot) => MLLoadSwitcher(
          loading: snapshot.connectionState == ConnectionState.waiting,
          skeleton: const MLSkeletonList(count: 5, lines: 2, leading: false, padding: EdgeInsets.all(16), spacing: 8),
          child: Builder(builder: (context) {
          if (snapshot.hasError) {
            return MLErrorState(
              onRetry: () => setState(() {
                _future = CsService.fetchNotices();
              }),
            );
          }
          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined, size: 64, color: context.scheme.onSurfaceVariant),
                  SizedBox(height: 12),
                  Text('등록된 공지사항이 없습니다.',
                      style: TextStyle(color: context.scheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = CsService.fetchNotices();
              });
            },
            // 위쪽 카드부터 60ms 간격으로 들어온다. 네 번째부터는 함께(400ms 상한).
            child: StaggerScope(
              playKey: 'notice_list',
              child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = notices[index];
                final isPinned = n['is_pinned'] == true;
                final createdAt = DateTime.tryParse(n['created_at'] ?? '');
                final dateStr = createdAt != null
                    ? DateFormat('yyyy.MM.dd', 'ko_KR').format(createdAt)
                    : '';
                return StaggerItem(
                  index: index,
                  child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.rField),
                    onTap: () =>
                        context.push('/cs/notice_detail/${n['id']}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isPinned) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(AppTheme.rBar),
                                  ),
                                  child: const Text('고정',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  n['title'] ?? '',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n['body'] ?? '',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: context.scheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(dateStr,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: context.scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
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
    );
  }
}
