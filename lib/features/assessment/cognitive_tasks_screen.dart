import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';
import 'dart:async';
import 'dart:math';

class CognitiveTasksScreen extends StatefulWidget {
  const CognitiveTasksScreen({super.key});

  @override
  State<CognitiveTasksScreen> createState() => _CognitiveTasksScreenState();
}

class _CognitiveTasksScreenState extends State<CognitiveTasksScreen> {
  int _currentTask = 0; // 0: Word Show, 1: Distracter, 2: Recall, 3: Attention
  
  // Word Memory Data
  final List<String> _targetWords = ['사과', '의자', '하늘'];
  final List<String> _recallOptions = ['사과', '바다', '의자', '구두', '하늘', '포크'];
  final Set<String> _selectedWords = {};
  int _memoryScore = 0;

  // Attention Data
  int _attentionPhase = 0;
  int _attentionScore = 0;
  final int _maxAttentionPhases = 5;

  /// 문항별 정답 칸 위치(0~8).
  ///
  /// 예전에는 정답이 항상 4번(정중앙)으로 고정돼 있어, 첫 문항에서 가운데를
  /// 찾은 사용자가 나머지 4문항을 보지도 않고 가운데만 눌러 100점을 받았다.
  /// 그 점수가 attention 카테고리로 DB에 저장되고 임상 리포트까지 흘러가므로,
  /// 측정값이라 부를 수 없는 상태였다.
  late final List<int> _attentionTargets;

  /// 문항별 (정답 기호, 방해 기호) 쌍. 위치만 바꾸면 기호를 외워서 풀 수 있다.
  late final List<({IconData target, IconData distractor})> _attentionIcons;

  static const List<({IconData target, IconData distractor})> _iconPairs = [
    (target: Icons.circle_outlined, distractor: Icons.square_outlined),
    (target: Icons.square_outlined, distractor: Icons.circle_outlined),
    (target: Icons.change_history_outlined, distractor: Icons.square_outlined),
    (target: Icons.star_outline, distractor: Icons.circle_outlined),
    (target: Icons.favorite_outline, distractor: Icons.star_outline),
  ];

  @override
  void initState() {
    super.initState();
    // 화면이 살아 있는 동안 위치가 고정되도록 initState에서 한 번만 뽑는다.
    // build에서 뽑으면 리빌드마다 정답이 옮겨 다닌다.
    final rng = Random();
    _attentionTargets =
        List.generate(_maxAttentionPhases, (_) => rng.nextInt(9));
    _attentionIcons = List.generate(
      _maxAttentionPhases,
      (i) => _iconPairs[i % _iconPairs.length],
    );
    _startWordShow();
  }

  void _startWordShow() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _currentTask = 1);
    });
  }

  void _onDistracterComplete() {
    setState(() => _currentTask = 2);
  }

  void _onRecallComplete() {
    _memoryScore = _selectedWords.where((w) => _targetWords.contains(w)).length;
    // 3문제 중 맞춘 개수를 0~100점으로 환산 (예: 3개 다 맞히면 100점)
    context.read<UserProvider>().setCognitiveScore('memory', (_memoryScore / 3.0) * 100.0);
    setState(() => _currentTask = 3);
  }

  void _onAttentionComplete() {
    // 5문제 중 맞춘 개수를 0~100점으로 환산
    context.read<UserProvider>().setCognitiveScore('attention', (_attentionScore / 5.0) * 100.0);
    context.push('/assessment_result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('인지 과제')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildCurrentTask(),
      ),
    );
  }

  Widget _buildCurrentTask() {
    switch (_currentTask) {
      case 0: return _buildWordShow();
      case 1: return _buildDistracter();
      case 2: return _buildRecall();
      case 3: return _buildAttention();
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildWordShow() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('다음 단어 3개를 잘 기억해주세요 (5초)', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _targetWords.map((w) => Chip(label: Text(w, style: const TextStyle(fontSize: 24)))).toList(),
        ),
      ],
    );
  }

  Widget _buildDistracter() {
    // 단어 암기와 회상 사이의 '방해 과제'(간섭). 즉답 리허설을 막기 위해
    // 실제로 골라야 하는 3지선다로 제시한다. 정답을 눌러야 다음으로 진행.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('잠깐! 간단한 계산을 해주세요', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 40),
        const Text('5 + 3 = ?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [6, 8, 9].map((n) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () {
                  if (n == 8) {
                    _onDistracterComplete();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('다시 한번 계산해 보세요.'),
                        duration: Duration(milliseconds: 800),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                ),
                child: Text('$n', style: const TextStyle(fontSize: 24)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecall() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('기억나는 단어 3개를 골라주세요', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _recallOptions.map((w) {
            final isSelected = _selectedWords.contains(w);
            return ChoiceChip(
              label: Text(w, style: const TextStyle(fontSize: 18)),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedWords.add(w);
                  } else {
                    _selectedWords.remove(w);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        FilledButton(
          onPressed: _selectedWords.length == 3 ? _onRecallComplete : null,
          child: const Text('제출하기'),
        ),
      ],
    );
  }

  Widget _buildAttention() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('다른 기호를 하나만 찾아주세요 (${_attentionPhase + 1}/$_maxAttentionPhases)', style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 40),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: List.generate(9, (index) {
            final targetIndex = _attentionTargets[_attentionPhase];
            final icons = _attentionIcons[_attentionPhase];
            final isTarget = index == targetIndex;
            return Semantics(
              button: true,
              label: '${index + 1}번 칸',
              child: InkWell(
                onTap: () {
                  if (isTarget) {
                    _attentionScore++;
                  }

                  if (_attentionPhase < _maxAttentionPhases - 1) {
                    setState(() {
                      _attentionPhase++;
                    });
                  } else {
                    _onAttentionComplete();
                  }
                },
                child: Icon(
                  isTarget ? icons.target : icons.distractor,
                  size: 60,
                  color: Colors.teal,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
