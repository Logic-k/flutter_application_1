import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Material 기본 팔레트를 화면 색으로 쓰지 못하게 막는다.
///
/// theme_contrast_test 는 MLColors 토큰의 대비비만 계산한다. 그래서 위젯이
/// 토큰을 놔두고 `Colors.grey` 같은 원색을 직접 쓰면 아무도 못 잡았고,
/// 실제로 그렇게 새어 들어온 값들이 전부 WCAG AA(4.5:1) 미달이었다:
///   grey #9E9E9E 2.85:1 · red #F44336 3.76:1 · green #4CAF50 2.28:1
///   orange #FF9800 2.11:1 · amber #FFC107 1.62:1
/// 고령 사용자가 주 대상인 앱에서 이건 그냥 안 읽히는 글자다.
///
/// 대응 토큰: 보조 텍스트 textSoft · 위험 badText · 양호 goodText · 주의 warnText.
/// 카테고리 강조는 calc/logic/mem/care/read/sky.
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

/// 금지 대상. white·black·transparent 는 밝기 중립이라 허용한다.
const _bannedSwatches = <String>[
  'grey',
  'red',
  'green',
  'orange',
  'amber',
  'blue',
  'purple',
  'teal',
  'pink',
  'indigo',
  'cyan',
  'lime',
  'brown',
  'greenAccent',
  'orangeAccent',
  'redAccent',
  'blueAccent',
];

/// PDF 리포트는 인쇄물이라 화면 팔레트와 무관하게 PdfColors 를 쓴다.
const _exemptFiles = <String>[
  'clinical_report_generator.dart',
];

void main() {
  test('화면 코드는 Material 기본 팔레트를 색으로 쓰지 않는다', () {
    final root = _repositoryRoot();
    final libDir = Directory(
      '${root.path}${Platform.pathSeparator}lib',
    );

    // `MLColors.grey` 나 `PdfColors.grey700` 처럼 접두사가 붙은 것은 제외하고
    // 맨 앞의 `Colors.` 만 잡는다.
    final pattern = RegExp(
      r'(?<![A-Za-z])Colors\.(' + _bannedSwatches.join('|') + r')\b',
    );

    final violations = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final name = entity.path.split(Platform.pathSeparator).last;
      if (_exemptFiles.contains(name)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final match in pattern.allMatches(lines[i])) {
          final relative = entity.path.substring(root.path.length + 1);
          violations.add('$relative:${i + 1}  ${match.group(0)}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Material 기본 팔레트는 전부 WCAG AA 미달이다. MLColors 의 의미 토큰으로 '
          '바꿔라 — 보조 텍스트 textSoft, 상태 goodText/warnText/badText, '
          '카테고리 calc/logic/mem/care/read/sky.\n${violations.join('\n')}',
    );
  });
}
