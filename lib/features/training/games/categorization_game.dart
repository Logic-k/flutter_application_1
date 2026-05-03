import 'dart:async';
import 'package:flutter/material.dart';

class CategorizationGame extends StatefulWidget {
  const CategorizationGame({super.key});

  @override
  State<CategorizationGame> createState() => _CategorizationGameState();
}

class _CategorizationGameState extends State<CategorizationGame> {
  int _score = 0;
  int _currentIndex = 0;
  bool _isFinished = false;

  final List<Map<String, dynamic>> _allQuestions = [
    {
      "item": "사과",
      "options": ["과일", "채소", "곡류"],
      "answer": "과일",
    },
    {
      "item": "시금치",
      "options": ["과일", "채소", "육류"],
      "answer": "채소",
    },
    {
      "item": "고등어",
      "options": ["육류", "어류", "곡류"],
      "answer": "어류",
    },
    {
      "item": "소고기",
      "options": ["어류", "육류", "채소"],
      "answer": "육류",
    },
    {
      "item": "쌀",
      "options": ["과일", "채소", "곡류"],
      "answer": "곡류",
    },
  ];

  void _checkAnswer(String selected) {
    if (selected == _allQuestions[_currentIndex]["answer"]) {
      setState(() {
        _score += 20;
      });
      _showFeedback(true);
    } else {
      _showFeedback(false);
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (_currentIndex < _allQuestions.length - 1) {
        setState(() {
          _currentIndex++;
        });
      } else {
        setState(() {
          _isFinished = true;
        });
      }
    });
  }

  void _showFeedback(bool isCorrect) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "정답입니다! (+20점)" : "아쉽네요. 다음 문제를 풀어보세요."),
        backgroundColor: isCorrect ? Colors.green.shade600 : theme.colorScheme.error,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isFinished) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
              const SizedBox(height: 24),
              Text('훈련 완료!', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('최종 점수: $_score점', style: theme.textTheme.titleLarge),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _allQuestions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('범주화 훈련'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _allQuestions.length,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
            const SizedBox(height: 40),
            Text(
              '다음 단어는 어느 분류에 속하나요?',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2), width: 2),
              ),
              child: Text(
                currentQuestion["item"],
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 60),
            Expanded(
              child: ListView.separated(
                itemCount: (currentQuestion["options"] as List).length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final option = currentQuestion["options"][index];
                  return SizedBox(
                    height: 70,
                    child: OutlinedButton(
                      onPressed: () => _checkAnswer(option),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        option,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
