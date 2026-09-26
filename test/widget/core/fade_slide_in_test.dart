import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/motion/fade_slide_in.dart';
import 'package:flutter_test/flutter_test.dart';

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.byType(Opacity)).opacity;

Widget _subject({bool reduce = false, int index = 0}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: FadeSlideIn(
        playKey: 'test',
        index: index,
        child: const Text('카드'),
      ),
    ),
  );
}

void main() {
  setUp(FadeSlideIn.resetPlayed);

  testWidgets('처음에는 투명하게 시작해 400ms 안에 완전히 나타난다', (tester) async {
    await tester.pumpWidget(_subject(index: 3));
    expect(_opacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(_opacity(tester), 1);
    await tester.pumpAndSettle();
  });

  testWidgets('움직임 줄이기면 첫 프레임부터 최종 상태다', (tester) async {
    await tester.pumpWidget(_subject(reduce: true));
    expect(_opacity(tester), 1);
  });

  testWidgets('같은 키는 앱 실행 동안 한 번만 재생한다', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_subject());
    expect(_opacity(tester), 1);
  });
}
