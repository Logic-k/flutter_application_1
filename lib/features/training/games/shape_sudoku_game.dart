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

  // 3×3용 기호 3개 / 4×4용 기호 4개
  static const List<IconData> _symbols = [
    Icons.wb_sunny_outlined,
    Icons.cloud_outlined,
    Icons.beach_access_outlined,
    Icons.waves_outlined,
  ];

  late int _gridSize;   // 3 또는 4
  late List<List<int>> _grid;
  late int _targetRow;
  late int _targetCol;
  late int _correctSymbolIdx;

  @override
  void initState() {
    super.initState();
    _generateSudoku();
    _stopwatch.start();
  }

  // ── Latin Square 생성 ──────────────────────────────────────────
  // 기본 cyclic 패턴에서 행/열/기호를 랜덤 순열하여 다양한 패턴 생성
  List<List<int>> _buildLatinSquare(int n, {bool randomize = true}) {
    // 기본 순환 패턴
    List<List<int>> grid =
        List.generate(n, (i) => List.generate(n, (j) => (i + j) % n));

    if (!randomize) return grid;

    // 행 셔플
    final rowOrder = List.generate(n, (i) => i)..shuffle(_random);
    grid = rowOrder.map((r) => List<int>.from(grid[r])).toList();

    // 열 셔플
    final colOrder = List.generate(n, (i) => i)..shuffle(_random);
    grid = List.generate(n, (r) => colOrder.map((c) => grid[r][c]).toList());

    // 기호 순열 (같은 모양이 다른 위치에 오게)
    final symOrder = List.generate(n, (i) => i)..shuffle(_random);
    grid = List.generate(
        n, (r) => grid[r].map((v) => symOrder[v]).toList());

    return grid;
  }

  void _generateSudoku() {
    final level = context.read<DifficultyProvider>().getLevel(GameCategory.memory);

    // Level 1-4: 3×3 (단순 순환 패턴으로 규칙 파악 용이)
    // Level 5-10: 4×4 (랜덤 Latin Square로 난이도↑)
    _gridSize = (level <= 4) ? 3 : 4;
    final randomize = level >= 5;

    _grid = _buildLatinSquare(_gridSize, randomize: randomize);

    // 타겟 셀 하나만 숨기고 나머지는 모두 표시
    _targetRow = _random.nextInt(_gridSize);
    _targetCol = _random.nextInt(_gridSize);
    _correctSymbolIdx = _grid[_targetRow][_targetCol];

    _stopwatch.reset();
  }

  void _checkAnswer(int selectedIdx) {
    _stopwatch.stop();
    final reactionTime = _stopwatch.elapsedMilliseconds / 1000.0;

    final isCorrect = selectedIdx == _correctSymbolIdx;
    if (isCorrect) {
      _score++;
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    context.read<DifficultyProvider>().updatePerformance(
      GameCategory.memory,
      isCorrect,
      responseTime: reactionTime,
    );

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _generateSudoku();
        _stopwatch.start();
      });
    } else {
      context
          .read<UserProvider>()
          .setCognitiveScore('memory', (_score / _totalSteps) * 100.0);
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
    final theme = Theme.of(context);
    final diffProvider = context.watch<DifficultyProvider>();
    final level = diffProvider.getLevel(GameCategory.memory);
    final targetTime = diffProvider.getTargetTime(GameCategory.memory);

    final iconSize = _gridSize == 3 ? 44.0 : 34.0;
    final questionFontSize = _gridSize == 3 ? 40.0 : 30.0;
    final btnSize = _gridSize == 3 ? 76.0 : 66.0;
    final btnIconSize = _gridSize == 3 ? 34.0 : 28.0;

    return GameTemplate(
      title: '그림 스도쿠',
      objective: '가로, 세로에 겹치지 않게\n물음표(?)에 들어올 알맞은 그림을 찾으세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      child: Column(
        children: [
          // 난이도 + 권장시간 배지
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoBadge(theme, Icons.bar_chart_outlined,
                  'Lv.$level  $_gridSize×$_gridSize'),
              const SizedBox(width: 10),
              _infoBadge(theme, Icons.timer_outlined,
                  '목표 ${targetTime.toStringAsFixed(1)}초'),
            ],
          ),
          const SizedBox(height: 20),

          // 그리드
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha: theme.brightness == Brightness.light
                            ? 0.05
                            : 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Table(
                border: TableBorder.all(color: theme.dividerColor, width: 2),
                children: List.generate(_gridSize, (r) {
                  return TableRow(
                    children: List.generate(_gridSize, (c) {
                      final isTarget = r == _targetRow && c == _targetCol;
                      return AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          alignment: Alignment.center,
                          color: isTarget
                              ? theme.primaryColor.withValues(alpha: 0.12)
                              : null,
                          child: isTarget
                              ? Text(
                                  '?',
                                  style: TextStyle(
                                    fontSize: questionFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                )
                              : Icon(
                                  _symbols[_grid[r][c]],
                                  size: iconSize,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),

          const Spacer(),
          Text(
            '알맞은 그림을 선택하세요',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 보기 버튼 (_gridSize 개)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_gridSize, (idx) {
              return InkWell(
                onTap: () => _checkAnswer(idx),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: btnSize,
                  height: btnSize,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.25)),
                  ),
                  child: Icon(_symbols[idx],
                      color: theme.primaryColor, size: btnIconSize),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.primaryColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
