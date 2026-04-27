import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../core/design/app_colors.dart';
import 'package:parion/core/design/app_spacing.dart';
class FilterBar extends StatelessWidget {
  final String selectedTimeFilter;
  final List<String> selectedCategories;
  final List<String> selectedWallets;
  final String selectedTransactionType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final List<Category> availableCategories;
  final List<Wallet> availableWallets;
  final Function(String) onTimeFilterChanged;
  final Function(List<String>) onCategoriesChanged;
  final Function(List<String>) onWalletsChanged;
  final Function(String) onTransactionTypeChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onCustomDateRange;

  const FilterBar({
    super.key,
    required this.selectedTimeFilter,
    required this.selectedCategories,
    required this.selectedWallets,
    required this.selectedTransactionType,
    this.customStartDate,
    this.customEndDate,
    required this.availableCategories,
    required this.availableWallets,
    required this.onTimeFilterChanged,
    required this.onCategoriesChanged,
    required this.onWalletsChanged,
    required this.onTransactionTypeChanged,
    required this.onClearFilters,
    required this.onCustomDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilters = selectedCategories.isNotEmpty ||
        selectedWallets.isNotEmpty ||
        selectedTransactionType != 'all';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeFilterRow(context, isDark),
          if (hasActiveFilters || selectedCategories.isNotEmpty || selectedWallets.isNotEmpty)
            _buildAdditionalFiltersRow(context, isDark),
          _buildFilterChips(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTimeFilterRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeFilterChip(context, 'Günlük', isDark),
            const SizedBox(width: 8),
            _buildTimeFilterChip(context, 'Haftalık', isDark),
            const SizedBox(width: 8),
            _buildTimeFilterChip(context, 'Aylık', isDark),
            const SizedBox(width: 8),
            _buildTimeFilterChip(context, 'Yıllık', isDark),
            const SizedBox(width: 8),
            _buildCustomDateChip(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalFiltersRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton(
                    context,
                    icon: Icons.category,
                    label: selectedCategories.isEmpty
                        ? 'Kategori'
                        : '${selectedCategories.length} Kategori',
                    isActive: selectedCategories.isNotEmpty,
                    onTap: () => _showCategoryFilter(context),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    context,
                    icon: Icons.account_balance_wallet,
                    label: selectedWallets.isEmpty
                        ? 'Cüzdan'
                        : '${selectedWallets.length} Cüzdan',
                    isActive: selectedWallets.isNotEmpty,
                    onTap: () => _showWalletFilter(context),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    context,
                    icon: Icons.swap_vert,
                    label: _getTransactionTypeLabel(),
                    isActive: selectedTransactionType != 'all',
                    onTap: () => _showTransactionTypeFilter(context),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          if (selectedCategories.isNotEmpty ||
              selectedWallets.isNotEmpty ||
              selectedTransactionType != 'all')
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.clear_all, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Filtreler temizlendi'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  onClearFilters();
                },
                tooltip: 'Filtreleri Temizle',
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    final chips = <Widget>[];
    for (final categoryId in selectedCategories) {
      final category = availableCategories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(
          id: categoryId,
          name: categoryId,
          icon: Icons.category,
          color: AppColors.onSurface.withValues(alpha: 0.5),
          type: 'expense',
        ),
      );
      chips.add(_buildRemovableChip(
        context,
        label: category.name,
        onRemove: () {
          final updated = List<String>.from(selectedCategories)
            ..remove(categoryId);
          onCategoriesChanged(updated);
        },
        isDark: isDark,
      ));
    }
    for (final walletId in selectedWallets) {
      final wallet = availableWallets.firstWhere(
        (w) => w.id == walletId,
        orElse: () => Wallet(
          id: walletId,
          name: walletId,
          balance: 0,
          type: 'unknown',
          color: '0xFF9E9E9E',
          icon: 'wallet',
          creditLimit: 0.0,
        ),
      );
      chips.add(_buildRemovableChip(
        context,
        label: wallet.name,
        onRemove: () {
          final updated = List<String>.from(selectedWallets)..remove(walletId);
          onWalletsChanged(updated);
        },
        isDark: isDark,
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildTimeFilterChip(BuildContext context, String label, bool isDark) {
    final isSelected = selectedTimeFilter == label;
    return GestureDetector(
      onTap: () => onTimeFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.background),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.surface
                : (isDark ? AppColors.surface : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip(BuildContext context, bool isDark) {
    final isSelected = selectedTimeFilter == 'Özel';
    final dateText = customStartDate != null && customEndDate != null
        ? '${DateFormat('dd/MM').format(customStartDate!)} - ${DateFormat('dd/MM').format(customEndDate!)}'
        : 'Özel';

    return GestureDetector(
      onTap: onCustomDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.background),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: isSelected
                  ? AppColors.surface
                  : (isDark ? AppColors.surface : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              dateText,
              style: TextStyle(
                color: isSelected
                    ? AppColors.surface
                    : (isDark ? AppColors.surface : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceDark : AppColors.background),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.onSurface.withValues(alpha: 0.8) : AppColors.background),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? AppColors.primary
                  : (isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6)),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovableChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getTransactionTypeLabel() {
    switch (selectedTransactionType) {
      case 'income':
        return 'Gelir';
      case 'expense':
        return 'Gider';
      default:
        return 'Tümü';
    }
  }

  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFilterSheet(
        availableCategories: availableCategories,
        selectedCategories: selectedCategories,
        onChanged: onCategoriesChanged,
      ),
    );
  }

  void _showWalletFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WalletFilterSheet(
        availableWallets: availableWallets,
        selectedWallets: selectedWallets,
        onChanged: onWalletsChanged,
      ),
    );
  }

  void _showTransactionTypeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionTypeFilterSheet(
        selectedType: selectedTransactionType,
        onChanged: onTransactionTypeChanged,
      ),
    );
  }
}
class _CategoryFilterSheet extends StatefulWidget {
  final List<Category> availableCategories;
  final List<String> selectedCategories;
  final Function(List<String>) onChanged;

  const _CategoryFilterSheet({
    required this.availableCategories,
    required this.selectedCategories,
    required this.onChanged,
  });

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : AppColors.background!,
                ),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kategori Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempSelected.clear();
                    });
                  },
                  child: const Text('Temizle'),
                ),
                TextButton(
                  onPressed: () {
                    widget.onChanged(_tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.availableCategories.length,
              itemBuilder: (context, index) {
                final category = widget.availableCategories[index];
                final isSelected = _tempSelected.contains(category.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _tempSelected.add(category.id);
                      } else {
                        _tempSelected.remove(category.id);
                      }
                    });
                  },
                  title: Text(category.name),
                  secondary: CircleAvatar(
                    backgroundColor: category.color,
                    radius: 16,
                    child: Icon(
                      category.icon,
                      size: 16,
                      color: AppColors.surface,
                    ),
                  ),
                  activeColor: AppColors.primary,
                );
              },
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
class _WalletFilterSheet extends StatefulWidget {
  final List<Wallet> availableWallets;
  final List<String> selectedWallets;
  final Function(List<String>) onChanged;

