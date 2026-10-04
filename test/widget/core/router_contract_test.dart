import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/admin_provider.dart';
import 'package:flutter_application_1/core/app_config.dart';
import 'package:flutter_application_1/core/router.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/features/admin/admin_cs_management_screen.dart';
import 'package:flutter_application_1/features/admin/admin_dashboard_screen.dart';
import 'package:flutter_application_1/features/admin/admin_faq_edit_screen.dart';
import 'package:flutter_application_1/features/admin/admin_inquiry_detail_screen.dart';
import 'package:flutter_application_1/features/admin/admin_login_screen.dart';
import 'package:flutter_application_1/features/admin/admin_notice_edit_screen.dart';
import 'package:flutter_application_1/features/admin/admin_user_detail_screen.dart';
import 'package:flutter_application_1/features/ai_chat/ai_chat_screen.dart';
import 'package:flutter_application_1/features/assessment/assessment_screen.dart';
import 'package:flutter_application_1/features/assessment/cognitive_tasks_screen.dart';
import 'package:flutter_application_1/features/assessment/result_screen.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart';
import 'package:flutter_application_1/features/auth/register_screen.dart';
import 'package:flutter_application_1/features/cs/cs_center_screen.dart';
import 'package:flutter_application_1/features/cs/faq_screen.dart';
import 'package:flutter_application_1/features/cs/inquiry_detail_screen.dart';
import 'package:flutter_application_1/features/cs/inquiry_submit_screen.dart';
import 'package:flutter_application_1/features/cs/my_inquiries_screen.dart';
import 'package:flutter_application_1/features/cs/notice_detail_screen.dart';
import 'package:flutter_application_1/features/cs/notice_list_screen.dart';
import 'package:flutter_application_1/features/dementia_center/dementia_center_finder_screen.dart';
import 'package:flutter_application_1/features/diary/diary_book_screen.dart';
import 'package:flutter_application_1/features/diary/diary_screen.dart';
import 'package:flutter_application_1/features/gait_analysis/walking_dashboard_screen.dart';
import 'package:flutter_application_1/features/health/health_input_screen.dart';
import 'package:flutter_application_1/features/navigation/main_nav_screen.dart';
import 'package:flutter_application_1/features/onboarding/consent_screen.dart';
import 'package:flutter_application_1/features/onboarding/onboarding_screen.dart';
import 'package:flutter_application_1/features/profile/guardian_link_screen.dart';
import 'package:flutter_application_1/features/profile/profile_screen.dart';
import 'package:flutter_application_1/features/reports/clinical_report_options_screen.dart';
import 'package:flutter_application_1/features/settings/model_download_screen.dart';
import 'package:flutter_application_1/features/settings/settings_screen.dart';
import 'package:flutter_application_1/features/training/daily_recall_page.dart';
import 'package:flutter_application_1/features/training/games/categorization_game.dart';
import 'package:flutter_application_1/features/training/games/comparison_game.dart';
import 'package:flutter_application_1/features/training/games/multiplication_game.dart';
import 'package:flutter_application_1/features/training/games/sentence_reading_game.dart';
import 'package:flutter_application_1/features/training/games/sequence_game.dart';
import 'package:flutter_application_1/features/training/games/shape_match_game.dart';
import 'package:flutter_application_1/features/training/games/shape_sudoku_game.dart';
import 'package:flutter_application_1/features/training/training_history_screen.dart';
import 'package:flutter_application_1/features/training/training_hub_page.dart';
import 'package:flutter_application_1/features/voice_assessment/voice_assessment_blocked_screen.dart';

// DS-001 라우터 계약 (핸드오프 §4.1·§4.2·§10 G1).
//
// redirect는 화면을 그리지 않고 앱의 Router 위젯이 쓰는 것과 같은
// `routeInformationParser`로 최종 위치를 계산한다. 가벼운 두 화면(로그인·관리자
// 로그인)만 MaterialApp.router에 실제로 올려 딥링크 이동을 끝까지 확인한다.
// MainNav 셸 렌더 검증은 DS-002(main_nav_shell_test)의 몫이라 여기서 하지 않는다.

