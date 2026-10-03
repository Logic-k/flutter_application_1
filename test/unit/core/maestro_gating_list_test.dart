import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Maestro 게이팅 목록은 maestro/gating_flows.txt 한 곳에만 둔다.
///
/// 로컬(run_maestro_tests.ps1)과 CI(scripts/maestro_gating.sh)가 목록을 따로 들고 있다가
/// CI가 지워진 flow(social_ranking_flow)를 계속 실행한 적이 있다(LAUNCH_AUDIT P0-02).
void main() {
  String read(String path) => File(path).readAsStringSync().replaceAll('\r\n', '\n');

  final flows = read('maestro/gating_flows.txt')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();

  test('게이팅 목록의 flow 파일이 모두 있고 중복이 없다', () {
    expect(flows, isNotEmpty);
    expect(flows.toSet().length, flows.length);
    for (final flow in flows) {
      expect(File(flow).existsSync(), isTrue, reason: '$flow 파일이 없다');
    }
  });

  test('로컬 러너와 CI가 같은 목록 파일을 읽는다', () {
    expect(read('run_maestro_tests.ps1'), contains('maestro/gating_flows.txt'));
    expect(read('scripts/maestro_gating.sh'), contains('maestro/gating_flows.txt'));
    final workflow = read('.github/workflows/maestro.yml');
    expect(workflow, contains('bash scripts/maestro_gating.sh'));
    // 목록을 워크플로에 다시 적지 않는다(스크린샷 촬영 flow만 예외).
    final listed = RegExp(r'maestro/\w+\.yaml').allMatches(workflow).map((m) => m.group(0)).toSet();
    expect(listed, {'maestro/screenshot_tour_flow.yaml'});
  });
}
