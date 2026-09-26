import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/services/voice_service.dart';
import '../application/training_attempt_input.dart';
import '../application/training_completion_ui.dart';
import '../../../core/motion/game_feedback.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';
import '../training_progress_provider.dart';

class CategorizationGame extends StatefulWidget {
  const CategorizationGame({super.key});

  @override
  State<CategorizationGame> createState() => _CategorizationGameState();
}

class _CategorizationGameState extends State<CategorizationGame> {
  // 정답·오답 신호. GameTemplate 이 햅틱·효과음·배지·파티클을 한 곳에서 처리한다.
  final _feedback = GameFeedbackController();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  static const int _totalSteps = 10;

  // 문제 풀 — [단어, 정답카테고리, 오답1, 오답2, 오답3]
  // 난이도에 따라 사용할 부분집합과 보기 수가 달라짐
  // ★ easy(1-3): 식품류만 / medium(4-6): 전체 / hard(7-10): 전체 + 4지선다
  static const List<List<String>> _easyBank = [
    ['사과', '과일', '채소', '육류', '곡류'],
    ['배', '과일', '채소', '어류', '유제품'],
    ['포도', '과일', '채소', '곡류', '육류'],
    ['딸기', '과일', '채소', '육류', '어류'],
    ['복숭아', '과일', '채소', '유제품', '곡류'],
    ['수박', '과일', '채소', '어류', '육류'],
    ['오렌지', '과일', '채소', '곡류', '유제품'],
    ['귤', '과일', '채소', '육류', '어류'],
    ['바나나', '과일', '채소', '유제품', '곡류'],
    ['감', '과일', '채소', '어류', '육류'],
    ['시금치', '채소', '과일', '육류', '곡류'],
    ['당근', '채소', '과일', '곡류', '어류'],
    ['양파', '채소', '과일', '어류', '유제품'],
    ['배추', '채소', '과일', '육류', '곡류'],
    ['감자', '채소', '과일', '곡류', '어류'],
    ['고구마', '채소', '과일', '유제품', '육류'],
    ['오이', '채소', '과일', '어류', '곡류'],
    ['호박', '채소', '과일', '육류', '유제품'],
    ['마늘', '채소', '과일', '곡류', '어류'],
    ['상추', '채소', '과일', '어류', '육류'],
    ['고등어', '어류', '육류', '채소', '곡류'],
    ['갈치', '어류', '육류', '과일', '유제품'],
    ['참치', '어류', '육류', '채소', '곡류'],
    ['연어', '어류', '육류', '과일', '채소'],
    ['멸치', '어류', '육류', '채소', '유제품'],
    ['소고기', '육류', '어류', '채소', '과일'],
    ['돼지고기', '육류', '어류', '과일', '곡류'],
    ['닭고기', '육류', '어류', '채소', '유제품'],
    ['쌀', '곡류', '채소', '과일', '어류'],
    ['보리', '곡류', '채소', '어류', '유제품'],
    ['밀', '곡류', '채소', '육류', '과일'],
    ['옥수수', '곡류', '채소', '과일', '어류'],
    ['우유', '유제품', '과일', '채소', '곡류'],
    ['치즈', '유제품', '어류', '채소', '육류'],
    ['요거트', '유제품', '과일', '어류', '곡류'],
  ];

  static const List<List<String>> _hardBank = [
    ['의자', '가구', '가전', '탈것', '운동'],
    ['책상', '가구', '가전', '운동', '탈것'],
    ['침대', '가구', '가전', '탈것', '운동'],
    ['소파', '가구', '가전', '운동', '탈것'],
    ['옷장', '가구', '가전', '탈것', '운동'],
    ['냉장고', '가전', '가구', '탈것', '운동'],
    ['세탁기', '가전', '가구', '운동', '탈것'],
    ['에어컨', '가전', '가구', '탈것', '운동'],
    ['청소기', '가전', '가구', '운동', '탈것'],
    ['전자레인지', '가전', '가구', '탈것', '운동'],
    ['버스', '탈것', '가구', '가전', '운동'],
    ['기차', '탈것', '가구', '운동', '가전'],
    ['비행기', '탈것', '가구', '가전', '운동'],
    ['자전거', '탈것', '운동', '가구', '가전'],
    ['오토바이', '탈것', '가전', '가구', '운동'],
    ['수영', '운동', '가전', '가구', '탈것'],
    ['등산', '운동', '가전', '탈것', '가구'],
    ['달리기', '운동', '가전', '가구', '탈것'],
    ['요가', '운동', '가전', '가구', '탈것'],
    ['줄넘기', '운동', '탈것', '가전', '가구'],
  ];

  late List<Map<String, dynamic>> _questions;
  int _score = 0;
  int _currentStep = 1;
  bool _waitingNext = false;
  bool _isSaving = false;
  late final String _attemptId;
  late final DateTime _startedAt;
  TrainingAttemptInput? _completionInput;

  @override
  void initState() {
    super.initState();
    _attemptId = createTrainingAttemptId();
    _startedAt = DateTime.now();
    _buildQuestions();
  }

  // 난이도에 따라 문제풀 선택 및 보기 수 결정
  void _buildQuestions() {
    final rng = Random();
    final level = context.read<DifficultyProvider>().getLevel(
      GameCategory.logic,
    );

    // Level 1-3: 식품 카테고리만 (쉬운 단어, 3지선다)
    // Level 4-6: 식품 + 생활 전체 (3지선다)
    // Level 7-10: 전체 (4지선다)
    final int optionCount = level >= 7 ? 4 : 3;
    final pool = level <= 3 ? _easyBank : [..._easyBank, ..._hardBank];

    final shuffled = List.of(pool)..shuffle(rng);
    final picked = shuffled.take(_totalSteps).toList();

    _questions = picked.map((q) {
      final correct = q[1];
      // wrong 보기 optionCount-1 개 선택
      final wrongs = q.sublist(2, 2 + (optionCount - 1));
      final options = [correct, ...wrongs]..shuffle(rng);
      return {'item': q[0], 'answer': correct, 'options': options};
    }).toList();
  }

