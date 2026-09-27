import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/motion/app_motion.dart';
import '../../core/motion/motion_play_log.dart';
import '../../core/motion/motion_settings.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';

// ─── 콜드 스타트 오프닝 "기억 속으로" (DESIGN.md §4.1 네 번째 예외) ────────────
//
// 네이티브 스플래시와 같은 자리·크기(110dp, 모서리 26dp)의 로고에서 시작한다.
//   0 ~ 700ms   로고 안으로 들어간다. 접힌 면들이 갈라져 흩어지고 남색 바탕이 화면을 채운다.
//   450 ~ 1500  면이 만나던 한 점에서 점과 선이 뉴런처럼 이어져 두 반구의 뇌 모양이 된다.
//   1050 ~ 1450 워드마크가 떠오른다.
//   1700        로그인 확인이 끝나지 않았으면 여기서 **멈춰** 기다린다(반복 없음).
//   1800 ~ 2400 가운데가 원형으로 열리며 앱이 나온다. 아래 앱의 진입 안무가 이때 재생된다.
// 각 값은 [AppMotion.opening] 안의 시각(ms)이고, 길이 토큰이 아니다.
const double _diveEnd = 700;
const double _facetFadeStart = 300;
const double _facetFadeEnd = 650;
const double _netStart = 450;
const double _netSpread = 550; // 가장 바깥 점이 가운데 점보다 늦게 나타나는 만큼
const double _nodePop = 220;
const double _edgeDraw = 260;
const double _wordStart = 1050;
const double _wordEnd = 1450;
const double _holdAt = 1700;
const double _exitStart = 1800;
const double _exitFade = 300;

const double _logoSize = 110;

/// 앱 실행 직후 한 번 보이는 오프닝. [child](앱 전체) 위를 덮었다가 걷힌다.
///
/// - 로딩과 겹쳐 흐른다. [ready] 가 늦으면 워드마크까지 그린 정지 화면에서 기다리므로
///   예전 로딩 스피너 자리를 대신한다. 준비가 빨라도 전체는 [AppMotion.opening] 이다.
/// - 아무 곳이나 누르면 건너뛴다.
/// - fadeOnly: 로고 정지 화면이 [AppMotion.fade] 로 사라진다. none: 즉시 사라진다.
/// - 덮는 동안 아래 앱의 접근성 트리를 막는다. 가려진 입력 칸을 TalkBack·Maestro 가
///   찾아 누르면 탭이 오프닝에 먹혀 입력이 사라진다.
/// - 덮는 동안 아래 앱의 [TickerMode] 를 끈다. 홈·로그인의 진입 스태거가 가려진 채
///   끝나지 않고, 가운데가 열리는 순간 재생된다.
class MemoryOpening extends StatefulWidget {
  const MemoryOpening({
    super.key,
    required this.start,
    required this.ready,
    required this.child,
  });

  /// 모션 단계를 정할 수 있는가(저장된 앱 설정을 다 읽었는가).
  final bool start;

  /// 아래 앱이 첫 화면을 정했는가(로그인 확인이 끝났는가).
  final bool ready;

  final Widget child;

  /// Maestro·위젯 테스트용 식별자. Android 에서는 resource-id 로 보인다.
  static const String semanticsId = 'memory_opening';

  @override
  State<MemoryOpening> createState() => _MemoryOpeningState();
}

