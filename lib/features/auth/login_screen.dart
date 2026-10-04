import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';
import '../../core/theme.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/motion_play_log.dart';
import '../../core/motion/motion_settings.dart';
import '../../core/motion/staggered_column.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// 스플래시 → 로그인 로고 이동의 재생 기록 키. 오프닝(`MemoryOpening`)이 먼저
  /// 로고를 보여 주면 이 키를 재생된 것으로 표시해 이동을 건너뛴다.
  static const String splashPlayKey = 'login_splash';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isError = false;

  // ─── 스플래시 → 로그인 연결(08 계획 G-03) ─────────────────────────────
  // 네이티브 스플래시(launch_background.xml·values-v31)는 화면 중앙에 같은 로고를
  // 같은 크기(110dp)·같은 모서리로 그린다. 첫 Flutter 프레임도 로고를 중앙에 두었다가
  // 제자리로 올려 보내 "스플래시가 그대로 로그인 화면이 되는" 연결을 만든다.
  // 뒤로가기 대상이 아닌 화면 내부 전환이라 CustomTransitionPage 를 쓰지 않는다.
  // 앱 실행당 1회, 움직임 줄이기(fadeOnly·none)면 하지 않는다.
  static const double _logoSize = 110;
  final _logoKey = GlobalKey();
  final _stackKey = GlobalKey();
  late final AnimationController _flight;
  Rect? _flightEnd;
  bool _flying = false;
  bool _decided = false;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(vsync: this, duration: AppMotion.route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    if (MotionSettings.levelOf(context, listen: false) != MotionLevel.full ||
        MotionPlayLog.hasPlayed(LoginScreen.splashPlayKey)) {
      return;
    }
    MotionPlayLog.markPlayed(LoginScreen.splashPlayKey);
    _flying = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlight());
  }

  /// 첫 프레임이 그려진 뒤에야 로고의 제자리를 잴 수 있다.
  void _startFlight() {
    if (!mounted) return;
    final logo = _logoKey.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (logo == null || stack == null || !logo.hasSize) {
      setState(() => _flying = false);
      return;
    }
    setState(() => _flightEnd = logo.localToGlobal(Offset.zero, ancestor: stack) & logo.size);
    _flight.forward().whenCompleteOrCancel(() {
      if (mounted) setState(() => _flying = false);
    });
  }

  @override
  void dispose() {
    _flight.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _logo() => ClipRRect(
    borderRadius: BorderRadius.circular(AppTheme.rCard),
    child: Image.asset('assets/icon/app_icon.png', width: _logoSize, height: _logoSize),
  );

  /// 날아가는 로고. 시작은 화면 중앙(스플래시와 같은 자리), 끝은 레이아웃 속 제자리.
  Widget _flyingLogo(Size size) {
    final start = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: _logoSize,
      height: _logoSize,
    );
    return AnimatedBuilder(
      animation: _flight,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_flight.value);
        return Positioned.fromRect(
          rect: Rect.lerp(start, _flightEnd ?? start, t)!,
          child: child!,
        );
      },
      child: IgnorePointer(child: ExcludeSemantics(child: _logo())),
    );
  }

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
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          key: _stackKey,
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // MemoryLink 로고 히어로. 스플래시에서 날아오는 동안은 자리만 차지한다.
                    Opacity(
                      key: _logoKey,
                      opacity: _flying ? 0 : 1,
                      child: _logo(),
                    ),

                    // 제목 → 입력 → 버튼 → 가입 안내 순서로 들어온다(총 380ms).
                    StaggeredColumn(
                      playKey: 'login',
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            Text('MemoryLink', style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800,
                              color: context.scheme.primary, letterSpacing: 1.2,
                            )),
                            const SizedBox(height: 8),
                            Text('당신의 소중한 기억을 잇다', style: TextStyle(color: context.scheme.onSurfaceVariant)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: MLColors.badText, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 36),
                          child: SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: FilledButton(
                              onPressed: _handleLogin,
                              child: const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text('처음이신가요? 회원가입', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_flying) _flyingLogo(constraints.biggest),
          ],
        ),
      ),
    );
  }
}
