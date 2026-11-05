import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kart yüzeyi için dekoratif desen çizici.
///
/// [pattern] değerine göre farklı geometrik/tipografik arka planlar
/// çizer. Tüm desenler tek dosyada toplanmıştır; bilinmeyen desen
/// anahtarları sessizce atlanır.
class CardBackgroundPainter extends CustomPainter {
  const CardBackgroundPainter({
    required this.pattern,
    required this.accent,
    this.opacity = 0.12,
    this.textColor = Colors.white,
  });

  /// Hangi desenin çizileceğini belirler (örn. `"b"`, `"m"`, `"spiral"`).
  final String pattern;

  /// Desen vurgu rengi.
  final Color accent;

  /// Desen opaklığı (0-1).
  final double opacity;

  /// Tipografik desenlerde kullanılacak metin rengi.
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = accent.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    switch (pattern) {
      case 'circle':
        _drawCirclePattern(canvas, size, base);
        break;
      case 'spiral':
        _drawSpiralPattern(canvas, size, base);
        break;
      case 'b':
      case 'bonus':
      case 'axess':
        _drawLetterPattern(
          canvas,
          size,
          letter: pattern == 'axess' ? 'a' : 'b',
          fontSize: 260,
          offsetX: size.width * 0.45,
        );
        break;
      case 'm':
        _drawLetterPattern(
          canvas,
          size,
          letter: 'M',
          fontSize: 220,
          offsetX: size.width * 0.35,
        );
        break;
      case 'v':
        _drawLetterPattern(
          canvas,
          size,
          letter: 'V',
          fontSize: 220,
          offsetX: size.width * 0.35,
        );
        break;
      case 'wave':
        _drawWavePattern(canvas, size, base);
        break;
      case 'zigzag':
        _drawZigzagPattern(canvas, size, base);
        break;
      case 'star':
        _drawStarPattern(canvas, size, base);
        break;
      case 'anchor':
        _drawAnchorPattern(canvas, size, base);
        break;
      case 'premium':
        _drawPremiumPattern(canvas, size, base);
        break;
      case 'lion':
        _drawLetterPattern(
          canvas,
          size,
          letter: 'İ',
          fontSize: 280,
          offsetX: size.width * 0.40,
        );
        break;
      case 'generic':
      default:
        _drawGenericPattern(canvas, size, base);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Bireysel desen çizimleri
  // ---------------------------------------------------------------------------

  void _drawCirclePattern(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.8, size.height * 0.6);
    canvas.drawCircle(center, size.height * 0.5, paint);
    canvas.drawCircle(center, size.height * 0.35, paint);
  }

  void _drawSpiralPattern(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.35, size.height * 0.5);
    for (var i = 0; i < 10; i++) {
      canvas.drawCircle(center, 20 + (i * 12).toDouble(), paint);
    }
  }

  void _drawLetterPattern(
    Canvas canvas,
    Size size, {
    required String letter,
    required double fontSize,
    required double offsetX,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          color: accent.withValues(alpha: opacity),
          fontWeight: FontWeight.w900,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(offsetX, -fontSize * 0.08));
  }

  void _drawWavePattern(Canvas canvas, Size size, Paint paint) {
    final path = Path()..moveTo(0, size.height * 0.5);
    for (var x = 0.0; x <= size.width; x += 8) {
      final y = size.height * 0.5 +
          math.sin((x / size.width) * math.pi * 4) * size.height * 0.18;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  void _drawZigzagPattern(Canvas canvas, Size size, Paint paint) {
    final path = Path()..moveTo(0, size.height * 0.75);
    final step = size.width / 8;
    for (var i = 0; i < 8; i++) {
      final yPeak = i.isEven ? size.height * 0.25 : size.height * 0.75;
      path.lineTo(step * (i + 1), yPeak);
    }
    canvas.drawPath(path, paint);
  }

  void _drawStarPattern(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.78, size.height * 0.35);
    final outer = size.height * 0.32;
    final inner = outer * 0.45;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final angle = (i * 36) * math.pi / 180 - math.pi / 2;
      final p = Offset(center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawAnchorPattern(Canvas canvas, Size size, Paint paint) {
    final c = Offset(size.width * 0.78, size.height * 0.55);
    final r = size.height * 0.22;
    // Halka
    canvas.drawCircle(c, r, paint);
    // Üst dikme
    canvas.drawLine(
      Offset(c.dx, c.dy - r),
      Offset(c.dx, c.dy + r * 0.4),
      paint,
    );
    // Çapraz kollar
    canvas.drawLine(
      Offset(c.dx - r * 0.7, c.dy - r * 0.3),
      Offset(c.dx + r * 0.7, c.dy - r * 0.3),
      paint,
    );
  }

  void _drawPremiumPattern(Canvas canvas, Size size, Paint paint) {
    // Premium için ince altın vurgu: çift halka + ortada baklava.
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final r = size.height * 0.35;
    final thinPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, r, thinPaint);
    canvas.drawCircle(center, r * 0.85, thinPaint);
  }

  void _drawGenericPattern(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.2,
        size.width * 0.8,
        size.height,
      )
      ..moveTo(size.width * 0.2, 0)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.7,
        size.width,
        size.height * 0.3,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CardBackgroundPainter old) =>
      old.pattern != pattern ||
      old.accent != accent ||
      old.opacity != opacity ||
      old.textColor != textColor;
}
