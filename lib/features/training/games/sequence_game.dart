import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
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

  /// 숫자 칸을 스크린리더가 읽을 한 문장으로 만든다.
  /// 빈칸은 화면에서 '?' 로만 보이기 때문에, 소리로는 몇 번째 자리가 비었는지까지
  /// 알려 주지 않으면 어느 위치를 채워야 하는지 알 수 없다.
  /// 앞머리에 진행 단계를 넣는 이유는, 문항이 우연히 같은 숫자열로 생성돼도
  /// label 이 달라져 liveRegion 재낭독이 확실히 일어나게 하기 위함이다.
  String _questionSemanticsLabel() {
    final parts = <String>[];
    for (int i = 0; i < _sequence.length; i++) {
      final n = _sequence[i];
      parts.add(n == -1 ? '${i + 1}번째는 빈칸' : '${i + 1}번째는 $n');
    }
    return '$_totalSteps문제 중 $_currentStep번째 문제. '
        '숫자 순서는 ${parts.join(', ')}. 빈칸에 들어갈 숫자를 보기에서 고르세요.';
  }

  /// 이 게임은 정답 여부를 화면에 따로 표시하지 않고 곧바로 다음 문항으로 넘어간다.
  /// 스크린리더 사용자는 화면 전환을 눈으로 확인할 수 없어 맞았는지조차 알 수 없으므로,
  /// 결과를 소리(청각 경로)로 따로 알린다. (WCAG 1.4.1 — 시각 단독 전달 금지)
  void _announceResult(bool isCorrect) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      isCorrect ? '정답입니다.' : '아쉬워요. 정답은 $_correctAnswer 입니다.',
      Directionality.of(context),
    );
  }

  void _checkAnswer(int selected) {
    if (_isSaving || _isFinished) return;

    bool isCorrect = (selected == _correctAnswer);
    if (isCorrect) _score++;
    _announceResult(isCorrect);

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
          // 숫자 칸이 하나씩 따로 읽히면 '순서'라는 문제의 핵심이 전달되지 않는다.
          // 그래서 순서 전체를 담은 문장을 label 로 얹어 맥락을 보강한다.
          // 다만 자식 시맨틱스는 지우지 않는다. 각 칸의 숫자와 '?' 는 화면에 실제로
          // 보이는 텍스트이므로 접근성 트리에도 남아 있어야 하고, Maestro E2E 가
          // 바로 그 트리에서 요소를 찾기 때문이다. 낭독이 조금 겹치더라도
          // 정보가 통째로 사라지는 것보다 낫다.
          // liveRegion 은 label 이 바뀔 때 스스로 다시 읽히므로
          // 문항이 넘어가면 새 문제가 자동으로 안내된다.
          Semantics(
            container: true,
            liveRegion: true,
            label: _questionSemanticsLabel(),
            child: Row(
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
                    borderRadius: BorderRadius.circular(AppTheme.rField),
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
              // 보기가 숫자뿐이라 '7' 처럼만 읽히면 네 개 중 어느 버튼인지 구분되지 않는다.
              // 그래서 번호를 붙인 label 을 더해 몇 번째 보기인지 알려 준다.
              // 안쪽 Text 의 시맨틱스는 지우지 않는다. 화면에 보이는 숫자는 접근성
              // 트리에도 남아 있어야 하며, Maestro E2E 가 그 트리에서 보기 숫자를
              // 찾아 탭하기 때문이다. MergeSemantics 로 버튼 노드와 label 을 한 노드로
              // 합쳐 두면 여러 노드로 흩어지지 않고 이어서 읽힌다.
              // 버튼 자체(Key·onPressed)는 손대지 않아야 탭 동작과 E2E 참조가 유지된다.
              return MergeSemantics(
                child: ElevatedButton(
                  key: Key('sequence-answer-$index'),
                  onPressed: _isSaving || _isFinished
                      ? null
                      : () => _checkAnswer(opt),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.rField),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Semantics(
                    button: true,
                    label: '${index + 1}번 보기, $opt',
                    child: Text('$opt'),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
