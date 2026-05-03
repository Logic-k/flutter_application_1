import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, int> _answers = {};

  final List<String> _questions = [
    '당신의 기억력에 문제가 있습니까?',
    '당신의 기억력이 10년 전보다 나빠졌습니까?',
    '당신의 기억력이 같은 또래의 다른 사람들에 비해 나쁘다고 생각합니까?',
    '기억력 저하로 일상생활에 불편을 느끼십니까?',
    '최근에 일어난 일을 기억하는 것이 어렵습니까?',
    '며칠 전에 나눈 대화 내용을 기억하기 어렵습니까?',
    '약속이나 집안일 등을 자주 잊으십니까?',
    '물건을 둔 곳을 찾지 못해 헤맨 적이 자주 있습니까?',
    '예전보다 돈 계산을 하거나 관리하기가 어려워졌습니까?',
    '길을 찾거나 익숙한 장소로 가는 것이 어려워졌습니까?',
  ];

  void _onAnswer(int answer) {
    _answers[_currentPage] = answer;
    context.read<UserProvider>().setSurveyAnswer(_currentPage, answer);
    
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.push('/cognitive_tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('자가 체크 (${_currentPage + 1}/${_questions.length})'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / _questions.length,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _questions[index],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _onAnswer(1),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('예', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _onAnswer(0),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('아니오', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
