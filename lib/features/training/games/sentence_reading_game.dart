import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../../../core/user_provider.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';
import '../../../core/services/voice_service.dart';

class SentenceReadingGame extends StatefulWidget {
  const SentenceReadingGame({super.key});

  @override
  State<SentenceReadingGame> createState() => _SentenceReadingGameState();

  static double computeSpeechScore(String target, String recognized) {
    String cleanTarget = target.replaceAll(' ', '');
    String cleanInput = recognized.replaceAll(' ', '');
    if (cleanInput.isEmpty) return 0.0;
    if (cleanInput.contains(cleanTarget) || cleanTarget.contains(cleanInput)) {
      return 100.0;
    }
    return (cleanInput.length / cleanTarget.length * 100).clamp(0, 100).toDouble();
  }
}

class _SentenceReadingGameState extends State<SentenceReadingGame> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  
  int _currentStep = 1;
  final int _totalSteps = 5;
  
  final List<String> _sentences = [
    "화창한 봄날에 개나리가 피었습니다.",
    "건강을 위해 매일 꾸준히 걷는 것이 좋습니다.",
    "아침에 일찍 일어나서 물 한 잔을 마십니다.",
    "가장 행복했던 기억을 떠올려 보세요.",
    "오늘 점심으로 무엇을 맛있게 드셨나요?"
  ];

  late String _targetSentence;

  @override
  void initState() {
    super.initState();
    _targetSentence = _sentences[0];
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
    if (mounted) setState(() {});
  }

  void _listen() async {
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
    final double score = SentenceReadingGame.computeSpeechScore(_targetSentence, _text);

    if (score > 70) {
      context.read<DifficultyProvider>().updatePerformance(GameCategory.perception, true);
      _nextStep();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('다시 한번 명확하게 읽어주세요.')),
      );
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
      context.read<UserProvider>().setCognitiveScore('perception', 100.0);
      VoiceService().speakSuccess();
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('문장 읽기 완료!'),
        content: const Text('말하기 훈련은 언어 능력과 기억력 유지에 큰 도움이 됩니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
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
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 10),
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
              color: _text.isEmpty ? theme.colorScheme.onSurfaceVariant : theme.primaryColor,
              fontWeight: _text.isEmpty ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _listen,
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
