// Adapted from flutterfx/flutterfx_widgets (lib/tools/curves.dart, commit 9089ad7)
// https://github.com/flutterfx/flutterfx_widgets
// Copyright (c) 2024 FlutterFX - MIT License.
// Modified for MemoryLink: 원본은 t≈0에서 곧바로 1 근처로 점프하는 "정착 전용" 곡선이라
// 0→1 램프(easeOutCubic)를 더했다. 원본의 "감쇠 사인파" 구조는 유지하되 위상을 t^tension
// 으로 늦춰 오버슈트가 램프가 끝나는 뒤쪽에서 일어나게 했고, 오버슈트 기본값을 0.2에서
// 0.05로 낮췄다(고령 사용자 흔들림 최소화). t=1에서 정확히 1로 끝난다.
import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// 끝에서 살짝 넘쳤다가 돌아오는 스프링 곡선.
///
/// `MLSpringOutCurve()`의 최대 오버슈트는 [maxOvershoot](기본 0.05)을 넘지 않는다.
/// 눌림 복귀(`PressableScale`)와 해금 노드 scale-in 에 쓴다. 그 밖의 용도로 쓰려면
/// `DESIGN.md` §4 "모션은 상태 변화를 알릴 때만"을 먼저 확인한다.
class MLSpringOutCurve extends Curve {
  const MLSpringOutCurve({
    this.tension = 3.0,
    this.bounces = 1,
    this.maxOvershoot = 0.05,
  }) : assert(tension >= 1),
       assert(bounces >= 1),
       assert(maxOvershoot >= 0 && maxOvershoot <= 0.2);

  /// 위상 지연. 클수록 오버슈트가 뒤쪽(램프가 끝난 뒤)에서 일어난다.
  final double tension;

  /// 반(半)진동 횟수. 1이면 한 번 넘쳤다가 돌아오고, 2면 한 번 되튄다.
  final int bounces;

  /// 목표값을 넘어서는 최대 비율(0.05 = 5%).
  final double maxOvershoot;

  @override
  double transformInternal(double t) {
    if (t <= 0 || t >= 1) return t.clamp(0, 1).toDouble();
    final base = Curves.easeOutCubic.transform(t);
    final phase = math.pow(t, tension).toDouble();
    final wave = math.sin(math.pi * bounces * phase);
    return base + maxOvershoot * wave;
  }
}
