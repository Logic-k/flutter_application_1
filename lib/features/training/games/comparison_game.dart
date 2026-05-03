import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../core/user_provider.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';

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

  late String _leftExpr;
  late int _leftVal;
  late String _rightExpr;
  late int _rightVal;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _generateProblem();
    _isInitialized = true;
  }

  void _generateProblem() {
    final diffProvider = context.read<DifficultyProvider>();
    final level = diffProvider.getLevel(GameCategory.calculation);

    int range = 10 + (level * 10);
    
    _leftVal = _random.nextInt(range) + 1;
    _leftExpr = '$_leftVal';
    
    _rightVal = _random.nextInt(range) + 1;
    if (_leftVal == _rightVal) _rightVal++;
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
  }

  void _checkAnswer(bool leftSelected) {
    bool isCorrect = (leftSelected && _leftVal > _rightVal) || (!leftSelected && _rightVal > _leftVal);
    if (isCorrect) _score++;

    context.read<DifficultyProvider>().updatePerformance(GameCategory.calculation, isCorrect);

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _generateProblem();
      });
    } else {
      context.read<UserProvider>().setCognitiveScore('calculation', (_score / _totalSteps) * 10.0);
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('계산 훈련 완료!'),
        content: Text('$_totalSteps문제 중 $_score문제를 맞히셨습니다.\n난이도가 클라우드와 동기화되었습니다.'),
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
      title: '누가 큰가요?',
      objective: '더 큰 숫자를 가진 쪽을 터치하세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: _buildChoiceCard(theme, _leftExpr, true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              ),
              Expanded(child: _buildChoiceCard(theme, _rightExpr, false)),
            ],
          ),
          const SizedBox(height: 32),
          Text('= 같습니다 =', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildChoiceCard(ThemeData theme, String expr, bool isLeft) {
    return InkWell(
      onTap: () => _checkAnswer(isLeft),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        alignment: Alignment.center,
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
        child: Text(
          expr,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
