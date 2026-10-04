import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/core/motion/app_motion.dart';
import 'package:flutter_application_1/core/motion/motion_play_log.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import '../../helpers/mock_definitions.dart';

class _FadeOnlySettings extends FakeSettingsProvider {
  @override
  bool get reduceMotion => true;
}

/// 로그인 화면의 로고 이미지(날아가는 것 포함).
Finder _logos() => find.byWidgetPredicate(
  (w) => w is Image && w.image is AssetImage &&
      (w.image as AssetImage).assetName == 'assets/icon/app_icon.png',
);

Widget _buildSubject(MockUserProvider mockUser) {
  return ChangeNotifierProvider<UserProvider>.value(
    value: mockUser,
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  late MockUserProvider mockUser;

  setUp(() {
    mockUser = MockUserProvider();
    when(() => mockUser.isLoggedIn).thenReturn(false);
    when(() => mockUser.isLoading).thenReturn(false);
  });

  testWidgets('LoginScreen: 사용자 아이디, 비밀번호 TextField 2개를 렌더링한다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('사용자 아이디'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
  });

  testWidgets('LoginScreen: MemoryLink 타이틀을 표시한다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    expect(find.text('MemoryLink'), findsOneWidget);
  });

  testWidgets('LoginScreen: 회원가입 TextButton이 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser));
    expect(find.text('처음이신가요? 회원가입'), findsOneWidget);
  });

  testWidgets('LoginScreen: 로그인 실패 시 에러 메시지를 표시한다', (tester) async {
    when(() => mockUser.login(any(), any())).thenAnswer((_) async => false);

    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.enterText(find.byType(TextField).first, 'wronguser');
    await tester.enterText(find.byType(TextField).last, 'wrongpass');
    await tester.tap(find.text('로그인'));
    await tester.pump(); // Future 완료 대기
    await tester.pump(); // setState 반영

    expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
  });

  testWidgets('LoginScreen: 성공 시 login()이 입력한 자격증명으로 호출된다', (tester) async {
    when(() => mockUser.login('admin', 'admin')).thenAnswer((_) async => false);

    await tester.pumpWidget(_buildSubject(mockUser));
    await tester.enterText(find.byType(TextField).first, 'admin');
    await tester.enterText(find.byType(TextField).last, 'admin');
    await tester.tap(find.text('로그인'));
    await tester.pump();
    await tester.pump();

    verify(() => mockUser.login('admin', 'admin')).called(1);
  });

  group('스플래시 → 로그인 로고 연결(08 계획 G-03)', () {
    setUp(MotionPlayLog.reset);

    testWidgets('full: 첫 프레임 로고는 화면 중앙(스플래시 자리)에서 시작해 300ms 뒤 제자리에 남는다', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(mockUser));
      await tester.pump(); // 제자리 측정 후 이동 시작
      // 날아가는 로고 + 자리만 차지하는 로고.
      expect(_logos(), findsNWidgets(2));
      final screenCenter = tester.getCenter(find.byType(Scaffold));
      expect(tester.getCenter(_logos().last), screenCenter);

      // 컨트롤러는 경과 시간이 지속시간을 "넘은" 프레임에 끝난다 — 한 프레임 더 준다.
      await tester.pump(AppMotion.route + const Duration(milliseconds: 16));
      await tester.pump();
      expect(_logos(), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('fadeOnly: 로고가 움직이지 않고 제자리에 한 벌만 있다', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: _FadeOnlySettings(),
          child: _buildSubject(mockUser),
        ),
      );
      await tester.pump();
      expect(_logos(), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('none(Android 애니메이션 제거): pump 1회로 최종 배치', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockUser,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: LoginScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_logos(), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('로고 이동은 앱 실행당 한 번뿐이다(로그아웃 후 재진입 무모션)', (tester) async {
      await tester.pumpWidget(_buildSubject(mockUser));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());

      await tester.pumpWidget(_buildSubject(mockUser));
      await tester.pump();
      expect(_logos(), findsOneWidget);
    });
  });
}
