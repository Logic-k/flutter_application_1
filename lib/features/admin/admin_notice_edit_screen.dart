import 'package:flutter/material.dart';
import '../../core/cs_service.dart';

class AdminNoticeEditScreen extends StatefulWidget {
  final int? id;
  final String? initialTitle;
  final String? initialBody;
  final bool initialPinned;

  const AdminNoticeEditScreen({
    super.key,
    this.id,
    this.initialTitle,
    this.initialBody,
    this.initialPinned = false,
  });

  @override
  State<AdminNoticeEditScreen> createState() => _AdminNoticeEditScreenState();
}

class _AdminNoticeEditScreenState extends State<AdminNoticeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late bool _isPinned;
  bool _isSaving = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialTitle ?? '');
    _bodyController =
        TextEditingController(text: widget.initialBody ?? '');
    _isPinned = widget.initialPinned;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await CsService.updateNotice(
          widget.id!,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          isPinned: _isPinned,
        );
      } else {
        await CsService.createNotice(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          isPinned: _isPinned,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? '공지사항 수정' : '공지사항 작성')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: '내용',
                alignLabelWithHint: true,
              ),
              minLines: 6,
              maxLines: 12,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '내용을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('상단 고정'),
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('저장하기',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
