import 'package:flutter/material.dart' hide CardThemeData;

import '../../models/card_design/card_brand.dart';
import '../../models/card_design/card_theme_data.dart';

/// Tüm desteklenen kart markaları için görsel tema kayıtları.
///
/// Tüm temalar salt okunur ve const oldukları için aynı örnek
/// uygulama ömrü boyunca paylaşılabilir. Yeni banka eklemek için
/// `_registry` sözlüğüne yeni bir giriş eklemek yeterlidir.
class CardThemeRegistry {
  CardThemeRegistry._();

  /// Tüm kayıtlı temalara marka üzerinden erişim.
  static const Map<CardBrand, CardThemeData> _registry = {
    CardBrand.bonus: CardThemeData(
      colors: [Color(0xFF00A651), Color(0xFF006D35)],
      accentColor: Color(0xFF66FF66),
      backgroundPattern: 'bonus',
    ),
    CardBrand.axess: CardThemeData(
      colors: [Color(0xFFE30613), Color(0xFF8B0000)],
      accentColor: Color(0xFFFF6666),
      backgroundPattern: 'axess',
    ),
    CardBrand.maximum: CardThemeData(
      colors: [Color(0xFF003B8E), Color(0xFF001E4D)],
      accentColor: Color(0xFF0D47FF),
      backgroundPattern: 'm',
    ),
    CardBrand.world: CardThemeData(
      colors: [Color(0xFF001F5C), Color(0xFF001133)],
      accentColor: Color(0xFF0055FF),
      backgroundPattern: 'spiral',
    ),
    CardBrand.paraf: CardThemeData(
      colors: [Color(0xFF6A1B9A), Color(0xFF311B92)],
      accentColor: Color(0xFFBB86FC),
      backgroundPattern: 'wave',
    ),
    CardBrand.bankkart: CardThemeData(
      colors: [Color(0xFFD50000), Color(0xFF8B0000)],
      accentColor: Color(0xFFFF4444),
      backgroundPattern: 'zigzag',
    ),
    CardBrand.cardfinans: CardThemeData(
      colors: [Color(0xFF002B7F), Color(0xFF001848)],
      accentColor: Color(0xFF3D5AFE),
      backgroundPattern: 'star',
    ),
    CardBrand.denizBonus: CardThemeData(
      colors: [Color(0xFF0088CC), Color(0xFF005577)],
      accentColor: Color(0xFF33CCFF),
      backgroundPattern: 'anchor',
    ),
    CardBrand.milesSmiles: CardThemeData(
      colors: [Color(0xFF000000), Color(0xFF111111)],
      accentColor: Color(0xFFB8924A),
      textColor: Color(0xFFF1E5C8),
      labelColor: Color(0xFFB8924A),
      backgroundPattern: 'premium',
    ),
    CardBrand.vakifWorld: CardThemeData(
      colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
      accentColor: Color(0xFFFFD54F),
      textColor: Color(0xFF1C1C1E),
      labelColor: Color(0xFF5D4A1A),
      backgroundPattern: 'v',
    ),
    CardBrand.ing: CardThemeData(
      colors: [Color(0xFF002D62), Color(0xFF001933)],
      accentColor: Color(0xFFFF6600),
      backgroundPattern: 'lion',
    ),
    CardBrand.generic: CardThemeData(
      colors: [Color(0xFF2C6BED), Color(0xFF1A56D6)],
      accentColor: Color(0xFF66A3FF),
      backgroundPattern: 'generic',
    ),
  };

  /// Marka için temayı getirir. Bilinmiyorsa generic tema döner.
  static CardThemeData of(CardBrand brand) =>
      _registry[brand] ?? _registry[CardBrand.generic]!;

  /// Banka adından tahmin edilen marka için temayı getirir.
  static CardThemeData fromBankName(String? bankName) =>
      of(CardBrand.fromBankName(bankName));

  /// Tüm kayıtlı markalar (UI listeleme için).
  static List<CardBrand> get brands => CardBrand.values;

  /// Belirli bir markanın teması kayıtlı mı?
  static bool contains(CardBrand brand) => _registry.containsKey(brand);
}
