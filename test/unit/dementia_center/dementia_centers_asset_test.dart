import 'dart:io';

import 'package:flutter_application_1/features/dementia_center/data/dementia_center_csv.dart';
import 'package:flutter_application_1/features/dementia_center/data/dementia_center_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// 앱에 실제로 번들되는 CSV 파일 자체를 읽어 검증한다.
///
/// 데이터를 갱신본으로 교체할 때 인코딩이나 컬럼 구성이 어긋나면 앱에서는
/// "센터 목록을 불러오지 못했습니다"라는 안내만 보이고 원인을 알 수 없다.
/// 그 상황을 파일 교체 즉시 잡는다.
void main() {
  late List<String> lines;
  late String source;

  setUpAll(() {
    final file = File(DementiaCenterRepository.assetPath);
    expect(file.existsSync(), isTrue,
        reason: '${DementiaCenterRepository.assetPath} 가 없다');
    // UTF-8이 아니면 여기서 예외가 난다 — data.go.kr CSV는 EUC-KR로 배포되는
    // 경우가 있어 실제로 겪을 수 있는 실패다.
    source = file.readAsStringSync();
    lines = source.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
  });

  test('UTF-8로 읽히고 헤더가 배포 스키마와 일치한다', () {
    final header = lines.first.replaceFirst('﻿', '');
    expect(
      header,
      '치매안심센터명,시도,시군구,우편번호,주소1,주소2,도로명코드,법정동코드,행정동코드,'
      '위도,경도,홈페이지,전화번호,팩스번호,개소일',
    );
  });

  test('자리표시자가 아니라 실제 데이터가 들어 있다', () {
    final centers = DementiaCenterCsv.parse(source);
    // 헤더만 있는 자리표시자를 실수로 커밋하는 것을 막는다.
    expect(centers.length, greaterThan(200),
        reason: '센터 ${centers.length}곳 — 자리표시자이거나 일부만 들어갔다');
  });

  test('전국 시도가 고르게 들어 있다', () {
    final centers = DementiaCenterCsv.parse(source);
    final sido = DementiaCenterRepository.sidoList(centers);
    // 광역시·도는 17개다. 일부 지역만 든 파일은 "우리 동네엔 센터가 없다"는
    // 오해를 만들기 때문에 부분 데이터를 허용하지 않는다.
    expect(sido.length, greaterThanOrEqualTo(16),
        reason: '시도가 ${sido.length}개뿐이다 — ${sido.join(", ")}');
  });

  test('필수 필드가 비어 있는 센터가 없다', () {
    final centers = DementiaCenterCsv.parse(source);
    for (final c in centers) {
      expect(c.name, isNotEmpty);
      expect(c.sido, isNotEmpty);
      expect(c.sigungu, isNotEmpty);
    }
  });

  test('대부분의 센터가 전화번호와 좌표를 갖는다', () {
    final centers = DementiaCenterCsv.parse(source);
    final withPhone = centers.where((c) => c.hasPhone).length;
    final withCoords = centers.where((c) => c.hasCoordinates).length;

    // 전화·지도 버튼은 값이 있을 때만 노출되므로, 비율이 급락하면
    // 파싱이 어긋났다는 신호다.
    expect(withPhone / centers.length, greaterThan(0.9));
    expect(withCoords / centers.length, greaterThan(0.9));
  });

  test('쉼표가 든 주소가 한 필드로 유지된다', () {
    final centers = DementiaCenterCsv.parse(source);
    // 따옴표 필드 파싱이 깨지면 주소가 잘리고 컬럼이 한 칸씩 밀린다.
    final withCommaAddress =
        centers.where((c) => c.address1.contains(',')).length;
    expect(withCommaAddress, greaterThan(0),
        reason: '쉼표 든 주소가 하나도 없다 — 따옴표 파싱이 깨졌을 수 있다');
  });
}
