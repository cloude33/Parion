import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cash_flow_data.dart';
import '../../services/statistics_service.dart';
import '../../services/data_service.dart';
import 'package:get_it/get_it.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import 'interactive_pie_chart.dart';
import 'statistics_empty_state.dart';
import 'statistics_error_state.dart';
import 'statistics_loading_state.dart';
import 'period_comparison_card.dart';
import 'budget_tracker_card.dart';
import 'spending_habits_card.dart';
import 'responsive_statistics_layout.dart';

class SpendingTab extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? categories;
  final Map<String, double>? budgets;

  const SpendingTab({
    super.key,
    required this.startDate,
    required this.endDate,
    this.categories,
    this.budgets,
  });

  @override
  State<SpendingTab> createState() => _SpendingTabState();
}

class _SpendingTabState extends State<SpendingTab> {
  final StatisticsService _statisticsService = GetIt.I<StatisticsService>();
  final DataService _dataService = GetIt.I<DataService>();
  SpendingAnalysis? _spendingData;
  SpendingAnalysis? _previousPeriodData;
  Map<String, double> _incomeByCategory = {};
  int _totalTransactionCount = 0;
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  bool _showComparison = false;
  static const Map<String, Color> categoryColors = {
    'Market': AppColors.success,
    'Restoran': AppColors.warning,
    'Ulaşım': AppColors.primary,
    'Eğlence': AppColors.primaryVariant,
    'Sağlık': AppColors.error,
    'Giyim': AppColors.expenseColor,
    'Faturalar': AppColors.primaryDark,
    'Eğitim': AppColors.secondary,
    'Diğer': AppColors.onSurface,
  };

  @override
  void initState() {
    super.initState();
    _loadSpendingData();
  }

