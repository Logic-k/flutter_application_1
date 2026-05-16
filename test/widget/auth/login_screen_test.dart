import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import '../../helpers/mock_definitions.dart';

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
}
