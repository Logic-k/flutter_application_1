import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../core/settings_provider.dart';
import '../../../core/services/voice_service.dart';
import '../application/training_attempt_input.dart';
import '../application/training_completion_ui.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';
import '../training_progress_provider.dart';

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
  bool _isSaving = false;
  late final String _attemptId;
  late final DateTime _startedAt;
  TrainingAttemptInput? _completionInput;

  // 3×3용 기호 3개 / 4×4용 기호 4개
  static const List<IconData> _symbols = [
    Icons.wb_sunny_outlined,
    Icons.cloud_outlined,
    Icons.beach_access_outlined,
    Icons.waves_outlined,
  ];

  // 보기와 격자는 아이콘만 그리므로 스크린리더가 읽을 텍스트가 존재하지 않는다.
  // 이 게임에서 실제로 사용하는 4개 기호만 한국어 이름으로 옮겨 준다.
  // IconData는 == 를 재정의하고 있어 const Map의 키로 쓸 수 없으므로 조건문으로 둔다.
  static String _symbolName(IconData icon) {
    if (icon == Icons.wb_sunny_outlined) return '해';
    if (icon == Icons.cloud_outlined) return '구름';
    if (icon == Icons.beach_access_outlined) return '우산';
    if (icon == Icons.waves_outlined) return '물결';
    return '보기';
  }

  // 격자를 "줄 단위"로 읽어 줘야 가로·세로에 겹치면 안 된다는 규칙을
  // 눈으로 보지 않고도 귀로 따라갈 수 있다.
  String _buildGridSemanticLabel() {
    final buffer = StringBuffer('$_gridSize 곱하기 $_gridSize 그림 스도쿠 문제. ');
    for (var r = 0; r < _gridSize; r++) {
      final cells = <String>[];
      for (var c = 0; c < _gridSize; c++) {
        final isTarget = r == _targetRow && c == _targetCol;
        cells.add(isTarget ? '물음표' : _symbolName(_symbols[_grid[r][c]]));
      }
      buffer.write('${r + 1}번째 줄, ${cells.join(', ')}. ');
    }
    buffer.write('물음표 자리에 들어갈 그림을 고르세요.');
    return buffer.toString();
  }

  late int _gridSize; // 3 또는 4
  late List<List<int>> _grid;
  late int _targetRow;
  late int _targetCol;
  late int _correctSymbolIdx;

  @override
  void initState() {
    super.initState();
    _attemptId = createTrainingAttemptId();
    _startedAt = DateTime.now();
    _generateSudoku();
    _stopwatch.start();
  }

  // ── Latin Square 생성 ──────────────────────────────────────────
  // 기본 cyclic 패턴에서 행/열/기호를 랜덤 순열하여 다양한 패턴 생성
  List<List<int>> _buildLatinSquare(int n, {bool randomize = true}) {
    // 기본 순환 패턴
    List<List<int>> grid = List.generate(
      n,
      (i) => List.generate(n, (j) => (i + j) % n),
    );

    if (!randomize) return grid;

    // 행 셔플
    final rowOrder = List.generate(n, (i) => i)..shuffle(_random);
    grid = rowOrder.map((r) => List<int>.from(grid[r])).toList();

    // 열 셔플
    final colOrder = List.generate(n, (i) => i)..shuffle(_random);
    grid = List.generate(n, (r) => colOrder.map((c) => grid[r][c]).toList());

    // 기호 순열 (같은 모양이 다른 위치에 오게)
    final symOrder = List.generate(n, (i) => i)..shuffle(_random);
    grid = List.generate(n, (r) => grid[r].map((v) => symOrder[v]).toList());

    return grid;
  }

  void _generateSudoku() {
    final level = context.read<DifficultyProvider>().getLevel(
      GameCategory.memory,
    );

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
    if (_isSaving) return;
    _stopwatch.stop();
    final reactionTime = _stopwatch.elapsedMilliseconds / 1000.0;

    final isCorrect = selectedIdx == _correctSymbolIdx;
    final haptic = context.read<SettingsProvider>().hapticFeedbackEnabled;
    if (isCorrect) {
      _score++;
      if (haptic) HapticFeedback.mediumImpact();
    } else {
      if (haptic) HapticFeedback.heavyImpact();
    }

    // 정답/오답이 진동으로만 전달되고 화면에는 아무 표시 없이 다음 문항으로 넘어간다.
    // 시각·촉각 외의 경로가 없으면 스크린리더 사용자는 결과를 알 수 없다(WCAG 1.4.1).
    SemanticsService.sendAnnouncement(
      View.of(context),
      isCorrect
          ? '정답입니다.'
          : '틀렸습니다. 정답은 ${_symbolName(_symbols[_correctSymbolIdx])}입니다.',
      Directionality.of(context),
    );

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
    _completionInput ??= TrainingAttemptInput(
      attemptId: _attemptId,
      userId: userId,
      activityId: 'shape_sudoku',
      completedAt: completedAt,
      score: (_score / _totalSteps) * 100.0,
      correctAnswers: _score,
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
      adaptiveCategory: GameCategory.memory,
      child: Column(
        children: [
          // 난이도 + 권장시간 배지
          // Row로 두면 좁은 폭·큰 글자 배율에서 가로로 넘친다.
          // Wrap은 글자 크기를 줄이지 않고 다음 줄로 내린다(고령 사용자 가독성 유지).
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _infoBadge(
                theme,
                Icons.bar_chart_outlined,
                'Lv.$level  $_gridSize×$_gridSize',
              ),
              _infoBadge(
                theme,
                Icons.timer_outlined,
                '목표 ${targetTime.toStringAsFixed(1)}초',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 그리드
          // Expanded + AspectRatio: 폭이 아니라 "남은 세로 공간"에 맞춰 정사각형을
          // 유지한 채 축소된다. 고정 높이로 두면 작은 화면·큰 글자 배율에서
          // 하단 보기 버튼이 잘린다.
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                // 문항 전체를 하나의 라이브 영역으로 묶는다. 문항이 바뀌면 label도
                // 바뀌므로 TalkBack이 새 격자를 자동으로 읽어 준다.
                // label에는 격자를 줄 단위로 풀어 쓴 요약을 담되, 자식 시맨틱스는
                // 지우지 않는다. 화면에 보이는 '?' 텍스트가 접근성 트리에 남아 있어야
                // 스크린리더 사용자도 눈에 보이는 것과 같은 정보를 얻고,
                // 접근성 트리로 요소를 찾는 Maestro E2E도 문항을 인식할 수 있다.
                // 요약과 개별 셀이 겹쳐 낭독되는 편이, 정보가 사라지는 것보다 낫다.
                // Semantics는 제약을 그대로 통과시키므로 레이아웃에는 영향이 없다.
                child: Semantics(
                  liveRegion: true,
                  label: _buildGridSemanticLabel(),
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
                                : 0.2,
                          ),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Table(
                      border: TableBorder.all(
                        color: theme.dividerColor,
                        width: 2,
                      ),
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
                                    ? FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '?',
                                          style: TextStyle(
                                            fontSize: questionFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
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
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            '알맞은 그림을 선택하세요',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 보기 버튼 (_gridSize 개)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_gridSize, (idx) {
              // 보기는 아이콘뿐이라 낭독할 이름이 없고, 순서로도 지목할 수 없다.
              // "몇 번째 보기인지 + 무슨 그림인지"를 함께 담아야 음성만으로 고를 수 있다.
              // InkWell을 감싸 두면 탭 동작(onTap) 시맨틱스는 그대로 유지된다.
              return Semantics(
                button: true,
                label: '${idx + 1}번 보기, ${_symbolName(_symbols[idx])}',
                child: InkWell(
                  onTap: _isSaving ? null : () => _checkAnswer(idx),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: btnSize,
                    height: btnSize,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      _symbols[idx],
                      color: theme.primaryColor,
                      size: btnIconSize,
                    ),
                  ),
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
          Text(
            label,
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
