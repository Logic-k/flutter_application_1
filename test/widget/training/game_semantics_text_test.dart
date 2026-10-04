import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/services/voice_service.dart';
import 'package:flutter_application_1/features/training/games/comparison_game.dart';
import 'package:flutter_application_1/features/training/games/multiplication_game.dart';
import 'package:flutter_application_1/features/training/games/sequence_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

/// 화면에 보이는 글자가 접근성 트리에도 **그 글자 그대로** 남아 있는지 지킨다.
///
/// 접근성 작업 중 두 가지 방식으로 이 계약이 깨졌다.
///   1. `excludeSemantics: true` — 자식 시맨틱스를 통째로 지운다.
///   2. `Semantics(label: ...)` 만 주기 — 자식이 부모 노드로 **병합**되어
///      노드 텍스트가 "긴 라벨 + 원래 글자"가 된다.
///
/// 둘 다 스크린리더 사용자에게서 화면 정보를 빼앗고, 접근성 트리로 요소를 찾는
/// Maestro E2E도 깨뜨린다. 실제로 게이팅 20개 중 3개가 이 이유로 실패했다.
/// `flutter test`가 먼저 잡아야 할 종류라 여기에 가드를 둔다.
void main() {
  setUpAll(() => VoiceService.voiceEnabled = false);

  // 핸들은 테스트 본문 안에서 해제해야 한다. addTearDown은 프레임워크의
  // 종료 검증보다 늦게 돌아 "SemanticsHandle was active"로 실패한다.
  Future<SemanticsHandle> pumpGame(WidgetTester tester, Widget game) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    await pumpWithProviders(tester, game);
    await tester.pump();
    return handle;
  }

  testWidgets('크기 비교: 가운데 VS가 제 이름의 시맨틱 노드로 남는다', (tester) async {
    final handle = await pumpGame(tester, const ComparisonGame());

    // 문항 라이브 리전 label에 흡수되면 이 finder가 비어 버린다.
    expect(
      find.bySemanticsLabel('VS'),
      findsOneWidget,
      reason: 'VS가 문항 label로 병합됐다 — explicitChildNodes를 확인하라',
    );
    handle.dispose();
  });

  testWidgets('구구단: 보기 숫자가 화면과 트리에 모두 있다', (tester) async {
    final handle = await pumpGame(tester, const MultiplicationGame());

    // 보기 버튼은 '1번 보기, 12' 같은 label을 갖되, 숫자 자체도 남아야 한다.
    final answer = find.byKey(const Key('multiplication-answer-0'));
    expect(answer, findsOneWidget);

    final text = tester.widget<Text>(
      find.descendant(of: answer, matching: find.byType(Text)).first,
    );
    expect(text.data, isNotNull);
    expect(find.text(text.data!), findsWidgets);
    handle.dispose();
  });

  testWidgets('순서 기억: 보기 숫자가 화면과 트리에 모두 있다', (tester) async {
    final handle = await pumpGame(tester, const SequenceGame());

    final answer = find.byKey(const Key('sequence-answer-0'));
    expect(answer, findsOneWidget);

    final text = tester.widget<Text>(
      find.descendant(of: answer, matching: find.byType(Text)).first,
    );
    expect(text.data, isNotNull);
    expect(find.text(text.data!), findsWidgets);
    handle.dispose();
  });
}
