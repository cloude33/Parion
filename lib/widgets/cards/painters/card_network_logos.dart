import 'package:flutter/material.dart';

/// Desteklenen uluslararası kart ağları.
enum CardNetwork { visa, mastercard, amex, troy, unknown }

/// Kart ağına karar vermek için basit BIN aralığı kontrolü.
///
/// Gerçek projede bu mantık BIN veritabanıyla değiştirilmelidir;
/// burada yalnızca yaygın önekler için hızlı tahmin yapılır.
class CardNetworkDetector {
  CardNetworkDetector._();

  static CardNetwork fromPan(String pan) {
    if (pan.isEmpty) return CardNetwork.unknown;
    final clean = pan.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return CardNetwork.unknown;
    final n = int.parse(clean.substring(0, clean.length.clamp(1, 4)));

    if (clean.startsWith('4')) return CardNetwork.visa;
    if (n >= 5100 && n <= 5599) return CardNetwork.mastercard;
    if (n >= 2221 && n <= 2720) return CardNetwork.mastercard;
    if (clean.startsWith('34') || clean.startsWith('37')) return CardNetwork.amex;
    if (clean.startsWith('9792')) return CardNetwork.troy;

    return CardNetwork.unknown;
  }
}

/// Visa logosunu çizer: italik "VISA" yazısı, opsiyonel altın çerçeve.
class VisaLogoPainter extends CustomPainter {
  const VisaLogoPainter({this.color = Colors.white});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'VISA',
        style: TextStyle(
          color: color,
          fontSize: size.height * 0.85,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.2,
          fontFamily: 'Helvetica',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Ortala
    final dx = (size.width - tp.width) / 2;
    final dy = (size.height - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant VisaLogoPainter old) => old.color != color;
}

/// Mastercard logosunu çizer: kırmızı + sarı kesişen daireler.
class MastercardLogoPainter extends CustomPainter {
  const MastercardLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height * 0.42;
    final leftCenter = Offset(size.width * 0.36, size.height * 0.5);
    final rightCenter = Offset(size.width * 0.64, size.height * 0.5);

    final red = Paint()..color = const Color(0xFFF79E1B);
    final blendMode = BlendMode.srcIn;

    final yellowPath = Path()
      ..addOval(Rect.fromCircle(center: leftCenter, radius: radius));
    final redPath = Path()
      ..addOval(Rect.fromCircle(center: rightCenter, radius: radius));

    canvas.save();
    canvas.clipPath(yellowPath);
    canvas.drawPath(redPath, red..blendMode = blendMode);
    canvas.restore();

    // Sarı daire (clip dışında kalan kısım) açıkça çizilir.
    final yellowPaint = Paint()..color = const Color(0xFFEB001B);
    canvas.drawPath(yellowPath, yellowPaint);
  }

  @override
  bool shouldRepaint(covariant MastercardLogoPainter old) => false;
}

/// AMEX logosu: mavi kutu üzerine "AMERICAN EXPRESS" mini yazı.
class AmexLogoPainter extends CustomPainter {
  const AmexLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..color = const Color(0xFF1A72D0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      bg,
    );

    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'AMERICAN\n',
            style: TextStyle(
              color: Colors.white,
              fontSize: size.height * 0.32,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          TextSpan(
            text: 'EXPRESS',
            style: TextStyle(
              color: Colors.white,
              fontSize: size.height * 0.42,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2,
          (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant AmexLogoPainter old) => false;
}

/// Troy logosu: kırmızı kutu + beyaz "TROY".
class TroyLogoPainter extends CustomPainter {
  const TroyLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..color = const Color(0xFF00509E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      bg,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'TROY',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.height * 0.55,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2,
          (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant TroyLogoPainter old) => false;
}

/// Tüm ağları tek noktadan seçilebilen widget.
class CardNetworkLogo extends StatelessWidget {
  const CardNetworkLogo({
    super.key,
    required this.network,
    this.width = 56,
    this.height = 36,
    this.color = Colors.white,
  });

  final CardNetwork network;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: switch (network) {
        CardNetwork.visa => CustomPaint(painter: VisaLogoPainter(color: color)),
        CardNetwork.mastercard =>
          const CustomPaint(painter: MastercardLogoPainter()),
        CardNetwork.amex => const CustomPaint(painter: AmexLogoPainter()),
        CardNetwork.troy => const CustomPaint(painter: TroyLogoPainter()),
        CardNetwork.unknown => const SizedBox.shrink(),
      },
    );
  }
}
