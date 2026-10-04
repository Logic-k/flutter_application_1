import 'package:flutter_application_1/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fmt.count', () {
    test('천 단위마다 구분 기호를 넣는다', () {
      expect(Fmt.count(0), '0');
      expect(Fmt.count(999), '999');
      expect(Fmt.count(1000), '1,000');
      expect(Fmt.count(9100), '9,100');
      expect(Fmt.count(10000), '10,000');
      expect(Fmt.count(1234567), '1,234,567');
    });

    test('음수도 구분 기호를 유지한다', () {
      expect(Fmt.count(-9100), '-9,100');
    });
  });

  group('걸음 수 표기', () {
    // 홈 헤더와 걷기 미니 카드가 같은 값을 다르게 보여주던 회귀를 막는다.
    test('steps와 stepsOfGoal이 같은 구분 기호를 쓴다', () {
      expect(Fmt.steps(9100), '9,100보');
      expect(Fmt.stepsOfGoal(9100, 10000), '9,100 / 10,000 걸음');
    });

    test('목표치도 구분 기호를 받는다', () {
      expect(Fmt.stepsOfGoal(0, 10000), '0 / 10,000 걸음');
    });
  });

  group('Fmt.decimal', () {
    test('소수 자릿수를 고정한다', () {
      expect(Fmt.decimal(3.14159, 1), '3.1');
      expect(Fmt.decimal(3.14159, 3), '3.142');
      expect(Fmt.decimal(7, 2), '7.00');
    });
  });
}
