import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/dementia_center/data/dementia_center_repository.dart';
import 'package:flutter_application_1/features/dementia_center/dementia_center_finder_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// 자산 대신 메모리에서 CSV를 돌려주는 번들.
class _FakeBundle extends CachingAssetBundle {
  final List<int>? _bytes;

  _FakeBundle(this._bytes);

  @override
  Future<ByteData> load(String key) async {
    final data = _bytes;
    if (data == null) throw Exception('asset 없음: $key');
    return ByteData.view(Uint8List.fromList(data).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final data = await load(key);
    return utf8.decode(data.buffer.asUint8List());
  }
}

DementiaCenterRepository _repo(String? csv) => DementiaCenterRepository(
      bundle: _FakeBundle(csv == null ? null : utf8.encode(csv)),
    );

const _csv = '''
치매안심센터명,시도,시군구,주소1,주소2,위도,경도,홈페이지,전화번호
서울특별시강남구치매안심센터,서울특별시,강남구,"서울 강남구 선릉로108길 27 (삼성동, 강남구치매지원센터)","4층, 5층",37.5103126,127.0463796,gangnam.nid.or.kr,02-568-4203
서울특별시강서구치매안심센터,서울특별시,강서구,서울 강서구 화곡로 371 (등촌동),3층,37.55695579,126.8522421,gangseo.nid.or.kr,02-3663-0943
부산광역시해운대구치매안심센터,부산광역시,해운대구,부산 해운대구 무슨로 1,,35.1631,129.1635,,051-749-7583''';

Future<void> _pump(WidgetTester tester, DementiaCenterRepository repo) async {
  await tester.pumpWidget(
    MaterialApp(home: DementiaCenterFinderScreen(repository: repo)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('첫 시도의 센터 목록을 보여준다', (tester) async {
    await _pump(tester, _repo(_csv));

    // 시도 목록의 첫 항목(서울특별시)이 기본 선택된다.
    expect(find.text('서울특별시강남구치매안심센터'), findsOneWidget);
    expect(find.text('서울특별시강서구치매안심센터'), findsOneWidget);
    // 다른 시도는 섞이지 않는다.
    expect(find.text('부산광역시해운대구치매안심센터'), findsNothing);
    expect(find.text('검색 결과 2곳'), findsOneWidget);
  });

  testWidgets('주소는 상세주소까지 합쳐 보여준다', (tester) async {
    await _pump(tester, _repo(_csv));
    expect(
      find.text('서울 강남구 선릉로108길 27 (삼성동, 강남구치매지원센터) 4층, 5층'),
      findsOneWidget,
    );
  });

  testWidgets('시도를 바꾸면 그 지역 센터로 교체된다', (tester) async {
    await _pump(tester, _repo(_csv));

    await tester.tap(find.text('서울특별시').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('부산광역시').last);
    await tester.pumpAndSettle();

    expect(find.text('부산광역시해운대구치매안심센터'), findsOneWidget);
    expect(find.text('서울특별시강남구치매안심센터'), findsNothing);
  });

  testWidgets('전화번호가 없으면 전화 버튼을 숨기고, 홈페이지가 없으면 홈페이지 버튼을 숨긴다',
      (tester) async {
    // 부산 센터는 홈페이지가 비어 있다.
    await _pump(tester, _repo(_csv));
    await tester.tap(find.text('서울특별시').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('부산광역시').last);
    await tester.pumpAndSettle();

    expect(find.text('전화'), findsOneWidget);
    expect(find.text('지도'), findsOneWidget);
    expect(find.text('홈페이지'), findsNothing);
  });

  testWidgets('데이터가 없어도 막다른 곳에 두지 않고 상담콜센터를 안내한다', (tester) async {
    await _pump(tester, _repo(null));

    expect(find.text('센터 목록을 불러오지 못했습니다'), findsOneWidget);
    expect(find.text('치매상담콜센터'), findsOneWidget);
    expect(find.textContaining('1899-9988'), findsOneWidget);
  });

  testWidgets('헤더만 있는 자리표시자 CSV도 같은 안내를 보여준다', (tester) async {
    await _pump(tester, _repo('치매안심센터명,시도,시군구'));
    expect(find.text('센터 목록을 불러오지 못했습니다'), findsOneWidget);
    expect(find.text('치매상담콜센터'), findsOneWidget);
  });

  testWidgets('UTF-8이 아닌 파일은 원인을 알려 준다', (tester) async {
    // EUC-KR "가"(0xB0 0xA1)는 유효한 UTF-8이 아니다.
    final repo = DementiaCenterRepository(
      bundle: _FakeBundle([0xB0, 0xA1, 0x2C, 0xB0]),
    );
    await _pump(tester, repo);
    expect(find.textContaining('UTF-8'), findsOneWidget);
  });

  // 출처표시는 공공누리상 의무다. 리팩터링으로 사라지는 것을 막는다.
  // 목록 아래쪽에 있어 ListView가 지연 빌드하므로 스크롤해서 확인한다.
  testWidgets('공공데이터 출처표시가 화면에 남아 있다', (tester) async {
    await _pump(tester, _repo(_csv));
    await tester.dragUntilVisible(
      find.textContaining('국립중앙의료원'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    expect(find.textContaining('국립중앙의료원'), findsOneWidget);
    expect(find.textContaining('공공데이터포털'), findsOneWidget);
  });

  testWidgets('위치정보를 수집하지 않는다는 사실을 밝힌다', (tester) async {
    await _pump(tester, _repo(_csv));
    await tester.dragUntilVisible(
      find.textContaining('위치정보를 수집하지 않습니다'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    expect(find.textContaining('위치정보를 수집하지 않습니다'), findsOneWidget);
  });

  testWidgets('동작 버튼은 최소 터치 영역 48dp를 지킨다', (tester) async {
    await _pump(tester, _repo(_csv));
    // 고령 사용자는 진전으로 정확도가 낮아 작은 버튼을 놓친다.
    final callButton = find.ancestor(
      of: find.text('전화').first,
      matching: find.byType(InkWell),
    );
    final size = tester.getSize(callButton.first);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(88));
  });
}
