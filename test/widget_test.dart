import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/features/auth/login_screen.dart';
import 'helpers/mock_definitions.dart';

void main() {
  testWidgets('App smoke test: 로그인 화면이 렌더링된다', (WidgetTester tester) async {
    final mockUser = MockUserProvider();
    when(() => mockUser.isLoggedIn).thenReturn(false);
    when(() => mockUser.isLoading).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: mockUser),
          ChangeNotifierProvider<SettingsProvider>(
              create: (_) => FakeSettingsProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('MemoryLink'), findsOneWidget);
    expect(find.text('사용자 아이디'), findsOneWidget);
  });
}
