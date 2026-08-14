import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/features/training/difficulty_provider.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import 'mock_definitions.dart';

/// 게임/화면 위젯 테스트에 필요한 Provider 트리를 포함해 위젯을 pump한다.
Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget widget, {
  UserProvider? userProvider,
  DifficultyProvider? difficultyProvider,
  TrainingProgressProvider? trainingProgressProvider,
  SettingsProvider? settingsProvider,
}) async {
  final user = userProvider ?? _buildFakeUserProvider();
  final difficulty = difficultyProvider ??
      DifficultyProvider(username: 'testuser');
  final settings = settingsProvider ?? FakeSettingsProvider();
  final trainingProgress =
      trainingProgressProvider ?? buildFakeTrainingProgressProvider();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: user),
        ChangeNotifierProvider<DifficultyProvider>.value(value: difficulty),
        ChangeNotifierProvider<TrainingProgressProvider>.value(
          value: trainingProgress,
        ),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: MaterialApp(home: widget),
    ),
  );
}

/// 기본값이 채워진 훈련 진행 Provider mock.
///
/// mocktail은 stub되지 않은 non-nullable 게터에 null을 돌려주므로, 화면이 새 지표를
/// 읽기 시작하는 순간 관계없는 테스트까지 _TypeError로 무너진다. 화면이 읽을 만한
/// 값은 여기서 미리 채워 둔다.
TrainingProgressProvider buildFakeTrainingProgressProvider({
  int todayDistinctActivityCount = 0,
  int totalXp = 0,
  int level = 1,
  int currentStreak = 0,
  int longestStreak = 0,
}) {
  final mock = MockTrainingProgressProvider();
  when(() => mock.isLoading).thenReturn(false);
  when(() => mock.isSaving).thenReturn(false);
  when(() => mock.todayDistinctActivityCount)
      .thenReturn(todayDistinctActivityCount);
  when(() => mock.totalXp).thenReturn(totalXp);
  when(() => mock.level).thenReturn(level);
  when(() => mock.currentStreak).thenReturn(currentStreak);
  when(() => mock.longestStreak).thenReturn(longestStreak);
  return mock;
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
