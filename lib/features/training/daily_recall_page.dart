import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'application/training_attempt_input.dart';
import 'application/training_completion_ui.dart';
import 'training_progress_provider.dart';
import 'widgets/game_template.dart';

class DailyRecallPage extends StatefulWidget {
  const DailyRecallPage({super.key});

  @override
  State<DailyRecallPage> createState() => _DailyRecallPageState();
}

class _DailyRecallPageState extends State<DailyRecallPage> {
  final TextEditingController _controller = TextEditingController();
  int _currentQuestionIndex = 0;
  final List<String> _questions = [
    '오늘 아침 식사로 무엇을 드셨나요?',
    '오늘 가장 기억에 남는 일이 무엇인가요?',
    '어제 일기예보가 어땠는지 기억나시나요?',
    '최근에 만난 사람 중 가장 반가웠던 분은 누구인가요?',
    '오늘의 기분은 5점 만점에 몇 점인가요?',
  ];

  final List<String> _answers = [];
  bool _isSaving = false;
  late final String _attemptId;
  late final DateTime _startedAt;
  TrainingAttemptInput? _completionInput;

  @override
  void initState() {
    super.initState();
    _attemptId = createTrainingAttemptId();
    _startedAt = DateTime.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_isSaving) return;
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('생각나는 내용을 짧게라도 적어주세요.')));
      return;
    }

    final answer = _controller.text;
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    setState(() {
      _answers.add(answer);
      if (!isLastQuestion) {
        _controller.clear();
        _currentQuestionIndex++;
      }
    });
    if (isLastQuestion) {
      _submitCompletion();
    }
  }

  Future<void> _submitCompletion() async {
    if (_isSaving) return;
    final progress = context.read<TrainingProgressProvider>();
    final userId = progress.userId;
    if (userId == null) {
      _showSaveFailure();
      return;
    }

    final completedAt = DateTime.now();
    _completionInput ??= TrainingAttemptInput(
      attemptId: _attemptId,
      userId: userId,
      activityId: 'daily_recall',
      completedAt: completedAt,
      durationMs: completedAt.difference(_startedAt).inMilliseconds,
    );

    setState(() => _isSaving = true);
    try {
      final result = await progress.complete(_completionInput!);
      if (!mounted) return;
      await showTrainingCompletionResult(context, result);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSaveFailure();
    }
  }

  void _showSaveFailure() {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('기록을 저장하지 못했습니다. 다시 시도해 주세요.'),
        action: SnackBarAction(label: '다시 시도', onPressed: _submitCompletion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GameTemplate(
      title: '일상 회상 훈련',
      objective: '오늘의 사소한 기억들을 떠올려보며\n뇌의 기억 저장소를 활성화합니다.',
      currentStep: _currentQuestionIndex + 1,
      totalSteps: _questions.length,
      adaptiveCategory: null,
      child: ListView(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: theme.primaryColor,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  _questions[_currentQuestionIndex],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _controller,
            enabled: !_isSaving && _completionInput == null,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '여기에 내용을 적어주세요...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              fillColor: theme.cardColor,
              filled: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : _completionInput == null
                  ? _nextQuestion
                  : _submitCompletion,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _completionInput != null
                          ? '다시 시도'
                          : _currentQuestionIndex == _questions.length - 1
                          ? '완료하기'
                          : '다음 질문',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '천천히 생각해보셔도 괜찮습니다.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
