import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/dementia_center/data/dementia_center_repository.dart';
import 'package:flutter_application_1/features/dementia_center/domain/dementia_center.dart';
import 'package:flutter_test/flutter_test.dart';

/// 자산 로딩을 대신하는 번들. 실제 파일 없이 상태 분기를 검증한다.
class _FakeBundle extends CachingAssetBundle {
  final Map<String, List<int>> _bytes;

  _FakeBundle(this._bytes);

  @override
  Future<ByteData> load(String key) async {
    final data = _bytes[key];
    if (data == null) throw Exception('asset 없음: $key');
    return ByteData.view(Uint8List.fromList(data).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final data = await load(key);
    return utf8.decode(data.buffer.asUint8List());
  }
}

DementiaCenterRepository _repoWith(String? csv, {List<int>? rawBytes}) {
  final bytes = <String, List<int>>{};
  if (rawBytes != null) {
    bytes[DementiaCenterRepository.assetPath] = rawBytes;
  } else if (csv != null) {
    bytes[DementiaCenterRepository.assetPath] = utf8.encode(csv);
  }
  return DementiaCenterRepository(bundle: _FakeBundle(bytes));
}

const _csv = '''
치매안심센터명,시도,시군구,전화번호
서울특별시강남구치매안심센터,서울특별시,강남구,02-568-4203
서울특별시강서구치매안심센터,서울특별시,강서구,02-3663-0943
부산광역시해운대구치매안심센터,부산광역시,해운대구,051-749-7583
서울특별시강남구제2치매안심센터,서울특별시,강남구,02-000-0000''';

void main() {
  group('load 상태 분기', () {
    test('자산이 없으면 missing', () async {
      final data = await _repoWith(null).load();
      expect(data.status, DementiaCenterDataStatus.missing);
      expect(data.isReady, isFalse);
    });

    test('헤더만 있으면 missing — 파일이 깨진 게 아니라 아직 안 채운 것이다', () async {
      final data = await _repoWith('치매안심센터명,시도,시군구').load();
      expect(data.status, DementiaCenterDataStatus.missing);
    });

    test('필수 컬럼이 없으면 invalid이고 원인을 알려 준다', () async {
      final data = await _repoWith('시도,주소1\n서울특별시,어딘가').load();
      expect(data.status, DementiaCenterDataStatus.invalid);
      expect(data.message, contains('치매안심센터명'));
    });

    test('UTF-8이 아니면 invalid이고 인코딩을 지목한다', () async {
      // EUC-KR로 인코딩된 "가"(0xB0 0xA1)는 유효한 UTF-8 시퀀스가 아니다.
      final data = await _repoWith(null, rawBytes: [0xB0, 0xA1, 0x2C, 0xB0]).load();
      expect(data.status, DementiaCenterDataStatus.invalid);
      expect(data.message, contains('UTF-8'));
    });

    test('정상 CSV는 ready', () async {
      final data = await _repoWith(_csv).load();
      expect(data.status, DementiaCenterDataStatus.ready);
      expect(data.centers, hasLength(4));
    });

    test('두 번째 load는 자산을 다시 읽지 않는다', () async {
      final repo = _repoWith(_csv);
      final first = await repo.load();
      final second = await repo.load();
      expect(identical(first, second), isTrue);
    });
  });

  group('지역 목록', () {
    late List<DementiaCenter> centers;

    setUp(() async {
      centers = (await _repoWith(_csv).load()).centers;
    });

    test('시도는 중복 없이 원본 등장 순서를 지킨다', () {
      expect(DementiaCenterRepository.sidoList(centers),
          ['서울특별시', '부산광역시']);
    });

    test('시군구는 해당 시도 것만 중복 없이 가나다순', () {
      expect(DementiaCenterRepository.sigunguList(centers, '서울특별시'),
          ['강남구', '강서구']);
      expect(DementiaCenterRepository.sigunguList(centers, '부산광역시'),
          ['해운대구']);
    });

    test('시군구를 생략하면 시도 전체를 센터명 순으로 반환한다', () {
      final result =
          DementiaCenterRepository.filter(centers, sido: '서울특별시');
      expect(result, hasLength(3));
      expect(result.map((c) => c.name).toList(), [
        '서울특별시강남구치매안심센터',
        '서울특별시강남구제2치매안심센터',
        '서울특별시강서구치매안심센터',
      ]..sort());
    });

    test('시군구를 지정하면 그 안에서만 거른다', () {
      final result = DementiaCenterRepository.filter(
        centers,
        sido: '서울특별시',
        sigungu: '강남구',
      );
      expect(result, hasLength(2));
      expect(result.every((c) => c.sigungu == '강남구'), isTrue);
    });

    test('센터가 없는 지역은 빈 목록이지 예외가 아니다', () {
      final result =
          DementiaCenterRepository.filter(centers, sido: '대전광역시');
      expect(result, isEmpty);
    });
  });
}
