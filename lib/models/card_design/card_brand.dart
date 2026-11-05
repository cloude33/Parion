/// Türkiye'deki yaygın kredi kartı markaları.
///
/// Her değer, [CardThemeRegistry] içindeki ilgili temayla eşleşir.
/// Tanınmayan banka adları [CardBrand.generic] üzerinden
/// nötr bir temayla eşlenir.
enum CardBrand {
  bonus('Bonus', 'bonus'),
  axess('Axess', 'axess'),
  maximum('Maximum', 'maximum'),
  world('World', 'world'),
  paraf('Paraf', 'paraf'),
  bankkart('Bankkart', 'bankkart'),
  cardfinans('CardFinans', 'cardfinans'),
  denizBonus('Deniz Bonus', 'denizBonus'),
  milesSmiles('Miles&Smiles', 'miles'),
  vakifWorld('Vakıf World', 'vakif'),
  ing('ING', 'ing'),
  generic('Diğer', 'generic');

  const CardBrand(this.displayName, this.patternKey);

  /// Kullanıcıya gösterilecek marka adı.
  final String displayName;

  /// [CardThemeData.backgroundPattern] ile aynı anahtar.
  final String patternKey;

  /// Banka adından en uygun [CardBrand] değerini tahmin eder.
  ///
  /// Arama büyük-küçük harf duyarsız yapılır. Eşleşme bulunamazsa
  /// [CardBrand.generic] döner.
  static CardBrand fromBankName(String? bankName) {
    if (bankName == null || bankName.trim().isEmpty) {
      return CardBrand.generic;
    }
    final name = bankName.toLowerCase();

    if (name.contains('bonus')) return CardBrand.bonus;
    if (name.contains('axess') || name.contains('akbank')) return CardBrand.axess;
    if (name.contains('maximum') || name.contains('iş bank') || name.contains('is bank')) {
      return CardBrand.maximum;
    }
    if (name.contains('world') || name.contains('yapı') || name.contains('yapi')) {
      return CardBrand.world;
    }
    if (name.contains('paraf') || name.contains('halk')) return CardBrand.paraf;
    if (name.contains('bankkart') || name.contains('ziraat')) return CardBrand.bankkart;
    if (name.contains('cardfinans') || name.contains('finansbank') || name.contains('qnb')) {
      return CardBrand.cardfinans;
    }
    if (name.contains('deniz')) return CardBrand.denizBonus;
    if (name.contains('miles') || name.contains('smile')) return CardBrand.milesSmiles;
    if (name.contains('vakıf') || name.contains('vakif')) return CardBrand.vakifWorld;
    if (name.contains('ing')) return CardBrand.ing;

    return CardBrand.generic;
  }
}