class _MemoryOpeningState extends State<MemoryOpening> {
  bool _covering = true;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // 스플래시 → 로그인 로고 이동은 오프닝이 대신한다.
    MotionPlayLog.markPlayed(LoginScreen.splashPlayKey);
  }

  @override
  Widget build(BuildContext context) {
    Widget? layer;
    if (!_done) {
      layer = _OpeningLayer(
        start: widget.start,
        ready: widget.ready,
        onReveal: () => setState(() => _covering = false),
        onDone: () => setState(() => _done = true),
      );
      // 앱의 MediaQuery 는 아래 MaterialApp 이 만든다. 오프닝은 그 위에 있으므로
      // "애니메이션 제거" 설정을 읽으려면 창에서 직접 가져온다.
      if (MediaQuery.maybeOf(context) == null) {
        layer = MediaQuery.fromView(view: View.of(context), child: layer);
      }
      // 같은 이유로 글자 방향도 없다. 접근성 라벨에 필요하다.
      layer = Directionality(textDirection: TextDirection.ltr, child: layer);
    }
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        TickerMode(enabled: !_covering, child: widget.child),
        // 앞서 그린 형제(= 앱)의 접근성 노드를 지운다. 오프닝 안쪽에 두면 오프닝 자신의
        // 컨테이너 안에서만 막혀 앱은 그대로 읽힌다.
        if (layer != null) BlockSemantics(child: layer),
      ],
    );
  }
}

class _OpeningLayer extends StatefulWidget {
  const _OpeningLayer({
    required this.start,
    required this.ready,
    required this.onReveal,
    required this.onDone,
  });

  final bool start;
  final bool ready;
  final VoidCallback onReveal;
  final VoidCallback onDone;

  @override
  State<_OpeningLayer> createState() => _OpeningLayerState();
}

class _OpeningLayerState extends State<_OpeningLayer>
    with SingleTickerProviderStateMixin {
  static final double _total = AppMotion.opening.inMilliseconds.toDouble();

  /// 한 프레임에 흐르는 시간의 상한(ms). 콜드 스타트 직후엔 초기화(AI 모델 로드 등)가
  /// UI 스레드를 1초 가까이 잡는다. 벽시계를 따르면 그 사이 장면(로고 안으로 들어가기)을
  /// 통째로 건너뛰므로, 긴 프레임에서는 멈췄다가 이어서 흐르게 한다.
  static const double _maxStepMs = 50;

  late final Ticker _ticker;
  final ValueNotifier<double> _clock = ValueNotifier(0); // 0..1
  Duration _lastElapsed = Duration.zero;
  MotionLevel? _level;
  bool _revealed = false;
  bool _finished = false;
  double _opacity = 1;

  double get _ms => _clock.value * _total;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeBegin();
  }

  @override
  void didUpdateWidget(_OpeningLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeBegin();
    if (widget.ready && !oldWidget.ready) _release();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  /// 부모의 setState 는 이 위젯의 build·didUpdateWidget 도중에 부를 수 없어 다음 프레임으로 미룬다.
  void _notify(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  void _maybeBegin() {
    if (_level != null || !widget.start) return;
    _level = MotionSettings.levelOf(context, listen: false);
    if (_level == MotionLevel.full) {
      _run();
    } else if (widget.ready) {
      _release();
    }
  }

  void _run() {
    if (_ticker.isActive || _finished) return;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final step = (elapsed - _lastElapsed).inMicroseconds / 1000;
    _lastElapsed = elapsed;
    _seek(_ms + math.min(step, _maxStepMs));
  }

  /// 시각 [ms] 로 옮긴다. 준비 전이면 정지 지점에서, 끝에 닿으면 끝에서 멈춘다.
  void _seek(double ms) {
    if (!widget.ready && ms >= _holdAt) {
      ms = _holdAt;
      _ticker.stop();
    }
    if (ms >= _total) {
      ms = _total;
      _ticker.stop();
      if (!_finished) {
        _finished = true;
        _notify(widget.onDone);
      }
    }
    _clock.value = ms / _total;
    if (!_revealed && ms >= _exitStart) {
      _revealed = true;
      _notify(widget.onReveal);
    }
  }

  /// 아래 앱이 준비됐다. build 앞에서만 불리므로 setState 없이 값만 바꾼다.
  void _release() {
    switch (_level) {
      case null:
        return; // 단계가 정해지는 순간 _maybeBegin 이 다시 부른다.
      case MotionLevel.full:
        _run(); // 정지 화면에서 기다리던 중이면 이어서 재생한다.
      case MotionLevel.fadeOnly:
        _notify(widget.onReveal);
        _opacity = 0;
      case MotionLevel.none:
        _notify(widget.onReveal);
        _notify(widget.onDone);
    }
  }

  void _skip() {
    if (_level != MotionLevel.full) return;
    if (!widget.ready) {
      // 아직 보여 줄 화면이 없다. 기다리는 정지 화면으로만 건너뛴다.
      if (_ms < _holdAt) _seek(_holdAt);
      return;
    }
    if (_ms < _exitStart) _seek(_exitStart);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final full = _level == MotionLevel.full;
    Widget scene = RepaintBoundary(
      child: CustomPaint(
        painter: _OpeningPainter(_clock),
        size: Size.infinite,
      ),
    );
    if (_level == MotionLevel.fadeOnly) {
      scene = AnimatedOpacity(
        opacity: _opacity,
        duration: AppMotion.fade,
        onEnd: () {
          if (_opacity == 0) _notify(widget.onDone);
        },
        child: scene,
      );
    }
    return Semantics(
      identifier: MemoryOpening.semanticsId,
      container: true,
      label: 'MemoryLink',
      hint: full ? '누르면 건너뜁니다' : null,
      onTap: full ? _skip : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: ExcludeSemantics(child: scene),
      ),
    );
  }
}