  @override
  void didUpdateWidget(SpendingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.categories != widget.categories ||
        oldWidget.budgets != widget.budgets) {
      _loadSpendingData();
    }
  }

  Future<void> _loadSpendingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _statisticsService.analyzeSpending(
        startDate: widget.startDate,
        endDate: widget.endDate,
        categories: widget.categories,
        budgets: widget.budgets,
      );
      SpendingAnalysis? previousData;
      if (_showComparison) {
        final periodDuration = widget.endDate.difference(widget.startDate);
        final previousStartDate = widget.startDate.subtract(periodDuration);
        final previousEndDate = widget.startDate.subtract(
          const Duration(days: 1),
        );

        try {
          previousData = await _statisticsService.analyzeSpending(
            startDate: previousStartDate,
            endDate: previousEndDate,
            categories: widget.categories,
            budgets: widget.budgets,
          );
        } catch (e) {
          previousData = null;
        }
      }

      // Load income sources by category
      final allTransactions = await _dataService.getTransactions();
      final periodTransactions = allTransactions.where((t) {
        return t.date.isAfter(
              widget.startDate.subtract(const Duration(seconds: 1)),
            ) &&
            t.date.isBefore(widget.endDate.add(const Duration(days: 1)));
      }).toList();

      final incomeByCategory = <String, double>{};
      for (final t in periodTransactions) {
        if (t.type == 'income') {
          incomeByCategory[t.category] =
              (incomeByCategory[t.category] ?? 0) + t.amount;
        }
      }

      if (mounted) {
        setState(() {
          _spendingData = data;
          _previousPeriodData = previousData;
          _incomeByCategory = incomeByCategory;
          _totalTransactionCount = periodTransactions.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const StatisticsLoadingState(
        message: 'Harcama verileri yükleniyor...',
      );
    }

    if (_error != null) {
      return StatisticsErrorState(
        message: 'Veriler yüklenemedi',
        details: _error,
        onRetry: _loadSpendingData,
      );
    }

    if (_spendingData == null) {
      return StatisticsEmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Veri Bulunamadı',
        message: 'Bu dönem için harcama verisi bulunmamaktadır.',
        actionLabel: 'Harcama Ekle',
        onAction: () {},
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSpendingData,
      child: ResponsiveStatisticsLayout(
        children: [
          _buildComparisonToggle(),
          _buildSummaryCards(),
          if (_totalTransactionCount < 10) _buildInsufficientDataWarning(),
          if (_showComparison && _previousPeriodData != null)
            _buildPeriodComparison(),
          if (_spendingData!.budgetComparisons.isNotEmpty)
            BudgetSummaryCard(
              budgetComparisons: _spendingData!.budgetComparisons,
            ),
          _buildPieChartCard(),

          if (_spendingData!.budgetComparisons.isNotEmpty)
            BudgetTrackerCard(
              budgetComparisons: _spendingData!.budgetComparisons,
              categoryColors: categoryColors,
            ),
          _buildPaymentMethodCard(),
          _buildCategoryList(),
          SpendingHabitsCard(
            spendingData: _spendingData!,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
          _buildSpendingInsights(),
          _buildIncomeSourcesSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final data = _spendingData!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyAverage =
        data.totalSpending /
        (widget.endDate.difference(widget.startDate).inDays + 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceDark : AppColors.primary,
            isDark ? AppColors.primaryVariantDark : AppColors.primaryVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Toplam Harcama',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _formatCurrency(data.totalSpending),
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.onPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              _buildSummaryItem(
                'Günlük Ort.',
                _formatCurrency(dailyAverage),
                Icons.calendar_today,
                AppColors.onPrimary,
              ),
              Container(width: 1, height: 40, color: AppColors.onPrimary.withValues(alpha: 0.24)),
              _buildSummaryItem(
                'En Çok',
                data.topCategory.isNotEmpty ? data.topCategory : '-',
                Icons.star,
                AppColors.secondary,
              ),
              Container(width: 1, height: 40, color: AppColors.onPrimary.withValues(alpha: 0.24)),
              _buildSummaryItem(
                'Kategori',
                '${data.categoryBreakdown.length} Adet',
                Icons.category,
                AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.onPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    final data = _spendingData!;
    final theme = Theme.of(context);

    if (data.categoryBreakdown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Text(
            'Bu dönem için harcama bulunmamaktadır',
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    final colors = <String, Color>{};
    int colorIndex = 0;
    final defaultColors = [
      AppColors.success,
      AppColors.primary,
      AppColors.warning,
      AppColors.primaryVariant,
      AppColors.error,
      AppColors.primaryDark,
      AppColors.secondary,
      AppColors.successDark,
      AppColors.onSurface,
      AppColors.expenseColor,
    ];

    data.categoryBreakdown.forEach((category, value) {
      colors[category] =
          categoryColors[category] ??
          defaultColors[colorIndex % defaultColors.length];
      colorIndex++;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori Dağılımı',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedCategory != null)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedCategory = null),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Seçimi Kaldır'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 320,
          child: InteractivePieChart(
            data: data.categoryBreakdown,
            colors: colors,
            centerSpaceRadius: 60,
            radius: 110,
            showPercentage: true,
            enableTouch: true,
            onSectionTap: (category, value) {
              setState(() {
                _selectedCategory = _selectedCategory == category
                    ? null
                    : category;
              });
            },
          ),
        ),
        if (_selectedCategory != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildSelectedCategoryDetails(_selectedCategory!),
        ] else ...[
          const SizedBox(height: AppSpacing.xxl),
          _buildLegend(colors),
        ],
      ],
    );
  }

  Widget _buildLegend(Map<String, Color> colors) {
    final data = _spendingData!;
    final total = data.totalSpending;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: data.categoryBreakdown.entries.map((entry) {
        final category = entry.key;
        final value = entry.value;
        final percentage = total > 0 ? (value / total) * 100 : 0.0;
        final color = colors[category] ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$category (${percentage.toStringAsFixed(1)}%)',
              style: AppTextStyles.labelSmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSelectedCategoryDetails(String category) {
    final data = _spendingData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final amount = data.categoryBreakdown[category] ?? 0.0;
    final percentage = data.totalSpending > 0
        ? (amount / data.totalSpending) * 100
        : 0.0;
    final budgetComparison = data.budgetComparisons[category];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Tutar', amount, AppColors.error),
              _buildDetailItem('Oran', percentage, AppColors.primary, suffix: '%'),
              if (budgetComparison != null)
                _buildDetailItem(
                  'Bütçe',
                  budgetComparison.usagePercentage,
                  budgetComparison.exceeded ? AppColors.error : AppColors.success,
                  suffix: '%',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    double value,
    Color color, {
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          suffix != null
              ? '${value.toStringAsFixed(1)}$suffix'
              : _formatCurrency(value),
          style: AppTextStyles.labelLarge.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard() {
    final data = _spendingData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.paymentMethodBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ödeme Yöntemi Dağılımı',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            ...data.paymentMethodBreakdown.entries.map((entry) {
              final method = entry.key;
              final amount = entry.value;
              final percentage = data.totalSpending > 0
                  ? (amount / data.totalSpending) * 100
                  : 0.0;
              final methodColor = method == 'Kredi Kartı'
                  ? AppColors.primary
                  : AppColors.success;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              method == 'Kredi Kartı'
                                  ? Icons.credit_card
                                  : Icons.account_balance,
                              size: 20,
                              color: methodColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              method,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatCurrency(amount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.background,
                              valueColor: AlwaysStoppedAnimation<Color>(methodColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final data = _spendingData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }
    final sortedCategories = data.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            'Harcama Detayları',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...sortedCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          final category = categoryEntry.key;
          final amount = categoryEntry.value;
          final percentage = data.totalSpending > 0
              ? (amount / data.totalSpending) * 100
              : 0.0;

          final mainCategory = category.split(' > ')[0];
          final color =
              categoryColors[mainCategory] ??
              Colors.primaries[index % Colors.primaries.length];
          final budgetComparison = data.budgetComparisons[category];

          final Map<String, IconData> iconMap = {
            'Market': Icons.shopping_cart,
            'Restoran': Icons.restaurant,
            'Yiyecek': Icons.fastfood,
            'Ulaşım': Icons.directions_car,
            'Akaryakıt': Icons.local_gas_station,
            'Faturalar': Icons.receipt,
            'Elektrik': Icons.electric_bolt,
            'Su': Icons.water_drop,
            'Doğalgaz': Icons.fire_hydrant_alt,
            'İnternet': Icons.wifi,
            'Telefon': Icons.phone_android,
            'Kira': Icons.home,
            'Aidat': Icons.apartment,
            'Sağlık': Icons.medical_services,
            'Spor': Icons.fitness_center,
            'Eğlence': Icons.movie,
            'Giyim': Icons.checkroom,
            'Kozmetik': Icons.face,
            'Elektronik': Icons.devices,
            'Eğitim': Icons.school,
            'Hediye': Icons.card_giftcard,
            'Tatil': Icons.flight,
            'BES': Icons.savings,
            'Yatırım': Icons.trending_up,
            'Diğer': Icons.grid_view,
          };
          final IconData categoryIcon = iconMap[mainCategory] ?? Icons.category;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = _selectedCategory == category
                    ? null
                    : category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: _selectedCategory == category
                    ? color.withValues(alpha: 0.1)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: _selectedCategory == category
                    ? Border.all(color: color, width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(categoryIcon, color: color, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${percentage.toStringAsFixed(1)}% pay',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(amount),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (budgetComparison != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              budgetComparison.exceeded
                                  ? 'Bütçe Aşıldı'
                                  : 'Bütçe Uygun',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: budgetComparison.exceeded
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.background,
                      color: color,
                    ),
                  ),
                  if (_selectedCategory == category) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildSelectedCategoryDetails(category),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSpendingInsights() {
    final data = _spendingData!;
    final theme = Theme.of(context);
    const dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    final dayName = dayNames[data.mostSpendingDay.index];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Harcama Alışkanlıkları',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildInsightRow(
              icon: Icons.calendar_today,
              label: 'En Çok Harcama Yapılan Gün',
              value: dayName,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInsightRow(
              icon: Icons.access_time,
              label: 'En Çok Harcama Yapılan Saat',
              value: '${data.mostSpendingHour}:00',
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInsightRow(
              icon: Icons.trending_up,
              label: 'Günlük Ortalama Harcama',
              value: _formatCurrency(
                data.totalSpending /
                    (widget.endDate.difference(widget.startDate).inDays + 1),
              ),
              color: AppColors.primaryVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final inactiveColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 20,
                  color: _showComparison ? activeColor : inactiveColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Dönemsel Karşılaştırma',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _showComparison ? activeColor : null,
                  ),
                ),
              ],
            ),
            Switch(
              value: _showComparison,
              onChanged: (value) {
                setState(() {
                  _showComparison = value;
                });
                _loadSpendingData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodComparison() {
    if (_previousPeriodData == null) {
      return const SizedBox.shrink();
    }

    final comparisons = [
      PeriodComparisonData(
        label: 'Toplam Harcama',
        currentValue: _spendingData!.totalSpending,
        previousValue: _previousPeriodData!.totalSpending,
        icon: Icons.shopping_cart,
        color: AppColors.error,
        higherIsBetter: false,
      ),
      PeriodComparisonData(
        label: 'En Çok Harcanan Kategori',
        currentValue: _spendingData!.topCategoryAmount,
        previousValue: _previousPeriodData!.topCategoryAmount,
        icon: Icons.star,
        color: AppColors.warning,
        higherIsBetter: false,
      ),
      PeriodComparisonData(
        label: 'Kategori Sayısı',
        currentValue: _spendingData!.categoryBreakdown.length.toDouble(),
        previousValue: _previousPeriodData!.categoryBreakdown.length.toDouble(),
        icon: Icons.category,
        color: AppColors.primary,
        higherIsBetter: false,
      ),
    ];

    return PeriodComparisonList(comparisons: comparisons);
  }

  /// Yetersiz veri uyarısı (< 10 işlem) — Gereksinim 7.8
  Widget _buildInsufficientDataWarning() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Yeterli veri bulunmamaktadır. Daha doğru analiz için en az 10 işlem gereklidir. '
              'Şu an $_totalTransactionCount işlem mevcut.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gelir kaynakları dağılımı bölümü — Gereksinim 8.1–8.6
  Widget _buildIncomeSourcesSection() {
    final theme = Theme.of(context);

    // Gelir yoksa StatisticsEmptyState göster — Gereksinim 8.6
    if (_incomeByCategory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Gelir Kaynakları',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StatisticsEmptyStates.noTransactions(
            onAddTransaction: () {},
          ),
        ],
      );
    }

    // Kategorileri yüzdeye göre büyükten küçüğe sırala — Gereksinim 8.3
    final totalIncome = _incomeByCategory.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = _incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Renk paleti
    final incomeColors = [
      AppColors.success,
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.successDark,
      AppColors.incomeColor,
      AppColors.primaryVariant,
      AppColors.primaryVariantDark,
      AppColors.warning,
      AppColors.onSurface,
      AppColors.warningDark,
    ];
    final colorMap = <String, Color>{};
    for (int i = 0; i < sortedEntries.length; i++) {
      colorMap[sortedEntries[i].key] = incomeColors[i % incomeColors.length];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            'Gelir Kaynakları',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // InteractivePieChart — Gereksinim 8.1, 8.4
        Semantics(
          label: 'Gelir kaynakları pasta grafiği',
          child: SizedBox(
            height: 280,
            child: InteractivePieChart(
              data: _incomeByCategory,
              colors: colorMap,
              centerSpaceRadius: 50,
              radius: 100,
              showPercentage: true,
              enableTouch: true,
              title: null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Kategorileri yüzdeye göre sıralı liste — Gereksinim 8.2, 8.3
        ...sortedEntries.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = totalIncome > 0 ? (amount / totalIncome) * 100 : 0.0;
          final color = colorMap[category] ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    category,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _formatCurrency(amount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
