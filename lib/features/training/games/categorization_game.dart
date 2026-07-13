import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/user_provider.dart';
import '../../../core/settings_provider.dart';
import '../../../core/services/voice_service.dart';
import '../widgets/game_template.dart';
import '../difficulty_provider.dart';

class CategorizationGame extends StatefulWidget {
  const CategorizationGame({super.key});

  @override
  State<CategorizationGame> createState() => _CategorizationGameState();
}

class _CategorizationGameState extends State<CategorizationGame> {
  static const int _totalSteps = 10;

  // 문제 풀 — [단어, 정답카테고리, 오답1, 오답2, 오답3]
  // 난이도에 따라 사용할 부분집합과 보기 수가 달라짐
  // ★ easy(1-3): 식품류만 / medium(4-6): 전체 / hard(7-10): 전체 + 4지선다
  static const List<List<String>> _easyBank = [
    ['사과',     '과일',   '채소', '육류',  '곡류'],
    ['배',       '과일',   '채소', '어류',  '유제품'],
    ['포도',     '과일',   '채소', '곡류',  '육류'],
    ['딸기',     '과일',   '채소', '육류',  '어류'],
    ['복숭아',   '과일',   '채소', '유제품','곡류'],
    ['수박',     '과일',   '채소', '어류',  '육류'],
    ['오렌지',   '과일',   '채소', '곡류',  '유제품'],
    ['귤',       '과일',   '채소', '육류',  '어류'],
    ['바나나',   '과일',   '채소', '유제품','곡류'],
    ['감',       '과일',   '채소', '어류',  '육류'],
    ['시금치',   '채소',   '과일', '육류',  '곡류'],
    ['당근',     '채소',   '과일', '곡류',  '어류'],
    ['양파',     '채소',   '과일', '어류',  '유제품'],
    ['배추',     '채소',   '과일', '육류',  '곡류'],
    ['감자',     '채소',   '과일', '곡류',  '어류'],
    ['고구마',   '채소',   '과일', '유제품','육류'],
    ['오이',     '채소',   '과일', '어류',  '곡류'],
    ['호박',     '채소',   '과일', '육류',  '유제품'],
    ['마늘',     '채소',   '과일', '곡류',  '어류'],
    ['상추',     '채소',   '과일', '어류',  '육류'],
    ['고등어',   '어류',   '육류', '채소',  '곡류'],
    ['갈치',     '어류',   '육류', '과일',  '유제품'],
    ['참치',     '어류',   '육류', '채소',  '곡류'],
    ['연어',     '어류',   '육류', '과일',  '채소'],
    ['멸치',     '어류',   '육류', '채소',  '유제품'],
    ['소고기',   '육류',   '어류', '채소',  '과일'],
    ['돼지고기', '육류',   '어류', '과일',  '곡류'],
    ['닭고기',   '육류',   '어류', '채소',  '유제품'],
    ['쌀',       '곡류',   '채소', '과일',  '어류'],
    ['보리',     '곡류',   '채소', '어류',  '유제품'],
    ['밀',       '곡류',   '채소', '육류',  '과일'],
    ['옥수수',   '곡류',   '채소', '과일',  '어류'],
    ['우유',     '유제품', '과일', '채소',  '곡류'],
    ['치즈',     '유제품', '어류', '채소',  '육류'],
    ['요거트',   '유제품', '과일', '어류',  '곡류'],
  ];

