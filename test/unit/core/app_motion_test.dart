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
    // 오프닝은 축하 효과와 같은 자동재생 상한 안에서 끝난다(DESIGN.md §4.1 네 번째 예외).
    expect(AppMotion.opening, lessThanOrEqualTo(AppMotion.celebrateMax));
    expect(AppMotion.pressScale, 0.98);
  });

  test('스태거·안무 상한·스프링 토큰은 08 계획 G-01 값이다', () {
    expect(AppMotion.stagger.inMilliseconds, 60);
    expect(AppMotion.choreographyMax.inMilliseconds, 400);
    // 한 묶음 4개(enter + stagger×3)가 상한 안에 들어가야 한다.
    expect(AppMotion.enter + AppMotion.stagger * 3, lessThanOrEqualTo(AppMotion.choreographyMax));
    expect(AppMotion.spring.stiffness, 380);
    expect(AppMotion.spring.mass, 1);
    // 불투명도 눌림은 알아볼 만큼 흐리되 글자는 읽혀야 한다.
    expect(AppMotion.pressOpacity, inInclusiveRange(0.6, 0.85));
    // 다음 문항 지연은 배지 머묾보다 짧아야 풀이를 막지 않는다.
    expect(AppMotion.nextQuestionDelay, lessThan(AppMotion.feedbackHold));
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
