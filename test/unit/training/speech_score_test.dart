import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/training/games/sentence_reading_game.dart';

void main() {
  group('SentenceReadingGame.computeSpeechScore', () {
    test('공백 제거 후 완전 일치하면 100.0을 반환한다', () {
      expect(
        SentenceReadingGame.computeSpeechScore(
          '화창한 봄날에', '화창한봄날에'),
        100.0,
      );
    });

    test('인식 텍스트가 목표 문장을 포함하면 100.0을 반환한다', () {
      expect(
        SentenceReadingGame.computeSpeechScore(
          '봄날', '화창한봄날입니다'),
        100.0,
      );
    });

    test('목표 문장이 인식 텍스트를 포함하면 100.0을 반환한다', () {
      expect(
        SentenceReadingGame.computeSpeechScore(
          '화창한봄날에개나리가피었습니다', '화창한봄날'),
        100.0,
      );
    });

    test('빈 인식 텍스트는 0.0을 반환한다', () {
      expect(
        SentenceReadingGame.computeSpeechScore('화창한 봄날', ''),
        0.0,
      );
    });

    test('부분 일치 시 길이 비율로 점수를 계산한다', () {
      // target="사과바나나딸기" (7자), input="수박" (2자) - 서로 포함 관계 없음
      // score = 2/7 * 100 ≈ 28.6
      final score = SentenceReadingGame.computeSpeechScore('사과바나나딸기', '수박');
      expect(score, closeTo(28.57, 0.1));
    });

    test('점수는 0 ~ 100 범위를 벗어나지 않는다', () {
      // 인식 텍스트가 목표보다 길어도 100 초과하지 않음
      final score = SentenceReadingGame.computeSpeechScore(
        '봄', '화창한봄날에개나리가활짝피었습니다');
      expect(score, lessThanOrEqualTo(100.0));
      expect(score, greaterThanOrEqualTo(0.0));
    });
  });
}
