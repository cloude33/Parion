import 'package:flutter/material.dart' hide CardThemeData;

import '../../../core/design/app_spacing.dart';
import '../../../models/card_design/card_brand.dart';
import '../../../models/card_design/card_theme_data.dart';

/// Kart üzerinde sol üstte görünen banka/marka rozeti.
///
/// PNG yerine geometrik şekiller ve karakterlerden oluşur.
/// [CardBrand] değerine göre uygun alt-sınıfı otomatik seçer.
class BankBrandBadge extends StatelessWidget {
  const BankBrandBadge({
    super.key,
    required this.brand,
    this.size = 22,
  });

  final CardBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + AppSpacing.xs,
      height: size,
      child: switch (brand) {
        CardBrand.bonus => _BonusBadge(size: size),
        CardBrand.axess => _AxessBadge(size: size),
        CardBrand.maximum => _MaximumBadge(size: size),
        CardBrand.world => _WorldBadge(size: size),
        CardBrand.paraf => _HalkBadge(size: size),
        CardBrand.bankkart => _BankkartBadge(size: size),
        CardBrand.cardfinans => _CardFinansBadge(size: size),
        CardBrand.denizBonus => _DenizBadge(size: size),
        CardBrand.milesSmiles => _MilesBadge(size: size),
        CardBrand.vakifWorld => _VakifBadge(size: size),
        CardBrand.ing => _IngBadge(size: size),
        CardBrand.generic => _GenericBadge(size: size),
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Bireysel badge widget'ları
// -----------------------------------------------------------------------------

class _BonusBadge extends StatelessWidget {
  const _BonusBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Bonus',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AxessBadge extends StatelessWidget {
  const _AxessBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.4),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'AK',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.55,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MaximumBadge extends StatelessWidget {
  const _MaximumBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Text(
        'İŞ',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w900,
          fontFamily: 'serif',
        ),
      ),
    );
  }
}

class _WorldBadge extends StatelessWidget {
  const _WorldBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFC72C),
      ),
      child: Icon(Icons.star, color: const Color(0xFF6C2A8C), size: size * 0.7),
    );
  }
}

class _HalkBadge extends StatelessWidget {
  const _HalkBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.all_inclusive, color: Colors.white, size: size);
  }
}

class _BankkartBadge extends StatelessWidget {
  const _BankkartBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.eco, color: const Color(0xFFFFD700), size: size);
  }
}

class _CardFinansBadge extends StatelessWidget {
  const _CardFinansBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        'QNB',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DenizBadge extends StatelessWidget {
  const _DenizBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.sailing, color: Colors.white, size: size);
  }
}

class _MilesBadge extends StatelessWidget {
  const _MilesBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB8924A), width: 1.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        'M&S',
        style: TextStyle(
          color: const Color(0xFFF1E5C8),
          fontWeight: FontWeight.w900,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}

class _VakifBadge extends StatelessWidget {
  const _VakifBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.shield, color: const Color(0xFFFFC72C), size: size);
  }
}

class _IngBadge extends StatelessWidget {
  const _IngBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.pets, color: const Color(0xFFFF6600), size: size);
  }
}

class _GenericBadge extends StatelessWidget {
  const _GenericBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.credit_card,
      color: Colors.white.withValues(alpha: 0.85),
      size: size,
    );
  }
}

/// Tema vurgu rengine göre hesaplanmış ortalama parlaklık.
///
/// [CardThemeData.accentColor] üzerinden kontrast sağlamak için
/// metin rengini (örn. siyah veya beyaz) otomatik seçer.
Color onAccentTextColor(CardThemeData theme) {
  final hsl = HSLColor.fromColor(theme.accentColor);
  return hsl.lightness > 0.6 ? Colors.black : Colors.white;
}
