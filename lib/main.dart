import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'core/theme.dart';
import 'core/router.dart';
import 'core/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'core/firebase_service.dart';
import 'core/auth_service.dart';
import 'core/cs_service.dart';
import 'core/local_ai_service.dart';
import 'core/ai/ai_chat_service.dart';
import 'core/services/background_service.dart';
import 'core/services/diary_notification_service.dart';
import 'features/gait_analysis/gait_provider.dart';
import 'features/gait_analysis/pedometer_manager.dart';
import 'features/diary/diary_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/training/difficulty_provider.dart';
import 'core/settings_provider.dart';
import 'core/admin_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone 초기화 (저녁 7시 KST 알림 스케줄링용)
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  // 알림 플러그인 초기화
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );
  // Android 13+ 알림 런타임 권한 요청.
  // (만보기 토글에서만 요청하면 만보기를 안 쓰는 사용자는
  //  저녁 일기 알림을 영영 받지 못한다)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  await DiaryNotificationService.initialize(flutterLocalNotificationsPlugin);
  await DiaryNotificationService.scheduleDailyReminder(flutterLocalNotificationsPlugin);

  // 한국어 날짜 형식 데이터 초기화
  await initializeDateFormatting('ko_KR', null);
  
  // 에뮬레이터 빌드 시 --dart-define=IS_EMULATOR=true 로 실행하면 건너뜀
  const bool isEmulator = bool.fromEnvironment('IS_EMULATOR', defaultValue: false);
  if (!isEmulator) {
    await PedometerBackgroundService.initializeService();
  }
  
  // TFLite 모델 사전 로드 (없으면 규칙 기반으로 자동 fallback)
  await LocalAIService.initialize();

  // AI 대화 서비스 초기화 (GEMINI_API_KEY 없으면 LocalFallback 자동 사용)
  await AiChatService.initialize();

  // Firebase 초기화 (IS_EMULATOR=true 빌드에서는 네트워크 없으므로 건너뜀)
  if (!isEmulator) {
    await FirebaseService.initialize();
    // Firestore Security Rules 통과용 익명 세션. 네트워크 지연이 첫 화면
    // 표시를 막지 않도록 백그라운드로 수행한다 (실패해도 로컬 기능은 동작).
    // 데모 공지/FAQ 시드는 개발 빌드 전용 — 운영 콘텐츠는 관리자(콘솔)가 등록하며
    // 배포된 규칙상 일반 클라이언트의 notices/faqs 쓰기는 거부된다.
    unawaited(AuthService.ensureSignedIn().then((_) async {
      if (kDebugMode) {
        await CsService.seedDemoData();
      }
    }));
  }

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
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProxyProvider<UserProvider, DifficultyProvider>(
          create: (context) => DifficultyProvider(username: ''),
          update: (context, user, previous) {
            final username = user.currentUser?['username'] as String? ?? '';
            final provider = previous ?? DifficultyProvider(username: username);
            // 로그인 사용자가 바뀌면 난이도를 초기화하고 Firestore에서 재로딩
            provider.setUsername(username);
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
