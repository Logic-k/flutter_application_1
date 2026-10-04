import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/design_system/components/async_panel.dart';
import 'package:flutter_application_1/core/design_system/components/card.dart';
import 'package:flutter_application_1/core/design_system/components/form_section.dart';
import 'package:flutter_application_1/core/design_system/components/primary_action.dart';
import 'package:flutter_application_1/core/design_system/components/screen_frame.dart';
import 'package:flutter_application_1/core/design_system/components/status_banner.dart';
import 'package:flutter_application_1/core/design_system/foundations/elevation.dart';
import 'package:flutter_application_1/core/design_system/foundations/spacing.dart';
import 'package:flutter_application_1/core/design_system/patterns/metric_summary.dart';
import 'package:flutter_application_1/core/motion/app_motion.dart';
import 'package:flutter_application_1/core/motion/pressable_scale.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/core/theme.dart';
import '../../helpers/mock_definitions.dart';

// DS-005 공용 컴포넌트 (핸드오프 §6·§10 G3). 아직 어느 화면에도 연결하지 않았다.
//
// 컴포넌트마다 상태 × 모션 3단 × 접근성을 본다. 움직이는 것은 MLAsyncPanel의 상태 전환과
// 새로 고침 표시뿐이고 나머지는 정지 위젯이라, 3단에서 같은 정보를 그리는지만 확인한다.

class _FadeOnlySettings extends FakeSettingsProvider {
  @override
  bool get reduceMotion => true;
}

enum _Level { full, fadeOnly, none }

Widget _host(Widget child, {_Level level = _Level.full, EdgeInsets padding = const EdgeInsets.all(16)}) {
  Widget tree = MaterialApp(
    theme: AppTheme.lightTheme,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: level == _Level.none),
        child: Scaffold(body: Padding(padding: padding, child: child)),
      ),
    ),
  );
  if (level == _Level.fadeOnly) {
    tree = ChangeNotifierProvider<SettingsProvider>.value(value: _FadeOnlySettings(), child: tree);
  }
  return tree;
}

/// 고령 사용자 기준 터치 타깃 56dp(AppTheme.minTapTarget). Android 기본 48dp보다 엄격하다.
const _tapTarget56 = MinimumTapTargetGuideline(
  size: Size(AppTheme.minTapTarget, AppTheme.minTapTarget),
  link: 'lib/core/theme.dart AppTheme.minTapTarget',
);

Future<void> _meetsA11y(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(_tapTarget56));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

const _loading = '걸음 기록을 불러오는 중';
const _empty = '아직 오늘 기록이 없어요';
const _error = '걸음 기록을 불러오지 못했어요.';
const _content = '오늘 3,500걸음';

MLAsyncPanel _panel(
  MLAsyncStatus status, {
  bool refreshing = false,
  VoidCallback? onRetry,
  VoidCallback? onEmptyAction,
  VoidCallback? onFallback,
}) => MLAsyncPanel(
  status: status,
  loadingLabel: _loading,
  emptyMessage: _empty,
  emptyActionLabel: '걷기 시작하기',
  onEmptyAction: onEmptyAction ?? () {},
  errorMessage: _error,
  onRetry: onRetry ?? () {},
  fallbackLabel: '나중에 보기',
  onFallback: onFallback ?? () {},
  refreshing: refreshing,
  child: const Text(_content),
);

