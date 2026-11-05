import 'package:flutter/material.dart';

import '../../core/design/app_spacing.dart';
import '../../models/card_design/card_brand.dart';
import 'bank_card_carousel.dart';
import 'bank_card_theme_picker.dart';
import 'bank_card_widget.dart';
import 'painters/card_network_logos.dart';

/// Kart tasarım sisteminin tüm bileşenlerini sergileyen demo ekranı.
///
/// Production'a dahil edilmemelidir; sadece geliştirme sırasında
/// temaları, badge'leri ve seçim akışını gözle kontrol etmek içindir.
class BankCardDesignDemoScreen extends StatefulWidget {
  const BankCardDesignDemoScreen({super.key});

  @override
  State<BankCardDesignDemoScreen> createState() =>
      _BankCardDesignDemoScreenState();
}

class _BankCardDesignDemoScreenState extends State<BankCardDesignDemoScreen> {
  CardBrand _selected = CardBrand.bonus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kart Tasarımı Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          _sectionTitle(context, 'Carousel'),
          BankCardCarousel(
            cards: CardBrand.values
                .take(6)
                .map(
                  (b) => BankCardWidget(
                    bankName: b.displayName,
                    last4Digits: '4242',
                    brand: b,
                    cardHolderName: 'PARION DEMO',
                    expirationDate: '12/29',
                    network: CardNetwork.mastercard,
                    showDebtInfo: true,
                    currentDebt: 4521.5,
                    creditLimit: 15000,
                  ),
                )
                .toList(),
            height: 260,
          ),

          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Boyut varyasyonları'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                BankCardWidget(
                  bankName: _selected.displayName,
                  last4Digits: '1111',
                  brand: _selected,
                  cardHolderName: 'KÜÇÜK',
                  width: 160,
                  height: 100,
                  showDebtInfo: false,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: BankCardWidget(
                    bankName: _selected.displayName,
                    last4Digits: '2222',
                    brand: _selected,
                    cardHolderName: 'ORTA BOY',
                    network: CardNetwork.visa,
                    showDebtInfo: true,
                    currentDebt: 1234,
                    creditLimit: 10000,
                    height: 100,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Liste satırı'),
          ...CardBrand.values.take(4).map(
                (b) => BankCardListItem(
                  bankName: b.displayName,
                  last4Digits: '1234',
                  brand: b,
                  cardHolderName: 'Demo Kullanıcı',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ),

          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Tema seçici'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: BankCardThemePicker(
              selected: _selected,
              onSelected: (b) => setState(() => _selected = b),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Marka chip\'leri'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CardBrand.values
                  .map(
                    (b) => BankBrandChip(
                      brand: b,
                      selected: b == _selected,
                      onTap: () => setState(() => _selected = b),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          _sectionTitle(context, 'Seçili: ${_selected.displayName}'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: BankCardWidget(
              bankName: _selected.displayName,
              last4Digits: '0000',
              brand: _selected,
              cardHolderName: 'PARION KART',
              expirationDate: '08/30',
              network: CardNetworkDetector.fromPan('4'),
              showDebtInfo: true,
              currentDebt: 7425.0,
              creditLimit: 25000,
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

/// Banka adından otomatik brand tahmini yaparak kart üretir.
class BankCardFromName extends StatelessWidget {
  const BankCardFromName({super.key, required this.bankName});

  final String bankName;

  @override
  Widget build(BuildContext context) {
    return BankCardWidget(
      bankName: bankName,
      last4Digits: '0000',
      brand: CardBrand.fromBankName(bankName),
      cardHolderName: 'AUTO',
      showDebtInfo: false,
    );
  }
}

/// Banka adından otomatik brand tahmini yaparak chip üretir.
class BankBrandAutoChip extends StatelessWidget {
  const BankBrandAutoChip({super.key, required this.bankName, this.onTap});

  final String bankName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BankBrandChip(
      brand: CardBrand.fromBankName(bankName),
      onTap: onTap,
    );
  }
}
