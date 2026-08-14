import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../application/training_attempt_input.dart';
import '../application/training_completion_ui.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';
import '../training_progress_provider.dart';
import '../../../core/services/voice_service.dart';

/// IconData는 operator ==를 재정의해 const 맵의 키가 될 수 없으므로
/// 지연 초기화되는 최상위 final 맵으로 둔다.
final Map<IconData, String> _iconLabels = <IconData, String>{
  Icons.mic: '마이크',
  Icons.stop: '중지',
};

/// 아이콘만 렌더링되는 요소는 대체 텍스트가 없어 스크린리더 사용자가
/// 무엇을 누르는지 알 수 없다. 그래서 IconData를 한국어 이름으로 옮겨
/// Semantics label에 넣는다.
/// 이 게임은 보기(선택지)가 없고 마이크 조작 아이콘만 쓰지만, 매핑에 없는
/// 아이콘이 와도 다른 게임과 같은 기본값('보기')으로 떨어뜨려 라벨을 비우지 않는다.
String _iconSemanticLabel(IconData icon) => _iconLabels[icon] ?? '보기';

class SentenceReadingGame extends StatefulWidget {
  const SentenceReadingGame({super.key});

  @override
  State<SentenceReadingGame> createState() => _SentenceReadingGameState();

  /// 목표 문장과 인식 결과의 유사도(0~100)를 계산한다.
  ///
  /// 편집 거리(Levenshtein) 기반이라 "같은 길이의 아무 말"로는
  /// 점수가 나오지 않는다. STT가 앞뒤에 잡음 단어를 붙이는 경우를
  /// 대비해, 인식 결과 안에 목표 문장 전체가 포함되면 만점 처리한다.
  static double computeSpeechScore(String target, String recognized) {
    final cleanTarget = target.replaceAll(RegExp(r'[^가-힣0-9A-Za-z]'), '');
    final cleanInput = recognized.replaceAll(RegExp(r'[^가-힣0-9A-Za-z]'), '');
    if (cleanTarget.isEmpty || cleanInput.isEmpty) return 0.0;
    if (cleanInput.contains(cleanTarget)) return 100.0;

    final dist = _levenshtein(cleanTarget, cleanInput);
    final maxLen = max(cleanTarget.length, cleanInput.length);
    return ((1.0 - dist / maxLen) * 100.0).clamp(0.0, 100.0);
  }

  static int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    var prev = List<int>.generate(n + 1, (j) => j);
    var curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }
}

