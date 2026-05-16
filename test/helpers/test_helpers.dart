import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/features/training/difficulty_provider.dart';
import 'mock_definitions.dart';

/// 게임/화면 위젯 테스트에 필요한 Provider 트리를 포함해 위젯을 pump한다.
Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget widget, {
  UserProvider? userProvider,
  DifficultyProvider? difficultyProvider,
  SettingsProvider? settingsProvider,
}) async {
  final user = userProvider ?? _buildFakeUserProvider();
  final difficulty = difficultyProvider ??
      DifficultyProvider(
        username: 'testuser',
        supabase: FakeSupabaseClient(),
      );
  final settings = settingsProvider ?? FakeSettingsProvider();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: user),
        ChangeNotifierProvider<DifficultyProvider>.value(value: difficulty),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: MaterialApp(home: widget),
    ),
  );
}

UserProvider _buildFakeUserProvider() {
  final mock = MockUserProvider();
  when(() => mock.isLoggedIn).thenReturn(true);
  when(() => mock.currentUser)
      .thenReturn({'id': 1, 'username': 'testuser', 'has_completed_onboarding': 1});
  when(() => mock.calculationScore).thenReturn(7.0);
  when(() => mock.logicScore).thenReturn(6.0);
  when(() => mock.memoryScore).thenReturn(8.0);
  when(() => mock.attentionScore).thenReturn(7.0);
  when(() => mock.pedometerEnabled).thenReturn(false);
  when(() => mock.isLoading).thenReturn(false);
  // setCognitiveScore는 void이므로 별도 stubbing 불필요
  return mock;
}