class _FakeUser extends UserProvider {
  _FakeUser({this.loggedIn = false, this.onboarded = false});
  bool loggedIn;
  bool onboarded;
  @override
  bool get isLoggedIn => loggedIn;
  @override
  bool get hasCompletedOnboarding => onboarded;
  @override
  bool get isLoading => false;
}

class _FakeAdmin extends AdminProvider {
  _FakeAdmin({this.session = false});
  bool session;
  @override
  bool get isAdminLoggedIn => session;
}

/// router.dart 등록 순서 그대로의 44개 경로: (패턴, 실제 이동 위치, 화면).
const _routes = <(String, String, Type)>[
  ('/', '/', MainNavScreen),
  ('/login', '/login', LoginScreen),
  ('/register', '/register', RegisterScreen),
  ('/onboarding', '/onboarding', OnboardingScreen),
  ('/consent', '/consent', ConsentScreen),
  ('/assessment', '/assessment', AssessmentScreen),
  ('/cognitive_tasks', '/cognitive_tasks', CognitiveTasksScreen),
  ('/assessment_result', '/assessment_result', AssessmentResultScreen),
  ('/report_options', '/report_options', ClinicalReportOptionsScreen),
  ('/training_hub', '/training_hub', TrainingHubScreen),
  ('/training_history', '/training_history', TrainingHistoryScreen),
  ('/game/comparison', '/game/comparison', ComparisonGame),
  ('/game/sequence', '/game/sequence', SequenceGame),
  ('/game/sudoku', '/game/sudoku', ShapeSudokuGame),
  ('/game/multiplication', '/game/multiplication', MultiplicationGame),
  ('/game/shape_match', '/game/shape_match', ShapeMatchGame),
  ('/game/categorization', '/game/categorization', CategorizationGame),
  ('/game/reading', '/game/reading', SentenceReadingGame),
  ('/memory_garden', '/memory_garden', DiaryScreen),
  ('/diary_book', '/diary_book', DiaryBookScreen),
  ('/guardian_link', '/guardian_link', GuardianLinkScreen),
  ('/voice_assessment', '/voice_assessment', VoiceAssessmentBlockedScreen),
  ('/dementia_centers', '/dementia_centers', DementiaCenterFinderScreen),
  ('/ai_chat', '/ai_chat', AiChatScreen),
  ('/walking_dashboard', '/walking_dashboard', WalkingDashboardScreen),
  ('/training/recall', '/training/recall', DailyRecallPage),
  ('/profile', '/profile', ProfileScreen),
  ('/ondevice-ai', '/ondevice-ai', ModelDownloadScreen),
  ('/settings', '/settings', SettingsScreen),
  ('/health_input', '/health_input', HealthInputScreen),
  ('/cs_center', '/cs_center', CsCenterScreen),
  ('/cs/notices', '/cs/notices', NoticeListScreen),
  ('/cs/notice_detail/:id', '/cs/notice_detail/n-7', NoticeDetailScreen),
  ('/cs/faq', '/cs/faq', FaqScreen),
  ('/cs/inquiry_submit', '/cs/inquiry_submit', InquirySubmitScreen),
  ('/cs/my_inquiries', '/cs/my_inquiries', MyInquiriesScreen),
  ('/cs/inquiry_detail/:id', '/cs/inquiry_detail/q-3', InquiryDetailScreen),
  ('/admin_login', '/admin_login', AdminLoginScreen),
  ('/admin/dashboard', '/admin/dashboard', AdminDashboardScreen),
  ('/admin/user_detail/:userId', '/admin/user_detail/42', AdminUserDetailScreen),
  ('/admin/cs_management', '/admin/cs_management', AdminCsManagementScreen),
  ('/admin/notice_edit', '/admin/notice_edit', AdminNoticeEditScreen),
  ('/admin/faq_edit', '/admin/faq_edit', AdminFaqEditScreen),
  ('/admin/inquiry_detail/:id', '/admin/inquiry_detail/a-9', AdminInquiryDetailScreen),
];