class _SentenceReadingGameState extends State<SentenceReadingGame> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';

  /// 채점 결과가 화면에서는 다음 문장으로 넘어가는 것만으로 표현돼
  /// 시각 정보에 의존한다(WCAG 1.4.1). 스크린리더에도 결과를 전달하려고
  /// 마지막 판정을 문장으로 보관해 liveRegion 라벨 앞에 붙인다.
  String _lastFeedback = '';

  int _currentStep = 1;
  final int _totalSteps = 5;
  final List<double> _sentenceScores = [];
  int _attempts = 0;
  bool _isSaving = false;
  late final String _attemptId;
  late final DateTime _startedAt;
  TrainingAttemptInput? _completionInput;

  final List<String> _sentences = [
    "화창한 봄날에 개나리가 피었습니다.",
    "건강을 위해 매일 꾸준히 걷는 것이 좋습니다.",
    "아침에 일찍 일어나서 물 한 잔을 마십니다.",
    "가장 행복했던 기억을 떠올려 보세요.",
    "오늘 점심으로 무엇을 맛있게 드셨나요?",
  ];

  late String _targetSentence;

  @override
  void initState() {
    super.initState();
    _attemptId = createTrainingAttemptId();
    _startedAt = DateTime.now();
    _targetSentence = _sentences[0];
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
    if (mounted) setState(() {});
  }

  void _listen() async {
    if (_isSaving) return;
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        // 새로 말하기 시작하면 직전 채점 결과는 더 이상 현재 상태가 아니므로
        // 스크린리더가 낡은 판정을 반복해 읽지 않게 비운다.
        setState(() {
          _isListening = true;
          _lastFeedback = '';
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              // _accuracy 삭제됨
            }
          }),
          localeId: 'ko_KR',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _checkResult();
    }
  }

  void _checkResult() {
    final double score = SentenceReadingGame.computeSpeechScore(
      _targetSentence,
      _text,
    );

    if (score > 70) {
      _sentenceScores.add(score);
      _attempts = 0;
      _lastFeedback = '정답입니다. 잘 읽으셨어요.';
      context.read<DifficultyProvider>().updatePerformance(
        GameCategory.perception,
        true,
      );
      _nextStep();
    } else if (_attempts >= 1) {
      // 두 번째 시도도 실패하면 낮은 점수를 기록하고 다음 문장으로 진행
      // (같은 문장에서 무한히 막히는 것 방지)
      _sentenceScores.add(score);
      _attempts = 0;
      _lastFeedback = '아쉽게도 문장이 정확히 인식되지 않았습니다.';
      context.read<DifficultyProvider>().updatePerformance(
        GameCategory.perception,
        false,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('괜찮아요, 다음 문장으로 넘어갈게요.')));
      _nextStep();
    } else {
      // 재시도 분기는 화면이 그대로라 다시 그리지 않는데, 그러면 liveRegion이
      // 갱신되지 않아 스크린리더가 "다시 읽으라"는 안내를 놓친다.
      setState(() {
        _attempts++;
        _lastFeedback = '조금 달라요. 한 번 더 읽어주세요.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('다시 한번 명확하게 읽어주세요.')));
    }
  }

  /// 인식 결과 영역이 스크린리더에 읽어줄 문장을 만든다.
  /// 화면에는 인식된 단어만 보이지만, 채점 결과와 다음 할 일까지 함께 읽어야
  /// 화면을 못 보는 사용자도 지금 상태를 알 수 있다.
  String _speechStatusLabel() {
    final buffer = StringBuffer();
    if (_lastFeedback.isNotEmpty) {
      buffer.write('$_lastFeedback ');
    }
    if (_isListening) {
      buffer.write('듣고 있습니다. 문장을 읽은 뒤 버튼을 다시 눌러주세요.');
    } else if (_text.isEmpty) {
      buffer.write('아직 인식된 말이 없습니다. 마이크 버튼을 누르고 문장을 읽어주세요.');
    } else {
      buffer.write('인식된 말, $_text');
    }
    return buffer.toString();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _targetSentence = _sentences[_currentStep - 1];
        _text = '';
      });
    } else {
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
    final averageScore = _sentenceScores.isEmpty
        ? 0.0
        : _sentenceScores.reduce((a, b) => a + b) / _sentenceScores.length;
    _completionInput ??= TrainingAttemptInput(
      attemptId: _attemptId,
      userId: userId,
      activityId: 'sentence_reading',
      completedAt: completedAt,
      score: averageScore,
      correctAnswers: _sentenceScores.where((score) => score > 70).length,
      totalQuestions: _totalSteps,
      durationMs: completedAt.difference(_startedAt).inMilliseconds,
    );

    setState(() => _isSaving = true);
    try {
      final result = await progress.complete(_completionInput!);
      if (!mounted) return;
      VoiceService().speakSuccess();
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
      title: '문장 소리 내어 읽기',
      objective: '화면에 보이는 문장을 또박또박 읽어주세요.\n언어 자극을 통해 뇌를 활성화합니다.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      adaptiveCategory: GameCategory.perception,
      child: Column(
        children: [
          // 제시 문장은 길이가 가변이라 고정 배치하면 하단 마이크가 밀려 잘린다.
          // 남은 공간을 차지하되, 문장이 그보다 길면 카드 안에서 스크롤한다.
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                // 문장이 바뀌면 TalkBack이 새 문항을 자동으로 읽어야 하므로
                // liveRegion으로 표시한다. 라벨에 문항 번호와 문장을 모두 담았기에
                // 안쪽 Text가 다시 읽히지 않도록 하위 시맨틱스는 제외한다.
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: '$_currentStep번째 문장. $_targetSentence',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      _targetSentence,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 채점 결과가 색과 굵기로만 구분돼 시각에 의존하므로(WCAG 1.4.1),
          // 판정과 다음 행동을 문장으로 읽어주는 liveRegion을 덧입힌다.
          Semantics(
            container: true,
            liveRegion: true,
            label: _speechStatusLabel(),
            excludeSemantics: true,
            child: Text(
              _text.isEmpty ? '아래 마이크를 누르고 말씀하세요' : _text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: _text.isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.primaryColor,
                fontWeight: _text.isEmpty ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 마이크는 아이콘만 있어 대체 텍스트가 없다. 아이콘 한국어 이름과
          // 현재 상태(듣는 중/대기)를 라벨로 주되, GestureDetector의 탭 시맨틱스는
          // 그대로 살려야 TalkBack 두 번 탭으로 실행되므로 하위를 제외하지 않는다.
          Semantics(
            button: true,
            enabled: !_isSaving,
            label: _isListening
                ? '${_iconSemanticLabel(Icons.stop)} 버튼. 다 읽었으면 눌러서 채점하세요.'
                : '${_iconSemanticLabel(Icons.mic)} 버튼. 눌러서 문장 읽기를 시작하세요.',
            child: GestureDetector(
              onTap: _isSaving ? null : _listen,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: _isListening ? Colors.red : theme.primaryColor,
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 같은 안내가 바로 위 마이크 버튼 라벨에 이미 들어 있어,
          // 그대로 두면 스크린리더가 두 번 읽는다. 시각 안내는 유지하고
          // 음성 경로에서만 뺀다.
          ExcludeSemantics(
            child: Text(
              _isListening ? '듣고 있습니다... (다 읽으면 버튼 클릭)' : '마이크 버튼을 눌러 시작',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
