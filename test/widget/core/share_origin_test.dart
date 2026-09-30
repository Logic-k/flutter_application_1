import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/share_origin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('버튼의 전역 위치와 크기를 공유 기준 사각형으로 돌려준다', (tester) async {
    late BuildContext buttonContext;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned(
              left: 40,
              top: 100,
              width: 200,
              height: 48,
              child: Builder(
                builder: (context) {
                  buttonContext = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ],
        ),
      ),
    );

    // iPad 팝오버 조건: 비어 있지 않고 화면 안에 있어야 한다.
    expect(shareOriginOf(buttonContext), const Rect.fromLTWH(40, 100, 200, 48));
  });
}
