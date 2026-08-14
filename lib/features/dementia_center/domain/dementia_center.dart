/// 치매안심센터 한 곳.
///
/// 출처: 공공데이터포털 「국립중앙의료원_치매안심센터 정보」
/// https://www.data.go.kr/data/15138421/fileData.do (이용허락범위 제한 없음)
///
/// 원본 CSV는 15개 컬럼이지만 도로명코드·법정동코드·행정동코드는 화면에서 쓰지 않아
/// 모델에 담지 않는다. 필요해지면 그때 추가한다.
class DementiaCenter {
  /// 예: "서울특별시강남구치매안심센터"
  final String name;

  /// 예: "서울특별시"
  final String sido;

  /// 예: "강남구"
  final String sigungu;

  final String postalCode;

  /// 도로명 주소. 예: "서울 강남구 선릉로108길 27 (삼성동, 강남구치매지원센터)"
  final String address1;

  /// 상세 주소. 예: "4층, 5층". 비어 있을 수 있다.
  final String address2;

  /// 위경도. 원본에 값이 없거나 숫자가 아니면 null.
  final double? latitude;
  final double? longitude;

  /// 스킴 없이 저장된 경우가 많다. 예: "gangnam.nid.or.kr"
  final String homepage;

  /// 예: "02-568-4203"
  final String phone;

  final String fax;

  /// 개소일. 예: "2018-12-18"
  final String openedAt;

  const DementiaCenter({
    required this.name,
    required this.sido,
    required this.sigungu,
    this.postalCode = '',
    this.address1 = '',
    this.address2 = '',
    this.latitude,
    this.longitude,
    this.homepage = '',
    this.phone = '',
    this.fax = '',
    this.openedAt = '',
  });

  /// 화면에 한 줄로 보여줄 주소.
  String get fullAddress =>
      address2.isEmpty ? address1 : '$address1 $address2';

  bool get hasPhone => phone.trim().isNotEmpty;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// 원본이 "gangnam.nid.or.kr"처럼 스킴 없이 들어오므로 보정한다.
  /// 홈페이지가 없으면 null.
  Uri? get homepageUri {
    final raw = homepage.trim();
    if (raw.isEmpty) return null;
    final withScheme =
        raw.startsWith('http://') || raw.startsWith('https://') ? raw : 'https://$raw';
    return Uri.tryParse(withScheme);
  }

  /// 전화 걸기용 URI. 번호가 없으면 null.
  /// 하이픈과 공백은 다이얼러가 무시하지만, 일부 기기에서 문제가 되어 미리 제거한다.
  Uri? get telUri {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return null;
    return Uri(scheme: 'tel', path: digits);
  }

  /// 지도 앱/웹에서 위치를 여는 URI.
  /// 카카오맵 링크는 앱이 없으면 웹으로 열려 별도 의존성 없이 동작한다.
  Uri? get mapUri {
    if (!hasCoordinates) return null;
    return Uri.parse(
      'https://map.kakao.com/link/map/${Uri.encodeComponent(name)},$latitude,$longitude',
    );
  }
}
