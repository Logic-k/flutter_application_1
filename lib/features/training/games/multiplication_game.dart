import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import 'dart:math';
import '../../../core/user_provider.dart';
import '../../../core/services/voice_service.dart';
import '../application/training_attempt_input.dart';
import '../application/training_completion_ui.dart';
import '../widgets/adaptive_answer_grid.dart';
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
  // 화면의 '×' 기호는 스크린리더가 곱셈으로 읽어 주지 못해 뜻이 사라진다.
  // 그래서 낭독 전용 한국어 표현을 따로 보관한다.
  late String _spokenExpression;
  late int _answer;
  late List<int> _options;
  bool _isInitialized = false;

  // 이 게임은 정답/오답을 화면에 표시하지 않고 곧바로 다음 문항으로 넘어간다.
  // 시각 정보조차 없으므로, 직전 결과를 다음 문항 낭독 앞에 붙여 청각 경로를 만든다.
  String _feedbackLabel = '';

  // liveRegion 은 label 이 바뀔 때 자동 낭독되므로, 문항이 바뀌면 새 문제가 읽힌다.
  String get _questionSemanticsLabel =>
      '$_feedbackLabel문제 $_currentStep번. $_spokenExpression. 정답을 아래 보기에서 고르세요.';

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
      _spokenExpression = '$a 곱하기 $b';
    } else if (level <= 6) {
      a = _random.nextInt(8) + 2;
      b = _random.nextInt(9) + 1;
      _answer = a * b;
      _expression = '$a × $b';
      _spokenExpression = '$a 곱하기 $b';
    } else if (level <= 9) {
      a = _random.nextInt(9) + 11;
      b = _random.nextInt(9) + 2;
      _answer = a * b;
      _expression = '$a × $b';
      _spokenExpression = '$a 곱하기 $b';
    } else {
      a = _random.nextInt(8) + 2;
      b = _random.nextInt(8) + 2;
      c = _random.nextInt(20) + 1;
      _answer = (a * b) + c;
      _expression = '($a × $b) + $c';
      // 괄호는 낭독되지 않으므로 계산 순서를 말로 풀어 준다.
      _spokenExpression = '$a 곱하기 $b, 그 결과에 $c 더하기';
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

    // _generateProblem() 이 _answer 를 덮어쓰기 전에 결과 문구를 만들어 둔다.
    _feedbackLabel = isCorrect ? '정답입니다. ' : '틀렸습니다. 정답은 $_answer 이었습니다. ';

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
        children: [
          // 수식 카드: 세로 공간이 부족하면 비율을 유지한 채 축소된다.
          Flexible(
            flex: 4,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 60,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.rPill),
                  ),
                  // '×' 기호는 스크린리더가 뜻대로 읽지 못하므로 한국어 label 을 덧붙인다.
                  // 다만 자식 시맨틱스는 지우지 않는다. 화면에 보이는 수식 텍스트가
                  // 접근성 트리에 그대로 남아야 Maestro E2E 가 이 요소를 찾을 수 있고,
                  // 보이는 글자가 트리에서 사라지는 편이 중복 낭독보다 더 나쁘다.
                  child: Semantics(
                    liveRegion: true,
                    label: _questionSemanticsLabel,
                    child: Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 6,
            child: AdaptiveAnswerGrid(
              itemCount: _options.length,
              columns: 2,
              spacing: 20,
              childAspectRatio: 1.5,
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
                      borderRadius: BorderRadius.circular(AppTheme.rPanel),
                    ),
                  ),
                  // 바깥이 아니라 버튼의 child 를 감싼다. 그래야 Key 와 탭 동작이
                  // 그대로 ElevatedButton 에 남는다. label 은 "몇 번째 보기인지"를
                  // 알려 주는 추가 정보일 뿐이므로, 보기 숫자 자체의 시맨틱스는
                  // 지우지 않고 살려 둔다. Maestro E2E 가 접근성 트리에서 숫자
                  // 텍스트로 보기를 찾기 때문이다.
                  child: Semantics(
                    button: true,
                    label: '${index + 1}번 보기, ${_options[index]}',
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _options[index].toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
