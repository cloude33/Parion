import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class GarantiCloverLogo extends StatelessWidget {
  const GarantiCloverLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 0, child: Container(width: 7.5, height: 7.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
          Positioned(bottom: 0, child: Container(width: 7.5, height: 7.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
          Positioned(left: 0, child: Container(width: 7.5, height: 7.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
          Positioned(right: 0, child: Container(width: 7.5, height: 7.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
          Container(width: 3.5, height: 3.5, decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

class IsBankLogo extends StatelessWidget {
  const IsBankLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Center(
        child: Text(
          'İŞ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 9,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }
}

class YapiKrediLogo extends StatelessWidget {
  const YapiKrediLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Icon(Icons.star, color: Color(0xFFFFC72C), size: 10),
    );
  }
}

class AkbankLogo extends StatelessWidget {
  const AkbankLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'AK',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ZiraatLogo extends StatelessWidget {
  const ZiraatLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(Icons.eco, color: Color(0xFFFFD700), size: 18),
    );
  }
}

class HalkbankLogo extends StatelessWidget {
  const HalkbankLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(Icons.all_inclusive, color: Colors.white, size: 18),
    );
  }
}

class VakifbankLogo extends StatelessWidget {
  const VakifbankLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(Icons.shield, color: Color(0xFFFFC72C), size: 18),
    );
  }
}

class QnbLogo extends StatelessWidget {
  const QnbLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(Icons.diamond, color: Colors.white, size: 16),
    );
  }
}

class BankCardVisualWidget extends StatelessWidget {
  final String bankName;
  final String cardName;
  final String last4Digits;
  final double currentDebt;
  final double limit;
  final String colorHex;
  final int? cutOffDay;
  final int? paymentDay; // If only day of month is known
  final DateTime? fullPaymentDate; // If full date is known (preferred for List Screen)
  final Widget? action;
  final VoidCallback? onTap;
  final String? cardImagePath;
  final String? cardHolderName;
  final String? expirationDate;

  const BankCardVisualWidget({
    super.key,
    required this.bankName,
    required this.cardName,
    required this.last4Digits,
    required this.currentDebt,
    required this.limit,
    required this.colorHex,
    this.cutOffDay,
    this.paymentDay,
    this.fullPaymentDate,
    this.action,
    this.onTap,
    this.cardImagePath,
    this.cardHolderName,
    this.expirationDate,
  });

  String _formatCardNumber(String last4) {
    String clean4 = last4.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean4.length > 4) clean4 = clean4.substring(clean4.length - 4);
    if (clean4.isEmpty) clean4 = "1234";
    return "****   ****   ****   $clean4";
  }

  Widget _buildBankLogo(String bankName) {
    final name = bankName.toLowerCase();
    
    if (name.contains('garanti')) {
      return const GarantiCloverLogo();
    } else if (name.contains('iş bankası') || name.contains('is bankasi') || name.contains('iş bank')) {
      return const IsBankLogo();
    } else if (name.contains('yapı kredi') || name.contains('yapi kredi') || name.contains('world')) {
      return const YapiKrediLogo();
    } else if (name.contains('akbank') || name.contains('axess')) {
      return const AkbankLogo();
    } else if (name.contains('ziraat') || name.contains('bankkart')) {
      return const ZiraatLogo();
    } else if (name.contains('qnb') || name.contains('finansbank')) {
      return const QnbLogo();
    } else if (name.contains('teb')) {
      return const Padding(
        padding: EdgeInsets.only(right: 8),
        child: Icon(Icons.eco, color: Colors.white, size: 18),
      );
    } else if (name.contains('denizbank')) {
      return const Padding(
        padding: EdgeInsets.only(right: 8),
        child: Icon(Icons.sailing, color: Colors.white, size: 18),
      );
    } else if (name.contains('halkbank') || name.contains('paraf')) {
      return const HalkbankLogo();
    } else if (name.contains('vakıfbank') || name.contains('vakifbank')) {
      return const VakifbankLogo();
    } else if (name.contains('ing')) {
      return const Padding(
        padding: EdgeInsets.only(right: 8),
        child: Icon(Icons.pets, color: Colors.orange, size: 18),
      );
    } else if (name.contains('hsbc')) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Text(
          'HSBC',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 8,
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(Icons.credit_card, color: Colors.white70, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    try {
      cardColor = Color(int.parse(colorHex));
    } catch (_) {
      cardColor = const Color(0xFF212121);
    }
    
    String displayBankName = bankName;
    if (displayBankName == 'Banka' || displayBankName.isEmpty || displayBankName.trim() == '') {
      displayBankName = cardName; 
    }
    if (displayBankName.isEmpty) {
      displayBankName = 'Banka';
    }

    final bool useImage = cardImagePath != null && !cardImagePath!.startsWith('assets/');

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cardColor,
        Color.alphaBlend(Colors.black.withValues(alpha: 0.35), cardColor),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: !useImage ? gradient : null,
          image: useImage
              ? DecorationImage(
                  image: MemoryImage(base64Decode(cardImagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Premium subtle geometric background pattern
            if (!useImage)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: CustomPaint(
                    painter: CardPatternPainter(),
                  ),
                ),
              ),

            // Realistic Card Overlay for better text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            
            // 1. Bank Name & Logo (Top Left)
            Positioned(
              left: 20,
              top: 20,
              right: 60,
              child: Row(
                children: [
                  _buildBankLogo(displayBankName),
                  Expanded(
                    child: Text(
                      displayBankName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.5,
                        overflow: TextOverflow.ellipsis,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1))],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Action or Contactless Icon (Top Right)
            Positioned(
              right: 16,
              top: 16,
              child: action ?? const Icon(Icons.contactless, color: Colors.white70, size: 28),
            ),
            
            // 3. Chip (SIM Card) - Vertically Centered on the Left Side
            Positioned(
              left: 20,
              top: 68,
              child: Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF2D179),
                      const Color(0xFFD4AF37),
                      const Color(0xFFF3E5AB),
                      const Color(0xFFB8860B),
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
                  painter: ChipLinesPainter(),
                ),
              ),
            ),

            // 4. Card Number (Embossed look) - One Single Line with FittedBox
            Positioned(
              left: 20,
              right: 20,
              top: 112,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatCardNumber(last4Digits),
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.grey[100],
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                    fontFamily: 'Courier',
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(2, 2), blurRadius: 2),
                      Shadow(color: Colors.white.withValues(alpha: 0.3), offset: const Offset(-0.5, -0.5), blurRadius: 0.5),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Expiration Date (VALID THRU) - Bottom middle
            Positioned(
              left: 20,
              bottom: 42,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VALID', style: TextStyle(color: Colors.white70, fontSize: 5, fontWeight: FontWeight.bold, height: 0.8)),
                      Text('THRU', style: TextStyle(color: Colors.white70, fontSize: 5, fontWeight: FontWeight.bold, height: 0.8)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (expirationDate != null && expirationDate!.trim().isNotEmpty)
                        ? expirationDate!
                        : 'MM/YY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
                    ),
                  ),
                ],
              ),
            ),

            // 6. Cardholder Name (Bottom Left)
            Positioned(
              left: 20,
              bottom: 15,
              right: 140,
              child: Text(
                (cardHolderName ?? 'KART SAHİBİ').toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  overflow: TextOverflow.ellipsis,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(1, 1), blurRadius: 1),
                  ],
                ),
              ),
            ),

            // 7. Debt & Limit Info (Bottom Right)
            Positioned(
              right: 20,
              bottom: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₺${NumberFormat('#,##0', 'tr_TR').format(currentDebt)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'LİMİT: ₺${NumberFormat('#,##0', 'tr_TR').format(limit)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw inner rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(6, 6, size.width - 6, size.height - 6),
        const Radius.circular(4),
      ),
      paint,
    );

    // Draw horizontal middle line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw vertical dividers
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