// ─── 그리기 ─────────────────────────────────────────────────────────────

/// 로고의 접힌 면 하나. 좌표는 app_icon.png(1024px) 기준이다.
class _Facet {
  _Facet(this.points, this.color) {
    var sum = Offset.zero;
    for (final p in points) {
      sum += p;
    }
    final away = sum / points.length.toDouble() - _crease;
    direction = away / away.distance;
  }

  final List<Offset> points;
  final Color color;

  /// 면이 만나는 점에서 이 면의 무게중심 쪽. 들어갈 때 이 방향으로 흩어진다.
  late final Offset direction;
}

const Offset _logoCenter = Offset(512, 512);
const Offset _crease = Offset(512, 560); // 다섯 면이 만나는 점

final List<_Facet> _facets = [
  _Facet(const [Offset(300, 360), Offset(512, 300), Offset(512, 560)], Colors.white),
  _Facet(const [Offset(512, 300), Offset(724, 360), Offset(512, 560)], MLColors.logoFacetTop),
  _Facet(const [Offset(300, 360), Offset(512, 560), Offset(380, 724), Offset(300, 724)], MLColors.logoFacetSide),
  _Facet(const [Offset(724, 360), Offset(724, 724), Offset(644, 724), Offset(512, 560)], MLColors.logoFacetSide),
  _Facet(const [Offset(512, 560), Offset(644, 724), Offset(512, 634), Offset(380, 724)], MLColors.logoFacetFold),
];

/// 뇌를 위에서 본 두 반구의 점. x·y 는 -1..1(가로·세로 반폭 기준).
/// 위에서 본 뇌는 세로로 길고, 반구는 가운데 틈 쪽이 평평한 D 자 모양이다.
class _Node {
  const _Node(this.x, this.y, this.radius, this.color);

  final double x;
  final double y;
  final double radius;
  final Color color;

  Offset get offset => Offset(x, y);

  /// 가운데에서 멀수록 늦게 나타난다.
  double get appear => _netStart + math.min(1.0, offset.distance) * _netSpread;
}

