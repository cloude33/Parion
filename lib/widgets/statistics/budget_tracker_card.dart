import '../../core/design/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design/app_text_styles.dart';
import '../../models/cash_flow_data.dart';
class BudgetTrackerCard extends StatelessWidget {
  final Map<String, BudgetComparison> budgetComparisons;
  final Map<String, Color> categoryColors;
  final bool showOnlyExceeded;

  const BudgetTrackerCard({
    super.key,
    required this.budgetComparisons,
    required this.categoryColors,
    this.showOnlyExceeded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (budgetComparisons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Bütçe tanımlanmamış',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kategoriler için bütçe belirleyerek harcamalarınızı takip edebilirsiniz',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final filteredComparisons = showOnlyExceeded
        ? budgetComparisons.entries
            .where((e) => e.value.exceeded)
            .toList()
        : budgetComparisons.entries.toList();
    filteredComparisons.sort((a, b) =>
        b.value.usagePercentage.compareTo(a.value.usagePercentage));

    if (filteredComparisons.isEmpty && showOnlyExceeded) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tüm bütçeler kontrol altında!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bütçe Takibi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildOverallStatus(filteredComparisons),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ...filteredComparisons.map((entry) {
              final category = entry.key;
              final comparison = entry.value;
              final color = categoryColors[category] ?? Colors.grey;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _buildBudgetItem(
                  context,
                  theme,
                  isDark,
                  category,
                  comparison,
                  color,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatus(List<MapEntry<String, BudgetComparison>> comparisons) {
    final exceededCount = comparisons.where((e) => e.value.exceeded).length;
    final totalCount = comparisons.length;
    final onTrackCount = totalCount - exceededCount;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: exceededCount == 0
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            exceededCount == 0 ? Icons.check_circle : Icons.warning,
            size: 16,
            color: exceededCount == 0 ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$onTrackCount/$totalCount Kontrol Altında',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: exceededCount == 0 ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String category,
    BudgetComparison comparison,
    Color color,
  ) {
    final usagePercentage = comparison.usagePercentage.clamp(0.0, 100.0);
    final overBudget = comparison.exceeded;
    final statusColor = overBudget ? Colors.red : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                overBudget ? 'Aşıldı' : 'Kontrol Altında',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bütçe',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatCurrency(comparison.budget),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Harcanan',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatCurrency(comparison.actual),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: overBudget ? Colors.red : color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  overBudget ? 'Fazla' : 'Kalan',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatCurrency(comparison.remaining.abs()),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Stack(
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (usagePercentage / 100).clamp(0.0, 1.0),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: overBudget ? Colors.red : color,
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      overBudget ? Colors.red : color,
                      (overBudget ? Colors.red : color).withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 24,
              alignment: Alignment.center,
              child: Text(
                '${comparison.usagePercentage.toStringAsFixed(1)}%',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: usagePercentage > 50
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
        if (overBudget) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Bütçe ${_formatCurrency(comparison.remaining.abs())} aşıldı',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
class BudgetSummaryCard extends StatelessWidget {
  final Map<String, BudgetComparison> budgetComparisons;

  const BudgetSummaryCard({
    super.key,
    required this.budgetComparisons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (budgetComparisons.isEmpty) {
      return const SizedBox.shrink();
    }
    double totalBudget = 0;
    double totalActual = 0;
    int exceededCount = 0;

    for (var comparison in budgetComparisons.values) {
      totalBudget += comparison.budget;
      totalActual += comparison.actual;
      if (comparison.exceeded) {
        exceededCount++;
      }
    }

    final totalRemaining = totalBudget - totalActual;
    final overallUsage = totalBudget > 0 ? (totalActual / totalBudget) * 100 : 0.0;
    final onTrackCount = budgetComparisons.length - exceededCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bütçe Özeti',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Toplam Bütçe',
                    _formatCurrency(totalBudget),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSummaryItem(
                    'Harcanan',
                    _formatCurrency(totalActual),
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    totalRemaining >= 0 ? 'Kalan' : 'Fazla',
                    _formatCurrency(totalRemaining.abs()),
                    totalRemaining >= 0 ? Icons.savings : Icons.warning,
                    totalRemaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSummaryItem(
                    'Kontrol Altında',
                    '$onTrackCount/${budgetComparisons.length}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Genel Kullanım',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${overallUsage.toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: overallUsage > 100 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (overallUsage / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overallUsage > 100 ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0', 'tr_TR').format(value.abs())}';
  }
}


