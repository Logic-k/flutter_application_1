import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../features/navigation/main_nav_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/consent_screen.dart';
import '../features/assessment/assessment_screen.dart';
import '../features/assessment/cognitive_tasks_screen.dart';
import '../features/assessment/result_screen.dart';
import '../features/training/training_hub_page.dart';
import '../features/training/games/comparison_game.dart';
import '../features/training/games/sequence_game.dart';
import '../features/training/games/shape_sudoku_game.dart';
import '../features/training/games/multiplication_game.dart';
import '../features/training/games/shape_match_game.dart';
import '../features/training/games/categorization_game.dart';
import '../features/training/games/sentence_reading_game.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/gait_analysis/gait_screen.dart';
import '../features/gait_analysis/precise_analysis_screen.dart';
import '../features/home/memory_garden_screen.dart';
import '../features/profile/guardian_link_screen.dart';
import '../features/gait_analysis/walking_dashboard_screen.dart';
import '../features/training/daily_recall_page.dart';
import '../features/cs/cs_center_screen.dart';
import '../features/cs/notice_list_screen.dart';
import '../features/cs/notice_detail_screen.dart';
import '../features/cs/faq_screen.dart';
import '../features/cs/inquiry_submit_screen.dart';
import '../features/cs/my_inquiries_screen.dart';
import '../features/cs/inquiry_detail_screen.dart';
import '../features/admin/admin_login_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_user_detail_screen.dart';
import '../features/admin/admin_cs_management_screen.dart';
import '../features/admin/admin_notice_edit_screen.dart';
import '../features/admin/admin_faq_edit_screen.dart';
import '../features/admin/admin_inquiry_detail_screen.dart';
import 'admin_provider.dart';
import 'user_provider.dart';

GoRouter createAppRouter(
    UserProvider userProvider, AdminProvider adminProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable:
        Listenable.merge([userProvider, adminProvider]),
    redirect: (context, state) {
      final isLoggedIn = userProvider.isLoggedIn;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isAdminRoute = loc.startsWith('/admin') && loc != '/admin_login';

      // 관리자 포털 가드: 미로그인 시 /admin_login으로
      if (isAdminRoute && !adminProvider.isAdminLoggedIn) {
        return '/admin_login';
      }

      // 일반 앱 인증 가드 (admin 경로 제외)
      if (!loc.startsWith('/admin')) {
        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute) return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      // --- 일반 앱 ---
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/assessment',
        builder: (context, state) => const AssessmentScreen(),
      ),
      GoRoute(
        path: '/cognitive_tasks',
        builder: (context, state) => const CognitiveTasksScreen(),
      ),
      GoRoute(
        path: '/assessment_result',
        builder: (context, state) => const AssessmentResultScreen(),
      ),
      GoRoute(
        path: '/training_hub',
        builder: (context, state) => const TrainingHubScreen(),
      ),
      GoRoute(
        path: '/game/comparison',
        builder: (context, state) => const ComparisonGame(),
      ),
      GoRoute(
        path: '/game/sequence',
        builder: (context, state) => const SequenceGame(),
      ),
      GoRoute(
        path: '/game/sudoku',
        builder: (context, state) => const ShapeSudokuGame(),
      ),
      GoRoute(
        path: '/game/multiplication',
        builder: (context, state) => const MultiplicationGame(),
      ),
      GoRoute(
        path: '/game/shape_match',
        builder: (context, state) => const ShapeMatchGame(),
      ),
      GoRoute(
        path: '/game/categorization',
        builder: (context, state) => const CategorizationGame(),
      ),
      GoRoute(
        path: '/game/reading',
        builder: (context, state) => const SentenceReadingGame(),
      ),
      GoRoute(
        path: '/gait',
        builder: (context, state) => const GaitScreen(),
      ),
      GoRoute(
        path: '/precise_gait_analysis',
        builder: (context, state) => const PreciseGaitAnalysisScreen(),
      ),
      GoRoute(
        path: '/memory_garden',
        builder: (context, state) => const MemoryGardenScreen(),
      ),
      GoRoute(
        path: '/guardian_link',
        builder: (context, state) => const GuardianLinkScreen(),
      ),
      GoRoute(
        path: '/walking_dashboard',
        builder: (context, state) => const WalkingDashboardScreen(),
      ),
      GoRoute(
        path: '/training/recall',
        builder: (context, state) => const DailyRecallPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // --- CS센터 (사용자) ---
      GoRoute(
        path: '/cs_center',
        builder: (context, state) => const CsCenterScreen(),
      ),
      GoRoute(
        path: '/cs/notices',
        builder: (context, state) => const NoticeListScreen(),
      ),
      GoRoute(
        path: '/cs/notice_detail/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return NoticeDetailScreen(noticeId: id);
        },
      ),
      GoRoute(
        path: '/cs/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/cs/inquiry_submit',
        builder: (context, state) => const InquirySubmitScreen(),
      ),
      GoRoute(
        path: '/cs/my_inquiries',
        builder: (context, state) => const MyInquiriesScreen(),
      ),
      GoRoute(
        path: '/cs/inquiry_detail/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return InquiryDetailScreen(inquiryId: id);
        },
      ),

      // --- 관리자 포털 ---
      GoRoute(
        path: '/admin_login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/user_detail/:userId',
        builder: (context, state) {
          final id =
              int.tryParse(state.pathParameters['userId'] ?? '') ?? 0;
          return AdminUserDetailScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/admin/cs_management',
        builder: (context, state) => const AdminCsManagementScreen(),
      ),
      GoRoute(
        path: '/admin/notice_edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['id'];
          return AdminNoticeEditScreen(
            id: id != null ? int.tryParse(id.toString()) : null,
            initialTitle: extra?['title'] as String?,
            initialBody: extra?['body'] as String?,
            initialPinned: extra?['is_pinned'] == true,
          );
        },
      ),
      GoRoute(
        path: '/admin/faq_edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['id'];
          return AdminFaqEditScreen(
            id: id != null ? int.tryParse(id.toString()) : null,
            initialCategory: extra?['category'] as String?,
            initialQuestion: extra?['question'] as String?,
            initialAnswer: extra?['answer'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/admin/inquiry_detail/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AdminInquiryDetailScreen(inquiryId: id);
        },
      ),
    ],
  );
}
