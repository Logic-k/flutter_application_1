import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/cs_service.dart';

class AdminInquiryDetailScreen extends StatefulWidget {
  final int inquiryId;
  const AdminInquiryDetailScreen({super.key, required this.inquiryId});

  @override
  State<AdminInquiryDetailScreen> createState() =>
      _AdminInquiryDetailScreenState();
}

class _AdminInquiryDetailScreenState extends State<AdminInquiryDetailScreen> {
  final _replyController = TextEditingController();
  bool _isSending = false;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await CsService.fetchInquiryDetail(widget.inquiryId);
    if (mounted) setState(() => _data = data);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await CsService.replyToInquiry(
        inquiryId: widget.inquiryId,
        body: text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답변이 등록되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('답변 등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _data;

    return Scaffold(
      appBar: AppBar(title: const Text('문의 답변')),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 문의 내용
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(data['username'] as String? ?? '',
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(color: Colors.grey)),
                            const Spacer(),
                            Text(
                              () {
                                final d = DateTime.tryParse(
                                    data['created_at'] ?? '');
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
                        const SizedBox(height: 8),
                        Text(data['title'] as String? ?? '',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 20),
                        Text(data['body'] as String? ?? '',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 기존 답변 또는 답변 입력
                if (data['reply'] != null) ...[
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
                        Text('등록된 답변',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                            (data['reply'] as Map<String, dynamic>)['body']
                                    as String? ??
                                '',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ] else ...[
                  Text('답변 작성',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: '답변 내용을 입력해 주세요',
                      alignLabelWithHint: true,
                    ),
                    minLines: 4,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSending ? null : _sendReply,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('답변 보내기',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
