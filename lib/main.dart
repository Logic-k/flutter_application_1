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
import 'features/training/application/training_completion_service.dart';
import 'features/training/data/sqlite_training_progress_repository.dart';
import 'features/training/training_progress_provider.dart';
import 'core/database_helper.dart';
import 'core/settings_provider.dart';
import 'core/admin_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 알림 플러그인 초기화 → 런타임 권한 요청 → 저녁 일기 알림 예약.
/// runApp과 병렬로 진행되므로 실패해도 앱 기동에 영향을 주지 않는다.
Future<void> _prepareNotifications() async {
  try {
    // 타임존은 저녁 7시 KST 알림 예약에만 쓰인다. 예전에는 runApp 앞에서
    // 전 세계 전 역사 데이터를 파싱했는데, 그럴 이유가 없다.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    // Android 13+ 알림 런타임 권한 요청.
    // (만보기 토글에서만 요청하면 만보기를 안 쓰는 사용자는
    //  저녁 일기 알림을 영영 받지 못한다)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await DiaryNotificationService.initialize(flutterLocalNotificationsPlugin);
    await DiaryNotificationService.scheduleDailyReminder(
      flutterLocalNotificationsPlugin,
    );
  } catch (e) {
    debugPrint('[main] 알림 준비 실패 — 알림 없이 계속한다: $e');
  }
}

/// 첫 프레임 이후에 도는 초기화.
///
/// 여기 있는 작업은 어느 것도 로그인 화면을 그리는 데 필요하지 않다.
/// 예전에는 전부 `runApp` 앞에서 `await` 되어 안드로이드 `Displayed`
/// (= 첫 프레임) 시각을 그대로 밀어냈고, 실측이 `+15s078ms`였다.
Future<void> _bootstrap({required bool isEmulator}) async {
  if (isEmulator) return;

  // 만보기 백그라운드 서비스 설정. autoStart:false라 여기서 실제로 시작되는 건
  // 없고, 사용자가 만보기를 켤 때 비로소 startService가 불린다.
  try {
    await PedometerBackgroundService.initializeService();
  } catch (e) {
    debugPrint('[bootstrap] 만보기 서비스 설정 실패: $e');
  }

  // 규칙 기반 엔진 준비 (모델 파일 없으면 그대로 규칙 기반으로 동작).
  await LocalAIService.initialize();

  // AI 대화 서비스 (GEMINI_API_KEY 없으면 LocalFallback 자동 사용).
  // path_provider 채널 + SharedPreferences 최초 로드를 유발하므로 뒤로 미룬다.
  try {
    await AiChatService.initialize();
  } catch (e) {
    debugPrint('[bootstrap] AI 대화 초기화 실패 — 로컬 폴백으로 계속한다: $e');
  }

  await FirebaseService.initialize();
  // Firestore Security Rules 통과용 익명 세션 (실패해도 로컬 기능은 동작).
  // 데모 공지/FAQ 시드는 개발 빌드 전용 — 운영 콘텐츠는 관리자(콘솔)가 등록하며
  // 배포된 규칙상 일반 클라이언트의 notices/faqs 쓰기는 거부된다.
  if (FirebaseService.isAvailable) {
    unawaited(
      AuthService.ensureSignedIn()
          .then((_) async {
            if (kDebugMode) {
              await CsService.seedDemoData();
            }
          })
          .catchError((Object e) {
            debugPrint('[bootstrap] 익명 로그인 실패 — 로컬 기능만 사용한다: $e');
          }),
    );
  }

  // 알림 준비는 가장 마지막에. Android 13+ 권한 다이얼로그가 뜨므로
  // 사용자가 이미 화면을 보고 있는 상태여야 맥락이 이해된다.
  unawaited(_prepareNotifications());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const bool isEmulator = bool.fromEnvironment(
    'IS_EMULATOR',
    defaultValue: false,
  );

  // 한국어 날짜 데이터만 첫 프레임 앞에 남긴다. 홈·리포트·일기가 build 중에
  // ko_KR DateFormat을 쓰기 때문에 미초기화 상태로 도달하면 예외가 난다.
  await initializeDateFormatting('ko_KR', null);

  final userProvider = UserProvider();
  final trainingRepository = SqliteTrainingProgressRepository(DatabaseHelper());
  final trainingCompletionService = TrainingCompletionService(
    repository: trainingRepository,
    clock: DateTime.now,
  );

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
        ChangeNotifierProxyProvider<UserProvider, TrainingProgressProvider>(
          create: (_) => TrainingProgressProvider(
            repository: trainingRepository,
            completionService: trainingCompletionService,
            clock: DateTime.now,
          ),
          update: (_, user, previous) {
            final provider = previous!;
            final userId = user.currentUser?['id'] as int?;
            if (provider.userId != userId) {
              unawaited(provider.updateUser(userId));
            }
            return provider;
          },
        ),
      ],
      child: const MemoryLinkApp(),
    ),
  );

  // 첫 프레임이 실제로 그려진 뒤에 무거운 초기화를 시작한다.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_bootstrap(isEmulator: isEmulator));
  });

  unawaited(userProvider.checkLoginStatus());
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
        // 부팅 화면에도 다크 테마를 준다. 없으면 다크 모드 기기에서
        // 흰 화면이 한 번 번쩍인 뒤 어두워진다.
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
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
        // 시스템 글꼴 배율을 '덮어쓰지' 않고 '바닥값'으로 쓴다.
        //
        // 예전 코드는 TextScaler.linear(앱배율)로 통째로 교체해서, 안드로이드
        // 접근성 설정에서 글꼴을 이미 최대로 키워 둔 고령 사용자가 이 앱에서만
        // 1.0배로 되돌아갔다. 접근성 설정을 켠 사람에게 오히려 손해였다.
        //
        // clamp를 쓰면 시스템 배율이 앱 설정보다 크면 시스템을 따르고,
        // 작으면 앱 설정까지 올려 준다. 상한 2.0은 WCAG 1.4.4가 요구하는
        // 200% 확대치이며, 그 이상은 레이아웃이 견디지 못한다.
        final systemScaler = MediaQuery.textScalerOf(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: systemScaler.clamp(
              minScaleFactor: settings.textScaleFactor,
              maxScaleFactor: 2.0,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
