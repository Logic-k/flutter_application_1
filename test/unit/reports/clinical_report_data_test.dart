import 'dart:io';

import 'package:flutter_application_1/features/reports/models/clinical_report_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// 이 영역은 이번 정리 전까지 테스트가 한 건도 없었다.
/// 검증되지 않은 표준 척도 환산이 임상 리포트에 인쇄되는 상태로 오래 남아 있었던
/// 이유이기도 하다. 되돌아가지 않게 지킨다.
void main() {
  group('인지활동 지수', () {
    test('0~100 원 척도를 유지한다 (30점 환산으로 되돌아가지 않는다)', () {
      final index = ClinicalReportData.computeActivityIndex({
        'memory': 80.0,
        'attention': 90.0,
        'executive': 70.0,
        'language': 60.0,
      });
      expect(index, closeTo(75.0, 0.001));
      // 30점 만점이었다면 22.5가 나왔을 자리다.
      expect(index, greaterThan(30));
    });

    test('측정하지 않은 영역은 평균에서 제외한다', () {
      // 아직 해보지 않은 훈련 때문에 점수가 깎이면
      // "안 한 것"과 "못 한 것"을 구분할 수 없다.
      final index = ClinicalReportData.computeActivityIndex({
        'memory': 80.0,
        'attention': null,
        'executive': null,
        'language': null,
      });
      expect(index, closeTo(80.0, 0.001));
    });

    test('데이터가 하나도 없으면 0이다', () {
      expect(
        ClinicalReportData.computeActivityIndex({'memory': null}),
        0.0,
      );
    });

    test('100을 넘지 않는다', () {
      final index = ClinicalReportData.computeActivityIndex({'memory': 140.0});
      expect(index, 100.0);
    });
  });

  group('수행 구간(밴드)', () {
    test('75 / 55 / 35 경계에서 전환된다', () {
      expect(CognitiveBandExt.fromScore(100), CognitiveBand.normal);
      expect(CognitiveBandExt.fromScore(75), CognitiveBand.normal);
      expect(CognitiveBandExt.fromScore(74.9), CognitiveBand.borderline);
      expect(CognitiveBandExt.fromScore(55), CognitiveBand.borderline);
      expect(CognitiveBandExt.fromScore(54.9), CognitiveBand.needsFollowUp);
      expect(CognitiveBandExt.fromScore(35), CognitiveBand.needsFollowUp);
      expect(CognitiveBandExt.fromScore(34.9), CognitiveBand.specialistReferral);
      expect(CognitiveBandExt.fromScore(0), CognitiveBand.specialistReferral);
    });

    test('라벨이 비처방적 표현이다', () {
      final labels =
          CognitiveBand.values.map((b) => b.label).toList();
      expect(labels, ['양호', '주의 관찰', '변화가 관찰됨', '상담 권유']);

      // 의학적 판정을 시사하는 표현은 웰니스 범위를 벗어난다.
      for (final banned in ['정상', '전문의', '의뢰', '진단', '경과 관찰']) {
        expect(labels.any((l) => l.contains(banned)), isFalse,
            reason: '밴드 라벨에 "$banned"이(가) 남아 있다');
      }
    });
  });

  group('면책 고지', () {
    test('세 문장이 규정된 순서로 있다', () {
      expect(MedicalDisclaimer.sentences, hasLength(3));
      expect(MedicalDisclaimer.sentences.first,
          contains('진단·선별 검사가 아니며 의료기기가 아닙니다'));
      expect(MedicalDisclaimer.sentences[1], contains('등가성이 검증되지 않았습니다'));
      expect(MedicalDisclaimer.sentences.last, contains('치매안심센터'));
    });
  });

  group('소스에 표준 척도 이름이 남아 있지 않다', () {
    // 주석으로 "왜 안 쓰는지" 설명하는 것은 허용하고,
    // 사용자에게 보이는 문자열 리터럴만 검사한다.
    final userFacing = <String>[
      'lib/features/reports/clinical_report_generator.dart',
      'lib/features/reports/clinical_report_options_screen.dart',
      'lib/core/cs_service.dart',
    ];

    for (final path in userFacing) {
      test('$path 에 MMSE·GDS 표기가 없다', () {
        final lines = File(path).readAsLinesSync();
        final offending = <String>[];
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trimLeft();
          // 주석 줄은 건너뛴다 — 제거 이유를 설명하는 근거는 남겨야 한다.
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
          if (RegExp(r'MMSE 환산|GDS').hasMatch(line)) {
            offending.add('${i + 1}: ${line.trim()}');
          }
        }
        expect(offending, isEmpty,
            reason: '사용자에게 보이는 문자열에 표준 척도 표기가 남아 있다:\n'
                '${offending.join("\n")}');
      });
    }
  });
}
