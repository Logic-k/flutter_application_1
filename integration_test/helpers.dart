import 'package:flutter_test/flutter_test.dart';

/// [finder]가 화면에서 실제로 눌리는 상태인가.
bool tappable(Finder finder) => finder.hitTestable().evaluate().isNotEmpty;

/// [condition]이 참이 될 때까지 짧은 간격으로 프레임을 넘긴다.
///
/// 콜드 스타트 오프닝(MemoryOpening)은 앱 전체를 덮고 탭을 가로챈다. 프레임마다 최대 50ms만
/// 진행하므로 `pumpAndSettle(Duration(seconds: 5))`처럼 간격이 긴 pump는 오프닝을 몇 분씩 끈다.
/// 로그인 확인을 기다리는 정지 화면에서는 프레임이 멈춰 pumpAndSettle이 덮인 채로 끝나고,
/// 다음 탭이 로그인 버튼 대신 오프닝에 먹힌다(LAUNCH_AUDIT P0-02 로그인 실패).
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('$timeout 안에 $description 상태가 되지 않았다');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