  void _checkAnswer(String selected) {
    if (_waitingNext || _isSaving) return;
    _waitingNext = true;

    final isCorrect = selected == _questions[_currentStep - 1]['answer'];
    if (isCorrect) _score++;

    context.read<DifficultyProvider>().updatePerformance(
      GameCategory.logic,
      isCorrect,
    );

    _showFeedback(isCorrect);

    Future.delayed(AppMotion.nextQuestionDelay, () {
      if (!mounted) return;
      if (_currentStep < _totalSteps) {
        setState(() {
          _currentStep++;
          _waitingNext = false;
        });
      } else {
        _submitCompletion();
      }
    });
  }

  Future<void> _submitCompletion() async {
    if (_isSaving) return;
    final progress = context.read<TrainingProgressProvider>();
    final userId = progress.userId;
    if (userId == null) {
      _showSaveFailure();
      return;
    }

    _completionInput ??= TrainingAttemptInput(
      attemptId: _attemptId,
      userId: userId,
      activityId: 'categorization',
      completedAt: DateTime.now(),
      score: (_score / _totalSteps) * 100.0,
      correctAnswers: _score,
      totalQuestions: _totalSteps,
      durationMs: DateTime.now().difference(_startedAt).inMilliseconds,
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

  void _showFeedback(bool isCorrect) {
    final message = isCorrect ? '정답입니다!' : '아쉽네요. 다음 문제를 풀어보세요.';

    // 배지는 색 + 아이콘 + 문구로 보이지만 짧게 떴다 사라져 포커스를 받지 못한다.
    // 스크린리더에 직접 낭독을 요청해 청각 경로를 따로 만든다(WCAG 1.4.1).
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );

    isCorrect ? _feedback.correct(message) : _feedback.wrong(message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _questions[_currentStep - 1];
    final level = context.watch<DifficultyProvider>().getLevel(
      GameCategory.logic,
    );

    return GameTemplate(
      feedback: _feedback,
      activityId: 'categorization',
      title: '범주화 훈련',
      objective: '제시된 단어가 어느 분류에 속하는지 선택하세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      adaptiveCategory: GameCategory.logic,
      child: Column(
        children: [
          // 난이도 배지
          _levelBadge(level),
          const SizedBox(height: 20),

          // 단어 카드
          // 문항이 바뀌어도 화면 전환이 없어 스크린리더가 변화를 알아채지 못한다.
          // liveRegion으로 지정해 단계가 넘어갈 때마다 새 단어가 자동 낭독되게 한다.
          // label에는 문항 번호와 해야 할 일까지 담아 맥락을 보강하되,
          // 카드 안 Text의 시맨틱스는 지우지 않고 그대로 남긴다.
          // 화면에 보이는 단어는 접근성 트리에도 남아 있어야 하고,
          // Maestro E2E가 접근성 트리로 문항 텍스트를 찾기 때문이다.
          // 낭독이 조금 겹치는 편이 정보가 사라지는 것보다 낫다.
          Semantics(
            liveRegion: true,
            label:
                '$_currentStep번 문제. ${q['item']}. 어느 분류에 속하는지 아래 보기에서 고르세요.',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.rSheet),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Text(
                q['item'],
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // 보기 버튼
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (q['options'] as List).length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, idx) {
                final option = q['options'][idx] as String;
                final disabled = _waitingNext || _isSaving;
                // 보기 버튼은 텍스트만 읽히면 "과일"처럼 몇 번째 보기인지 알 수 없다.
                // 그래서 보기 번호를 앞에 붙인 label로 순서 정보를 보강한다.
                // 다만 버튼 내부 Text의 시맨틱스는 지우지 않는다. 보기 글자는 화면에
                // 보이는 정보라 접근성 트리에도 남아 있어야 하고, Maestro E2E가
                // 접근성 트리에서 보기 텍스트를 찾아 탭하기 때문이다.
                // onTap은 OutlinedButton과 같은 조건·같은 콜백으로 연결해
                // TalkBack 두 번 탭 동작을 보장한다.
                return Semantics(
                  button: true,
                  enabled: !disabled,
                  label: '${idx + 1}번 보기, $option',
                  onTap: disabled ? null : () => _checkAnswer(option),
                  child: SizedBox(
                    height: 64,
                    child: OutlinedButton(
                      onPressed: disabled ? null : () => _checkAnswer(option),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.rTile),
                        ),
                      ),
                      child: Text(
                        option,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelBadge(int level) {
    final label = level <= 3
        ? '초급 (Lv.$level)'
        : level <= 6
        ? '중급 (Lv.$level)'
        : '고급 (Lv.$level)';
    final color = level <= 3
        ? MLColors.goodText
        : level <= 6
        ? MLColors.warnText
        : MLColors.badText;
    // 난이도는 배지 색(초록/주황/빨강)으로도 구분되지만 색은 스크린리더에 전달되지 않는다.
    // 그래서 "현재 난이도"라는 맥락을 붙인 label로 의미를 보강한다.
    // 배지 안 Text의 시맨틱스는 그대로 살려 둔다. 화면에 보이는 등급 문구는
    // 접근성 트리에도 있어야 하며, Maestro E2E가 그 텍스트로 난이도를 검증한다.
    return Semantics(
      label: '현재 난이도 $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.rPanel),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
