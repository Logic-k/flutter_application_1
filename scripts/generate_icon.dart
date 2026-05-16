// scripts/generate_icon.dart
// Run with: dart run scripts/generate_icon.dart
//
// Design: "Memory Stars" constellation
// - Warm teal gradient background (light → dark, top → bottom)
// - 24 subtle background sparkles (night sky feel)
// - 5 constellation stars connected by thin mint lines
// - Stars glow with layered sage-green halo → white core
// - Primary star (A) has a 4-point sparkle cross
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;

  final transparent = img.ColorRgba8(0, 0, 0, 0);
  final lineColor   = img.ColorRgba8(0x70, 0xCA, 0xC4, 0xFF); // mint teal
  final white       = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);

  // Background gradient: light teal (#007A80) → deep teal (#003C40)
  const bgTop = (0x00, 0x7A, 0x80);
  const bgBot = (0x00, 0x3C, 0x40);

  // Star glow: sage green (#81C784)
  const glow = (0x81, 0xC7, 0x84);

  final image = img.Image(width: size, height: size);

  // 1. Vertical gradient background
  for (int y = 0; y < size; y++) {
    final t = y / (size - 1);
    final c = img.ColorRgba8(
      _lerp(bgTop.$1, bgBot.$1, t),
      _lerp(bgTop.$2, bgBot.$2, t),
      _lerp(bgTop.$3, bgBot.$3, t),
      0xFF,
    );
    for (int x = 0; x < size; x++) {
      image.setPixel(x, y, c);
    }
  }

  // 2. Rounded corners (radius 200)
  const cr = 200;
  _clearCorner(image, cr,        cr,        cr, transparent);
  _clearCorner(image, size - cr, cr,        cr, transparent);
  _clearCorner(image, cr,        size - cr, cr, transparent);
  _clearCorner(image, size - cr, size - cr, cr, transparent);

  // 3. Background sparkle dots (deterministic, subtle)
  const sparkles = [
    (110, 140, 4), (195, 385, 3), (165, 715, 5), (415,  95, 3),
    (505, 188, 4), (765, 142, 3), (888, 292, 5), (858, 722, 3),
    (942, 502, 4), (108, 858, 3), (315, 922, 4), (702, 912, 3),
    (912, 812, 5), (148, 492, 3), (612, 108, 4), (802, 398, 3),
    (758, 762, 4), (362, 762, 3), (872, 162, 3), (148, 272, 4),
    (932, 652, 3), (492, 872, 4), (682, 832, 3), (242, 822, 4),
  ];
  for (final (sx, sy, sr) in sparkles) {
    final t = sy / (size - 1);
    final c = img.ColorRgba8(
      _lerp(_lerp(bgTop.$1, bgBot.$1, t), 0xFF, 0.42),
      _lerp(_lerp(bgTop.$2, bgBot.$2, t), 0xFF, 0.42),
      _lerp(_lerp(bgTop.$3, bgBot.$3, t), 0xFF, 0.42),
      0xFF,
    );
    _fillCircle(image, sx, sy, sr, c);
  }

  // 4. Constellation definition
  //    (x, y, radius, hasCrossSparkle)
  const stars = [
    (355, 358, 50, true),  // A — upper-left, primary
    (658, 295, 34, false), // B — upper-right
    (755, 572, 38, false), // C — right
    (428, 715, 29, false), // D — lower-left
    (540, 488, 24, false), // E — center hub
  ];

  // 5. Connecting lines (drawn before stars so stars appear on top)
  const edges = [(0,1),(1,2),(2,3),(3,0),(0,4),(1,4)];
  for (final (i, j) in edges) {
    _drawThickLine(image,
        stars[i].$1, stars[i].$2,
        stars[j].$1, stars[j].$2,
        lineColor, 3);
  }

  // 6. Stars with layered glow (outer haze → sage green → white core)
  for (final (sx, sy, sr, hasCross) in stars) {
    final t = sy / (size - 1);
    final bgR = _lerp(bgTop.$1, bgBot.$1, t);
    final bgG = _lerp(bgTop.$2, bgBot.$2, t);
    final bgB = _lerp(bgTop.$3, bgBot.$3, t);

    // Outer haze (10% glow blended into background)
    _fillCircle(image, sx, sy, (sr * 3.2).round(), img.ColorRgba8(
      _lerp(bgR, glow.$1, 0.10),
      _lerp(bgG, glow.$2, 0.10),
      _lerp(bgB, glow.$3, 0.10),
      0xFF,
    ));
    // Mid glow (28% glow)
    _fillCircle(image, sx, sy, (sr * 2.0).round(), img.ColorRgba8(
      _lerp(bgR, glow.$1, 0.28),
      _lerp(bgG, glow.$2, 0.28),
      _lerp(bgB, glow.$3, 0.28),
      0xFF,
    ));
    // Inner glow (full sage green)
    _fillCircle(image, sx, sy, (sr * 1.4).round(), img.ColorRgba8(
      glow.$1, glow.$2, glow.$3, 0xFF,
    ));
    // White core
    _fillCircle(image, sx, sy, sr, white);

    if (hasCross) {
      // 4-point sparkle cross on primary star
      _fillRect(image, sx - sr - 12, sy - 5, sx + sr + 12, sy + 5, white);
      _fillRect(image, sx - 5, sy - sr - 12, sx + 5, sy + sr + 12, white);
      // Re-draw core over the cross centre
      _fillCircle(image, sx, sy, sr, white);
    }
  }

  // Output
  Directory('assets/icon').createSync(recursive: true);
  final out = File('assets/icon/app_icon.png');
  out.writeAsBytesSync(img.encodePng(image));
  // ignore: avoid_print
  print('Done: ${out.path} (${out.lengthSync()} bytes)');
}

