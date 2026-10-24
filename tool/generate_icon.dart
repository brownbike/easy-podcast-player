// Run with: dart run tool/generate_icon.dart
// Generates assets/icon/app_icon.png (1024x1024) used by flutter_launcher_icons.
//
// Design: chunky white headphones + orange sound-wave arcs on a deep-purple
// rounded-square background.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final purple = img.ColorRgba8(94, 23, 235, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);
  final orange = img.ColorRgba8(255, 152, 0, 255);

  // Background
  _fillRoundedRect(canvas, 0, 0, size, size, 180, purple);

  // Headphone geometry (all values in px at 1024×1024)
  const cx = size ~/ 2; // 512
  const earOffset = 255; // center → ear-cup centre distance
  const lx = cx - earOffset; // 257  left ear centre x
  const rx = cx + earOffset; // 767  right ear centre x
  const earCy = cx + 40; // 552  ear centre y (slightly below mid)
  const earHalfW = 82;
  const earHalfH = 118;
  const earCornerR = 38;

  // Headband arc: centred at (cx, earCy-earHalfH) so its endpoints sit
  // exactly at the tops of the two ear cups.
  const bandCy = earCy - earHalfH; // 434
  _drawThickArc(canvas, cx, bandCy, earOffset, 52, 185, 355, white);

  // Ear cups (rounded rectangles)
  _fillRoundedRect(canvas, lx - earHalfW, earCy - earHalfH,
      lx + earHalfW, earCy + earHalfH, earCornerR, white);
  _fillRoundedRect(canvas, rx - earHalfW, earCy - earHalfH,
      rx + earHalfW, earCy + earHalfH, earCornerR, white);

  // Sound waves — right side only, 3 concentric arcs facing right.
  // 310° → 410° (= 310° → 50° wrapping through 0°/right).
  _drawThickArc(canvas, rx, earCy, 112, 14, 310, 410, orange);
  _drawThickArc(canvas, rx, earCy, 158, 11, 310, 410, orange);
  _drawThickArc(canvas, rx, earCy, 204, 8, 310, 410, orange);

  final outFile = File('assets/icon/app_icon.png');
  outFile.writeAsBytesSync(img.encodePng(canvas));
  print('Saved ${outFile.path} (${size}×${size}px)');
}

// Draws a filled arc ring of given [thickness] centred on ([cx], [cy]) at
// [radius]. Angles are in degrees, 0° = right, increasing clockwise.
// Supports wrap-around (e.g. startDeg=310, endDeg=410 wraps past 360°).
void _drawThickArc(img.Image image, int cx, int cy, int radius, int thickness,
    double startDeg, double endDeg, img.Color color) {
  final rMin = radius - thickness ~/ 2;
  final rMax = radius + thickness ~/ 2;
  // Step small enough that adjacent pixels overlap at the largest radius.
  final step = math.max(0.1, 90.0 / (math.pi * rMax));
  var deg = startDeg;
  while (deg <= endDeg) {
    final a = deg * math.pi / 180.0;
    final cosA = math.cos(a);
    final sinA = math.sin(a);
    for (var r = rMin; r <= rMax; r++) {
      final px = cx + (r * cosA).round();
      final py = cy + (r * sinA).round();
      if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
        image.setPixel(px, py, color);
      }
    }
    deg += step;
  }
}

// Fills a rounded rectangle by composing two fillRects and four fillCircles.
void _fillRoundedRect(img.Image image, int x1, int y1, int x2, int y2, int r,
    img.Color color) {
  img.fillRect(image, x1: x1 + r, y1: y1, x2: x2 - r, y2: y2, color: color);
  img.fillRect(image, x1: x1, y1: y1 + r, x2: x2, y2: y2 - r, color: color);
  img.fillCircle(image, x: x1 + r, y: y1 + r, radius: r, color: color);
  img.fillCircle(image, x: x2 - r, y: y1 + r, radius: r, color: color);
  img.fillCircle(image, x: x1 + r, y: y2 - r, radius: r, color: color);
  img.fillCircle(image, x: x2 - r, y: y2 - r, radius: r, color: color);
}
