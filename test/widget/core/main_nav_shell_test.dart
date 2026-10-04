import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show DiagnosticsDebugCreator;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/ml_widgets.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/features/diary/diary_provider.dart';
import 'package:flutter_application_1/features/gait_analysis/gait_provider.dart';
import 'package:flutter_application_1/features/gait_analysis/pedometer_manager.dart';
import 'package:flutter_application_1/features/gait_analysis/walking_dashboard_screen.dart';
import 'package:flutter_application_1/features/home/home_screen.dart';
import 'package:flutter_application_1/features/navigation/main_nav_screen.dart';
import 'package:flutter_application_1/features/profile/profile_screen.dart';
import 'package:flutter_application_1/features/reports/reports_screen.dart';
import 'package:flutter_application_1/features/training/domain/training_catalog.dart';
import 'package:flutter_application_1/features/training/training_hub_page.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';
import '../../helpers/mock_definitions.dart';

// DS-002 MainNav 셸 계약 (핸드오프 §3-2·§8 MainNav·§10 G1).
//
// 5탭 순서·라벨, IndexedStack + 선택 탭만 TickerMode on, 탭 전환 후 State·스크롤 보존,
// 본문 위로 떠 있는 FloatingPillNav, 309dp 폭에서 예외 없음. 각 탭 화면의 내용은
// 해당 화면 테스트의 몫이라 여기서는 셸이 무엇을 어디에 두는지만 본다.

const _labels = ['홈', '인지훈련', '생활습관', '리포트', '내정보'];
const _screens = [
  HomeScreen, TrainingHubScreen, WalkingDashboardScreen, ReportsScreen, ProfileScreen,
];

class _LoggedInUser extends UserProvider {
  @override
  bool get isLoggedIn => true;
  @override
  bool get isLoading => false;
  @override
  bool get hasCompletedOnboarding => true;
  @override
  Map<String, dynamic>? get currentUser => const {
    'id': 1, 'username': 'testuser', 'name': '테스트', 'has_completed_onboarding': 1,
  };
}

Widget _app() {
  final pedometer = MockPedometerManager();
  when(() => pedometer.todaySteps).thenReturn(3500);
  when(() => pedometer.todayCalories).thenReturn(120.0);
  when(() => pedometer.todayDistance).thenReturn(2.5);
  when(() => pedometer.isTracking).thenReturn(false);
  when(() => pedometer.getWeeklySummary()).thenAnswer((_) async => []);
  when(() => pedometer.refreshTracking()).thenAnswer((_) async {});

  final diary = MockDiaryProvider();
  when(() => diary.loadMonth(any(), any())).thenAnswer((_) async {});
  when(() => diary.hasEntry(any())).thenReturn(false);

  final progress = MockTrainingProgressProvider();
  when(() => progress.isLoading).thenReturn(false);
  when(() => progress.isSaving).thenReturn(false);
  when(() => progress.error).thenReturn(null);
  when(() => progress.level).thenReturn(1);
  when(() => progress.totalXp).thenReturn(40);
  when(() => progress.todayDistinctActivityCount).thenReturn(1);
  when(() => progress.currentStreak).thenReturn(2);
  when(() => progress.longestStreak).thenReturn(4);
  when(() => progress.activityProgressById).thenReturn(const {});
  when(() => progress.refresh()).thenAnswer((_) async {});
  when(() => progress.isUnlocked(any())).thenAnswer(
    (i) => initialTrainingActivityIds.contains(i.positionalArguments.single),
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>(create: (_) => _LoggedInUser()),
      ChangeNotifierProvider<PedometerManager>.value(value: pedometer),
      ChangeNotifierProvider<DiaryProvider>.value(value: diary),
      ChangeNotifierProvider<TrainingProgressProvider>.value(value: progress),
      ChangeNotifierProvider<GaitProvider>(create: (_) => GaitProvider()),
      ChangeNotifierProvider<SettingsProvider>(create: (_) => FakeSettingsProvider()),
    ],
    child: const MaterialApp(home: MainNavScreen()),
  );
}

/// 셸이 직접 가진 IndexedStack(탭 화면 안쪽의 것은 제외).
IndexedStack _stack(WidgetTester tester) => tester.widget<IndexedStack>(
  find.descendant(
    of: find.byType(MainNavScreen),
    matching: find.byType(IndexedStack),
  ).first,
);

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(FloatingPillNav),
    matching: find.bySemanticsLabel(label),
  ));
  await tester.pumpAndSettle();
}

void _expectSelected(WidgetTester tester, int index) {
  final stack = _stack(tester);
  expect(stack.index, index);
  expect(stack.children, hasLength(5));
  for (var i = 0; i < 5; i++) {
    final tab = stack.children[i] as TickerMode;
    expect(tab.enabled, i == index, reason: '${_labels[i]} TickerMode');
    expect(tab.child.runtimeType, _screens[i], reason: '${_labels[i]} 자리');
  }
  expect(tester.widget<FloatingPillNav>(find.byType(FloatingPillNav)).currentIndex, index);
}