  const _WalletFilterSheet({
    required this.availableWallets,
    required this.selectedWallets,
    required this.onChanged,
  });

  @override
  State<_WalletFilterSheet> createState() => _WalletFilterSheetState();
}

class _WalletFilterSheetState extends State<_WalletFilterSheet> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedWallets);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : AppColors.background!,
                ),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cüzdan Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempSelected.clear();
                    });
                  },
                  child: const Text('Temizle'),
                ),
                TextButton(
                  onPressed: () {
                    widget.onChanged(_tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.availableWallets.length,
              itemBuilder: (context, index) {
                final wallet = widget.availableWallets[index];
                final isSelected = _tempSelected.contains(wallet.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _tempSelected.add(wallet.id);
                      } else {
                        _tempSelected.remove(wallet.id);
                      }
                    });
                  },
                  title: Text(wallet.name),
                  subtitle: Text(_getWalletTypeLabel(wallet.type)),
                  secondary: CircleAvatar(
                    backgroundColor: Color(int.parse(wallet.color)),
                    radius: 16,
                    child: Icon(
                      _getWalletIcon(wallet.type),
                      size: 16,
                      color: AppColors.surface,
                    ),
                  ),
                  activeColor: AppColors.primary,
                );
              },
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _getWalletTypeLabel(String type) {
    switch (type) {
      case 'cash':
        return 'Nakit';
      case 'bank':
        return 'Banka Hesabı';
      case 'credit_card':
        return 'Kredi Kartı';
      default:
        return 'Diğer';
    }
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
class _TransactionTypeFilterSheet extends StatelessWidget {
  final String selectedType;
  final Function(String) onChanged;

  const _TransactionTypeFilterSheet({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : AppColors.background!,
                ),
              ),
            ),
            child: const Text(
              'İşlem Tipi Seç',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive, color: Colors.blue),
            title: const Text('Tümü'),
            trailing: selectedType == 'all'
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              onChanged('all');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.green),
            title: const Text('Gelir'),
            trailing: selectedType == 'income'
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              onChanged('income');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_down, color: Colors.red),
            title: const Text('Gider'),
            trailing: selectedType == 'expense'
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              onChanged('expense');
              Navigator.pop(context);
            },
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}


