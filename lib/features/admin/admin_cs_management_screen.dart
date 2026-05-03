import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/cs_service.dart';

class AdminCsManagementScreen extends StatefulWidget {
  const AdminCsManagementScreen({super.key});

  @override
  State<AdminCsManagementScreen> createState() =>
      _AdminCsManagementScreenState();
}

class _AdminCsManagementScreenState extends State<AdminCsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _noticesFuture;
  late Future<List<Map<String, dynamic>>> _faqsFuture;
  late Future<List<Map<String, dynamic>>> _inquiriesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refresh();
  }

  void _refresh() {
    setState(() {
      _noticesFuture = CsService.fetchNotices();
      _faqsFuture = CsService.fetchFaqs();
      _inquiriesFuture = CsService.fetchAllInquiries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '공지사항'),
            Tab(text: 'FAQ'),
            Tab(text: '문의함'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NoticeTab(future: _noticesFuture, onRefresh: _refresh),
          _FaqTab(future: _faqsFuture, onRefresh: _refresh),
          _InquiryTab(future: _inquiriesFuture, onRefresh: _refresh),
        ],
      ),
    );
  }
}

class _NoticeTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onRefresh;

  const _NoticeTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return const Center(child: Text('공지사항이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final n = notices[i];
              return ListTile(
                title: Text(n['title'] as String? ?? ''),
                subtitle: Text(n['is_pinned'] == true ? '고정됨' : ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () async {
                        await context.push('/admin/notice_edit', extra: {
                          'id': n['id'],
                          'title': n['title'],
                          'body': n['body'],
                          'is_pinned': n['is_pinned'],
                        });
                        onRefresh();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: Colors.red[400]),
                      onPressed: () async {
                        final confirm = await _confirmDelete(context);
                        if (confirm) {
                          await CsService.deleteNotice(n['id'] as int);
                          onRefresh();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/notice_edit');
          onRefresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FaqTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onRefresh;

  const _FaqTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final faqs = snapshot.data ?? [];
          if (faqs.isEmpty) {
            return const Center(child: Text('FAQ가 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: faqs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final f = faqs[i];
              return ListTile(
                leading: Chip(
                    label: Text(f['category'] as String? ?? '',
                        style: const TextStyle(fontSize: 11))),
                title: Text(f['question'] as String? ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () async {
                        await context.push('/admin/faq_edit', extra: {
                          'id': f['id'],
                          'category': f['category'],
                          'question': f['question'],
                          'answer': f['answer'],
                        });
                        onRefresh();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: Colors.red[400]),
                      onPressed: () async {
                        final confirm = await _confirmDelete(context);
                        if (confirm) {
                          await CsService.deleteFaq(f['id'] as int);
                          onRefresh();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/faq_edit');
          onRefresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InquiryTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onRefresh;

  const _InquiryTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final inquiries = snapshot.data ?? [];
        if (inquiries.isEmpty) {
          return const Center(child: Text('접수된 문의가 없습니다.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: inquiries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final inq = inquiries[i];
            final isAnswered = inq['status'] == 'answered';
            final date = DateTime.tryParse(inq['created_at'] ?? '');
            final dateStr = date != null
                ? DateFormat('MM.dd HH:mm', 'ko_KR').format(date)
                : '';
            return ListTile(
              leading: Icon(
                isAnswered ? Icons.check_circle_outline : Icons.hourglass_top,
                color: isAnswered ? Colors.green : Colors.amber[700],
              ),
              title: Text(inq['title'] as String? ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle:
                  Text('${inq['username']}  ·  $dateStr'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await context.push('/admin/inquiry_detail/${inq['id']}');
                onRefresh();
              },
            );
          },
        );
      },
    );
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제')),
          ],
        ),
      ) ??
      false;
}
