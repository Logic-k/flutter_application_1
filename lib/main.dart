import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/user_provider.dart';
import 'core/supabase_client.dart';
import 'features/gait_analysis/gait_provider.dart';
import 'features/gait_analysis/pedometer_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/background_service.dart';

import 'features/training/difficulty_provider.dart';
import 'core/settings_provider.dart';
import 'core/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 한국어 날짜 형식 데이터 초기화
  await initializeDateFormatting('ko_KR', null);
  
  // [agency-backend-architect]: 백그라운드 서비스 엔진 초기화
  await PedometerBackgroundService.initializeService();
  
  // Supabase 초기화 (Cloud DB 연동)
  await SupabaseManager.initialize();
  
  final userProvider = UserProvider();
  await userProvider.checkLoginStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => GaitProvider()),
        ChangeNotifierProxyProvider<UserProvider, PedometerManager>(
          create: (context) => PedometerManager(context.read<UserProvider>()),
          update: (context, user, previous) => previous ?? PedometerManager(user),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProxyProvider<UserProvider, DifficultyProvider>(
          create: (context) => DifficultyProvider(username: ''),
          update: (context, user, previous) {
            final username = user.currentUser?['username'] ?? '';
            final provider = previous ?? DifficultyProvider(username: username);
            if (username.isNotEmpty) provider.loadLevels();
            return provider;
          },
        ),
      ],
      child: const MemoryLinkApp(),
    ),
  );
}

class MemoryLinkApp extends StatefulWidget {
  const MemoryLinkApp({super.key});

  @override
  State<MemoryLinkApp> createState() => _MemoryLinkAppState();
}

class _MemoryLinkAppState extends State<MemoryLinkApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // [agency-mobile-app-builder]: 라우터 인스턴스를 한 번만 생성하여 
    // 리빌드 시 내비게이션 상태가 초기화되거나 경로를 잃어버리는 방지합니다.
    final userProvider = context.read<UserProvider>();
    final adminProvider = context.read<AdminProvider>();
    _router = createAppRouter(userProvider, adminProvider);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final settings = context.watch<SettingsProvider>();
    
    if (userProvider.isLoading) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'MemoryLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textScaleFactor),
          ),
          child: child!,
        );
      },
    );
  }
}
