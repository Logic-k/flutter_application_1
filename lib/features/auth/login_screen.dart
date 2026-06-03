import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';
import '../../core/theme.dart';

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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // 브레인버디 마스코트 히어로
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: MLColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.rCard),
                ),
                child: Center(
                  child: SvgPicture.asset('assets/illustrations/brain_buddy.svg', width: 72),
                ),
              ),

              const SizedBox(height: 24),
              Text('MemoryLink', style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900,
                color: MLColors.primary, letterSpacing: 1.2,
              )),
              const SizedBox(height: 8),
              const Text('당신의 소중한 기억을 잇다', style: TextStyle(color: MLColors.textSoft)),

              const SizedBox(height: 56),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '사용자 아이디',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),

              if (_isError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '아이디 또는 비밀번호가 올바르지 않습니다.',
                    style: const TextStyle(color: MLColors.bad, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: _handleLogin,
                  child: const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('처음이신가요? 회원가입', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
