import 'dart:io';

import 'package:flutter_application_1/core/services/guardian_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 공개 처리방침이 실제 동작과 어긋나지 않게 지킨다.
///
/// 처리방침은 Firebase Hosting(`site/`)과 소개 페이지(`landing/`) 두 곳에 있고,
/// 서버 보관 기간은 매일 정리 작업(`firebase-ops/retention.mjs`)이 집행한다.
/// 기간을 바꾸면 세 곳을 함께 고쳐야 이 테스트가 통과한다.
void main() {
  String read(String path) => File(path).readAsStringSync().replaceAll('\r\n', '\n');

  final site = read('site/privacy.html');
  final landing = read('landing/privacy.html');
  final retention = read('firebase-ops/retention.mjs');

  int policy(String key) {
    final match = RegExp('$key: (\\d+)').firstMatch(retention);
    expect(match, isNotNull, reason: 'retention.mjs POLICY에 $key가 없다');
    return int.parse(match!.group(1)!);
  }

  test('두 처리방침 사본은 canonical 링크 한 줄 말고 같다', () {
    final canonical = RegExp(r'^\s*<link rel="canonical"[^\n]*\n', multiLine: true);
    expect(canonical.hasMatch(landing), isTrue);
    expect(landing.replaceFirst(canonical, ''), site);
  });

  test('처리방침의 보관 기간이 정리 작업과 보호자 링크 수명과 같다', () {
    expect(site, contains('접수일로부터 1년(${policy('inquiryRetentionDays')}일)'));
    expect(site, contains('1년(${policy('authInactiveDays')}일) 동안 쓰이지 않았고'));
    expect(site, contains('마지막 갱신 후 ${policy('difficultyStaleDays')}일'));
    expect(site, contains('${GuardianSyncService.linkLifetime.inDays}일 동안 소식이 없어'));
    // 만료 뒤 유예일과 하루 한 번 실행을 더해도 처리방침의 '5일 이내'를 넘지 않는다.
    expect(site, contains('닫힌 날로부터 5일 이내'));
    expect(policy('guardianGraceDays') + 1, lessThanOrEqualTo(5));
  });
}
