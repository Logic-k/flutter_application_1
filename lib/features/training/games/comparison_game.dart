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

class ComparisonGame extends StatefulWidget {
  const ComparisonGame({super.key});

  @override
  State<ComparisonGame> createState() => _ComparisonGameState();
}

class _ComparisonGameState extends State<ComparisonGame> {
  final Random _random = Random();
  int _currentStep = 1;
  final int _totalSteps = 10;
  int _score = 0;
  late final String _attemptId;
  late final DateTime _startedAt;
  TrainingAttemptInput? _completionInput;
  bool _isSaving = false;
  bool _isFinished = false;

  late String _leftExpr;
  late int _leftVal;
  late String _rightExpr;
  late int _rightVal;
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

    int range = 10 + (level * 10);

    // 좌우 값이 같으면 정답이 없는 문제가 되므로 다를 때까지 재생성한다.
    // (식 치환 이후에도 값이 같아질 수 있어 전체를 루프로 감싼다)
    do {
      _leftVal = _random.nextInt(range) + 1;
      _leftExpr = '$_leftVal';

      _rightVal = _random.nextInt(range) + 1;
      _rightExpr = '$_rightVal';

      if (_random.nextDouble() < (level * 0.1).clamp(0.1, 0.8)) {
        int a = _random.nextInt(range ~/ 2) + 1;
        int b = _random.nextInt(range ~/ 2) + 1;
        _leftVal = a + b;
        _leftExpr = '$a + $b';
      }

      if (_random.nextDouble() < (level * 0.1).clamp(0.1, 0.8)) {
        int a = _random.nextInt(range ~/ 2) + 1;
        int b = _random.nextInt(range ~/ 2) + 1;
        _rightVal = a + b;
        _rightExpr = '$a + $b';
      }
    } while (_leftVal == _rightVal);
  }

  void _checkAnswer(bool leftSelected) {
    if (_isSaving || _isFinished) return;

    bool isCorrect =
        (leftSelected && _leftVal > _rightVal) ||
        (!leftSelected && _rightVal > _leftVal);
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
        activityId: 'comparison',
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
      title: '누가 큰가요?',
      objective: '더 큰 숫자를 가진 쪽을 터치하세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      adaptiveCategory: GameCategory.calculation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: _buildChoiceCard(theme, _leftExpr, true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: _buildChoiceCard(theme, _rightExpr, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard(ThemeData theme, String expr, bool isLeft) {
    return InkWell(
      key: Key('comparison-answer-${isLeft ? 'left' : 'right'}'),
      onTap: _isSaving || _isFinished ? null : () => _checkAnswer(isLeft),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: theme.brightness == Brightness.light ? 0.05 : 0.3,
              ),
              blurRadius: 10,
            ),
          ],
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Text(
          expr,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