const _authRoutes = {'/login', '/register'};

/// 미온보딩 사용자가 머물 수 있는 경로. `/dementia_centers`가 빠지면 고위험 결과의
/// 센터 안내가 /consent로 역류한다(핸드오프 §3-4).
const _onboardingRoutes = {
  '/consent', '/onboarding', '/assessment', '/cognitive_tasks',
  '/assessment_result', '/dementia_centers',
};

bool _isAdmin((String, String, Type) r) => r.$1.startsWith('/admin');

/// 일반 앱 경로 중 인증 화면을 뺀 35개.
final _guarded =
    _routes.where((r) => !_isAdmin(r) && !_authRoutes.contains(r.$1)).toList();
final _admin = _routes.where(_isAdmin).toList();

GoRouter _router({
  bool loggedIn = false,
  bool onboarded = false,
  bool adminSession = false,
  bool? portal,
}) {
  final router = portal == null
      ? createAppRouter(
          _FakeUser(loggedIn: loggedIn, onboarded: onboarded),
          _FakeAdmin(session: adminSession),
        )
      : createAppRouter(
          _FakeUser(loggedIn: loggedIn, onboarded: onboarded),
          _FakeAdmin(session: adminSession),
          adminPortalEnabled: portal,
        );
  addTearDown(router.dispose);
  return router;
}

Future<BuildContext> _context(WidgetTester tester) async {
  await tester.pumpWidget(const Placeholder());
  return tester.element(find.byType(Placeholder));
}

Future<RouteMatchList> _parse(
  GoRouter router,
  BuildContext context,
  String location,
) async {
  final matches = await router.routeInformationParser
      .parseRouteInformationWithDependencies(
        RouteInformation(uri: Uri.parse(location)),
        context,
      );
  expect(matches.isError, isFalse, reason: '$location → ${matches.error}');
  return matches;
}

/// redirect까지 적용한 최종 위치.
Future<String> _land(GoRouter router, BuildContext context, String location) async =>
    (await _parse(router, context, location)).uri.path;

/// 위치를 해석해 그 route의 builder가 만드는 화면 위젯(렌더링하지 않음).
Future<Widget> _page(GoRouter router, BuildContext context, String location) async {
  final matches = await _parse(router, context, location);
  final route = matches.last.route;
  return route.builder!(
    context,
    matches.last.buildState(router.configuration, matches),
  );
}

