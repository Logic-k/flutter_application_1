import '../domain/dementia_center.dart';

/// 공공데이터포털 「국립중앙의료원_치매안심센터 정보」 CSV를 파싱한다.
///
/// 원본 헤더(15개, 이 순서로 배포됨):
/// 치매안심센터명,시도,시군구,우편번호,주소1,주소2,도로명코드,법정동코드,행정동코드,
/// 위도,경도,홈페이지,전화번호,팩스번호,개소일
///
/// 컬럼 **순서가 아니라 이름으로** 매핑한다. 데이터가 갱신되며 컬럼이 추가·재배치돼도
/// 조용히 엉뚱한 값이 들어가지 않게 하기 위함이다.
class DementiaCenterCsv {
  DementiaCenterCsv._();

  static const String _colName = '치매안심센터명';
  static const String _colSido = '시도';
  static const String _colSigungu = '시군구';
  static const String _colPostal = '우편번호';
  static const String _colAddr1 = '주소1';
  static const String _colAddr2 = '주소2';
  static const String _colLat = '위도';
  static const String _colLng = '경도';
  static const String _colHomepage = '홈페이지';
  static const String _colPhone = '전화번호';
  static const String _colFax = '팩스번호';
  static const String _colOpened = '개소일';

  /// 최소한 이 세 컬럼이 없으면 목록을 만들 수 없다.
  static const List<String> requiredColumns = [_colName, _colSido, _colSigungu];

  /// CSV 전문을 파싱한다.
  ///
  /// 필수 컬럼이 없으면 [FormatException]을 던진다 — 잘못된 파일을 빈 목록으로
  /// 조용히 넘기면 "데이터가 없는 지역"과 구분되지 않는다.
  static List<DementiaCenter> parse(String source) {
    final rows = parseRows(source);
    if (rows.isEmpty) return const [];

    final header = rows.first.map((c) => c.trim()).toList();
    final index = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      index[header[i]] = i;
    }

    final missing =
        requiredColumns.where((c) => !index.containsKey(c)).toList();
    if (missing.isNotEmpty) {
      throw FormatException(
        '치매안심센터 CSV에 필수 컬럼이 없습니다: ${missing.join(", ")}. '
        '실제 헤더: ${header.join(", ")}',
      );
    }

    final centers = <DementiaCenter>[];
    for (final row in rows.skip(1)) {
      String cell(String column) {
        final i = index[column];
        if (i == null || i >= row.length) return '';
        return row[i].trim();
      }

      final name = cell(_colName);
      final sido = cell(_colSido);
      final sigungu = cell(_colSigungu);
      // 이름 없는 행은 데이터가 아니다 (파일 끝 빈 줄 등).
      if (name.isEmpty || sido.isEmpty) continue;

      centers.add(DementiaCenter(
        name: name,
        sido: sido,
        sigungu: sigungu,
        postalCode: cell(_colPostal),
        address1: cell(_colAddr1),
        address2: cell(_colAddr2),
        latitude: double.tryParse(cell(_colLat)),
        longitude: double.tryParse(cell(_colLng)),
        homepage: cell(_colHomepage),
        phone: cell(_colPhone),
        fax: cell(_colFax),
        openedAt: cell(_colOpened),
      ));
    }
    return centers;
  }

  /// RFC 4180 방식으로 행·필드를 분해한다.
  ///
  /// 주소에 쉼표가 들어간 따옴표 필드가 실제로 존재하므로
  /// (예: `"서울 강남구 선릉로108길 27 (삼성동, 강남구치매지원센터)"`)
  /// 단순 `split(',')`은 쓸 수 없다.
  static List<List<String>> parseRows(String source) {
    // UTF-8 BOM 제거. 엑셀로 저장하면 붙는 경우가 많고, 붙으면 첫 컬럼명이 어긋난다.
    var text = source;
    if (text.startsWith('﻿')) text = text.substring(1);

    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var fieldStarted = false;

    void endField() {
      row.add(field.toString());
      field.clear();
      fieldStarted = false;
    }

    void endRow() {
      endField();
      // 빈 줄(필드 하나에 빈 문자열)은 버린다.
      if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];

      if (inQuotes) {
        if (ch == '"') {
          // 연속된 따옴표는 이스케이프된 따옴표 한 개다.
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
        continue;
      }

      if (ch == '"') {
        // 필드 시작 위치의 따옴표만 인용 시작으로 본다.
        if (!fieldStarted) {
          inQuotes = true;
          fieldStarted = true;
        } else {
          field.write(ch);
        }
      } else if (ch == ',') {
        endField();
      } else if (ch == '\r') {
        // CRLF의 CR은 버린다. 단독 CR도 줄바꿈으로 취급한다.
        if (i + 1 < text.length && text[i + 1] == '\n') i++;
        endRow();
      } else if (ch == '\n') {
        endRow();
      } else {
        field.write(ch);
        fieldStarted = true;
      }
    }

    // 마지막 줄에 줄바꿈이 없을 수 있다.
    if (field.isNotEmpty || row.isNotEmpty) endRow();

    return rows;
  }
}
