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

  // 이 게임은 정답/오답을 화면에 따로 표시하지 않고 곧바로 다음 문항으로 넘어간다.
  // 시각적 단서조차 없으므로(WCAG 1.4.1) 직전 결과를 문항 라이브 리전 앞에 붙여
  // 스크린리더가 "정답입니다. 문제 4번..." 형태로 함께 읽도록 보관한다.
  String? _lastAnswerFeedback;

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
        // 결과를 다음 문항 안내와 함께 들려주기 위해 상태로 남긴다.
        _lastAnswerFeedback = isCorrect ? '정답입니다.' : '아쉬워요, 오답입니다.';
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

  // '3 + 4' 같은 수식을 기호 그대로 읽으면 TalkBack이 "삼 플러스 사"처럼
  // 낯설게 발음하므로, 고령 사용자가 알아듣기 쉬운 한국어로 바꿔서 들려준다.
  String _exprToKorean(String expr) =>
      expr.replaceAll('+', '더하기').replaceAll(RegExp(r'\s+'), ' ').trim();

  // 문항 라이브 리전의 label. 문항이 바뀔 때마다 문자열이 달라져야
  // 스크린리더가 새 내용으로 인식하고 자동 낭독하므로 진행 번호까지 포함한다.
  String _buildQuestionSemanticsLabel() {
    final feedback = _lastAnswerFeedback;
    final prefix = feedback == null ? '' : '$feedback ';
    return '$prefix문제 $_currentStep번, 전체 $_totalSteps문제 중. '
        '왼쪽은 ${_exprToKorean(_leftExpr)}, 오른쪽은 ${_exprToKorean(_rightExpr)}. '
        '더 큰 쪽을 선택하세요.';
  }

  // 보기 번호를 앞에 붙여야 스크린리더 사용자가 좌우 위치를 소리만으로 구분할 수 있다.
  String _buildChoiceSemanticsLabel(String expr, bool isLeft) =>
      '${isLeft ? 1 : 2}번 보기, ${isLeft ? '왼쪽' : '오른쪽'}, ${_exprToKorean(expr)}';

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
              // 가운데 'VS'는 시각적 구분자일 뿐이라 그대로 읽히면 소음이 된다.
              // 대신 이 자리를 문항 라이브 리전으로 삼아, 두 카드 사이에 놓인
              // 잎(leaf) 노드 하나가 문항 전체를 대신 낭독하게 했다.
              // (보기 카드를 감싸지 않았으므로 보기 label과 중복 낭독되지 않는다)
              Semantics(
                liveRegion: true,
                excludeSemantics: true,
                label: _buildQuestionSemanticsLabel(),
                child: Padding(
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
              ),
              Expanded(child: _buildChoiceCard(theme, _rightExpr, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard(ThemeData theme, String expr, bool isLeft) {
    final bool enabled = !_isSaving && !_isFinished;

    // Key와 탭 동작은 InkWell에 그대로 두고 바깥만 Semantics로 감싼다.
    // excludeSemantics로 안쪽 숫자 Text의 중복 낭독을 막는 대신,
    // 자식의 탭 액션까지 함께 가려지므로 스크린리더 이중 탭이 죽지 않도록
    // 동일한 처리를 Semantics의 onTap에 한 번 더 선언해 둔다.
    return Semantics(
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      label: _buildChoiceSemanticsLabel(expr, isLeft),
      onTap: enabled ? () => _checkAnswer(isLeft) : null,
      child: InkWell(
        key: Key('comparison-answer-${isLeft ? 'left' : 'right'}'),
        onTap: enabled ? () => _checkAnswer(isLeft) : null,
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
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            expr,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
