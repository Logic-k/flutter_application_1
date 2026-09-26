import 'package:flutter_application_1/core/fx/spring_out_curve.dart';
import 'package:flutter_application_1/core/motion/app_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모션 토큰은 DESIGN.md §4의 4단 값이다', () {
    expect(AppMotion.press.inMilliseconds, 100);
    expect(AppMotion.fade.inMilliseconds, 150);
    expect(AppMotion.enter.inMilliseconds, 200);
    expect(AppMotion.route.inMilliseconds, 300);
    expect(AppMotion.celebrateMax.inMilliseconds, lessThan(3000));
    expect(AppMotion.pressScale, 0.98);
  });

  test('MLSpringOutCurve는 0에서 시작해 1로 끝나고 오버슈트가 5%를 넘지 않는다', () {
    const curve = MLSpringOutCurve();
    expect(curve.transform(0), 0);
    expect(curve.transform(1), 1);

    var maxValue = 0.0;
    var minValue = 1.0;
    for (var i = 0; i <= 1000; i++) {
      final v = curve.transform(i / 1000);
      if (v > maxValue) maxValue = v;
      if (v < minValue) minValue = v;
    }
    expect(maxValue, lessThanOrEqualTo(1.05 + 1e-9));
    expect(minValue, greaterThanOrEqualTo(0));
    // 눌림 복귀에 쓰는 곡선이므로 실제로 목표를 살짝 넘어야 스프링이다.
    expect(maxValue, greaterThan(1.0));
  });
}
