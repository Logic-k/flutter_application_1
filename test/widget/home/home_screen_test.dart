import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/features/home/home_screen.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/features/diary/diary_provider.dart';
import 'package:flutter_application_1/features/gait_analysis/pedometer_manager.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import '../../helpers/mock_definitions.dart';

void _stubTrainingProgress(
  MockTrainingProgressProvider mock, {
  required int todayCount,
  int totalXp = 340,
  int level = 4,
  int currentStreak = 3,
  int longestStreak = 9,
}) {
  when(() => mock.isLoading).thenReturn(false);
  when(() => mock.isSaving).thenReturn(false);
  when(() => mock.todayDistinctActivityCount).thenReturn(todayCount);
  when(() => mock.totalXp).thenReturn(totalXp);
  when(() => mock.level).thenReturn(level);
  when(() => mock.currentStreak).thenReturn(currentStreak);
  when(() => mock.longestStreak).thenReturn(longestStreak);
}

Widget _buildSubject({
  required MockUserProvider mockUser,
  required MockPedometerManager mockPedometer,
  required MockDiaryProvider mockDiary,
  MockTrainingProgressProvider? mockTrainingProgress,
}) {
  // 홈 헤더가 레벨·XP·연속학습을 읽는다. stub하지 않으면 mocktail이 null을
  // 돌려주어 화면 전체가 _TypeError로 무너진다.
  final progress = mockTrainingProgress ?? MockTrainingProgressProvider();
  if (mockTrainingProgress == null) {
    _stubTrainingProgress(progress, todayCount: 0);
  }
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: mockUser),
      ChangeNotifierProvider<PedometerManager>.value(value: mockPedometer),
      ChangeNotifierProvider<DiaryProvider>.value(value: mockDiary),
      ChangeNotifierProvider<TrainingProgressProvider>.value(
        value: progress,
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void _stubPedometer(MockPedometerManager m) {
  when(() => m.todaySteps).thenReturn(3500);
  when(() => m.todayCalories).thenReturn(120.0);
  when(() => m.todayDistance).thenReturn(2.5);
  when(() => m.isTracking).thenReturn(false);
}

void _stubUser(MockUserProvider m) {
  when(() => m.isLoggedIn).thenReturn(true);
  when(() => m.isLoading).thenReturn(false);
  when(() => m.pedometerEnabled).thenReturn(false);
  when(() => m.currentUser)
      .thenReturn({'id': 1, 'username': 'testuser', 'has_completed_onboarding': 1});
  when(() => m.calculationScore).thenReturn(7.0);
  when(() => m.logicScore).thenReturn(6.0);
  when(() => m.memoryScore).thenReturn(8.0);
  when(() => m.attentionScore).thenReturn(7.0);
  when(() => m.totalAssessmentScore).thenReturn(6.5);
}

void _stubDiary(MockDiaryProvider m) {
  when(() => m.loadMonth(any(), any())).thenAnswer((_) async {});
  when(() => m.hasEntry(any())).thenReturn(false);
}

void main() {
  late MockUserProvider mockUser;
  late MockPedometerManager mockPedometer;
  late MockDiaryProvider mockDiary;
  late MockTrainingProgressProvider mockTrainingProgress;

  setUpAll(() async {
    registerFallbackValue(DateTime(2026));
    await initializeDateFormatting('ko_KR');
  });

  setUp(() {
    mockUser = MockUserProvider();
    mockPedometer = MockPedometerManager();
    mockDiary = MockDiaryProvider();
    mockTrainingProgress = MockTrainingProgressProvider();
    _stubUser(mockUser);
    _stubPedometer(mockPedometer);
    _stubDiary(mockDiary);
    _stubTrainingProgress(mockTrainingProgress, todayCount: 2);
  });

  testWidgets('HomeScreen: MemoryLink 타이틀이 AppBar에 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser: mockUser, mockPedometer: mockPedometer, mockDiary: mockDiary));
    await tester.pump();

    expect(find.text('MemoryLink'), findsOneWidget);
  });

  testWidgets('HomeScreen: 사용자 이름으로 인사말이 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser: mockUser, mockPedometer: mockPedometer, mockDiary: mockDiary));
    await tester.pump();

    expect(find.textContaining('testuser'), findsOneWidget);
  });

  testWidgets('HomeScreen: 오늘의 추천 훈련 섹션이 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser: mockUser, mockPedometer: mockPedometer, mockDiary: mockDiary));
    await tester.pump();

    expect(find.text('오늘의 추천 훈련'), findsOneWidget);
  });

  testWidgets('HomeScreen: 알림 아이콘 버튼이 존재한다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser: mockUser, mockPedometer: mockPedometer, mockDiary: mockDiary));
    await tester.pump();

    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('HomeScreen: 알림 버튼 탭 시 다이얼로그가 나타난다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser: mockUser, mockPedometer: mockPedometer, mockDiary: mockDiary));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('알림'), findsOneWidget);
    expect(find.text('새로운 알림이 없습니다.\n매일 훈련을 완료하면 알림을 받을 수 있습니다.'), findsOneWidget);
  });

  testWidgets('HomeScreen: 만보기 걸음 수가 화면에 표시된다', (tester) async {
    await tester.pumpWidget(_buildSubject(mockUser: mockUser, mockPedometer: mockPedometer, mockDiary: mockDiary));
    await tester.pump();

    // 헤더 히어로 카드와 걷기 미니 카드가 같은 걸음 수를 각각 보여준다.
    // 두 곳 모두 천 단위 구분 기호를 써야 한다 — 예전에는 헤더만 "3,500보"이고
    // 미니 카드는 "3500 / 10,000 걸음"이라 같은 값이 다르게 읽혔다.
    expect(find.text('3,500보'), findsOneWidget);
    expect(find.text('3,500 / 10,000 걸음'), findsOneWidget);
    expect(find.textContaining('3500 '), findsNothing);
  });

  testWidgets('HomeScreen: 레벨·XP·연속학습 배지를 헤더에 표시한다', (tester) async {
    await tester.pumpWidget(_buildSubject(
      mockUser: mockUser,
      mockPedometer: mockPedometer,
      mockDiary: mockDiary,
      mockTrainingProgress: mockTrainingProgress,
    ));
    await tester.pump();

    // 훈련 허브에서만 보이던 지표를 매일 여는 화면으로 끌어왔다.
    expect(find.text('레벨 4'), findsOneWidget);
    expect(find.text('340 XP'), findsOneWidget);
    expect(find.text('3일 연속'), findsOneWidget);
    // 최장 기록(9)이 현재 기록(3)보다 클 때만 노출한다.
    expect(find.text('최장 9일'), findsOneWidget);
  });

  testWidgets('HomeScreen: 연속 기록이 없으면 연속 배지를 숨긴다', (tester) async {
    _stubTrainingProgress(
      mockTrainingProgress,
      todayCount: 0,
      currentStreak: 0,
      longestStreak: 0,
    );
    await tester.pumpWidget(_buildSubject(
      mockUser: mockUser,
      mockPedometer: mockPedometer,
      mockDiary: mockDiary,
      mockTrainingProgress: mockTrainingProgress,
    ));
    await tester.pump();

    // 0일 연속을 보여주는 건 격려가 아니라 잔소리다.
    expect(find.textContaining('연속'), findsNothing);
    expect(find.textContaining('최장'), findsNothing);
    expect(find.text('레벨 4'), findsOneWidget);
  });

  testWidgets('HomeScreen: 최장 기록이 현재와 같으면 중복 표시하지 않는다', (tester) async {
    _stubTrainingProgress(
      mockTrainingProgress,
      todayCount: 1,
      currentStreak: 5,
      longestStreak: 5,
    );
    await tester.pumpWidget(_buildSubject(
      mockUser: mockUser,
      mockPedometer: mockPedometer,
      mockDiary: mockDiary,
      mockTrainingProgress: mockTrainingProgress,
    ));
    await tester.pump();

    expect(find.text('5일 연속'), findsOneWidget);
    expect(find.textContaining('최장'), findsNothing);
  });

  testWidgets('HomeScreen: 진행 Provider의 오늘 활동 수를 즉시 표시한다', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        mockUser: mockUser,
        mockPedometer: mockPedometer,
        mockDiary: mockDiary,
        mockTrainingProgress: mockTrainingProgress,
      ),
    );
    await tester.pump();

    expect(find.text('오늘 2개'), findsOneWidget);
  });
}
