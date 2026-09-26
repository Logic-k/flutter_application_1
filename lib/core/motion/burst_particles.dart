import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 한 점에서 바깥으로 퍼졌다가 사라지는 1회성 파티클.
///
/// 정답 순간(작게, 짧게)과 결과 시트 축하(크게, 길게)에 같은 그리기를 쓴다.
/// 매 프레임 `setState` 없이 [CustomPainter] 의 `repaint` 로만 다시 그리고,
/// [RepaintBoundary] 로 주변 레이아웃과 떼어 둔다. 반복 재생은 하지 않는다
/// (DESIGN.md §4 "자동 재생·반복 애니메이션 금지").
///
/// 시각 장식이라 접근성 트리에서 뺀다. 상태는 배지 문구가 따로 전달한다.
class BurstParticles extends StatelessWidget {
  const BurstParticles({
    super.key,
    required this.progress,
    required this.colors,
    this.count = 14,
    this.maxRadius = 90,
    this.seed = 7,
    this.gravity = 0,
  }) : assert(count > 0 && count <= 60);

  /// 0→1 로 흐르는 애니메이션. 끝나면 아무것도 그리지 않는다.
  final Animation<double> progress;

  /// 3색 이내(07 계획 §7-2 "컨페티 색은 3색 이내").
  final List<Color> colors;

  /// 입자 수. 상한 60(07 계획 §3-6).
  final int count;

  /// 입자가 날아가는 최대 거리(dp).
  final double maxRadius;

  /// 같은 seed 면 같은 모양으로 퍼진다(테스트·재현용).
  final int seed;

  /// 0 이면 방사형, 0보다 크면 떨어지는 컨페티처럼 아래로 휜다.
  final double gravity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _BurstPainter(
              progress: progress,
              colors: colors,
              count: count,
              maxRadius: maxRadius,
              seed: seed,
              gravity: gravity,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle(this.angle, this.distance, this.size, this.color, this.square);
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final bool square;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required List<Color> colors,
    required int count,
    required this.maxRadius,
    required int seed,
    required this.gravity,
  }) : _particles = _build(colors, count, seed),
       super(repaint: progress);

  final Animation<double> progress;
  final double maxRadius;
  final double gravity;
  final List<_Particle> _particles;

  static List<_Particle> _build(List<Color> colors, int count, int seed) {
    final rng = math.Random(seed);
    return List.generate(count, (i) {
      // 각도를 고르게 나누고 약간만 흔들어, 한쪽으로 몰리지 않게 한다.
      final angle = (i / count) * 2 * math.pi + rng.nextDouble() * 0.4;
      return _Particle(
        angle,
        0.55 + rng.nextDouble() * 0.45,
        4 + rng.nextDouble() * 4,
        colors[i % colors.length],
        i.isEven,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final travel = Curves.easeOutCubic.transform(t);
    // 마지막 40% 동안 서서히 사라진다.
    final opacity = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
    final paint = Paint();
    for (final p in _particles) {
      final r = maxRadius * p.distance * travel;
      final offset = center +
          Offset(math.cos(p.angle) * r, math.sin(p.angle) * r + gravity * t * t);
      paint.color = p.color.withValues(alpha: opacity.clamp(0, 1).toDouble());
      final s = p.size * (1 - 0.3 * t);
      if (p.square) {
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.rotate(p.angle + t * math.pi);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s * 1.6, height: s),
            const Radius.circular(1.5),
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(offset, s / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.progress != progress || old._particles.length != _particles.length;
}