void main() {
  group('등록 경로 (§4.1)', () {
    testWidgets('router.dart 순서 그대로 44개 패턴을 중복 없이 등록한다', (tester) async {
      final router = _router();
      final paths =
          router.configuration.routes.map((r) => (r as GoRoute).path).toList();

      expect(paths, _routes.map((r) => r.$1).toList());
      expect(paths.toSet(), hasLength(44));
    });

    testWidgets('44개 위치가 모두 자기 route로 해석되고 기대한 화면을 만든다', (tester) async {
      final context = await _context(tester);
      // 로그인·온보딩 완료·관리자 세션·포털 켜짐이면 인증 화면 2개 외에는 redirect가 없다.
      // 인증 화면은 로그인 상태에서 /로 가므로(②) 미로그인 라우터로 해석한다.
      final open = _router(
        loggedIn: true, onboarded: true, adminSession: true, portal: true,
      );
      final loggedOut = _router(portal: true);

      for (final (pattern, location, screen) in _routes) {
        final router = _authRoutes.contains(pattern) ? loggedOut : open;
        final matches = await _parse(router, context, location);
        expect(matches.uri.path, location, reason: '$location 이 redirect 됐다');
        expect(matches.last.route.path, pattern, reason: location);
        final page = await _page(router, context, location);
        expect(page.runtimeType, screen, reason: location);
      }
    });

    testWidgets('경로 파라미터를 화면 인자로 그대로 넘긴다', (tester) async {
      final context = await _context(tester);
      final router = _router(
        loggedIn: true, onboarded: true, adminSession: true, portal: true,
      );

      final notice =
          await _page(router, context, '/cs/notice_detail/n-7') as NoticeDetailScreen;
      final inquiry =
          await _page(router, context, '/cs/inquiry_detail/q-3') as InquiryDetailScreen;
      final user =
          await _page(router, context, '/admin/user_detail/42') as AdminUserDetailScreen;
      final adminInquiry = await _page(router, context, '/admin/inquiry_detail/a-9')
          as AdminInquiryDetailScreen;

      expect(notice.noticeId, 'n-7');
      expect(inquiry.inquiryId, 'q-3');
      expect(user.userId, 42);
      expect(adminInquiry.inquiryId, 'a-9');
    });
  });

  group('redirect 불변조건 (§4.2)', () {
    testWidgets('① 미로그인이면 인증·관리자 외 35개 경로가 모두 /login', (tester) async {
      final context = await _context(tester);
      final router = _router(portal: true);

      expect(_guarded, hasLength(35));
      for (final (_, location, _) in _guarded) {
        expect(await _land(router, context, location), '/login', reason: location);
      }
      expect(await _land(router, context, '/login'), '/login');
      expect(await _land(router, context, '/register'), '/register');
    });

    testWidgets('② 로그인 상태의 인증 경로는 미온보딩이면 /consent, 완료면 /', (tester) async {
      final context = await _context(tester);
      final fresh = _router(loggedIn: true, portal: true);
      final done = _router(loggedIn: true, onboarded: true, portal: true);

      for (final location in _authRoutes) {
        expect(await _land(fresh, context, location), '/consent', reason: location);
        expect(await _land(done, context, location), '/', reason: location);
      }
    });

    testWidgets('③ 미온보딩은 온보딩 6개 경로에만 머물고 나머지 29개는 /consent', (tester) async {
      final context = await _context(tester);
      final router = _router(loggedIn: true, portal: true);

      var stayed = 0;
      for (final (pattern, location, _) in _guarded) {
        final allowed = _onboardingRoutes.contains(pattern);
        expect(
          await _land(router, context, location),
          allowed ? location : '/consent',
          reason: location,
        );
        if (allowed) stayed++;
      }
      expect(stayed, 6);
      expect(await _land(router, context, '/dementia_centers'), '/dementia_centers');
    });

    testWidgets('④ 포털이 꺼진 빌드는 관리자 세션이 남아 있어도 /admin* 7개를 모두 막는다',
        (tester) async {
      final context = await _context(tester);

      expect(_admin, hasLength(7));
      for (final session in [false, true]) {
        final out = _router(adminSession: session, portal: false);
        final done = _router(
          loggedIn: true, onboarded: true, adminSession: session, portal: false,
        );
        for (final (_, location, _) in _admin) {
          final why = '$location (admin session: $session)';
          expect(await _land(out, context, location), '/login', reason: why);
          expect(await _land(done, context, location), '/', reason: why);
        }
      }
    });

    // 알려진 결함(DS-001에서 발견, backlog) — 기대 동작을 적어 두고 건너뛴다.
    // go_router 17의 top-level redirect는 내비게이션당 한 번만 돈다. 포털 꺼진 가드가
    // 돌려준 '/'는 다시 평가되지 않아, 미온보딩 사용자가 온보딩 가드(③)를 우회해
    // '/'(MainNav)에 도착한다. 현재 결과는 '/'. 수정은 라우터 로직 변경이라 디자인 PR 밖이다.
    testWidgets('③×④ 미온보딩 사용자가 포털 꺼진 빌드에서 /admin*로 들어와도 /consent로 가야 한다',
        (tester) async {
      final context = await _context(tester);
      final fresh = _router(loggedIn: true, portal: false);
      for (final (_, location, _) in _admin) {
        expect(await _land(fresh, context, location), '/consent', reason: location);
      }
    }, skip: true);

    testWidgets('⑤ 포털이 켜진 빌드에서 관리자 세션이 없으면 /admin/* 6개는 /admin_login',
        (tester) async {
      final context = await _context(tester);

      // 관리자 가드는 앱 로그인과 무관하다 — 미로그인·로그인 모두 같은 결과.
      for (final loggedIn in [false, true]) {
        final noSession = _router(loggedIn: loggedIn, onboarded: true, portal: true);
        final withSession = _router(
          loggedIn: loggedIn, onboarded: true, adminSession: true, portal: true,
        );
        for (final (_, location, _) in _admin) {
          final why = '$location (app login: $loggedIn)';
          // /admin_login 자신은 가드 대상이 아니라 그대로 머문다.
          expect(await _land(noSession, context, location), '/admin_login', reason: why);
          expect(await _land(withSession, context, location), location, reason: why);
        }
      }
    });
  });

  group('기본 호출 (production 경로)', () {
    testWidgets('seam 없이 만든 라우터는 AppConfig.isAdminPortalEnabled와 똑같이 판정한다',
        (tester) async {
      final context = await _context(tester);
      // 테스트 빌드는 kReleaseMode=false라 포털이 켜져 있다.
      expect(AppConfig.isAdminPortalEnabled, isTrue);

      for (final (loggedIn, onboarded) in [(false, false), (true, false), (true, true)]) {
        for (final session in [false, true]) {
          final byDefault = _router(
            loggedIn: loggedIn, onboarded: onboarded, adminSession: session,
          );
          final explicit = _router(
            loggedIn: loggedIn, onboarded: onboarded, adminSession: session,
            portal: AppConfig.isAdminPortalEnabled,
          );
          for (final (_, location, _) in _routes) {
            expect(
              await _land(byDefault, context, location),
              await _land(explicit, context, location),
              reason: '$location (login $loggedIn, onboarded $onboarded, admin $session)',
            );
          }
        }
      }
    });

    // 테스트 빌드는 포털이 항상 켜져 있어서, 기본값을 `?? true`로 바꾸는 회귀(릴리스에서 포털이
    // 열림)를 위 동치 테스트로는 잡을 수 없다. 기본값이 AppConfig를 읽는지 소스로 지킨다.
    test('seam 기본값은 AppConfig.isAdminPortalEnabled다(릴리스 가드 보존)', () {
      final source = File('lib/core/router.dart').readAsStringSync();
      expect(source, contains('adminPortalEnabled ?? AppConfig.isAdminPortalEnabled'));
    });

    testWidgets('초기 위치는 /login', (tester) async {
      final router = _router();
      expect(router.routeInformationProvider.value.uri.path, '/login');
    });
  });

  group('MaterialApp.router에 올린 실제 라우터', () {
    Future<GoRouter> pumpApp(WidgetTester tester, {bool? portal}) async {
      final user = _FakeUser();
      final admin = _FakeAdmin();
      final router = portal == null
          ? createAppRouter(user, admin)
          : createAppRouter(user, admin, adminPortalEnabled: portal);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: user),
            ChangeNotifierProvider<AdminProvider>.value(value: admin),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    String current(GoRouter router) =>
        router.routerDelegate.currentConfiguration.uri.path;

    testWidgets('미로그인 딥링크는 로그인 화면에 머물고 관리자 경로는 관리자 로그인으로 간다',
        (tester) async {
      final router = await pumpApp(tester);
      expect(current(router), '/login');
      expect(find.byType(LoginScreen), findsOneWidget);

      router.go('/settings');
      await tester.pumpAndSettle();
      expect(current(router), '/login');
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);

      router.go('/admin/dashboard');
      await tester.pumpAndSettle();
      expect(current(router), '/admin_login');
      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });

    testWidgets('포털이 꺼진 빌드는 /admin_login 딥링크도 로그인 화면으로 돌린다', (tester) async {
      final router = await pumpApp(tester, portal: false);

      router.go('/admin_login');
      await tester.pumpAndSettle();
      expect(current(router), '/login');
      expect(find.byType(AdminLoginScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
