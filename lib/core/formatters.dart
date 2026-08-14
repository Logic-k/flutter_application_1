import 'package:intl/intl.dart';

/// 화면 전반의 숫자 표기를 한 곳에서 정한다.
///
/// 같은 값이 화면마다 다르게 보이면 고령 사용자에게는 다른 값으로 읽힌다.
/// 실제로 홈 화면에서 같은 걸음 수가 헤더에는 "9,100보", 미니 카드에는
/// "9100 / 10,000 걸음"으로 동시에 보이던 문제가 있었다.
class Fmt {
  Fmt._();

  static final NumberFormat _decimal = NumberFormat.decimalPattern('ko_KR');

  /// 천 단위 구분 기호를 넣은 정수 표기. 예: 9100 → "9,100"
  static String count(int value) => _decimal.format(value);

  /// 소수 자릿수를 고정한 표기. 예: (3.14159, 1) → "3.1"
  static String decimal(num value, int fractionDigits) =>
      value.toStringAsFixed(fractionDigits);

  /// 걸음 수 표기. 단위까지 포함한다. 예: 9100 → "9,100보"
  static String steps(int value) => '${count(value)}보';

  /// 목표 대비 걸음 수 표기. 예: (9100, 10000) → "9,100 / 10,000 걸음"
  static String stepsOfGoal(int value, int goal) =>
      '${count(value)} / ${count(goal)} 걸음';
}
