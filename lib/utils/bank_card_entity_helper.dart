import 'package:flutter/material.dart';

import '../models/credit_card.dart';
import '../models/card_design/card_brand.dart';
import '../core/design/card_themes.dart';
import '../widgets/cards/painters/card_network_logos.dart';

/// [CreditCard] modeli ile yeni kart tasarım sistemi arasındaki adaptör.
///
/// Üç yere yardımcı olur:
///   1. [CreditCard.bankName] üzerinden [CardBrand] tahmini yapar.
///   2. [CardNetwork] tahmini için BIN aralığını kullanır (kart görsel
///      bilgisi henüz modelde tutulmuyorsa son 4 haneyi kullanır).
///   3. PNG tabanlı [CreditCard.cardImagePath] alanı varsa (base64 veya
///      assets) `bool` olarak bildirir; yeni sistem PNG'ye gerek duymaz
///      ancak ileride fotoğraflı kartı da göstermek isteyen ekranlar
///      bu bayrağı kullanabilir.
class BankCardEntityHelper {
  BankCardEntityHelper._();

  /// Banka adından marka tahmin eder.
  static CardBrand resolveBrand(CreditCard card) {
    final name = card.cardName.isNotEmpty ? card.cardName : card.bankName;
    return CardBrand.fromBankName(name);
  }

  /// [CreditCard] üzerinden ağ tahmin eder.
  ///
  /// Modelde tam PAN tutulmadığı için BIN aralığı yerine son 4 hane
  /// ve kart adı ipuçlarına bakılır. Yine de gerçek BIN eklendiğinde
  /// tek değişiklik bu metodun içinde kalır.
  static CardNetwork resolveNetwork(CreditCard card) {
    final haystack = '${card.bankName} ${card.cardName}'.toLowerCase();
    if (haystack.contains('amex') || haystack.contains('american')) {
      return CardNetwork.amex;
    }
    if (haystack.contains('troy')) return CardNetwork.troy;
    if (haystack.contains('master') || haystack.contains('cardfinans')) {
      return CardNetwork.mastercard;
    }
    // Visa Türkiye'de en yaygın ağ; belirsizliğe düşüldüğünde Visa seçilir.
    return CardNetwork.visa;
  }

  /// Banka + kart adından otomatik renk çıkarır.
  ///
  /// Tanınmayan bankalar için generic tema rengi döner.
  static Color resolveThemeColor({
    required String bankName,
    required String cardName,
  }) {
    final haystack = cardName.trim().isNotEmpty
        ? '${bankName.trim()} ${cardName.trim()}'
        : bankName;
    return CardThemeRegistry.fromBankName(haystack).colors.first;
  }

  /// Kullanıcının kart için özel görsel yüklediyse `true`.
  ///
  /// Yeni tasarım sistemi PNG'ye ihtiyaç duymaz; bu bilgi yalnızca
  /// fotoğraflı kart gösterimini tercih eden eski bileşenlerle uyumluluk
  /// için döndürülür.
  static bool hasCustomImage(CreditCard card) {
    final path = card.cardImagePath;
    if (path == null || path.isEmpty) return false;
    return path.startsWith('assets/') || _looksLikeBase64(path);
  }

  static bool _looksLikeBase64(String s) {
    if (s.length < 32) return false;
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(s);
  }
}
