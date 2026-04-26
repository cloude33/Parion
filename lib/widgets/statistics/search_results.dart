import '../../core/design/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/credit_card_transaction.dart';
import '../../utils/currency_helper.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_text_styles.dart';
class SearchResults extends StatelessWidget {
  final List<dynamic> results;
  final String searchQuery;
  final VoidCallback? onResultTap;

  const SearchResults({
    super.key,
    required this.results,
    required this.searchQuery,
    this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    if (results.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${results.length} sonuç bulundu',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.8) : AppColors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.surfaceDark : AppColors.background,
          ),
          Expanded(
            child: ListView.separated(
              itemCount: results.length > 10 ? 10 : results.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: isDark ? AppColors.surfaceDark : AppColors.background,
              ),
              itemBuilder: (context, index) {
                final transaction = results[index];
                return _buildResultItem(context, transaction, isDark);
              },
            ),
          ),
          if (results.length > 10)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  '+${results.length - 10} daha fazla sonuç',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.onSurface.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDark ? AppColors.onSurface.withValues(alpha: 0.8) : AppColors.onSurfaceDark.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuç bulunamadı',
            style: AppTextStyles.headlineMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.8) : AppColors.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$searchQuery" için eşleşen işlem bulunamadı',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.onSurface.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context,
    dynamic transaction,
    bool isDark,
  ) {
    if (transaction is Transaction) {
      return _buildTransactionItem(context, transaction, isDark);
    } else if (transaction is CreditCardTransaction) {
      return _buildCreditCardTransactionItem(context, transaction, isDark);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Transaction transaction,
    bool isDark,
  ) {
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? Colors.green : Colors.red;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      leading: CircleAvatar(
        backgroundColor: isIncome
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          isIncome ? Icons.trending_up : Icons.trending_down,
          color: amountColor,
          size: 20,
        ),
      ),
      title: Text(
        _highlightMatch(transaction.description, searchQuery),
        style: AppTextStyles.labelLarge.copyWith(
          color: isDark ? AppColors.surface : AppColors.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            _highlightMatch(transaction.category, searchQuery),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('dd MMM yyyy', 'tr_TR').format(transaction.date),
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark ? AppColors.onSurface.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${CurrencyHelper.formatAmount(transaction.amount)}',
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
      ),
      onTap: onResultTap,
    );
  }

  Widget _buildCreditCardTransactionItem(
    BuildContext context,
    CreditCardTransaction transaction,
    bool isDark,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        child: const Icon(
          Icons.credit_card,
          color: Colors.orange,
          size: 20,
        ),
      ),
      title: Text(
        _highlightMatch(transaction.description, searchQuery),
        style: AppTextStyles.labelLarge.copyWith(
          color: isDark ? AppColors.surface : AppColors.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            _highlightMatch(transaction.category, searchQuery),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('dd MMM yyyy', 'tr_TR').format(transaction.transactionDate),
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark ? AppColors.onSurface.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      trailing: Text(
        '-${CurrencyHelper.formatAmount(transaction.amount)}',
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
      onTap: onResultTap,
    );
  }

  String _highlightMatch(String text, String query) {
    return text;
  }
}


