import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/voice_service.dart';
import 'package:flutter_application_1/features/training/games/categorization_game.dart';
import 'package:flutter_application_1/features/training/games/comparison_game.dart';
import 'package:flutter_application_1/features/training/games/multiplication_game.dart';
import 'package:flutter_application_1/features/training/games/sentence_reading_game.dart';
import 'package:flutter_application_1/features/training/games/sequence_game.dart';
import 'package:flutter_application_1/features/training/games/shape_match_game.dart';
import 'package:flutter_application_1/features/training/games/shape_sudoku_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

/// 훈련 게임 전체. 한 화면이라도 잘리면 해당 문항을 풀 수 없다.
const _games = <String, Widget>{
  '그림 스도쿠': ShapeSudokuGame(),
  '같은 모양 찾기': ShapeMatchGame(),
  '분류하기': CategorizationGame(),
  '크기 비교': ComparisonGame(),
  '구구단': MultiplicationGame(),
  '문장 읽기': SentenceReadingGame(),
  '순서 기억': SequenceGame(),
};

/// 실기기에서 하단이 잘리던 회귀를 막는다.
/// 기존 게임 테스트는 500x1200이라는 넉넉한 화면을 써서 오버플로를 놓쳤다.
/// 아래 크기는 실제 보고된 기기(1080x2400 @3x = 360x800dp)와
/// 릴리스 체크리스트가 요구하는 최소 폭 320dp 조건이다.
const _deviceSizes = <String, Size>{
  '360x800dp (보고된 기기)': Size(360, 800),
  '320x640dp (최소 지원)': Size(320, 640),
};

void main() {
  setUpAll(() => VoiceService.voiceEnabled = false);

  for (final size in _deviceSizes.entries) {
    group(size.key, () {
      for (final game in _games.entries) {
        testWidgets('${game.key}은(는) 오버플로 없이 그려진다', (tester) async {
          await _pumpAt(tester, game.value, size.value);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('그림 스도쿠의 보기 안내가 화면 안에 있다', (tester) async {
        await _pumpAt(tester, const ShapeSudokuGame(), size.value);
        _expectWithinViewport(tester, find.text('알맞은 그림을 선택하세요'), size.value);
      });

      testWidgets('같은 모양 찾기의 마지막 보기 타일이 화면 안에 있다', (tester) async {
        await _pumpAt(tester, const ShapeMatchGame(), size.value);
        // 화면 밖이면 탭이 불가능해 문항을 풀 수 없다.
        _expectWithinViewport(
          tester,
          find.byKey(const Key('shape-match-answer-3')),
          size.value,
        );
      });
    });
  }
}

Future<void> _pumpAt(WidgetTester tester, Widget game, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpWithProviders(tester, game);
  await tester.pump();
}

void _expectWithinViewport(WidgetTester tester, Finder finder, Size size) {
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  expect(
    rect.bottom,
    lessThanOrEqualTo(size.height),
    reason: '$finder 이(가) 화면 아래로 잘렸다',
  );
}
