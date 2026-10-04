import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/voice_service.dart';
import 'package:flutter_application_1/features/training/games/categorization_game.dart';
import 'package:flutter_application_1/features/training/games/comparison_game.dart';
import 'package:flutter_application_1/features/training/games/multiplication_game.dart';
import 'package:flutter_application_1/features/training/games/sequence_game.dart';
import 'package:flutter_application_1/features/training/games/shape_match_game.dart';
import 'package:flutter_application_1/features/training/games/shape_sudoku_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

/// 인지훈련 게임은 이 앱의 핵심 기능이다. 여기서 접근성이 무너지면
/// 스크린리더 사용자는 앱의 존재 이유를 쓰지 못한다.
const _games = <String, Widget>{
  '그림 스도쿠': ShapeSudokuGame(),
  '같은 모양 찾기': ShapeMatchGame(),
  '분류하기': CategorizationGame(),
  '크기 비교': ComparisonGame(),
  '구구단': MultiplicationGame(),
  '순서 기억': SequenceGame(),
};

/// flutter_test 기본 화면(800x600)은 실제 휴대폰보다 세로가 짧아
/// 실기기에서는 나지 않는 오버플로가 난다. 보고된 기기 크기로 맞춘다.
const _deviceSize = Size(360, 800);

Future<void> _pumpGame(WidgetTester tester, Widget game) async {
  await tester.binding.setSurfaceSize(_deviceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpWithProviders(tester, game);
  await tester.pump();
}

void main() {
  setUpAll(() => VoiceService.voiceEnabled = false);

  group('탭 가능한 요소는 스크린리더가 읽을 이름을 갖는다', () {
    // Flutter 공식 LabeledTapTargetGuideline.
    // 아이콘만 있는 보기는 label이 없으면 TalkBack이 "버튼"이라고만 읽는다.
    for (final game in _games.entries) {
      testWidgets(game.key, (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpGame(tester, game.value);

        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('탭 영역이 최소 크기를 지킨다', () {
    // Flutter 공식 androidTapTargetGuideline (48x48dp).
    // 고령 사용자는 진전·관절 가동범위 저하로 작은 타겟을 놓친다.
    for (final game in _games.entries) {
      testWidgets(game.key, (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpGame(tester, game.value);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  // 텍스트 대비는 여기서 검사하지 않는다.
  //
  // Flutter의 textContrastGuideline은 렌더된 픽셀을 샘플링하는데, 이 앱의 AppBar가
  // backgroundColor: Colors.transparent 라서 제목 글자 영역에서 전경·배경을 같은
  // 색으로 읽어 대비 1.00:1이라는 값을 낸다. 실기기 스크린샷에서 제목은 또렷하게
  // 보이므로 오탐이다.
  //
  // 색 대비는 대신 test/unit/core/theme_contrast_test.dart 가 지킨다. 그쪽은
  // 팔레트 조합의 대비비를 WCAG 공식으로 직접 계산하므로 렌더링 방식에 영향받지
  // 않고, 색 상수가 되돌아가는 순간 실패한다.
}
