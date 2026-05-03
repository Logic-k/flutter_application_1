import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceAssessmentScreen extends StatefulWidget {
  const VoiceAssessmentScreen({super.key});

  @override
  State<VoiceAssessmentScreen> createState() => _VoiceAssessmentScreenState();
}

class _VoiceAssessmentScreenState extends State<VoiceAssessmentScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  late AnimationController _pulseController;

  bool _isListening = false;
  bool _isAnalyzing = false;
  bool _speechAvailable = false;
  String _recognizedText = '';
  String _result = '';
  double _analysisScore = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening) _stopListening();
        }
      },
      onError: (error) {
        debugPrint('STT error: $error');
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음성 인식을 사용할 수 없습니다. 마이크 권한을 확인해주세요.')),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _result = '';
      _startTime = DateTime.now();
    });

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (mounted) {
          setState(() => _recognizedText = result.recognizedWords);
        }
      },
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 90),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    _analyzeText();
  }

  void _analyzeText() {
    final text = _recognizedText.trim();
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 30;

    if (text.isEmpty) {
      setState(() {
        _isAnalyzing = false;
        _result = '음성이 인식되지 않았습니다.\n조용한 환경에서 다시 시도해 주세요.';
        _analysisScore = 0;
      });
      return;
    }

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final totalWords = words.length;
    final uniqueWords = words.map((w) => w.toLowerCase()).toSet().length;

    final ttr = totalWords > 0 ? uniqueWords / totalWords : 0.0;
    final wordsPerMin = duration > 0 ? (totalWords / duration) * 60 : 0.0;

    // 점수 산출 (0~100)
    double ttrScore = (ttr * 100).clamp(0, 40).toDouble(); // 최대 40점
    double speedScore = 0.0;
    if (wordsPerMin >= 60 && wordsPerMin <= 180) {
      speedScore = 30.0; // 적정 속도 (60~180 wpm)
    } else if (wordsPerMin > 30 && wordsPerMin < 60) {
      speedScore = 20.0;
    } else if (wordsPerMin > 180) {
      speedScore = 15.0;
    } else {
      speedScore = 10.0;
    }
    double volumeScore = (totalWords >= 30 ? 30.0 : totalWords.toDouble()).clamp(0, 30);

    _analysisScore = (ttrScore + speedScore + volumeScore).clamp(0, 100);

    String assessment;
    String detail;
    if (_analysisScore >= 75) {
      assessment = '인지 건강 상태: 양호';
      detail = '어휘 다양성과 발화 속도가 모두 정상 범위입니다.';
    } else if (_analysisScore >= 50) {
      assessment = '인지 건강 상태: 보통';
      detail = '꾸준한 인지 훈련으로 발화 능력을 유지해 보세요.';
    } else {
      assessment = '인지 건강 상태: 주의 필요';
      detail = '좀 더 긴 문장으로 다양한 어휘를 사용해 보세요.';
    }

    setState(() {
      _isAnalyzing = false;
      _result = '$assessment\n\n'
          '• 총 발화 단어: $totalWords개\n'
          '• 어휘 다양성(TTR): ${(ttr * 100).toStringAsFixed(1)}%\n'
          '• 발화 속도: ${wordsPerMin.toStringAsFixed(0)} 단어/분\n\n'
          '$detail';
    });
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('초기 음성 진단'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isAnalyzing && _result.isEmpty) ...[
                Text(
                  '최근 가장 행복했던 기억에 대해\n1분간 자유롭게 이야기해주세요.',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'AI가 발화 속도와 어휘 다양성을 분석하여\n인지 건강 상태를 체크합니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              _buildCenterVisualizer(theme),
              if (_isListening && _recognizedText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _recognizedText,
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
              if (_isAnalyzing)
                _buildAnalysisStatus(theme)
              else if (_result.isNotEmpty)
                _buildResultView(theme)
              else
                _buildRecordButton(theme),
              const SizedBox(height: 16),
              if (!_isAnalyzing && _result.isEmpty)
                Text(
                  _isListening
                      ? '듣고 있어요... (누르면 중지)'
                      : (_speechAvailable
                          ? '아래 버튼을 눌러 시작하세요'
                          : '마이크 권한을 허용해주세요'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isListening
                        ? theme.primaryColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterVisualizer(ThemeData theme) {
    if (_isAnalyzing) return const SizedBox.shrink();

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isListening)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 150 * (1 + _pulseController.value * 0.2),
                  height: 150 * (1 + _pulseController.value * 0.2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withValues(alpha: 0.1),
                  ),
                );
              },
            ),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening
                  ? theme.primaryColor.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: _isListening
                    ? theme.primaryColor.withValues(alpha: 0.2)
                    : theme.colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: Icon(
              _result.isNotEmpty
                  ? Icons.check_circle_outline
                  : Icons.mic_none_outlined,
              size: 80,
              color: _isListening
                  ? theme.primaryColor
                  : (_result.isNotEmpty
                      ? Colors.green
                      : theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton(ThemeData theme) {
    return SizedBox(
      height: 70,
      child: ElevatedButton(
        onPressed: _isListening ? _stopListening : _startListening,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isListening ? Colors.red : theme.primaryColor,
          foregroundColor:
              _isListening ? Colors.white : theme.colorScheme.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isListening ? Icons.stop : Icons.play_arrow),
            const SizedBox(width: 12),
            Text(
              _isListening ? '녹음 중지하기' : '녹음 시작하기',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisStatus(ThemeData theme) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        const Text('AI 분석 엔진 작동 중...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('어휘 다양성과 발화 패턴을 추출하고 있습니다.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildResultView(ThemeData theme) {
    final isGood = _analysisScore >= 50;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isGood ? Colors.green : Colors.orange)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isGood ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isGood ? Icons.check_circle : Icons.info_outline,
                    color: isGood ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '분석 점수: ${_analysisScore.toStringAsFixed(0)}점',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isGood ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _result,
                style:
                    const TextStyle(fontSize: 14, height: 1.6),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _result = '';
              _recognizedText = '';
              _analysisScore = 0;
            });
          },
          child: const Text('다시 측정하기'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: FilledButton(
            onPressed: _finishOnboarding,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('시작하기',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
