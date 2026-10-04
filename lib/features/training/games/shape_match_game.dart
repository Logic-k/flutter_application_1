import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import 'dart:math';
import '../../../core/user_provider.dart';
import '../../../core/services/voice_service.dart';
import '../application/training_attempt_input.dart';
import '../application/training_completion_ui.dart';
import '../widgets/adaptive_answer_grid.dart';
import '../../../core/motion/game_feedback.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';
import '../training_progress_provider.dart';

/// 도형 아이콘을 한국어 이름으로 옮긴 표.
///
/// 이 게임은 화면에 아이콘만 그리기 때문에 스크린리더가 읽을 텍스트가 전혀 없다.
/// 아이콘 자체에는 대체 텍스트가 없으므로 사람이 부르는 이름을 따로 마련해야
/// TalkBack 사용자도 보기를 구분할 수 있다.
/// const 맵으로 만들 수 없는 이유: IconData가 ==를 재정의해 상수 맵의 키로 쓸 수 없다.
final Map<IconData, String> _shapeNames = {
  Icons.favorite: '하트',
  Icons.star: '별',
  Icons.circle: '동그라미',
  Icons.square: '네모',
  Icons.change_history: '세모',
  Icons.pentagon: '오각형',
  Icons.hexagon: '육각형',
  Icons.diamond: '다이아몬드',
  Icons.extension: '퍼즐 조각',
  Icons.cloud: '구름',
  Icons.wb_sunny: '해',
  Icons.auto_awesome: '반짝임',
  Icons.brightness_3: '달',
  Icons.eco: '나뭇잎',
  Icons.bolt: '번개',
  Icons.rocket: '로켓',
};

/// 표에 없는 아이콘이 추가되더라도 낭독이 빈칸이 되지 않도록 '보기'로 대체한다.
String _shapeName(IconData icon) => _shapeNames[icon] ?? '보기';

class ShapeMatchGame extends StatefulWidget {
  const ShapeMatchGame({super.key});

  @override
  State<ShapeMatchGame> createState() => _ShapeMatchGameState();
}

class _ShapeMatchGameState extends State<ShapeMatchGame> {
  // 정답·오답 신호. GameTemplate 이 햅틱·효과음·배지·파티클을 한 곳에서 처리한다.
  final _feedback = GameFeedbackController();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  final Random _random = Random();
  int _currentStep = 1;
  final int _totalSteps = 10;
  int _score = 0;
  late final String _attemptId;
  late final DateTime _startedAt;
  TrainingAttemptInput? _completionInput;
  bool _isSaving = false;
  bool _isFinished = false;

  late IconData _targetIcon;
  late List<IconData> _options;

  /// 직전 응답의 정오 결과를 담아 두는 문구.
  ///
  /// 이 게임은 정답을 고르면 곧바로 다음 문항으로 넘어갈 뿐, 화면에는 아무 표시도
  /// 남지 않는다. 눈으로 보는 사용자는 도형이 바뀌는 것으로 진행을 알지만
  /// 스크린리더 사용자에게는 단서가 없으므로, 문항 안내(liveRegion)에 결과를
  /// 함께 실어 청각으로도 전달한다. (WCAG 1.4.1)
  String? _lastResultMessage;
  bool _isInitialized = false;
  final Stopwatch _stopwatch = Stopwatch();

  final List<IconData> _allIcons = [
    Icons.favorite,
    Icons.star,
    Icons.circle,
    Icons.square,
    Icons.change_history,
    Icons.pentagon,
    Icons.hexagon,
    Icons.diamond,
    Icons.extension,
    Icons.cloud,
    Icons.wb_sunny,
    Icons.auto_awesome,
    Icons.brightness_3,
    Icons.eco,
    Icons.bolt,
    Icons.rocket,
  ];

  @override
  void initState() {
    super.initState();
    _attemptId = createTrainingAttemptId();
    _startedAt = DateTime.now();
    _generateProblem();
    _isInitialized = true;
    _stopwatch.start();
  }

  void _generateProblem() {
    final diffProvider = context.read<DifficultyProvider>();
    final level = diffProvider.getLevel(GameCategory.perception);

    _targetIcon = _allIcons[_random.nextInt(_allIcons.length)];

    int optionCount = (level <= 3)
        ? 4
        : (level <= 6)
        ? 6
        : (level <= 9)
        ? 9
        : 12;

    _options = [_targetIcon];
    while (_options.length < optionCount) {
      IconData wrong = _allIcons[_random.nextInt(_allIcons.length)];
      if (!_options.contains(wrong)) {
        _options.add(wrong);
      }
    }
    _options.shuffle();
  }

