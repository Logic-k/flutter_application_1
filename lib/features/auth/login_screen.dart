import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isError = false;

  Future<void> _handleLogin() async {
    final success = await context.read<UserProvider>().login(
      _usernameController.text,
      _passwordController.text,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Icon(Icons.lock_person_outlined, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'MemoryLink',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '당신의 소중한 기억을 잇다',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 60),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '사용자 아이디',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              if (_isError)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    '아이디 또는 비밀번호가 올바르지 않습니다.',
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: _handleLogin,
                  child: const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text(
                  '처음이신가요? 회원가입',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
