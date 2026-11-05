import 'package:flutter/material.dart' hide CardThemeData;

import '../../core/design/app_spacing.dart';
import '../../core/design/card_themes.dart';
import '../../models/card_design/card_brand.dart';
import 'bank_brand_badge.dart';
import 'bank_card_widget.dart';

/// Tema seçim diyaloğu / grid'i için kullanılan kart önizlemesi.
class BankCardThemePicker extends StatelessWidget {
  const BankCardThemePicker({
    super.key,
    required this.onSelected,
    this.selected,
  });

  final ValueChanged<CardBrand> onSelected;
  final CardBrand? selected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 350 / 220,
      ),
      itemCount: CardBrand.values.length,
      itemBuilder: (context, i) {
        final brand = CardBrand.values[i];
        final isSelected = selected == brand;
        return _PickerTile(
          brand: brand,
          isSelected: isSelected,
          onTap: () => onSelected(brand),
        );
      },
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  final CardBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2.5,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BankCardWidget(
                bankName: brand.displayName,
                last4Digits: '0000',
                brand: brand,
                cardHolderName: 'PARION DEMO',
                showDebtInfo: false,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  BankBrandBadge(brand: brand, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      brand.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
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

/// Tema seçimini tetiklemek için küçük bir chip.
class BankBrandChip extends StatelessWidget {
  const BankBrandChip({
    super.key,
    required this.brand,
    this.onTap,
    this.selected = false,
  });

  final CardBrand brand;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = CardThemeRegistry.of(brand);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? theme.gradient : null,
          color: selected ? null : theme.colors.first.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.colors.first.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card,
              size: 14,
              color: selected ? theme.textColor : theme.colors.first,
            ),
            const SizedBox(width: 4),
            Text(
              brand.displayName,
              style: TextStyle(
                color: selected ? theme.textColor : theme.colors.first,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
