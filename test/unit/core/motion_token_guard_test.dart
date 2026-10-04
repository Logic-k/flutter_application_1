import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 화면 코드가 모션 길이를 숫자로 직접 쓰지 못하게 막는다(08 계획 G-00).
///
/// DESIGN.md §4 는 "4단만 쓴다"고 정했지만 코드 감사(2026-09-25)에서 화면 코드의
/// `Duration(milliseconds:)` 직접 사용이 9곳 나왔다(300·200·700·800ms). 값이
/// 토큰과 같아도 숫자로 쓰면 토큰을 바꿀 때 따라오지 않는다.
/// 모든 길이는 `lib/core/motion/app_motion.dart` 의 `AppMotion.*` 를 쓴다.
Directory _repositoryRoot() {
  var directory = Directory.current.absolute;
  while (!File(
    '${directory.path}${Platform.pathSeparator}pubspec.yaml',
  ).existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Flutter repository root could not be found.');
    }
    directory = parent;
  }
  return directory;
}

/// 모션이 아닌 시간 값만 허용한다.
/// - `core/motion/` — 토큰 정의 자체.
/// - `gait_sensing_service.dart` — 가속도계 샘플링 주기(100Hz).
/// - `local_fallback_provider.dart` — AI 폴백 응답 지연.
const _exemptPaths = <String>[
  'core/motion/',
  'gait_sensing_service.dart',
  'local_fallback_provider.dart',
];

void main() {
  test('화면 코드는 Duration(milliseconds:) 를 직접 쓰지 않는다', () {
    final root = _repositoryRoot();
    final libDir = Directory('${root.path}${Platform.pathSeparator}lib');
    final pattern = RegExp(r'Duration\(\s*milliseconds\s*:');

    final violations = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relative = entity.path
          .substring(root.path.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      if (_exemptPaths.any(relative.contains)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          violations.add('$relative:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '모션 길이는 AppMotion 토큰(press 100 · fade 150 · enter 200 · route 300)을 '
          '쓴다. 새 값이 필요하면 DESIGN.md §4 를 먼저 고쳐라.\n${violations.join('\n')}',
    );
  });
}