void main() {
  group('MLAsyncPanel', () {
    testWidgets('네 상태는 각자 자기 내용만 그리고 error는 empty 문구로 위장하지 않는다', (tester) async {
      final expected = {
        MLAsyncStatus.loading: [_loading],
        MLAsyncStatus.empty: [_empty, '걷기 시작하기'],
        MLAsyncStatus.error: [_error, '다시 시도', '나중에 보기'],
        MLAsyncStatus.content: [_content],
      };
      final all = expected.values.expand((e) => e).toSet();
      for (final MapEntry(key: status, value: shown) in expected.entries) {
        await tester.pumpWidget(_host(_panel(status)));
        await tester.pumpAndSettle();
        for (final text in all) {
          expect(find.text(text), shown.contains(text) ? findsOneWidget : findsNothing,
              reason: '$status: $text');
        }
      }
    });

    testWidgets('상태 문구는 liveRegion으로 알리고 스켈레톤 블록은 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_panel(MLAsyncStatus.loading)));
      expect(tester.getSemantics(find.text(_loading)), isSemantics(isLiveRegion: true));
      expect(
        find.ancestor(of: find.byKey(const Key('ml-async-loading')).first, matching: find.byType(ExcludeSemantics)),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byKey(const Key('ml-async-loading')), matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );

      for (final (status, message) in [(MLAsyncStatus.empty, _empty), (MLAsyncStatus.error, _error)]) {
        await tester.pumpWidget(_host(_panel(status)));
        await tester.pumpAndSettle();
        expect(tester.getSemantics(find.text(message)), isSemantics(isLiveRegion: true), reason: '$status');
      }
      handle.dispose();
    });

    testWidgets('버튼은 받은 콜백만 부른다 — 불러오기 로직은 화면이 갖는다', (tester) async {
      var retry = 0, emptyAction = 0, fallback = 0;
      await tester.pumpWidget(_host(_panel(MLAsyncStatus.error,
          onRetry: () => retry++, onFallback: () => fallback++)));
      await tester.tap(find.text('다시 시도'));
      await tester.tap(find.text('나중에 보기'));
      await tester.pumpWidget(_host(_panel(MLAsyncStatus.empty, onEmptyAction: () => emptyAction++)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('걷기 시작하기'));
      expect((retry, fallback, emptyAction), (1, 1, 1));
    });

    testWidgets('새로 고침 중에도 content 위치는 그대로이고 작은 표시를 한 번 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_panel(MLAsyncStatus.content)));
      await tester.pumpAndSettle();
      final before = tester.getRect(find.text(_content));
      expect(find.text('새로 고치는 중'), findsNothing);

      await tester.pumpWidget(_host(_panel(MLAsyncStatus.content, refreshing: true)));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text(_content)), before);
      expect(find.text(_content), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('ml-async-refreshing'))),
        isSemantics(isLiveRegion: true, label: '새로 고치는 중'),
      );
      handle.dispose();
    });

    for (final level in _Level.values) {
      testWidgets('상태 전환 모션 [${level.name}] — none은 즉시, 나머지는 150ms 페이드, 끝나면 같은 정보',
          (tester) async {
        await tester.pumpWidget(_host(_panel(MLAsyncStatus.loading), level: level));
        await tester.pumpAndSettle();
        await tester.pumpWidget(_host(_panel(MLAsyncStatus.content), level: level));
        await tester.pump();
        expect(find.text(_loading), level == _Level.none ? findsNothing : findsOneWidget,
            reason: '전환 첫 프레임');

        await tester.pump(AppMotion.fade);
        await tester.pumpAndSettle();
        expect(find.text(_loading), findsNothing);
        expect(find.text(_content), findsOneWidget);
      });
    }

    for (final level in _Level.values) {
      testWidgets('새로 고침 표시 모션 [${level.name}] — none은 즉시, 나머지는 페이드로 나타난다', (tester) async {
        await tester.pumpWidget(_host(_panel(MLAsyncStatus.content), level: level));
        await tester.pumpAndSettle();
        await tester.pumpWidget(_host(_panel(MLAsyncStatus.content, refreshing: true), level: level));
        final fade = find.ancestor(
          of: find.byKey(const Key('ml-async-refreshing')), matching: find.byType(FadeTransition),
        ).first;
        expect(tester.widget<FadeTransition>(fade).opacity.value, level == _Level.none ? 1.0 : 0.0);

        await tester.pumpAndSettle();
        expect(tester.widget<FadeTransition>(fade).opacity.value, 1.0);
        expect(find.text('새로 고치는 중'), findsOneWidget);
      });
    }

    test('error 상태는 다시 시도나 대안 없이 만들 수 없다', () {
      expect(
        () => MLAsyncPanel(
          status: MLAsyncStatus.error, loadingLabel: _loading, emptyMessage: _empty, child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('빈 상태·오류 상태의 버튼은 56dp·라벨·대비 기준을 지킨다', (tester) async {
      final handle = tester.ensureSemantics();
      for (final status in [MLAsyncStatus.empty, MLAsyncStatus.error]) {
        await tester.pumpWidget(_host(_panel(status)));
        await tester.pumpAndSettle();
        await _meetsA11y(tester);
        for (final button in tester.widgetList<ButtonStyleButton>(find.byWidgetPredicate((w) => w is ButtonStyleButton))) {
          expect(tester.getSize(find.byWidget(button)).height, greaterThanOrEqualTo(AppTheme.minTapTarget));
        }
      }
      handle.dispose();
    });
  });

  group('MLStatusBanner', () {
    testWidgets('tone마다 아이콘·라벨 글자·문구를 그리고 글자는 면 색이 아닌 글자 전용 색이다', (tester) async {
      final handle = tester.ensureSemantics();
      for (final tone in MLStatusTone.values) {
        await tester.pumpWidget(_host(MLStatusBanner(
          tone: tone, message: '오늘 기록을 저장했어요.', actionLabel: '자세히 보기', onAction: () {},
        )));
        final label = MLStatusBanner.defaultLabelOf(tone);
        expect(find.text(label), findsOneWidget, reason: '$tone');
        expect(find.byType(Icon), findsOneWidget, reason: '$tone');
        final ink = tester.widget<Text>(find.text(label)).style!.color;
        expect(ink, MLStatusBanner.inkOf(tone));
        expect(ink, isNot(anyOf(MLColors.good, MLColors.warn, MLColors.bad)), reason: '신호등 면 색을 글자에 썼다');
        await _meetsA11y(tester);
      }
      handle.dispose();
    });

    testWidgets('announce면 나타날 때 한 번 읽히고, 아니면 읽기를 끼어들지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const MLStatusBanner(tone: MLStatusTone.danger, message: '저장하지 못했어요.', announce: true)));
      expect(tester.getSemantics(find.text('저장하지 못했어요.')), isSemantics(isLiveRegion: true));
      await tester.pumpWidget(_host(const MLStatusBanner(tone: MLStatusTone.info, message: '매일 저녁 알림이 와요.')));
      expect(tester.getSemantics(find.text('매일 저녁 알림이 와요.')), isSemantics(isLiveRegion: false));
      handle.dispose();
    });
  });

  group('MLMetricSummary', () {
    testWidgets('값 없음(null)은 "측정되지 않음", 0은 실제 0으로 구분한다', (tester) async {
      await tester.pumpWidget(_host(const MLMetricSummary(label: '걸음 수', value: null, unit: '걸음')));
      expect(find.text('측정되지 않음'), findsOneWidget);
      expect(find.byKey(const Key('ml-metric-value')), findsNothing);

      await tester.pumpWidget(_host(const MLMetricSummary(label: '걸음 수', value: '0', unit: '걸음')));
      expect(find.text('측정되지 않음'), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('ml-metric-value'))).data, '0');
    });

    testWidgets('스크린리더는 라벨·값·단위·해석·출처를 한 문장으로, 숫자는 tabular figures', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const MLMetricSummary(
        label: '걸음 수', value: '3,500', unit: '걸음',
        interpretation: '평소보다 조금 적어요', source: '오늘 14:05 · 걸음 센서',
      )));
      expect(
        tester.getSemantics(find.byType(MLMetricSummary)),
        isSemantics(label: '걸음 수 3,500걸음, 평소보다 조금 적어요, 오늘 14:05 · 걸음 센서'),
      );
      final style = tester.widget<Text>(find.byKey(const Key('ml-metric-value'))).style!;
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      handle.dispose();
    });
  });

  group('MLRoleCard', () {
    Finder surfaceOf(MLCardRole role) => find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).borderRadius == BorderRadius.circular(MLRoleCard.radiusOf(role)));

    testWidgets('hero만 gradient·hero 그림자, interactive만 raised, 나머지는 그림자 없이 역할별 반경', (tester) async {
      for (final role in MLCardRole.values) {
        await tester.pumpWidget(_host(MLRoleCard(
          role: role,
          onTap: role == MLCardRole.interactive ? () {} : null,
          child: const Text('내용'),
        )));
        final decoration = tester.widget<Container>(surfaceOf(role)).decoration as BoxDecoration;
        final primary = Theme.of(tester.element(find.byType(MLRoleCard))).colorScheme.primary;
        switch (role) {
          case MLCardRole.hero:
            expect(decoration.gradient, MLColors.grad);
            expect(decoration.boxShadow, AppElevation.hero(primary));
          case MLCardRole.interactive:
            expect(decoration.boxShadow, AppElevation.raised);
          case MLCardRole.standard || MLCardRole.data || MLCardRole.support:
            expect(decoration.boxShadow, isNull, reason: '$role');
        }
      }
      expect(
        MLCardRole.values.map(MLRoleCard.radiusOf).toSet(),
        hasLength(4),
        reason: '26 반경 하나로 모든 카드를 그리지 않는다',
      );
    });

    testWidgets('interactive는 카드 전체가 버튼 하나로 읽히고 눌림 피드백을 가진다', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(_host(MLRoleCard(
        role: MLCardRole.interactive,
        semanticLabel: '오늘의 훈련 시작',
        onTap: () => taps++,
        child: const Text('누가 큰가요?'),
      )));
      expect(find.byType(PressableScale), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('오늘의 훈련 시작'))),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await tester.tap(find.byType(MLRoleCard));
      expect(taps, 1);
      await _meetsA11y(tester);
      handle.dispose();
    });

    test('interactive에는 onTap이 필요하고, onTap은 interactive에만 준다', () {
      expect(() => MLRoleCard(role: MLCardRole.interactive, child: const SizedBox()), throwsAssertionError);
      expect(() => MLRoleCard(role: MLCardRole.standard, onTap: () {}, child: const SizedBox()),
          throwsAssertionError);
    });
  });

  group('MLPrimaryAction', () {
    testWidgets('높이 56dp 이상·전체 폭이고 누르면 한 번 부른다', (tester) async {
      final handle = tester.ensureSemantics();
      var pressed = 0;
      await tester.pumpWidget(_host(MLPrimaryAction(label: '저장하기', onPressed: () => pressed++)));
      final size = tester.getSize(find.byKey(const Key('ml-primary-action')));
      expect(size.height, greaterThanOrEqualTo(AppTheme.minTapTarget));
      expect(size.width, tester.getSize(find.byType(MLPrimaryAction)).width);
      await tester.tap(find.text('저장하기'));
      expect(pressed, 1);
      await _meetsA11y(tester);
      handle.dispose();
    });

    testWidgets('제출 중이면 누를 수 없고 진행 문구를 버튼 이름으로 한 번 알린다', (tester) async {
      final handle = tester.ensureSemantics();
      var pressed = 0;
      await tester.pumpWidget(_host(MLPrimaryAction(
        label: '저장하기', busy: true, busyLabel: '저장하는 중이에요', onPressed: () => pressed++,
      )));
      expect(find.text('저장하기'), findsNothing);
      expect(find.text('저장하는 중이에요'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('ml-primary-action'))),
        isSemantics(isLiveRegion: true, isEnabled: false, label: '저장하는 중이에요'),
      );
      await tester.tap(find.byKey(const Key('ml-primary-action')), warnIfMissed: false);
      expect(pressed, 0);
      // 진행 문구는 흐린 비활성 회색이 아니라 읽히는 글자색으로 그린다.
      final style = tester.widget<FilledButton>(find.byKey(const Key('ml-primary-action'))).style!;
      expect(style.backgroundColor!.resolve({WidgetState.disabled}), MLColors.primarySoft);
      expect(style.foregroundColor!.resolve({WidgetState.disabled}), MLColors.primaryDeep);
      handle.dispose();
    });

    testWidgets('누를 수 없을 때는 이유를 글자로 보여 주고 버튼 hint로도 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      const reason = '필수 동의 2개를 선택하면 다음으로 갈 수 있어요';
      await tester.pumpWidget(_host(const MLPrimaryAction(label: '다음', onPressed: null, disabledReason: reason)));
      expect(find.text(reason), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('ml-primary-action'))),
        isSemantics(label: '다음', hint: reason, isEnabled: false),
      );
      handle.dispose();
      await tester.pumpWidget(_host(MLPrimaryAction(label: '다음', onPressed: () {}, disabledReason: reason)));
      expect(find.text(reason), findsNothing);
    });
  });

  group('MLFormSection', () {
    testWidgets('제목은 header로 읽히고 필수·선택은 글자로 표시한다', (tester) async {
      final handle = tester.ensureSemantics();
      for (final (requirement, tag) in [
        (MLFieldRequirement.required, '필수'),
        (MLFieldRequirement.optional, '선택'),
        (null, null),
      ]) {
        await tester.pumpWidget(_host(MLFormSection(
          title: '기본 정보', description: '나이와 목표를 알려 주세요.', requirement: requirement,
          children: const [SizedBox(height: 20)],
        )));
        expect(tester.getSemantics(find.text('기본 정보')), isSemantics(isHeader: true));
        expect(find.text('필수'), tag == '필수' ? findsOneWidget : findsNothing);
        expect(find.text('선택'), tag == '선택' ? findsOneWidget : findsNothing);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      handle.dispose();
    });

    testWidgets('필드 사이는 itemGap, 설명은 제목 아래', (tester) async {
      await tester.pumpWidget(_host(const MLFormSection(
        title: '기본 정보', description: '설명',
        children: [SizedBox(key: Key('a'), height: 20), SizedBox(key: Key('b'), height: 20)],
      )));
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dy - tester.getBottomLeft(find.byKey(const Key('a'))).dy,
          AppSpacing.itemGap);
      expect(tester.getTopLeft(find.text('설명')).dy, greaterThan(tester.getTopLeft(find.text('기본 정보')).dy));
    });
  });

  group('MLScreenFrame', () {
    Future<EdgeInsetsGeometry?> paddingOf(WidgetTester tester, MLScreenFrame frame) async {
      await tester.pumpWidget(_host(frame, padding: EdgeInsets.zero));
      return tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).padding;
    }

    testWidgets('탭 화면은 떠 있는 네비만큼 하단 여백, 폼은 좌우 24, 일반은 22', (tester) async {
      expect(
        await paddingOf(tester, const MLScreenFrame(isTab: true, children: [Text('x')])),
        const EdgeInsets.fromLTRB(22, AppSpacing.screenTop, 22, AppSpacing.bottomSafeContent),
      );
      expect(
        await paddingOf(tester, const MLScreenFrame(form: true, children: [Text('x')])),
        const EdgeInsets.fromLTRB(24, AppSpacing.screenTop, 24, AppSpacing.sectionGap),
      );
    });

    for (final (width, expected) in [(360.0, 316.0), (839.0, 720.0), (1600.0, 1200.0)]) {
      testWidgets('본문 최대 폭 — ${width.toInt()}dp 창에서 ${expected.toInt()}', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_host(const MLScreenFrame(children: [Text('본문')]), padding: EdgeInsets.zero));
        expect(tester.getSize(find.byKey(const Key('ml-screen-frame-content'))).width, expected);
      });
    }

    testWidgets('제목은 header로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const MLScreenFrame(title: '주간 분석 리포트', subtitle: '지난 7일', children: [])));
      expect(tester.getSemantics(find.text('주간 분석 리포트')), isSemantics(isHeader: true));
      handle.dispose();
    });
  });

  testWidgets('정지 컴포넌트는 모션 3단에서 같은 정보를 그린다', (tester) async {
    final sample = SingleChildScrollView(child: Column(children: [
      const MLStatusBanner(tone: MLStatusTone.warning, message: '오늘 기록이 아직 없어요.'),
      const MLMetricSummary(label: '걸음 수', value: '3,500', unit: '걸음', interpretation: '평소보다 적어요'),
      MLRoleCard(role: MLCardRole.interactive, onTap: () {}, child: const Text('훈련 시작')),
      const MLFormSection(title: '기본 정보', requirement: MLFieldRequirement.required, children: [Text('나이')]),
      const MLPrimaryAction(label: '다음', onPressed: null, disabledReason: '나이를 입력해 주세요'),
    ]));
    List<String?> texts() => tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();

    await tester.pumpWidget(_host(sample));
    final full = texts();
    for (final level in [_Level.fadeOnly, _Level.none]) {
      await tester.pumpWidget(_host(sample, level: level));
      await tester.pumpAndSettle();
      expect(texts(), full, reason: level.name);
    }
  });
}