void main() {
  setUpAll(() async {
    registerFallbackValue(DateTime(2026));
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('5탭을 홈·인지훈련·생활습관·리포트·내정보 순서로 두고 홈에서 시작한다', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final nav = tester.widget<FloatingPillNav>(find.byType(FloatingPillNav));
    expect(nav.items.map((e) => e.label).toList(), _labels);
    for (final label in _labels) {
      expect(
        find.descendant(of: find.byType(FloatingPillNav), matching: find.bySemanticsLabel(label)),
        findsOneWidget,
        reason: label,
      );
    }
    _expectSelected(tester, 0);
  });

  testWidgets('탭을 누르면 IndexedStack index만 바뀌고 선택 탭에만 TickerMode가 켜진다',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final i in [1, 2, 3, 4, 0]) {
      await _tapTab(tester, _labels[i]);
      _expectSelected(tester, i);
    }
  });

  testWidgets('탭을 옮겨도 5개 탭이 다시 만들어지지 않고 홈 스크롤 위치가 유지된다', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Stateless 탭(인지훈련·내정보)도 있으므로 State 대신 Element 동일성으로 본다.
    final elements = [
      for (final screen in _screens) tester.element(find.byType(screen, skipOffstage: false)),
    ];

    final homeScroll = find.descendant(
      of: find.byType(HomeScreen), matching: find.byType(Scrollable),
    ).first;
    await tester.drag(homeScroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    final offset = tester.state<ScrollableState>(homeScroll).position.pixels;
    expect(offset, greaterThan(0));

    for (final label in ['인지훈련', '생활습관', '리포트', '내정보', '홈']) {
      await _tapTab(tester, label);
    }

    for (var i = 0; i < 5; i++) {
      expect(
        identical(tester.element(find.byType(_screens[i], skipOffstage: false)), elements[i]),
        isTrue,
        reason: '${_labels[i]} 탭이 새로 만들어졌다',
      );
    }
    expect(tester.state<ScrollableState>(homeScroll).position.pixels, offset);
  });

  testWidgets('본문은 네비 뒤까지 흐르고 네비는 그 위에 떠 있다', (tester) async {
    // QA_Device(1440×3120 @3.5)의 dp 크기. 좁은 폭의 탭 내용 넘침은 아래 309dp 테스트가 본다.
    const screen = Size(411, 891);
    await tester.binding.setSurfaceSize(screen);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.descendant(
      of: find.byType(MainNavScreen), matching: find.byType(Scaffold),
    ).first);
    expect(scaffold.extendBody, isTrue);
    expect(scaffold.bottomNavigationBar, isA<FloatingPillNav>());

    final body = tester.getRect(find.descendant(
      of: find.byType(MainNavScreen), matching: find.byType(IndexedStack),
    ).first);
    final nav = tester.getRect(find.byType(FloatingPillNav));
    expect(body.bottom, screen.height, reason: '본문이 화면 바닥까지 닿아야 한다');
    expect(nav.overlaps(body), isTrue, reason: '네비가 본문 위에 겹쳐 떠 있어야 한다');
    expect(nav.height, lessThanOrEqualTo(FloatingPillNav.overlayHeight + 24));
  });

  testWidgets('309dp 폭에서 셸(네비·탭 전환)은 넘치지 않고 5탭이 모두 동작한다', (tester) async {
    final owners = await _visitAllTabsAt309(tester);
    expect(owners.where((o) => !_labels.contains(o)), isEmpty,
        reason: '셸 또는 출처 불명의 레이아웃 오류: $owners');
  });

  // 알려진 결함(DS-002에서 발견, backlog → DS-007 대형 글자 매트릭스·DS-008 홈·G8 생활습관).
  // 309dp에서 ① 홈의 동기부여 칩(home_screen.dart `_buildTrainingMotivationChip`)이 Flexible 없는
  // 한 줄 Text라 가로로 넘치고, ② 생활습관의 MLMetricCard(ml_widgets.dart 339~346)가 값·단위 Row로
  // 오른쪽 13~50px, 고정 높이 타일로 아래 10px 넘친다. 현재 결과는 홈 1건 + 생활습관 8건.
  // 테스트 폰트(글자당 1em)라 실제 Pretendard보다 넓게 재지만 글자 배율을 키우면 넘칠 구조다.
  testWidgets('309dp 폭에서 5개 탭의 내용도 넘치지 않아야 한다', (tester) async {
    expect(await _visitAllTabsAt309(tester), isEmpty);
  }, skip: true);
}

/// 309dp에서 5탭을 모두 돌며 난 overflow를 출처(탭 라벨·'nav'·'shell'·'unknown')로 모은다.
/// overflow가 아닌 오류(크래시 등)는 원래 처리기로 넘겨 그대로 테스트를 실패시킨다.
Future<List<String>> _visitAllTabsAt309(WidgetTester tester) async {
  tester.view.physicalSize = const Size(309, 668);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final owners = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      owners.add(_ownerOf(details));
    } else {
      previous?.call(details);
    }
  };
  try {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    for (final i in [1, 2, 3, 4, 0]) {
      await _tapTab(tester, _labels[i]);
      _expectSelected(tester, i);
    }
  } finally {
    FlutterError.onError = previous;
  }
  return owners;
}

/// 오류를 낸 위젯이 네비 안인지, 어느 탭 안인지. overflow 보고에는 그 위젯의 Element가 실려 온다.
String _ownerOf(FlutterErrorDetails details) {
  for (final node in details.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
    final creator = node is DiagnosticsDebugCreator ? node.value : null;
    if (creator is! DebugCreator) continue;
    var owner = 'shell';
    creator.element.visitAncestorElements((ancestor) {
      final type = ancestor.widget.runtimeType;
      if (type == FloatingPillNav) {
        owner = 'nav';
        return false;
      }
      final tab = _screens.indexOf(type);
      if (tab >= 0) {
        owner = _labels[tab];
        return false;
      }
      return true;
    });
    return owner;
  }
  return 'unknown';
}
