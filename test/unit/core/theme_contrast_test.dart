import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_application_1/core/theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.2 상대 휘도.
/// https://www.w3.org/TR/WCAG22/#dfn-relative-luminance
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

/// WCAG 2.2 대비비. 1.0(동일) ~ 21.0(흑백).
/// https://www.w3.org/TR/WCAG22/#dfn-contrast-ratio
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// 앱이 실제로 쓰는 배경 두 가지. 어느 쪽에 얹혀도 읽혀야 한다.
const _backgrounds = <String, Color>{
  '흰 카드': MLColors.surface,
  '스캐폴드 배경': MLColors.bg,
  '보조 카드': MLColors.surfaceAlt,
};

/// WCAG 1.4.3 — 본문 텍스트 최소 대비.
const double _aaText = 4.5;

/// WCAG 1.4.11 — UI 컴포넌트·경계선 최소 대비.
const double _aaNonText = 3.0;

void main() {
  group('본문 텍스트 대비 (WCAG 1.4.3, 4.5:1)', () {
    const textTokens = <String, Color>{
      'text': MLColors.text,
      'textSoft': MLColors.textSoft,
    };

    for (final token in textTokens.entries) {
      for (final bg in _backgrounds.entries) {
        test('${token.key} on ${bg.key}', () {
          final ratio = contrastRatio(token.value, bg.value);
          expect(
            ratio,
            greaterThanOrEqualTo(_aaText),
            reason: '${token.key}(${_hex(token.value)}) on '
                '${bg.key}(${_hex(bg.value)}) = ${ratio.toStringAsFixed(2)}:1 '
                '— 저시력 고령 사용자가 읽지 못한다',
          );
        });
      }
    }
  });

  group('상태 문구 색 대비 (WCAG 1.4.3, 4.5:1)', () {
    // 신호등 원색(good/warn/bad)은 면 전용이므로 여기서 검사하지 않는다.
    // 글자로 쓰는 변형만 검사한다.
    const statusTextTokens = <String, Color>{
      'goodText': MLColors.goodText,
      'warnText': MLColors.warnText,
      'badText': MLColors.badText,
    };

    for (final token in statusTextTokens.entries) {
      test('${token.key} on 흰 카드', () {
        final ratio = contrastRatio(token.value, MLColors.surface);
        expect(
          ratio,
          greaterThanOrEqualTo(_aaText),
          reason: '${token.key}(${_hex(token.value)}) = '
              '${ratio.toStringAsFixed(2)}:1',
        );
      });
    }
  });

  group('조작 영역 경계선 대비 (WCAG 1.4.11, 3:1)', () {
    for (final bg in _backgrounds.entries) {
      test('lineStrong on ${bg.key}', () {
        final ratio = contrastRatio(MLColors.lineStrong, bg.value);
        expect(
          ratio,
          greaterThanOrEqualTo(_aaNonText),
          reason: 'lineStrong = ${ratio.toStringAsFixed(2)}:1 — '
              '입력 필드와 선택지 버튼의 경계가 보이지 않는다',
        );
      });
    }

    test('장식용 line은 대비 요건 대상이 아니다', () {
      // 의도를 코드로 못박아 둔다. line을 조작 영역 경계로 승격하면
      // 이 테스트가 아니라 위의 lineStrong 테스트를 봐야 한다.
      final ratio = contrastRatio(MLColors.line, MLColors.surface);
      expect(ratio, lessThan(_aaNonText),
          reason: 'line이 3:1을 넘었다면 lineStrong과 역할이 겹친다');
    });
  });

  group('강조색 위 흰 글자', () {
    test('primary 위 흰 글자는 AA 큰 글자(3:1)를 넘는다', () {
      final ratio =
          contrastRatio(const Color(0xFFFFFFFF), MLColors.primary);
      expect(ratio, greaterThanOrEqualTo(_aaNonText));
    });
  });

  group('연보라 면 위 글자', () {
    // 게임 목표 카드·목표 시간 배지·결과 축하 칩. primary 를 얹으면 3.77:1 이었다.
    test('onPrimaryContainer 는 primaryContainer 위에서 4.5:1 을 넘는다', () {
      final scheme = AppTheme.lightTheme.colorScheme;
      final ratio = contrastRatio(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
      );
      expect(ratio, greaterThanOrEqualTo(_aaText),
          reason: '${_hex(scheme.onPrimaryContainer)} on '
              '${_hex(scheme.primaryContainer)} = ${ratio.toStringAsFixed(2)}:1');
    });
  });
}

String _hex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
