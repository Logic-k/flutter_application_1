import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../domain/dementia_center.dart';
import 'dementia_center_csv.dart';

/// 데이터 적재 결과. 화면이 "빈 목록"과 "파일 없음"과 "파일 깨짐"을
/// 서로 다르게 안내할 수 있어야 한다.
enum DementiaCenterDataStatus {
  /// 정상 적재.
  ready,

  /// asset이 없다. CSV를 아직 넣지 않은 상태.
  missing,

  /// 파일은 있으나 UTF-8이 아니거나 헤더가 다르다.
  invalid,
}

class DementiaCenterData {
  final DementiaCenterDataStatus status;
  final List<DementiaCenter> centers;

  /// [DementiaCenterDataStatus.invalid]일 때 원인 설명.
  final String? message;

  const DementiaCenterData({
    required this.status,
    this.centers = const [],
    this.message,
  });

  bool get isReady => status == DementiaCenterDataStatus.ready;
}

/// 치매안심센터 목록을 자산에서 읽어 시도·시군구로 묶어 준다.
///
/// 위치 권한이나 GPS를 쓰지 않는다. 사용자가 시도와 시군구를 고르는 방식이라
/// 새 의존성도, 새 런타임 권한도 필요 없다. 위치정보를 수집하지 않으므로
/// 개인정보 최소수집 원칙에도 맞는다.
class DementiaCenterRepository {
  /// 앱에 번들되는 CSV 경로. 파일을 교체하면 앱 전체가 갱신된다.
  static const String assetPath = 'assets/data/dementia_centers.csv';

  final AssetBundle _bundle;

  DementiaCenterRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  DementiaCenterData? _cache;

  /// 자산을 읽어 파싱한다. 결과는 캐시되어 재진입 시 파일을 다시 읽지 않는다.
  Future<DementiaCenterData> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final result = await _loadUncached();
    _cache = result;
    return result;
  }

  Future<DementiaCenterData> _loadUncached() async {
    late final ByteData raw;
    try {
      raw = await _bundle.load(assetPath);
    } catch (_) {
      // pubspec에 선언은 되어 있으나 파일이 없는 경우가 여기로 온다.
      return const DementiaCenterData(
        status: DementiaCenterDataStatus.missing,
      );
    }

    String text;
    try {
      // data.go.kr CSV는 EUC-KR로 배포되는 경우가 있다. Dart 기본 라이브러리에는
      // EUC-KR 디코더가 없으므로, 잘못된 인코딩은 조용히 깨뜨리지 말고 알려준다.
      text = const Utf8Decoder(allowMalformed: false)
          .convert(raw.buffer.asUint8List());
    } catch (_) {
      return const DementiaCenterData(
        status: DementiaCenterDataStatus.invalid,
        message: 'CSV가 UTF-8이 아닙니다. UTF-8로 저장한 뒤 다시 넣어 주세요.',
      );
    }

    try {
      final centers = DementiaCenterCsv.parse(text);
      if (centers.isEmpty) {
        // 헤더만 있는 자리표시자 CSV가 여기로 온다. 파일이 깨진 게 아니라
        // 아직 채워지지 않은 것이므로 사용자에게는 같은 안내를 보여준다.
        return const DementiaCenterData(
          status: DementiaCenterDataStatus.missing,
        );
      }
      return DementiaCenterData(
        status: DementiaCenterDataStatus.ready,
        centers: centers,
      );
    } on FormatException catch (e) {
      debugPrint('[DementiaCenterRepository] CSV 파싱 실패: ${e.message}');
      return DementiaCenterData(
        status: DementiaCenterDataStatus.invalid,
        message: e.message,
      );
    }
  }

  @visibleForTesting
  void clearCache() => _cache = null;

  /// 시도 목록. 원본 등장 순서(대체로 서울→부산→…)를 유지한다.
  static List<String> sidoList(List<DementiaCenter> centers) {
    final seen = <String>{};
    final out = <String>[];
    for (final c in centers) {
      if (seen.add(c.sido)) out.add(c.sido);
    }
    return out;
  }

  /// 주어진 시도의 시군구 목록. 가나다순으로 정렬한다.
  static List<String> sigunguList(List<DementiaCenter> centers, String sido) {
    final seen = <String>{};
    for (final c in centers) {
      if (c.sido == sido) seen.add(c.sigungu);
    }
    final out = seen.toList()..sort();
    return out;
  }

  /// 시도(필수)와 시군구(선택)로 거른 목록. 센터명 가나다순.
  static List<DementiaCenter> filter(
    List<DementiaCenter> centers, {
    required String sido,
    String? sigungu,
  }) {
    final out = centers
        .where((c) => c.sido == sido)
        .where((c) => sigungu == null || c.sigungu == sigungu)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return out;
  }
}
