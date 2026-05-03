import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../core/user_provider.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';

class ShapeSudokuGame extends StatefulWidget {
  const ShapeSudokuGame({super.key});

  @override
  State<ShapeSudokuGame> createState() => _ShapeSudokuGameState();
}

class _ShapeSudokuGameState extends State<ShapeSudokuGame> {
  final Random _random = Random();
  final Stopwatch _stopwatch = Stopwatch();
  int _currentStep = 1;
  final int _totalSteps = 5;
  int _score = 0;

  final List<IconData> _symbols = [
    Icons.wb_sunny_outlined,
    Icons.cloud_outlined,
    Icons.beach_access_outlined,
    Icons.waves_outlined,
  ];

  late int _gridSize;
  late List<List<int>> _grid;
  late List<List<bool>> _isVisible;
  late int _targetRow;
  late int _targetCol;
  late int _correctSymbolIdx;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _generateSudoku();
    _isInitialized = true;
    _stopwatch.start();
  }

  void _generateSudoku() {
    final diffProvider = context.read<DifficultyProvider>();
    final level = diffProvider.getLevel(GameCategory.memory);

    _gridSize = (level <= 4) ? 3 : 4;
    
    int shift = _random.nextInt(_gridSize);
    _grid = List.generate(_gridSize, (i) => 
      List.generate(_gridSize, (j) => (i + j + shift) % _gridSize)
    );

    int visibleCount = (_gridSize * _gridSize) - (level > 7 ? 4 : 2);
    _isVisible = List.generate(_gridSize, (_) => List.generate(_gridSize, (_) => false));
    
    int placed = 0;
    while (placed < visibleCount) {
      int r = _random.nextInt(_gridSize);
      int c = _random.nextInt(_gridSize);
      if (!_isVisible[r][c]) {
        _isVisible[r][c] = true;
        placed++;
      }
    }

    _targetRow = _random.nextInt(_gridSize);
    _targetCol = _random.nextInt(_gridSize);
    _isVisible[_targetRow][_targetCol] = false;
    _correctSymbolIdx = _grid[_targetRow][_targetCol];
    
    _stopwatch.reset();
  }

  void _checkAnswer(int selectedIdx) {
    _stopwatch.stop();
    double reactionTime = _stopwatch.elapsedMilliseconds / 1000.0;
    
    bool isCorrect = (selectedIdx == _correctSymbolIdx);
    if (isCorrect) {
      _score++;
      HapticFeedback.mediumImpact(); // 성공 시 햅틱 피드백
    } else {
      HapticFeedback.heavyImpact(); // 실패 시 다른 느낌의 피드백
    }

    // 난이도 제공자에게 결과 및 반응 시간 보고
    context.read<DifficultyProvider>().updatePerformance(
      GameCategory.memory, 
      isCorrect, 
      responseTime: reactionTime
    );

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _generateSudoku();
        _stopwatch.start();
      });
    } else {
      context.read<UserProvider>().setCognitiveScore('memory', (_score / _totalSteps) * 100.0);
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('시지각 훈련 완료!'),
        content: Text('참 잘하셨습니다!\n5문제 중 $_score문제를 맞히셨습니다.'),
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
    final diffProvider = context.watch<DifficultyProvider>();
    final targetTime = diffProvider.getTargetTime(GameCategory.memory);

    return GameTemplate(
      title: '그림 스도쿠',
      objective: '가로, 세로에 겹치지 않게\n물음표(?)에 들어올 알맞은 그림을 찾으세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      child: Column(
        children: [
          // 권장 시간 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '권장 시간: ${targetTime.toStringAsFixed(1)}초',
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.brightness == Brightness.light ? 0.05 : 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Table(
                border: TableBorder.all(color: theme.dividerColor, width: 2),
                children: List.generate(_gridSize, (r) {
                  return TableRow(
                    children: List.generate(_gridSize, (c) {
                      bool isTarget = (r == _targetRow && c == _targetCol);
                      bool visible = _isVisible[r][c];
                      return AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          alignment: Alignment.center,
                          color: isTarget ? theme.primaryColor.withValues(alpha: 0.1) : null,
                          child: isTarget
                              ? Text('?', style: TextStyle(fontSize: _gridSize == 3 ? 40 : 32, fontWeight: FontWeight.bold, color: theme.primaryColor))
                              : (visible 
                                  ? Icon(_symbols[_grid[r][c]], size: _gridSize == 3 ? 44 : 36, color: theme.colorScheme.onSurface.withValues(alpha: 0.8))
                                  : const SizedBox.shrink()),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
          const Spacer(),
          Text('알맞은 그림을 선택하세요', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_gridSize, (idx) {
              return InkWell(
                onTap: () => _checkAnswer(idx),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: _gridSize == 3 ? 80 : 70,
                  height: _gridSize == 3 ? 80 : 70,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Icon(_symbols[idx], color: theme.primaryColor, size: _gridSize == 3 ? 36 : 32),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
