import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
import 'core/ai/legacy_model_cleanup.dart';
import 'core/services/background_service.dart';
import 'core/services/diary_notification_service.dart';
import 'core/services/notification_tap_router.dart';
import 'features/gait_analysis/gait_provider.dart';
import 'features/gait_analysis/guardian_alert_sms_dialog.dart';
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
import 'features/opening/memory_opening.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 알림 플러그인 초기화 → 저장된 선택대로 저녁 일기 알림 예약 → 알림 탭 연결.
/// runApp과 병렬로 진행되므로 실패해도 앱 기동에 영향을 주지 않는다.
///
/// 앱을 열 때 알림 권한을 묻지 않는다. 일기 알림은 설정에서 켤 때,
/// 걸음 측정 알림은 걸음 측정을 켤 때 묻는다(LAUNCH_AUDIT P0-04).
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
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) =>
          NotificationTapRouter.handle(response.payload),
    );
    await DiaryNotificationService.configure(flutterLocalNotificationsPlugin);
    await DiaryNotificationService.applySavedPreference();
    // 앱이 꺼져 있을 때 알림을 눌러 열었으면, 화면이 준비된 뒤 처리한다.
    final launch = await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      NotificationTapRouter.handle(launch!.notificationResponse?.payload);
    }
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
  // ── 에뮬레이터 빌드에서도 필요한 것 ──────────────────────────────
  // 네트워크가 없어도 로컬 폴백으로 동작하므로 건너뛰면 안 된다.

  // 규칙 기반 엔진 준비 (모델 파일 없으면 그대로 규칙 기반으로 동작).
  await LocalAIService.initialize();

  // 예전 빌드가 남긴 온디바이스 모델(약 1.5GB)과 HuggingFace 토큰을 지운다(LAUNCH_AUDIT P0-11).
  unawaited(LegacyOnDeviceModelCleanup.run());

  // AI 대화 서비스 (GEMINI_API_KEY 없으면 LocalFallback 자동 사용).
  // path_provider 채널 + SharedPreferences 최초 로드를 유발하므로 뒤로 미룬다.
  try {
    await AiChatService.initialize();
  } catch (e) {
    debugPrint('[bootstrap] AI 대화 초기화 실패 — 로컬 폴백으로 계속한다: $e');
  }

  // 알림 채널·저장된 일기 알림 예약·알림 탭 연결. 권한은 묻지 않고(LAUNCH_AUDIT P0-04) 네트워크도
  // 쓰지 않으므로 에뮬레이터 QA 빌드에서도 준비한다. 알림 권한 거부 E2E가 이 경로를 쓴다.
  unawaited(_prepareNotifications());

  // ── 실제 기기에서만 필요한 것 ────────────────────────────────────
  // 네트워크·센서는 에뮬레이터 QA 빌드에서 건너뛴다.
  if (isEmulator) return;

  // 만보기 백그라운드 서비스 설정. autoStart:false라 여기서 실제로 시작되는 건
  // 없고, 사용자가 만보기를 켤 때 비로소 startService가 불린다.
  try {
    await PedometerBackgroundService.initializeService();
  } catch (e) {
    debugPrint('[bootstrap] 만보기 서비스 설정 실패: $e');
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
}

/// Pretendard 는 SIL Open Font License 1.1 로 배포된다. OFL 은 폰트를 포함해
/// 배포할 때 라이선스 전문을 함께 제공할 것을 요구하므로, 앱 안의 오픈소스 고지
/// 화면(showLicensePage)에서 볼 수 있도록 등록한다. 자산은 assets/fonts/Pretendard-OFL.txt.
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/Pretendard-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Pretendard'], text);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicense();
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
    NotificationTapRouter.pending.addListener(_schedulePendingTap);
  }

  @override
  void dispose() {
    NotificationTapRouter.pending.removeListener(_schedulePendingTap);
    super.dispose();
  }

  /// 알림 탭은 화면이 그려진 뒤, 로그인 확인이 끝난 다음에 처리한다.
  void _schedulePendingTap() {
    if (NotificationTapRouter.pending.value == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingTap());
  }

  Future<void> _handlePendingTap() async {
    if (!mounted || NotificationTapRouter.pending.value == null) return;
    final user = context.read<UserProvider>();
    if (user.isLoading) return; // 로딩이 끝나면 build가 다시 부른다.
    final navigatorContext = _router.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    final payload = NotificationTapRouter.take();
    if (payload != NotificationTapRouter.guardianAlertPayload || user.currentUser == null) return;
    await showGuardianAlertSmsDialog(navigatorContext, phone: user.emergencyContact);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final settings = context.watch<SettingsProvider>();
    if (!userProvider.isLoading) _schedulePendingTap();

    // 콜드 스타트 오프닝(DESIGN.md §4.1 네 번째 예외). 로그인 확인과 겹쳐 흐르고,
    // 확인이 늦으면 정지 화면에서 기다리므로 아래 로딩 스피너는 보이지 않는다.
    return MemoryOpening(
      start: settings.isLoaded,
      ready: !userProvider.isLoading,
      child: _buildApp(userProvider, settings),
    );
  }

  Widget _buildApp(UserProvider userProvider, SettingsProvider settings) {
    if (userProvider.isLoading) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        // 다크는 의도적으로 꺼 둔 상태다. 사유는 아래 MaterialApp.router 주석 참조.
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
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
      // 다크 테마는 정의만 해 두고 쓰지 않는다.
      //
      // ThemeMode.system이던 동안, 안드로이드 다크를 켠 사용자에게는 이 앱도
      // 다크로 그려졌다. 그런데 화면 위젯이 MLColors.*(라이트 전용 상수)를
      // 직접 참조해 테마를 우회하는 곳이 많아 글씨가 배경에 묻혔다.
      // 당시 실측 — 본문 MLColors.text on dSurface 1.04:1, textSoft 2.48:1.
      //
      // 표면·텍스트·primary의 우회는 2026-08-24에 전부 회수했다(colorScheme 경유).
      // 그래도 아직 켜지 않는 이유는 남은 게 하나 더 있어서다: 상태 문구용
      // 토큰이 흰 배경에 맞춰 어둡게 잡혀 있어 다크에서 되레 안 읽힌다.
      //
      //   dSurface 위    goodText 3.10:1 · warnText 2.76:1 · badText 2.91:1
      //   dBg 위         goodText 3.47:1 · warnText 3.09:1 · badText 3.26:1
      //
      // 면(good/warn/bad)과 카테고리 강조(mem·care·read·sky·logic)는 밝은 값이라
      // 다크에서 5.9~10.6:1로 여유가 있다. 문제는 *Text 3종과 calc(3.37:1)뿐이다.
      //
      // 재개 조건: 위 4개에 다크 대응값을 주고(ColorScheme 분기 또는 밝은 변형),
      // theme_contrast_test에 다크 배경 케이스를 추가해 통과시킬 것.
      // 그 뒤 이 한 줄만 ThemeMode.system으로 되돌리면 된다.
      //
      // 저시력 대응은 그와 별개로 설정의 글꼴 배율(1.0/1.2/1.4배)이 맡는다.
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
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
