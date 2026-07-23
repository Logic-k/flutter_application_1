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

Widget _buildSubject({
  required MockUserProvider mockUser,
  required MockPedometerManager mockPedometer,
  required MockDiaryProvider mockDiary,
  MockTrainingProgressProvider? mockTrainingProgress,
}) {
  final progress = mockTrainingProgress ?? MockTrainingProgressProvider();
  if (mockTrainingProgress == null) {
    when(() => progress.todayDistinctActivityCount).thenReturn(0);
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
    when(() => mockTrainingProgress.todayDistinctActivityCount).thenReturn(2);
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

    // 3500 → "3,500보" 형식으로 포맷팀
    expect(find.textContaining('3,500'), findsOneWidget);
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
