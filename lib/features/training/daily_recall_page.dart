import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';
import 'widgets/game_template.dart';

class DailyRecallPage extends StatefulWidget {
  const DailyRecallPage({super.key});

  @override
  State<DailyRecallPage> createState() => _DailyRecallPageState();
}

class _DailyRecallPageState extends State<DailyRecallPage> {
  final TextEditingController _controller = TextEditingController();
  int _currentQuestionIndex = 0;
  final List<String> _questions = [
    '오늘 아침 식사로 무엇을 드셨나요?',
    '오늘 가장 기억에 남는 일이 무엇인가요?',
    '어제 일기예보가 어땠는지 기억나시나요?',
    '최근에 만난 사람 중 가장 반가웠던 분은 누구인가요?',
    '오늘의 기분은 5점 만점에 몇 점인가요?',
  ];

  final List<String> _answers = [];

  void _nextQuestion() {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생각나는 내용을 짧게라도 적어주세요.')),
      );
      return;
    }

    setState(() {
      _answers.add(_controller.text);
      _controller.clear();
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    // 회상 훈련은 정답이 없으므로 참여 자체에 높은 점수를 부여합니다.
    context.read<UserProvider>().setCognitiveScore('memory', 100.0);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('오늘의 회상 완료'),
        content: const Text('기억을 떠올리는 것만으로도 뇌 건강에 큰 도움이 됩니다.\n수고하셨습니다!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Page
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

    return GameTemplate(
      title: '일상 회상 훈련',
      objective: '오늘의 사소한 기억들을 떠올려보며\n뇌의 기억 저장소를 활성화합니다.',
      currentStep: _currentQuestionIndex + 1,
      totalSteps: _questions.length,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, color: theme.primaryColor, size: 32),
                const SizedBox(height: 16),
                Text(
                  _questions[_currentQuestionIndex],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '여기에 내용을 적어주세요...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              fillColor: theme.cardColor,
              filled: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _currentQuestionIndex == _questions.length - 1 ? '완료하기' : '다음 질문',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '천천히 생각해보셔도 괜찮습니다.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
