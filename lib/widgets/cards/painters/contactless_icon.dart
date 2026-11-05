import 'package:flutter/material.dart';

/// Temassız (NFC/contactless) ikonu çizer.
///
/// 4 dikey, kıvrımlı yaydan oluşur; her biri bir sonrakinden
/// daha büyük olacak şekilde sağa doğru açılır.
/// Yay açıları küçük (-50°) ile büyük (-130°) arasında değişir.
class ContactlessIconPainter extends CustomPainter {
  const ContactlessIconPainter({
    this.color = Colors.white70,
    this.strokeWidth = 2,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Yayların yarıçap adımları ve yayılma miktarları
    final radii = <double>[
      size.width * 0.18,
      size.width * 0.32,
      size.width * 0.46,
      size.width * 0.6,
    ];
    // Merkez, sol kenardan biraz içeride
    final center = Offset(size.width * 0.10, size.height * 0.5);

    for (final r in radii) {
      final rect = Rect.fromCircle(center: center, radius: r);
      // Üst yay: -50° (sol üst) -> -10° (sağ üst yarım)
      canvas.drawArc(rect, -1.4, 1.2, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ContactlessIconPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Temassız ikon için hazır widget.
class ContactlessIcon extends StatelessWidget {
  const ContactlessIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white70,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ContactlessIconPainter(color: color),
      ),
    );
  }
}