  void _checkAnswer(IconData selected) {
    if (_isSaving || _isFinished) return;

    _stopwatch.stop();
    double responseTime = _stopwatch.elapsedMilliseconds / 1000.0;

    bool isCorrect = (selected == _targetIcon);
    if (isCorrect) _score++;

    // 오답일 때 무엇이 정답이었는지까지 알려야 색·아이콘 없이도 학습이 가능하다.
    _lastResultMessage = isCorrect
        ? '정답입니다.'
        : '아쉽지만 오답입니다. 정답은 ${_shapeName(_targetIcon)}였습니다.';
    isCorrect
        ? _feedback.correct()
        : _feedback.wrong('아쉬워요 · 정답은 ${_shapeName(_targetIcon)}');

    context.read<DifficultyProvider>().updatePerformance(
      GameCategory.perception,
      isCorrect,
      responseTime: responseTime,
    );

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _generateProblem();
        _stopwatch.reset();
        _stopwatch.start();
      });
    } else {
      final completedAt = DateTime.now();
      _completionInput = TrainingAttemptInput(
        attemptId: _attemptId,
        userId: context.read<UserProvider>().currentUser!['id'] as int,
        activityId: 'shape_match',
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

    // 문항이 바뀔 때마다 문구가 달라져야 liveRegion이 다시 낭독된다.
    // 단계 번호를 앞에 두어 같은 도형이 연속으로 나와도 갱신이 감지되게 했다.
    final questionLabel = [
      if (_lastResultMessage != null) _lastResultMessage!,
      '$_currentStep번 문제.',
      '제시된 도형은 ${_shapeName(_targetIcon)}입니다.',
      '아래 보기에서 같은 모양을 고르세요.',
    ].join(' ');

    return GameTemplate(
      feedback: _feedback,
      activityId: 'shape_match',
      title: '같은 모양 찾기',
      objective: '상단에 제시된 도형과 똑같은 모양을 아래에서 찾으세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      adaptiveCategory: GameCategory.perception,
      child: Column(
        children: [
          // 제시 도형: 세로 공간이 부족하면 비율을 유지한 채 축소된다.
          Flexible(
            flex: 3,
            // liveRegion으로 지정해 새 문항이 나오면 초점을 옮기지 않아도
            // TalkBack이 스스로 읽어 준다. Semantics는 프록시 위젯이라
            // 기존 Flexible/Center/FittedBox 배치에는 영향이 없다.
            child: Semantics(
              liveRegion: true,
              label: questionLabel,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.rPill),
                    ),
                    child: Icon(
                      _targetIcon,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 7,
            child: AdaptiveAnswerGrid(
              itemCount: _options.length,
              columns: (_options.length <= 4)
                  ? 2
                  : (_options.length <= 9)
                  ? 3
                  : 4,
              itemBuilder: (context, index) {
                // 보기 번호를 함께 읽어 주어야 "왼쪽 위 도형" 같은 시각 표현 없이도
                // 사용자가 몇 번째 보기를 듣고 있는지 알 수 있다.
                // excludeSemantics는 쓰지 않는다. 하위 Icon에는 semanticLabel이
                // 없어 중복 낭독이 생기지 않고, 제외하면 InkWell의 탭 동작까지
                // 접근성 트리에서 사라져 TalkBack으로 선택할 수 없게 된다.
                return Semantics(
                  button: true,
                  label: '${index + 1}번 보기, ${_shapeName(_options[index])}',
                  child: InkWell(
                    key: Key('shape-match-answer-$index'),
                    onTap: _isSaving || _isFinished
                        ? null
                        : () => _checkAnswer(_options[index]),
                    borderRadius: BorderRadius.circular(AppTheme.rPanel),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppTheme.rPanel),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(
                              alpha: theme.brightness == Brightness.light
                                  ? 0.05
                                  : 0.3,
                            ),
                            blurRadius: 10,
                          ),
                        ],
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _options[index],
                            size: 36,
                            color: theme.colorScheme.onSurface,
                          ),
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
