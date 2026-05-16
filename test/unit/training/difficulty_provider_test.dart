import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training/difficulty_provider.dart';
import '../../helpers/mock_definitions.dart';

DifficultyProvider _provider() =>
    DifficultyProvider(username: 'testuser', supabase: FakeSupabaseClient());

void main() {
  group('DifficultyProvider - 초기 상태', () {
    test('모든 카테고리의 초기 레벨은 1이다', () {
      final p = _provider();
      expect(p.getLevel(GameCategory.calculation), 1);
      expect(p.getLevel(GameCategory.logic), 1);
      expect(p.getLevel(GameCategory.memory), 1);
      expect(p.getLevel(GameCategory.perception), 1);
    });

    test('getTargetTime은 레벨 1에서 max(2.0, 5.0 - 0.3) = 4.7을 반환한다', () {
      final p = _provider();
      expect(p.getTargetTime(GameCategory.calculation), closeTo(4.7, 0.01));
    });
  });

  group('DifficultyProvider - 레벨 조정 (Supabase 동기화 제외)', () {
    test('3연속 정답이면 레벨이 1 올라간다', () async {
      final p = _provider();
      expect(p.getLevel(GameCategory.calculation), 1);
      await p.updatePerformance(GameCategory.calculation, true);
      await p.updatePerformance(GameCategory.calculation, true);
      await p.updatePerformance(GameCategory.calculation, true);
      expect(p.getLevel(GameCategory.calculation), 2);
    });

    test('2연속 오답이면 레벨이 1 내려간다', () async {
      final p = _provider();
      // 먼저 레벨 2로 올리기
      await p.updatePerformance(GameCategory.calculation, true);
      await p.updatePerformance(GameCategory.calculation, true);
      await p.updatePerformance(GameCategory.calculation, true);
      expect(p.getLevel(GameCategory.calculation), 2);

      // 2연속 오답
      await p.updatePerformance(GameCategory.calculation, false);
      await p.updatePerformance(GameCategory.calculation, false);
      expect(p.getLevel(GameCategory.calculation), 1);
    });

    test('레벨 1에서 오답이 반복되어도 1 미만으로 내려가지 않는다', () async {
      final p = _provider();
      await p.updatePerformance(GameCategory.logic, false);
      await p.updatePerformance(GameCategory.logic, false);
      expect(p.getLevel(GameCategory.logic), 1);
    });

    test('레벨 10이 최대치이며 초과하지 않는다', () async {
      final p = _provider();
      // 30회 연속 정답으로 최대 레벨 도달 시도
      for (int i = 0; i < 30; i++) {
        await p.updatePerformance(GameCategory.memory, true);
      }
      expect(p.getLevel(GameCategory.memory), lessThanOrEqualTo(10));
    });

    test('카테고리 간 레벨은 서로 독립적이다', () async {
      final p = _provider();
      await p.updatePerformance(GameCategory.logic, true);
      await p.updatePerformance(GameCategory.logic, true);
      await p.updatePerformance(GameCategory.logic, true);
      expect(p.getLevel(GameCategory.logic), 2);
      expect(p.getLevel(GameCategory.calculation), 1); // 변경 없음
    });

    test('레벨이 높을수록 getTargetTime이 짧아진다', () async {
      final p = _provider();
      final timeLevel1 = p.getTargetTime(GameCategory.perception);
      // 레벨 4로 올리기 (3+3+3 = 9회 정답, 3번 레벨업)
      for (int i = 0; i < 9; i++) {
        await p.updatePerformance(GameCategory.perception, true);
      }
      final timeLevel4 = p.getTargetTime(GameCategory.perception);
      expect(timeLevel4, lessThan(timeLevel1));
    });

    test('getTargetTime은 최솟값 2.0 이하로 내려가지 않는다', () async {
      final p = _provider();
      // 최대 레벨까지 올리기
      for (int i = 0; i < 30; i++) {
        await p.updatePerformance(GameCategory.calculation, true);
      }
      expect(p.getTargetTime(GameCategory.calculation), greaterThanOrEqualTo(2.0));
    });
  });
}
