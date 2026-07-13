import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_1/core/database_helper.dart';
import 'package:flutter_application_1/features/health/health_input_screen.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({}); // FakeSettingsProvider 대비
    DatabaseHelper.resetForTest();
    // 데모 시드를 포함한 DB 초기화를 미리 완료해 위젯 로드가 즉시 끝나게 한다
    await DatabaseHelper().getRecentHealthLogs(1, 1);
  });

  // ffi DB는 실제 async I/O로 완료되므로 initState의 _load까지 runAsync 범위에서
  // 진행시킨 뒤 프레임을 그린다.
  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(() async {
      await pumpWithProviders(tester, const HealthInputScreen());
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets('HealthInputScreen: 주요 입력 섹션이 표시된다', (tester) async {
    await pump(tester);

    expect(find.text('수면'), findsOneWidget);
    expect(find.text('혈압 · 혈당'), findsOneWidget);
    expect(find.text('식이 (지중해식)'), findsOneWidget);
    expect(find.text('오늘 기록 저장'), findsOneWidget);
  });

  testWidgets('HealthInputScreen: 식이 칩 선택 시 식이 점수가 증가한다', (tester) async {
    await pump(tester);

    expect(find.text('식이 점수: 0 / 5'), findsOneWidget);
    await tester.ensureVisible(find.text('채소'));
    await tester.pump();
    await tester.tap(find.text('채소'));
    await tester.pump();
    expect(find.text('식이 점수: 1 / 5'), findsOneWidget);
  });

  testWidgets('HealthInputScreen: 저장 시 스낵바가 표시된다', (tester) async {
    await pump(tester);

    await tester.ensureVisible(find.text('오늘 기록 저장'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('오늘 기록 저장'));
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump(); // 저장 후 스낵바 프레임
    expect(find.text('오늘의 건강 기록이 저장되었습니다.'), findsOneWidget);
  });
}
