import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController(); // 나이용 컨트롤러
  final _weightController = TextEditingController(); // 체중용 컨트롤러
  String _selectedGoal = '예방';
  bool _isError = false;

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _weightController.text.isEmpty) {
      setState(() => _isError = true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    final int age = int.tryParse(_ageController.text) ?? 40;
    final double weight = double.tryParse(_weightController.text) ?? 60.0;

    final success = await context.read<UserProvider>().register(
      _usernameController.text,
      _passwordController.text,
      _selectedGoal,
      age,
      weight,
    );

    if (success) {
      if (mounted) context.pushReplacement('/');
    } else {
      setState(() => _isError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('회원가입'), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '기본 정보 입력',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '회원님의 맞춤 훈련을 위해 정보를 입력해 주세요.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '아이디',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                ),
              ),
              const SizedBox(height: 20),
              // 나이 및 체중 입력 필드 추가
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '나이 (세)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '체중 (kg)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                '관심 분야 선택',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildGoalSelector(theme),
              const SizedBox(height: 40),
              if (_isError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    '모든 필드를 정확히 입력해 주세요.',
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('가입 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSelector(ThemeData theme) {
    final goals = ['예방', '걱정', '가족 관리'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: goals.map((goal) {
        bool isSelected = _selectedGoal == goal;
        return InkWell(
          onTap: () => setState(() => _selectedGoal = goal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
            ),
            child: Text(
              goal,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
