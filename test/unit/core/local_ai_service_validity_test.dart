import 'package:flutter_application_1/core/local_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = LocalAIService();

  test('음성 시간과 WPM 미확보 시 텍스트 지표만 남긴다', () async {
    final result = await service.analyzeText(
      text: '오늘 산책했어요', ttr: 1, wpm: null, totalWords: 2,
    );
    expect(result['is_available'], false);
    expect(result['cognitive_score'], isNull);
    expect(result['risk_score'], isNull);
    expect(result['analysis'], contains('100.0% (텍스트 기준)'));
    expect(result['analysis'], contains('휴지 비율: 측정 불가'));
  });

  test('시간을 생략하면 기본값으로 점수를 만들지 않는다', () async {
    final result = await service.analyzeText(
      text: '오늘 산책했어요', ttr: 1, wpm: 120, totalWords: 2,
    );
    expect(result['cognitive_score'], isNull);
  });

  for (final ttr in [null, -0.1, 1.1, double.nan, double.infinity]) {
    test('유효하지 않은 TTR $ttr 는 점수를 만들지 않는다', () async {
      final result = await service.analyzeText(
        text: '오늘 산책했어요', ttr: ttr, wpm: 120, totalWords: 2,
        durationSeconds: 10,
      );
      expect(result['cognitive_score'], isNull);
    });
  }

  for (final seconds in [-1.0, double.nan, double.infinity]) {
    test('유효하지 않은 시간 $seconds 는 점수를 만들지 않는다', () async {
      final result = await service.analyzeText(
        text: '오늘 산책했어요', ttr: 1, wpm: 120, totalWords: 2,
        durationSeconds: seconds,
      );
      expect(result['cognitive_score'], isNull);
    });
  }

  test('빈 전사는 저점수나 최고 위험 점수가 아니다', () async {
    final result = await service.analyzeText(
      text: '  ', ttr: 0, wpm: 0, totalWords: 0, durationSeconds: 0,
    );
    expect(result['cognitive_score'], isNull);
    expect(result['risk_score'], isNull);
    expect(result['is_available'], false);
  });

  for (final speed in [0.0, -1.0, double.nan, double.infinity]) {
    test('유효하지 않은 WPM $speed 는 측정 불가다', () async {
      final result = await service.analyzeText(
        text: '오늘 산책했어요', ttr: 1, wpm: speed, totalWords: 2,
        durationSeconds: 10,
      );
      expect(result['cognitive_score'], isNull);
      expect(result['risk_score'], isNull);
      expect(result['is_available'], false);
    });
  }

  test('시간 0은 양수 WPM을 전달해도 점수를 만들지 않는다', () async {
    final result = await service.analyzeText(
      text: '오늘 산책했어요', ttr: 1, wpm: 120, totalWords: 2,
      durationSeconds: 0,
    );
    expect(result['cognitive_score'], isNull);
  });
}
