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

class SequenceGame extends StatefulWidget {
  const SequenceGame({super.key});

  @override
  State<SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<SequenceGame> {
  final Random _random = Random();
  int _currentStep = 1;
  final int _totalSteps = 5;
  int _score = 0;
  late final String _attemptId;
  late final DateTime _startedAt;
  TrainingAttemptInput? _completionInput;
  bool _isSaving = false;
  bool _isFinished = false;

  late List<int> _sequence;
  late int _correctAnswer;
  late List<int> _options;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _attemptId = createTrainingAttemptId();
    _startedAt = DateTime.now();
    _generateSequence();
    _isInitialized = true;
  }

  void _generateSequence() {
    final diffProvider = context.read<DifficultyProvider>();
    final level = diffProvider.getLevel(GameCategory.logic);

    int start = _random.nextInt(10) + 1;
    int diff = _random.nextInt(5) + 2;
    int type = (level <= 3) ? _random.nextInt(2) : _random.nextInt(4);

    int seqLength = (level >= 7) ? 5 : 4;

    _sequence = [];
    if (type == 0) {
      for (int i = 0; i < seqLength; i++) {
        _sequence.add(start + (i * diff));
      }
    } else if (type == 1) {
      start = 50 + (level * 5);
      for (int i = 0; i < seqLength; i++) {
        _sequence.add(start - (i * diff));
      }
    } else if (type == 2) {
      diff = 2;
      for (int i = 0; i < seqLength; i++) {
        _sequence.add(start * pow(diff, i).toInt());
      }
    } else {
      int current = start;
      for (int i = 0; i < seqLength; i++) {
        _sequence.add(current);
        current += (i + 1);
      }
    }

    int blankIndex = _random.nextInt(seqLength);
    _correctAnswer = _sequence[blankIndex];
    _sequence[blankIndex] = -1;

    _options = [_correctAnswer];
    while (_options.length < 4) {
      int wrong = _correctAnswer + (_random.nextInt(10) - 5);
      if (!_options.contains(wrong) && wrong > 0) {
        _options.add(wrong);
      }
    }
    _options.shuffle();
  }

  void _checkAnswer(int selected) {
    if (_isSaving || _isFinished) return;

    bool isCorrect = (selected == _correctAnswer);
    if (isCorrect) _score++;

    context.read<DifficultyProvider>().updatePerformance(
      GameCategory.logic,
      isCorrect,
    );

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _generateSequence();
      });
    } else {
      final completedAt = DateTime.now();
      _completionInput = TrainingAttemptInput(
        attemptId: _attemptId,
        userId: context.read<UserProvider>().currentUser!['id'] as int,
        activityId: 'sequence',
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
      title: '규칙 찾아보기',
      objective: '물음표(?)에 들어갈 알맞은 숫자를 고르세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      adaptiveCategory: GameCategory.logic,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _sequence.map((n) {
              return Container(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: n == -1
                      ? theme.primaryColor.withValues(alpha: 0.1)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: n == -1 ? theme.primaryColor : theme.dividerColor,
                    width: 2,
                  ),
                ),
                child: Text(
                  n == -1 ? '?' : '$n',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: n == -1
                        ? theme.primaryColor
                        : theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Icon(
            Icons.arrow_right_alt,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 48),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: _options.asMap().entries.map((entry) {
              final index = entry.key;
              final opt = entry.value;
              return ElevatedButton(
                key: Key('sequence-answer-$index'),
                onPressed: _isSaving || _isFinished
                    ? null
                    : () => _checkAnswer(opt),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text('$opt'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
