import 'package:flutter/material.dart';

/// Kredi kartı çipinin (SIM benzeri) altın yüzey çizimi.
///
/// Çipin dış çerçevesi, orta yatay çizgisi ve iki dikey bölücü çizilir.
/// Tüm çizimler [Color] tabanlı olduğu için farklı altın tonları
/// veya hatta gümüş/kart-beyaz varyantları kolayca elde edilebilir.
class CardChipPainter extends CustomPainter {
  const CardChipPainter({
    this.lineColor = const Color(0x55000000),
    this.strokeWidth = 0.8,
  });

  final Color lineColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // İç çerçeve
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(6, 6, size.width - 6, size.height - 6),
        const Radius.circular(4),
      ),
      paint,
    );

    // Orta yatay çizgi
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Dikey bölücüler
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, 0),
      Offset(size.width * 0.65, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CardChipPainter old) =>
      old.lineColor != lineColor || old.strokeWidth != strokeWidth;
}

/// Çip için altın gradyanlı Container saran hazır widget.
class CardChip extends StatelessWidget {
  const CardChip({
    super.key,
    this.width = 40,
    this.height = 28,
    this.lineColor = const Color(0x66000000),
  });

  final double width;
  final double height;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF2D179),
            Color(0xFFD4AF37),
            Color(0xFFF3E5AB),
            Color(0xFFB8860B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CardChipPainter(lineColor: lineColor),
      ),
    );
  }
}