const List<_Node> _nodes = [
  _Node(0, 0, 5.5, Colors.white), // 면이 만나던 점. 두 반구를 잇는 다리(뇌들보) 자리다.
  // 왼쪽 반구 — 바깥 윤곽
  _Node(-0.12, -0.92, 3.0, Colors.white),
  _Node(-0.48, -0.86, 3.2, MLColors.primarySoft),
  _Node(-0.80, -0.58, 3.6, MLColors.mem),
  _Node(-0.95, -0.18, 3.0, Colors.white),
  _Node(-0.92, 0.26, 3.2, MLColors.primarySoft),
  _Node(-0.74, 0.64, 3.0, Colors.white),
  _Node(-0.44, 0.88, 3.4, MLColors.mem),
  _Node(-0.12, 0.90, 3.0, MLColors.primarySoft),
  // 왼쪽 반구 — 안쪽
  _Node(-0.30, -0.52, 3.0, Colors.white),
  _Node(-0.62, -0.20, 3.0, MLColors.primarySoft),
  _Node(-0.30, 0.02, 3.8, Colors.white),
  _Node(-0.60, 0.34, 3.0, Colors.white),
  _Node(-0.28, 0.52, 3.2, MLColors.primarySoft),
  // 오른쪽 반구 — 거울상이 아니게 조금씩 비튼다.
  _Node(0.13, -0.90, 3.0, MLColors.primarySoft),
  _Node(0.50, -0.84, 3.0, Colors.white),
  _Node(0.82, -0.54, 3.2, MLColors.primarySoft),
  _Node(0.95, -0.14, 3.6, MLColors.mem),
  _Node(0.90, 0.30, 3.0, Colors.white),
  _Node(0.72, 0.66, 3.2, MLColors.primarySoft),
  _Node(0.42, 0.88, 3.0, Colors.white),
  _Node(0.11, 0.91, 3.4, MLColors.mem),
  _Node(0.32, -0.48, 3.2, Colors.white),
  _Node(0.64, -0.16, 3.0, Colors.white),
  _Node(0.28, 0.06, 3.8, MLColors.primarySoft),
  _Node(0.58, 0.38, 3.0, Colors.white),
  _Node(0.30, 0.56, 3.0, MLColors.primarySoft),
];

/// 같은 반구 안에서는 가까운 세 점끼리 잇는다. 두 반구를 잇는 것은 가운데 점뿐이다
/// — 이름 그대로 "기억을 잇는" 점.
final List<(int, int)> _edges = () {
  double gap(int a, int b) => (_nodes[a].offset - _nodes[b].offset).distance;
  final out = <(int, int)>{};
  for (var i = 1; i < _nodes.length; i++) {
    final side = [
      for (var j = 1; j < _nodes.length; j++)
        if (j != i && (_nodes[j].x < 0) == (_nodes[i].x < 0)) j,
    ]..sort((a, b) => gap(i, a).compareTo(gap(i, b)));
    for (final j in side.take(3)) {
      out.add(i < j ? (i, j) : (j, i));
    }
  }
  final near = [for (var j = 1; j < _nodes.length; j++) j]
    ..sort((a, b) => gap(0, a).compareTo(gap(0, b)));
  for (final j in near.take(4)) {
    out.add((0, j));
  }
  return out.toList();
}();

double _seg(double ms, double from, double to) =>
    ((ms - from) / (to - from)).clamp(0.0, 1.0);

class _OpeningPainter extends CustomPainter {
  _OpeningPainter(this.clock) : super(repaint: clock);

  /// 오프닝 안의 진행(0..1).
  final ValueListenable<double> clock;

  static final double _total = AppMotion.opening.inMilliseconds.toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final ms = clock.value * _total;
    final c = size.center(Offset.zero);
    final screen = Offset.zero & size;
    final diag = math.sqrt(size.width * size.width + size.height * size.height);

    // 5. 가운데가 원형으로 열린다 — 이후 모든 그리기에서 구멍을 뺀다.
    final exit = Curves.easeInOutCubic.transform(_seg(ms, _exitStart, _total));
    if (exit > 0) {
      canvas.clipPath(Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(screen)
        ..addOval(Rect.fromCircle(center: c, radius: exit * (diag / 2 + 8))));
    }
    canvas.drawRect(screen, Paint()..color = MLColors.bg);

