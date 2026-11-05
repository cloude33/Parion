import 'package:flutter/material.dart';

import '../../models/card_design/card_brand.dart';
import 'bank_card_widget.dart';

/// Yatay kaydırmalı kart galerisi (Apple Wallet benzeri).
///
/// Her sayfa kartın biraz yan komşularını gösterir; ortadaki
/// kart tam boyutlu görünür. [onPageChanged] ile dışarıya
/// seçili indeksi bildirir. İsteğe bağlı olarak altta sayfa
/// göstergesi (noktalar) çizilir.
class BankCardCarousel extends StatefulWidget {
  const BankCardCarousel({
    super.key,
    required this.cards,
    this.initialIndex = 0,
    this.height = 240,
    this.viewportFraction = 0.85,
    this.onPageChanged,
    this.controller,
    this.showIndicator = false,
    this.indicatorColor,
  });

  /// Sırayla gösterilecek kart widget'ları.
  final List<Widget> cards;

  /// Başlangıçtaki görünür kart indeksi.
  final int initialIndex;

  /// Carousel toplam yüksekliği.
  final double height;

  /// Her sayfanın ekran genişliğine oranı (0-1).
  final double viewportFraction;

  final ValueChanged<int>? onPageChanged;

  /// Dışarıdan kontrol için isteğe bağlı [PageController].
  ///
  /// Verilirse carousel kendi içinde yeni bir controller oluşturmaz;
  /// dışarıdaki çağrılar (animateToPage, nextPage, vb.) doğrudan çalışır.
  final PageController? controller;

  /// true ise carousel altında nokta göstergesi çizilir.
  final bool showIndicator;

  /// Aktif olmayan noktaların rengi. Varsayılan: tema primary %30.
  final Color? indicatorColor;

  @override
  State<BankCardCarousel> createState() => _BankCardCarouselState();
}

class _BankCardCarouselState extends State<BankCardCarousel> {
  late final PageController _controller;
  late int _currentIndex;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = PageController(
        viewportFraction: widget.viewportFraction,
        initialPage: widget.initialIndex,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = widget.showIndicator && widget.cards.length > 1
        ? _buildIndicator(context)
        : const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.cards.length,
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
              widget.onPageChanged?.call(i);
            },
            itemBuilder: (context, index) {
              final isActive = index == _currentIndex;
              return AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: isActive ? 0 : 14,
                ),
                child: AnimatedScale(
                  scale: isActive ? 1.0 : 0.94,
                  duration: const Duration(milliseconds: 250),
                  child: widget.cards[index],
                ),
              );
            },
          ),
        ),
        if (widget.showIndicator && widget.cards.length > 1) ...[
          const SizedBox(height: 8),
          dots,
        ],
      ],
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final inactive = widget.indicatorColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
    final active = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.cards.length, (i) {
        final isActive = i == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Kısa listeleme için kompakt kart (tek satır).
///
/// Solda mini kart, sağda banka adı + son 4 hane. ListView.builder
/// içinde performanslı çalışacak şekilde tasarlandı.
class BankCardListItem extends StatelessWidget {
  const BankCardListItem({
    super.key,
    required this.bankName,
    required this.last4Digits,
    this.brand,
    this.cardHolderName,
    this.trailing,
    this.onTap,
    this.miniWidth = 60,
    this.miniHeight = 38,
    this.isSelected = false,
  });

  final String bankName;
  final String last4Digits;
  final CardBrand? brand;
  final String? cardHolderName;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double miniWidth;
  final double miniHeight;

  /// Carousel'da o anda görünür olan kartı listede vurgulamak için kullanılır.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: scheme.primary, width: 1.5)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Mini kart önizleme
              SizedBox(
                width: miniWidth + 4,
                height: miniHeight + 4,
                child: BankCardWidget(
                  bankName: bankName,
                  last4Digits: last4Digits,
                  brand: brand,
                  cardHolderName: cardHolderName,
                  width: miniWidth,
                  height: miniHeight,
                  borderRadius: 8,
                  showChip: false,
                  showContactless: false,
                  showNetworkLogo: false,
                  showExpiration: false,
                  showHolderName: false,
                  showMaskedNumber: false,
                  showBankName: false,
                  showBrandBadge: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bankName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '•••• •••• •••• $last4Digits',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                            fontFamily: 'Courier',
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
