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

    test('문장의 일부만 읽으면 만점이 아닌 부분 점수를 받는다', () {
      // 예전에는 target이 input을 포함하기만 하면 100점이었음 (버그)
      final score = SentenceReadingGame.computeSpeechScore(
          '화창한봄날에개나리가피었습니다', '화창한봄날');
      expect(score, greaterThan(0.0));
      expect(score, lessThan(100.0));
    });

    test('빈 인식 텍스트는 0.0을 반환한다', () {
      expect(
        SentenceReadingGame.computeSpeechScore('화창한 봄날', ''),
        0.0,
      );
    });

    test('내용이 전혀 다르면 0에 가까운 점수를 받는다', () {
      // target="사과바나나딸기", input="수박" — 겹치는 글자 없음
      final score = SentenceReadingGame.computeSpeechScore('사과바나나딸기', '수박');
      expect(score, lessThan(15.0));
    });

    test('길이만 같고 내용이 다른 발화는 높은 점수를 받지 못한다', () {
      // 예전에는 길이 비율 채점이라 같은 길이의 아무 말이나 100점이었음 (버그)
      final score = SentenceReadingGame.computeSpeechScore('화창한봄날', '아무말이나');
      expect(score, lessThan(30.0));
    });

    test('한 글자만 틀리면 높은 점수를 받는다', () {
      // "화창한봄날" vs "화챙한봄날" — 5자 중 1자 치환 → 80점
      final score = SentenceReadingGame.computeSpeechScore('화창한봄날', '화챙한봄날');
      expect(score, closeTo(80.0, 0.1));
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
