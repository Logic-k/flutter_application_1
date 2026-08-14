import 'package:flutter_application_1/features/dementia_center/data/dementia_center_csv.dart';
import 'package:flutter_test/flutter_test.dart';

/// 공공데이터포털 「국립중앙의료원_치매안심센터 정보」 원본에서 그대로 가져온 행.
/// 주소에 쉼표가 들어간 따옴표 필드가 실제로 존재하므로 픽스처에 반드시 남겨 둔다.
const _header =
    '치매안심센터명,시도,시군구,우편번호,주소1,주소2,도로명코드,법정동코드,행정동코드,'
    '위도,경도,홈페이지,전화번호,팩스번호,개소일';

const _realRows = '''
서울특별시강남구치매안심센터,서울특별시,강남구,06153,"서울 강남구 선릉로108길 27 (삼성동, 강남구치매지원센터)","4층, 5층",4166442,1168010500,1168058000,37.5103126,127.0463796,gangnam.nid.or.kr,02-568-4203,02-568-4280,2018-12-18
서울특별시강서구치매안심센터,서울특별시,강서구,07590,서울 강서구 화곡로 371 (등촌동),3층,3005069,1150010200,1150052000,37.55695579,126.8522421,gangseo.nid.or.kr,02-3663-0943,02-3663-0909,2018-07-02''';

void main() {
  group('parseRows', () {
    test('따옴표 안의 쉼표를 필드 구분자로 보지 않는다', () {
      final rows = DementiaCenterCsv.parseRows('$_header\n$_realRows');
      expect(rows, hasLength(3));
      // 헤더 15개 + 각 행 15개. 쉼표를 잘못 세면 여기서 어긋난다.
      for (final row in rows) {
        expect(row, hasLength(15));
      }
      expect(rows[1][4], '서울 강남구 선릉로108길 27 (삼성동, 강남구치매지원센터)');
      expect(rows[1][5], '4층, 5층');
    });

    test('이스케이프된 따옴표를 한 개로 되돌린다', () {
      final rows = DementiaCenterCsv.parseRows('a,b\n"큰""따옴표",2');
      expect(rows[1][0], '큰"따옴표');
    });

    test('CRLF와 LF를 모두 줄바꿈으로 처리한다', () {
      final rows = DementiaCenterCsv.parseRows('a,b\r\n1,2\r\n3,4');
      expect(rows, hasLength(3));
      expect(rows[2], ['3', '4']);
    });

    test('UTF-8 BOM을 제거해 첫 컬럼명이 어긋나지 않게 한다', () {
      final rows = DementiaCenterCsv.parseRows('﻿치매안심센터명,시도\n가,나');
      expect(rows.first.first, '치매안심센터명');
    });

    test('끝의 빈 줄은 행으로 세지 않는다', () {
      final rows = DementiaCenterCsv.parseRows('a,b\n1,2\n\n');
      expect(rows, hasLength(2));
    });
  });

  group('parse', () {
    test('실제 배포 스키마를 모델로 옮긴다', () {
      final centers = DementiaCenterCsv.parse('$_header\n$_realRows');
      expect(centers, hasLength(2));

      final gangnam = centers.first;
      expect(gangnam.name, '서울특별시강남구치매안심센터');
      expect(gangnam.sido, '서울특별시');
      expect(gangnam.sigungu, '강남구');
      expect(gangnam.latitude, closeTo(37.5103126, 1e-7));
      expect(gangnam.longitude, closeTo(127.0463796, 1e-7));
      expect(gangnam.phone, '02-568-4203');
      expect(gangnam.fullAddress,
          '서울 강남구 선릉로108길 27 (삼성동, 강남구치매지원센터) 4층, 5층');
    });

    test('컬럼 순서가 바뀌어도 이름으로 매핑한다', () {
      const reordered = '시군구,시도,치매안심센터명\n강남구,서울특별시,강남센터';
      final centers = DementiaCenterCsv.parse(reordered);
      expect(centers.single.name, '강남센터');
      expect(centers.single.sido, '서울특별시');
      expect(centers.single.sigungu, '강남구');
    });

    test('필수 컬럼이 없으면 조용히 비우지 않고 예외를 던진다', () {
      expect(
        () => DementiaCenterCsv.parse('시도,주소1\n서울특별시,어딘가'),
        throwsA(isA<FormatException>()),
      );
    });

    test('헤더만 있으면 빈 목록이다', () {
      expect(DementiaCenterCsv.parse(_header), isEmpty);
    });

    test('이름이나 시도가 빈 행은 건너뛴다', () {
      final centers = DementiaCenterCsv.parse(
        '치매안심센터명,시도,시군구\n,서울특별시,강남구\n센터,,강남구\n정상,서울특별시,강남구',
      );
      expect(centers.single.name, '정상');
    });

    test('위경도가 비어 있으면 null로 두고 지도 링크를 만들지 않는다', () {
      final centers = DementiaCenterCsv.parse(
        '치매안심센터명,시도,시군구,위도,경도\n센터,서울특별시,강남구,,',
      );
      expect(centers.single.hasCoordinates, isFalse);
      expect(centers.single.mapUri, isNull);
    });
  });

  group('DementiaCenter 파생 값', () {
    test('스킴 없는 홈페이지에 https를 붙인다', () {
      final centers = DementiaCenterCsv.parse(
        '치매안심센터명,시도,시군구,홈페이지\n센터,서울특별시,강남구,gangnam.nid.or.kr',
      );
      expect(centers.single.homepageUri.toString(), 'https://gangnam.nid.or.kr');
    });

    test('전화번호의 하이픈을 제거한 tel URI를 만든다', () {
      final centers = DementiaCenterCsv.parse(
        '치매안심센터명,시도,시군구,전화번호\n센터,서울특별시,강남구,02-568-4203',
      );
      expect(centers.single.telUri.toString(), 'tel:025684203');
    });

    test('전화번호가 없으면 tel URI도 없다', () {
      final centers = DementiaCenterCsv.parse(
        '치매안심센터명,시도,시군구,전화번호\n센터,서울특별시,강남구,',
      );
      expect(centers.single.hasPhone, isFalse);
      expect(centers.single.telUri, isNull);
    });
  });
}
