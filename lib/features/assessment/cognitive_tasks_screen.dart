import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
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
    // 3문제 중 맞춘 개수를 0~10점으로 환산 (예: 3개 다 맞히면 10점)
    context.read<UserProvider>().setCognitiveScore('memory', (_memoryScore / 3.0) * 10.0);
    setState(() => _currentTask = 3);
  }

  void _onAttentionComplete() {
    // 5문제 중 맞춘 개수를 0~10점으로 환산
    context.read<UserProvider>().setCognitiveScore('attention', (_attentionScore / 5.0) * 10.0);
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('간단한 계산을 해주세요', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 40),
        const Text('5 + 3 = ?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _onDistracterComplete, child: const Text('8', style: TextStyle(fontSize: 24))),
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
            final isTarget = index == 4; // Mock target at index 4
            return InkWell(
              onTap: () {
                if (index == 4) {
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
                isTarget ? Icons.circle_outlined : Icons.square_outlined,
                size: 60,
                color: Colors.teal,
              ),
            );
          }),
        ),
      ],
    );
  }
}
