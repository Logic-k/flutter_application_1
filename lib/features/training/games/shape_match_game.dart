import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../core/user_provider.dart';
import '../../../core/services/voice_service.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';

class ShapeMatchGame extends StatefulWidget {
  const ShapeMatchGame({super.key});

  @override
  State<ShapeMatchGame> createState() => _ShapeMatchGameState();
}

class _ShapeMatchGameState extends State<ShapeMatchGame> {
  final Random _random = Random();
  int _currentStep = 1;
  final int _totalSteps = 10;
  int _score = 0;

  late IconData _targetIcon;
  late List<IconData> _options;
  bool _isInitialized = false;
  final Stopwatch _stopwatch = Stopwatch();
  
  final List<IconData> _allIcons = [
    Icons.favorite, Icons.star, Icons.circle, Icons.square, 
    Icons.change_history, Icons.pentagon, Icons.hexagon, Icons.diamond,
    Icons.extension, Icons.cloud, Icons.wb_sunny, Icons.auto_awesome,
    Icons.brightness_3, Icons.eco, Icons.bolt, Icons.rocket,
  ];

  @override
  void initState() {
    super.initState();
    _generateProblem();
    _isInitialized = true;
    _stopwatch.start();
  }

  void _generateProblem() {
    final diffProvider = context.read<DifficultyProvider>();
    final level = diffProvider.getLevel(GameCategory.perception);

    _targetIcon = _allIcons[_random.nextInt(_allIcons.length)];
    
    int optionCount = (level <= 3) ? 4 : (level <= 6) ? 6 : (level <= 9) ? 9 : 12;

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
    _stopwatch.stop();
    double responseTime = _stopwatch.elapsedMilliseconds / 1000.0;
    
    bool isCorrect = (selected == _targetIcon);
    if (isCorrect) _score++;

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
      context.read<UserProvider>().setCognitiveScore('attention', (_score / _totalSteps) * 10.0);
      VoiceService().speakSuccess();
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('지각 훈련 완료!'),
        content: Text('$_totalSteps문제 중 $_score문제를 맞히셨습니다.\n난이도가 클라우드에 저장되었습니다!'),
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
    if (!_isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final theme = Theme.of(context);

    return GameTemplate(
      title: '같은 모양 찾기',
      objective: '상단에 제시된 도형과 똑같은 모양을 아래에서 찾으세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(_targetIcon, size: 80, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 50),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (_options.length <= 4) ? 2 : (_options.length <= 9) ? 3 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => _checkAnswer(_options[index]),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: theme.brightness == Brightness.light ? 0.05 : 0.3),
                        blurRadius: 10,
                      ),
                    ],
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Icon(_options[index], size: 36, color: theme.colorScheme.onSurface),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
