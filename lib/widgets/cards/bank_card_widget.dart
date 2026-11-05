import 'package:flutter/material.dart' hide CardThemeData;
import 'package:intl/intl.dart';

import '../../core/design/app_spacing.dart';
import '../../core/design/card_themes.dart';
import '../../models/card_design/card_brand.dart';
import '../../models/card_design/card_theme_data.dart';
import 'bank_brand_badge.dart';
import 'painters/card_background_painter.dart';
import 'painters/card_chip_painter.dart';
import 'painters/card_network_logos.dart';
import 'painters/contactless_icon.dart';

/// Tüm banka kartlarını temsil eden yeniden kullanılabilir widget.
///
/// Tasarım:
///   * PNG/logo kullanmaz; her şey [CustomPainter] ile çizilir.
///   * Tek bir [CardThemeData] üzerinden renk, gradyan ve desen alır.
///   * Liste satırı, detay sayfası veya seçim diyaloğu gibi tüm
///     kullanım senaryolarında aynı görsel dili korur.
class BankCardWidget extends StatelessWidget {
  const BankCardWidget({
    super.key,
    required this.bankName,
    required this.last4Digits,
    this.brand,
    this.cardHolderName,
    this.expirationDate,
    this.network = CardNetwork.unknown,
    this.currentDebt,
    this.creditLimit,
    this.width = 350,
    this.height = 220,
    this.borderRadius = 20,
    this.showChip = true,
    this.showContactless = true,
    this.showNetworkLogo = true,
    this.showBrandBadge = true,
    this.showBankName = true,
    this.showMaskedNumber = true,
    this.showExpiration = true,
    this.showHolderName = true,
    this.showDebtInfo = false,
    this.onTap,
    this.action,
  });

  // ----- Veri parametreleri -----
  final String bankName;
  final String last4Digits;
  final CardBrand? brand;
  final String? cardHolderName;
  final String? expirationDate;
  final CardNetwork network;
  final double? currentDebt;
  final double? creditLimit;

  // ----- Boyut / stil -----
  final double width;
  final double height;
  final double borderRadius;

  // ----- Hangi parçalar görünsün -----
  final bool showChip;
  final bool showContactless;
  final bool showNetworkLogo;
  final bool showBrandBadge;
  final bool showBankName;
  final bool showMaskedNumber;
  final bool showExpiration;
  final bool showHolderName;
  final bool showDebtInfo;

  // ----- Etkileşim -----
  final VoidCallback? onTap;
  final Widget? action;

  CardBrand get _resolvedBrand => brand ?? CardBrand.fromBankName(bankName);

  CardThemeData get _theme => CardThemeRegistry.of(_resolvedBrand);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: _theme.gradient,
            boxShadow: [
              BoxShadow(
                color: _theme.colors.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // 1. Arka plan deseni
                Positioned.fill(
                  child: CustomPaint(
                    painter: CardBackgroundPainter(
                      pattern: _theme.backgroundPattern,
                      accent: _theme.accentColor,
                      textColor: _theme.textColor,
                    ),
                  ),
                ),

                // 2. Işık / gölge overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: _theme.overlayGradient),
                  ),
                ),

                // 3. İçerik katmanı
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildContent(),
                ),

                // 4. Sağ üst aksiyon (NFC veya custom)
                if (showContactless)
                  Positioned(
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    child: action ??
                        ContactlessIcon(
                          size: 28,
                          color: _theme.textColor.withValues(alpha: 0.75),
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = _theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Üst satır: banka adı + (badge opsiyonel)
        if (showBankName || showBrandBadge)
          Row(
            children: [
              if (showBrandBadge) ...[
                BankBrandBadge(brand: _resolvedBrand),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (showBankName)
                Expanded(
                  child: Text(
                    bankName.toUpperCase(),
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),

        const Spacer(),

        // Çip satırı
        if (showChip)
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: AppSpacing.md),
            child: CardChip(),
          ),

        // Maskeli numara
        if (showMaskedNumber)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatMaskedNumber(last4Digits),
              maxLines: 1,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
                fontFamily: 'Courier',
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.md),

        // Alt satır: son kullanma + isim + (opsiyonel) borç + ağ logosu
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // VALID THRU + isim
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showExpiration)
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VALID',
                              style: TextStyle(
                                color: theme.effectiveLabelColor,
                                fontSize: 5,
                                fontWeight: FontWeight.bold,
                                height: 0.8,
                              ),
                            ),
                            Text(
                              'THRU',
                              style: TextStyle(
                                color: theme.effectiveLabelColor,
                                fontSize: 5,
                                fontWeight: FontWeight.bold,
                                height: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Text(
                          expirationDate?.trim().isNotEmpty == true
                              ? expirationDate!
                              : 'MM/YY',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 2,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (showHolderName) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      (cardHolderName ?? 'KART SAHİBİ').toUpperCase(),
                      style: TextStyle(
                        color: theme.textColor.withValues(alpha: 0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 1,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Borç / limit (opsiyonel)
            if (showDebtInfo && currentDebt != null && creditLimit != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₺${NumberFormat('#,##0', 'tr_TR').format(currentDebt)}',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'LİMİT: ₺${NumberFormat('#,##0', 'tr_TR').format(creditLimit)}',
                    style: TextStyle(
                      color: theme.textColor.withValues(alpha: 0.9),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Ağ logosu
            if (showNetworkLogo && network != CardNetwork.unknown) ...[
              const SizedBox(width: AppSpacing.sm),
              CardNetworkLogo(
                network: network,
                width: 56,
                height: 36,
                color: theme.textColor,
              ),
            ],
          ],
        ),
      ],
    );
  }

  static String _formatMaskedNumber(String last4) {
    var clean = last4.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length > 4) clean = clean.substring(clean.length - 4);
    if (clean.isEmpty) clean = '1234';
    return '****   ****   ****   $clean';
  }
}