// ── Helpers ──────────────────────────────────────────────────────────────────

int _lerp(int a, int b, double t) =>
    (a + (b - a) * t).round().clamp(0, 255);

void _fillCircle(img.Image im, int cx, int cy, int r, img.Color c) {
  final r2 = r * r;
  final y0 = (cy - r).clamp(0, im.height - 1);
  final y1 = (cy + r).clamp(0, im.height - 1);
  final x0 = (cx - r).clamp(0, im.width - 1);
  final x1 = (cx + r).clamp(0, im.width - 1);
  for (int y = y0; y <= y1; y++) {
    for (int x = x0; x <= x1; x++) {
      final dx = x - cx, dy = y - cy;
      if (dx * dx + dy * dy <= r2) im.setPixel(x, y, c);
    }
  }
}

void _fillRect(img.Image im, int x0, int y0, int x1, int y1, img.Color c) {
  for (int y = y0.clamp(0, im.height - 1); y <= y1.clamp(0, im.height - 1); y++) {
    for (int x = x0.clamp(0, im.width - 1); x <= x1.clamp(0, im.width - 1); x++) {
      im.setPixel(x, y, c);
    }
  }
}

void _clearCorner(img.Image im, int cX, int cY, int r, img.Color c) {
  final isL = cX < im.width  ~/ 2;
  final isT = cY < im.height ~/ 2;
  final r2  = r * r;
  final y0  = isT ? 0 : cY;
  final y1  = isT ? cY : im.height - 1;
  final x0  = isL ? 0 : cX;
  final x1  = isL ? cX : im.width  - 1;
  for (int y = y0; y <= y1; y++) {
    for (int x = x0; x <= x1; x++) {
      final dx = x - cX, dy = y - cY;
      if (dx * dx + dy * dy > r2) im.setPixel(x, y, c);
    }
  }
}

void _drawThickLine(
    img.Image im, int x0, int y0, int x1, int y1, img.Color c, int t) {
  int dx = (x1 - x0).abs(), dy = (y1 - y0).abs();
  int sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
  int err = dx - dy, x = x0, y = y0;
  final h = t ~/ 2;
  while (true) {
    for (int by = -h; by <= h; by++) {
      for (int bx = -h; bx <= h; bx++) {
        if (bx * bx + by * by <= h * h) {
          final px = x + bx, py = y + by;
          if (px >= 0 && px < im.width && py >= 0 && py < im.height) {
            im.setPixel(px, py, c);
          }
        }
      }
    }
    if (x == x1 && y == y1) break;
    final e2 = 2 * err;
    if (e2 > -dy) { err -= dy; x += sx; }
    if (e2 <  dx) { err += dx; y += sy; }
  }
}
