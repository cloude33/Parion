import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/design/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// 5-tab bottom navigation bar for the Parion app.
///
/// Tabs: Ana Sayfa, Kredi Kartı, KMH, İstatistik, Ayarlar
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? theme.colorScheme.surface : theme.colorScheme.surface;

    final l10n = AppLocalizations.of(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: theme.unselectedWidgetColor,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.home),
          label: l10n?.home ?? 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.creditCard),
          label: l10n?.cards ?? 'Kredi Kartı',
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.landmark),
          label: 'KMH',
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.barChart2),
          label: l10n?.stats ?? 'İstatistik',
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.settings),
          label: l10n?.settings ?? 'Ayarlar',
        ),
      ],
    );
  }
}