    // 1. 로고 바탕이 커져 화면을 채운다. 그라데이션도 로고 칸에서 화면 전체로 넓어진다.
    final dive = Curves.easeInCubic.transform(_seg(ms, 0, _diveEnd));
    final logo = Rect.fromCenter(center: c, width: _logoSize, height: _logoSize);
    final side = _logoSize + dive * (diag * 1.05 - _logoSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: side, height: side),
        Radius.circular(AppTheme.rCard * (1 - dive)),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MLColors.logoNavy, MLColors.logoNavyDeep],
        ).createShader(Rect.lerp(logo, screen, dive)!),
    );

    // 2. 접힌 면이 커지며 바깥으로 갈라져 사라진다(카메라가 면 사이로 지나간다).
    final facetAlpha = 1 - _seg(ms, _facetFadeStart, _facetFadeEnd);
    if (facetAlpha > 0) {
      // 면은 바탕과 거의 같이 커진다(카메라가 다가간다). 덜 커지면 작은 화살표처럼 흩어져 보인다.
      final zoom = 1 + (side / _logoSize - 1) * 0.7;
      final unit = _logoSize / 1024 * zoom;
      final spread = dive * size.shortestSide * 0.35;
      for (final f in _facets) {
        final path = Path();
        for (var i = 0; i < f.points.length; i++) {
          final p = c + (f.points[i] - _logoCenter) * unit + f.direction * spread;
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          path..close(),
          Paint()..color = f.color.withValues(alpha: facetAlpha),
        );
      }
    }

    // 3. 점과 선이 가운데에서 바깥으로 이어진다. 열릴 때는 조금 다가오며 흐려진다.
    final netAlpha = 1 - _seg(ms, _exitStart, _exitStart + _exitFade);
    if (ms < _netStart || netAlpha <= 0) return;
    final w = math.min(size.width * 0.62, 250.0);
    final h = w * 1.12;
    final origin = c + Offset(0, -h * 0.16);
    final zoom = 1 + 0.25 * exit;
    Offset at(_Node n) => origin + Offset(n.x * w / 2, n.y * h / 2) * zoom;

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.32 * netAlpha)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final (i, j) in _edges) {
      final a = _nodes[i].appear <= _nodes[j].appear ? _nodes[i] : _nodes[j];
      final b = identical(a, _nodes[i]) ? _nodes[j] : _nodes[i];
      final end = math.max(b.appear, a.appear + _edgeDraw);
      final t = Curves.easeOutCubic.transform(_seg(ms, a.appear, end));
      if (t == 0) continue;
      canvas.drawLine(at(a), Offset.lerp(at(a), at(b), t)!, line);
    }
    for (final n in _nodes) {
      final pop = Curves.easeOutCubic.transform(_seg(ms, n.appear, n.appear + _nodePop));
      if (pop == 0) continue;
      final p = at(n);
      canvas.drawCircle(p, n.radius * 2.6 * pop,
          Paint()..color = n.color.withValues(alpha: 0.16 * netAlpha));
      canvas.drawCircle(p, n.radius * pop,
          Paint()..color = n.color.withValues(alpha: netAlpha));
    }

    // 4. 워드마크.
    final word = Curves.easeOutCubic.transform(_seg(ms, _wordStart, _wordEnd)) * netAlpha;
    if (word <= 0) return;
    var y = origin.dy + h / 2 * zoom + 36 + 8 * (1 - word);
    y += _centeredText(canvas, 'MemoryLink', c.dx, y, TextStyle(
      fontFamily: 'Pretendard', fontSize: 30, fontWeight: FontWeight.w800,
      letterSpacing: 1.2, color: Colors.white.withValues(alpha: word),
    ));
    _centeredText(canvas, '기억을 잇다, 오늘을 기록하다', c.dx, y + 8, TextStyle(
      fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w500,
      color: MLColors.primarySoft.withValues(alpha: word),
    ));
  }

  /// 가운데 정렬로 한 줄을 그리고 높이를 돌려준다.
  double _centeredText(Canvas canvas, String text, double cx, double top, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(cx - painter.width / 2, top));
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  bool shouldRepaint(_OpeningPainter oldDelegate) => oldDelegate.clock != clock;
}
