import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/cs_service.dart';
import '../../core/user_provider.dart';

class InquirySubmitScreen extends StatefulWidget {
  const InquirySubmitScreen({super.key});

  @override
  State<InquirySubmitScreen> createState() => _InquirySubmitScreenState();
}

class _InquirySubmitScreenState extends State<InquirySubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final username =
        context.read<UserProvider>().currentUser?['username'] as String? ?? '';
    setState(() => _isSubmitting = true);
    try {
      await CsService.submitInquiry(
        username: username,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의가 접수되었습니다. 빠른 시일 내 답변 드리겠습니다.')),
      );
      context.pushReplacement('/cs/my_inquiries');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문의 접수 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('1:1 문의하기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '문의 제목을 입력해 주세요',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: '문의 내용',
                hintText: '궁금하신 내용을 자세히 작성해 주세요',
                alignLabelWithHint: true,
              ),
              minLines: 5,
              maxLines: 10,
              maxLength: 500,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '내용을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('문의 제출',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