  static const List<List<String>> _hardBank = [
    ['의자',       '가구', '가전', '탈것', '운동'],
    ['책상',       '가구', '가전', '운동', '탈것'],
    ['침대',       '가구', '가전', '탈것', '운동'],
    ['소파',       '가구', '가전', '운동', '탈것'],
    ['옷장',       '가구', '가전', '탈것', '운동'],
    ['냉장고',     '가전', '가구', '탈것', '운동'],
    ['세탁기',     '가전', '가구', '운동', '탈것'],
    ['에어컨',     '가전', '가구', '탈것', '운동'],
    ['청소기',     '가전', '가구', '운동', '탈것'],
    ['전자레인지', '가전', '가구', '탈것', '운동'],
    ['버스',       '탈것', '가구', '가전', '운동'],
    ['기차',       '탈것', '가구', '운동', '가전'],
    ['비행기',     '탈것', '가구', '가전', '운동'],
    ['자전거',     '탈것', '운동', '가구', '가전'],
    ['오토바이',   '탈것', '가전', '가구', '운동'],
    ['수영',       '운동', '가전', '가구', '탈것'],
    ['등산',       '운동', '가전', '탈것', '가구'],
    ['달리기',     '운동', '가전', '가구', '탈것'],
    ['요가',       '운동', '가전', '가구', '탈것'],
    ['줄넘기',     '운동', '탈것', '가전', '가구'],
  ];

  late List<Map<String, dynamic>> _questions;
  int _score = 0;
  int _currentStep = 1;
  bool _isFinished = false;
  bool _waitingNext = false;

  @override
  void initState() {
    super.initState();
    _buildQuestions();
  }

  // 난이도에 따라 문제풀 선택 및 보기 수 결정
  void _buildQuestions() {
    final rng = Random();
    final level =
        context.read<DifficultyProvider>().getLevel(GameCategory.logic);

    // Level 1-3: 식품 카테고리만 (쉬운 단어, 3지선다)
    // Level 4-6: 식품 + 생활 전체 (3지선다)
    // Level 7-10: 전체 (4지선다)
    final int optionCount = level >= 7 ? 4 : 3;
    final pool = level <= 3
        ? _easyBank
        : [..._easyBank, ..._hardBank];

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
    if (_waitingNext) return;
    _waitingNext = true;

    final isCorrect = selected == _questions[_currentStep - 1]['answer'];
    final haptic = context.read<SettingsProvider>().hapticFeedbackEnabled;
    if (isCorrect) {
      _score++;
      if (haptic) HapticFeedback.mediumImpact();
    } else {
      if (haptic) HapticFeedback.heavyImpact();
    }

    context
        .read<DifficultyProvider>()
        .updatePerformance(GameCategory.logic, isCorrect);

    _showFeedback(isCorrect);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_currentStep < _totalSteps) {
        setState(() {
          _currentStep++;
          _waitingNext = false;
        });
      } else {
        // 0-100 스케일로 저장 (전 카테고리 공통)
        final normalized = (_score / _totalSteps) * 100.0;
        context.read<UserProvider>().setCognitiveScore('logic', normalized);
        VoiceService().speakSuccess();
        setState(() {
          _isFinished = true;
          _waitingNext = false;
        });
      }
    });
  }

  void _showFeedback(bool isCorrect) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? '정답입니다!' : '아쉽네요. 다음 문제를 풀어보세요.'),
        backgroundColor:
            isCorrect ? Colors.green.shade600 : theme.colorScheme.error,
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _restart() {
    setState(() {
      _score = 0;
      _currentStep = 1;
      _isFinished = false;
      _waitingNext = false;
      _buildQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildResultScreen();

    final theme = Theme.of(context);
    final q = _questions[_currentStep - 1];
    final level = context.watch<DifficultyProvider>().getLevel(GameCategory.logic);

    return GameTemplate(
      title: '범주화 훈련',
      objective: '제시된 단어가 어느 분류에 속하는지 선택하세요.',
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      child: Column(
        children: [
          // 난이도 배지
          _levelBadge(level),
          const SizedBox(height: 20),

          // 단어 카드
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.25),
                  width: 2),
            ),
            child: Text(
              q['item'],
              style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
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
                return SizedBox(
                  height: 64,
                  child: OutlinedButton(
                    onPressed: _waitingNext ? null : () => _checkAnswer(option),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: theme.colorScheme.outlineVariant, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      option,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
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
        ? Colors.green
        : level <= 6
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 96, color: Colors.amber),
            const SizedBox(height: 24),
            Text('훈련 완료!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '$_totalSteps문제 중 $_score개 정답',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _restart,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('다시 하기'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('돌아가기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
