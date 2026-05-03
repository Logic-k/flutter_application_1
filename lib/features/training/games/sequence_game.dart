import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../core/user_provider.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';

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

  late List<int> _sequence;
  late int _correctAnswer;
  late List<int> _options;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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

  void _checkAnswer(int selected) {
    bool isCorrect = (selected == _correctAnswer);
    if (isCorrect) _score++;

    context.read<DifficultyProvider>().updatePerformance(GameCategory.logic, isCorrect);

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _generateSequence();
      });
    } else {
      context.read<UserProvider>().setCognitiveScore('logic', (_score / _totalSteps) * 10.0);
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('논리 훈련 완료!'),
        content: Text('$_totalSteps문제 중 $_score문제를 맞히셨습니다.'),
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
      title: '규칙 찾아보기',
      objective: '물음표(?)에 들어갈 알맞은 숫자를 고르세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _sequence.map((n) {
              return Container(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: n == -1 ? theme.primaryColor.withValues(alpha: 0.1) : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: n == -1 ? theme.primaryColor : theme.dividerColor, width: 2),
                ),
                child: Text(
                  n == -1 ? '?' : '$n',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: n == -1 ? theme.primaryColor : theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Icon(Icons.arrow_right_alt, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 48),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: _options.map((opt) {
              return ElevatedButton(
                onPressed: () => _checkAnswer(opt),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: Text('$opt'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
