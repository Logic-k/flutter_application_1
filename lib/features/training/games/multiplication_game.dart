import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../core/user_provider.dart';
import '../../../core/services/voice_service.dart';
import '../application/training_attempt_input.dart';
import '../application/training_completion_ui.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';
import '../training_progress_provider.dart';

class MultiplicationGame extends StatefulWidget {
  const MultiplicationGame({super.key});

  @override
  State<MultiplicationGame> createState() => _MultiplicationGameState();
}

class _MultiplicationGameState extends State<MultiplicationGame> {
  final Random _random = Random();
  int _currentStep = 1;
  final int _totalSteps = 10;
  int _score = 0;
  late final String _attemptId;
  late final DateTime _startedAt;
  TrainingAttemptInput? _completionInput;
  bool _isSaving = false;
  bool _isFinished = false;

  late String _expression;
  late int _answer;
  late List<int> _options;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _attemptId = createTrainingAttemptId();
    _startedAt = DateTime.now();
    _generateProblem();
    _isInitialized = true;
  }

  void _generateProblem() {
    final diffProvider = context.read<DifficultyProvider>();
    final level = diffProvider.getLevel(GameCategory.calculation);

    int a, b, c = 0;

    if (level <= 3) {
      a = _random.nextInt(4) + 2;
      b = _random.nextInt(9) + 1;
      _answer = a * b;
      _expression = '$a × $b';
    } else if (level <= 6) {
      a = _random.nextInt(8) + 2;
      b = _random.nextInt(9) + 1;
      _answer = a * b;
      _expression = '$a × $b';
    } else if (level <= 9) {
      a = _random.nextInt(9) + 11;
      b = _random.nextInt(9) + 2;
      _answer = a * b;
      _expression = '$a × $b';
    } else {
      a = _random.nextInt(8) + 2;
      b = _random.nextInt(8) + 2;
      c = _random.nextInt(20) + 1;
      _answer = (a * b) + c;
      _expression = '($a × $b) + $c';
    }

    _options = [_answer];
    while (_options.length < 4) {
      int offset = _random.nextInt(10) - 5;
      if (offset == 0) offset = 5;
      int wrong = _answer + offset;
      if (wrong > 0 && !_options.contains(wrong)) {
        _options.add(wrong);
      }
    }
    _options.shuffle();
  }

  void _checkAnswer(int selected) {
    if (_isSaving || _isFinished) return;

    bool isCorrect = (selected == _answer);
    if (isCorrect) _score++;

    context.read<DifficultyProvider>().updatePerformance(
      GameCategory.calculation,
      isCorrect,
    );

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _generateProblem();
      });
    } else {
      final completedAt = DateTime.now();
      _completionInput = TrainingAttemptInput(
        attemptId: _attemptId,
        userId: context.read<UserProvider>().currentUser!['id'] as int,
        activityId: 'multiplication',
        completedAt: completedAt,
        score: (_score / _totalSteps) * 100.0,
        correctAnswers: _score,
        totalQuestions: _totalSteps,
        durationMs: completedAt.difference(_startedAt).inMilliseconds,
      );
      setState(() => _isFinished = true);
      _submitCompletion();
    }
  }

  Future<void> _submitCompletion() async {
    final input = _completionInput;
    if (input == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final result = await context.read<TrainingProgressProvider>().complete(
        input,
      );
      if (!mounted) return;
      VoiceService().speakSuccess();
      await showTrainingCompletionResult(context, result);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('기록을 저장하지 못했습니다. 다시 시도해 주세요.'),
          action: SnackBarAction(
            label: '다시 시도',
            onPressed: () => _submitCompletion(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);

    return GameTemplate(
      title: '구구단 맞추기',
      objective: '가운데 수식의 정답을 아래에서 선택하세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      adaptiveCategory: GameCategory.calculation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _expression,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 60),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.5,
            ),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              return ElevatedButton(
                key: Key('multiplication-answer-$index'),
                onPressed: _isSaving || _isFinished
                    ? null
                    : () => _checkAnswer(_options[index]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.cardColor,
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: theme.brightness == Brightness.light ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _options[index].toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
