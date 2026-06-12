import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training/difficulty_provider.dart';

DifficultyProvider _provider() =>
    DifficultyProvider(username: 'testuser');

void main() {
  group('DifficultyProvider - 珥덇린 ?곹깭', () {
    test('紐⑤뱺 移댄뀒怨좊━??珥덇린 ?덈꺼? 1?대떎', () {
      final p = _provider();
      expect(p.getLevel(GameCategory.calculation), 1);
      expect(p.getLevel(GameCategory.logic), 1);
      expect(p.getLevel(GameCategory.memory), 1);
      expect(p.getLevel(GameCategory.perception), 1);
    });

    test('getTargetTime? ?덈꺼 1?먯꽌 max(2.0, 5.0 - 0.3) = 4.7??諛섑솚?쒕떎', () {
      final p = _provider();
      expect(p.getTargetTime(GameCategory.calculation), closeTo(4.7, 0.01));
    });
  });

  group('DifficultyProvider - ?덈꺼 議곗젙 (Supabase ?숆린???쒖쇅)', () {
    test('3?곗냽 ?뺣떟?대㈃ ?덈꺼??1 ?щ씪媛꾨떎', () async {
      final p = _provider();
      expect(p.getLevel(GameCategory.calculation), 1);
      await p.updatePerformance(GameCategory.calculation, true);
      await p.updatePerformance(GameCategory.calculation, true);
      await p.updatePerformance(GameCategory.calculation, true);
      expect(p.getLevel(GameCategory.calculation), 2);
    });

    test('2?곗냽 ?ㅻ떟?대㈃ ?덈꺼??1 ?대젮媛꾨떎', () async {
      final p = _provider();
      // 癒쇱? ?덈꺼 2濡??щ━湲?      await p.updatePerformance(GameCategory.calculation, true);
      await p.updatePerformance(GameCategory.calculation, true);
      await p.updatePerformance(GameCategory.calculation, true);
      expect(p.getLevel(GameCategory.calculation), 2);

      // 2?곗냽 ?ㅻ떟
      await p.updatePerformance(GameCategory.calculation, false);
      await p.updatePerformance(GameCategory.calculation, false);
      expect(p.getLevel(GameCategory.calculation), 1);
    });

    test('?덈꺼 1?먯꽌 ?ㅻ떟??諛섎났?섏뼱??1 誘몃쭔?쇰줈 ?대젮媛吏 ?딅뒗??, () async {
      final p = _provider();
      await p.updatePerformance(GameCategory.logic, false);
      await p.updatePerformance(GameCategory.logic, false);
      expect(p.getLevel(GameCategory.logic), 1);
    });

    test('?덈꺼 10??理쒕?移섏씠硫?珥덇낵?섏? ?딅뒗??, () async {
      final p = _provider();
      // 30???곗냽 ?뺣떟?쇰줈 理쒕? ?덈꺼 ?꾨떖 ?쒕룄
      for (int i = 0; i < 30; i++) {
        await p.updatePerformance(GameCategory.memory, true);
      }
      expect(p.getLevel(GameCategory.memory), lessThanOrEqualTo(10));
    });

    test('移댄뀒怨좊━ 媛??덈꺼? ?쒕줈 ?낅┰?곸씠??, () async {
      final p = _provider();
      await p.updatePerformance(GameCategory.logic, true);
      await p.updatePerformance(GameCategory.logic, true);
      await p.updatePerformance(GameCategory.logic, true);
      expect(p.getLevel(GameCategory.logic), 2);
      expect(p.getLevel(GameCategory.calculation), 1); // 蹂寃??놁쓬
    });

    test('?덈꺼???믪쓣?섎줉 getTargetTime??吏㏃븘吏꾨떎', () async {
      final p = _provider();
      final timeLevel1 = p.getTargetTime(GameCategory.perception);
      // ?덈꺼 4濡??щ━湲?(3+3+3 = 9???뺣떟, 3踰??덈꺼??
      for (int i = 0; i < 9; i++) {
        await p.updatePerformance(GameCategory.perception, true);
      }
      final timeLevel4 = p.getTargetTime(GameCategory.perception);
      expect(timeLevel4, lessThan(timeLevel1));
    });

    test('getTargetTime? 理쒖넖媛?2.0 ?댄븯濡??대젮媛吏 ?딅뒗??, () async {
      final p = _provider();
      // 理쒕? ?덈꺼源뚯? ?щ━湲?      for (int i = 0; i < 30; i++) {
        await p.updatePerformance(GameCategory.calculation, true);
      }
      expect(p.getTargetTime(GameCategory.calculation), greaterThanOrEqualTo(2.0));
    });
  });
}
