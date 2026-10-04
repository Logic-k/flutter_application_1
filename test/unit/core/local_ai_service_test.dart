import 'package:flutter_application_1/core/local_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = LocalAIService();

  String completeText([List<String> prefix = const []]) {
    final words = [...prefix];
    while (words.length < 29) {
      words.add('단어${words.length}');
    }
    return [...words, '마쳤다'].join(' ');
  }

  Future<Map<String, dynamic>> analyze({
    String? text,
    double ttr = 0.6,
    double wpm = 120,
    int totalWords = 30,
  }) => service.analyzeText(
    text: text ?? completeText(),
    ttr: ttr,
    wpm: wpm,
    totalWords: totalWords,
    durationSeconds: 15,
  );

  group('LocalAIService 유효 발화 점수 기준선', () {
    test('모든 항목의 최고점 합계는 95점이다', () async {
      final result = await analyze(ttr: 1.0);

      expect(result['cognitive_score'], 95.0);
      expect(result['risk_score'], 0.0);
      expect(result['model'], 'MemoryLink-Rules-v2');
      expect(result['is_local'], true);
      expect(result['analysis'], contains('문장 완결성: 100%'));
    });

    for (final entry in <double, double>{
      49: 80,
      50: 88,
      79: 88,
      80: 95,
      160: 95,
      161: 88,
      200: 88,
      201: 80,
    }.entries) {
      test('WPM ${entry.key}의 인지 점수는 ${entry.value}점이다', () async {
        final result = await analyze(wpm: entry.key);

        expect(result['cognitive_score'], entry.value);
        expect(result['risk_score'], 0.0);
      });
    }

    for (final sample in [
      (ttr: 0.399, score: 81.6, grade: '부족'),
      (ttr: 0.4, score: 81.66666666666667, grade: '보통'),
      (ttr: 0.599, score: 94.93333333333334, grade: '보통'),
      (ttr: 0.6, score: 95.0, grade: '양호'),
      (ttr: 0.601, score: 95.0, grade: '양호'),
    ]) {
      test('TTR ${sample.ttr}의 점수와 ${sample.grade} 등급을 유지한다', () async {
        final result = await analyze(ttr: sample.ttr);

        expect(result['cognitive_score'], closeTo(sample.score, 1e-10));
        expect(result['analysis'], contains(
          '어휘 다양성(TTR): ${(sample.ttr * 100).toStringAsFixed(1)}% — ${sample.grade}',
        ));
      });
    }

    test('같은 단어가 두 번이면 반복 감점이 없다', () async {
      final result = await analyze(text: completeText(['반복', '반복']));

      expect(result['cognitive_score'], 95.0);
      expect(result['analysis'], isNot(contains('반복 표현:')));
    });

    for (final entry in <int, double>{1: 93.5, 2: 92, 3: 90.5, 4: 90, 5: 90}.entries) {
      test('세 번 이상 반복된 ${entry.key}종은 최대 5점까지 감점한다', () async {
        final repeated = [
          for (var kind = 0; kind < entry.key; kind++)
            for (var count = 0; count < 3; count++) '반복$kind',
        ];
        final result = await analyze(text: completeText(repeated));

        expect(result['cognitive_score'], entry.value);
        expect(result['risk_score'], 0.0);
        expect(result['analysis'], contains('반복 표현: ${entry.key}종 감지'));
      });
    }

    test('기억 관련 표현은 인지 점수와 별도로 위험 점수에 반영된다', () async {
      final neutral = await analyze();
      final withKeyword = await analyze(text: completeText(['모르겠어요']));

      expect(neutral['cognitive_score'], 95.0);
      expect(withKeyword['cognitive_score'], 95.0);
      expect(neutral['risk_score'], 0.0);
      expect(withKeyword['risk_score'], 0.15);
      expect(withKeyword['analysis'], contains('기억 관련 표현: 1회 감지'));
    });

    test('같은 위험 키워드가 두 번 있어도 한 종류로 계산한다', () async {
      final result = await analyze(text: completeText(['모르겠어요', '모르겠어요']));

      expect(result['cognitive_score'], 95.0);
      expect(result['risk_score'], 0.15);
      expect(result['analysis'], contains('기억 관련 표현: 1회 감지'));
    });

    test('위험 키워드 여섯 종류도 위험 점수는 0.6을 넘지 않는다', () async {
      final result = await analyze(text: completeText([
        '모르겠어요', '기억이', '안', '생각이', '안', '뭐였더라', '깜빡', '헷갈려요',
      ]));

      expect(result['cognitive_score'], 95.0);
      expect(result['risk_score'], 0.6);
      expect(result['analysis'], contains('기억 관련 표현: 6회 감지'));
    });
  });
}
