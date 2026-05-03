import 'package:flutter/material.dart';
import '../../core/cs_service.dart';

class AdminFaqEditScreen extends StatefulWidget {
  final int? id;
  final String? initialCategory;
  final String? initialQuestion;
  final String? initialAnswer;

  const AdminFaqEditScreen({
    super.key,
    this.id,
    this.initialCategory,
    this.initialQuestion,
    this.initialAnswer,
  });

  @override
  State<AdminFaqEditScreen> createState() => _AdminFaqEditScreenState();
}

class _AdminFaqEditScreenState extends State<AdminFaqEditScreen> {
  static const _categories = ['계정', '훈련', '보행', '기타'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late String _category;
  bool _isSaving = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    _category = (widget.initialCategory != null &&
            _categories.contains(widget.initialCategory))
        ? widget.initialCategory!
        : _categories.first;
    _questionController =
        TextEditingController(text: widget.initialQuestion ?? '');
    _answerController =
        TextEditingController(text: widget.initialAnswer ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await CsService.updateFaq(
          widget.id!,
          category: _category,
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
        );
      } else {
        await CsService.createFaq(
          category: _category,
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
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
      appBar: AppBar(title: Text(_isEdit ? 'FAQ 수정' : 'FAQ 작성')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: '카테고리'),
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: '질문'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '질문을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: '답변',
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 8,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '답변을 입력해 주세요.' : null,
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
