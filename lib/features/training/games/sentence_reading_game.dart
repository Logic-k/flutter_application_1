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
        setState(() => _isListening = true);
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
      context.read<DifficultyProvider>().updatePerformance(
        GameCategory.perception,
        false,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('괜찮아요, 다음 문장으로 넘어갈게요.')));
      _nextStep();
    } else {
      _attempts++;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('다시 한번 명확하게 읽어주세요.')));
    }
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
          const SizedBox(height: 40),
          Container(
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
          const Spacer(),
          Text(
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
          const SizedBox(height: 32),
          GestureDetector(
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
          const SizedBox(height: 16),
          Text(
            _isListening ? '듣고 있습니다... (다 읽으면 버튼 클릭)' : '마이크 버튼을 눌러 시작',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
