import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get_it/get_it.dart';
import '../../services/recurring_transaction_service.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import 'statistics_loading_state.dart';
import 'statistics_empty_state.dart';
import 'statistics_error_state.dart';

/// Wrapper widget for recurring transaction statistics content.
/// Wraps recurring_statistics_screen.dart content as a tab widget.
class RecurringStatisticsTab extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const RecurringStatisticsTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<RecurringStatisticsTab> createState() => _RecurringStatisticsTabState();
}

class _RecurringStatisticsTabState extends State<RecurringStatisticsTab> {
  RecurringTransactionService? _service;
  bool _isLoading = true;
  String? _error;
  Map<String, double> _stats = {};
  Map<String, double> _categoryBreakdown = {};

  @override
  void initState() {
    super.initState();
    _initService();
  }

  void _initService() {
    try {
      _service = GetIt.I<RecurringTransactionService>();
    } catch (_) {
      // Service not registered; will show error state
    }
    _loadData();
  }

  @override
  void didUpdateWidget(RecurringStatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_service == null) {
        setState(() {
          _error = 'Tekrarlayan işlem servisi bulunamadı.';
          _isLoading = false;
        });
        return;
      }

      final stats = _service!.getStatistics();
      final breakdown = _service!.getCategoryBreakdown();

      setState(() {
        _stats = stats;
        _categoryBreakdown = breakdown;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const StatisticsLoadingState(
        message: 'Tekrarlayan işlemler yükleniyor...',
      );
    }

    if (_error != null) {
      return StatisticsErrorState(
        message: 'Veriler yüklenemedi',
        details: _error,
        onRetry: _loadData,
      );
    }

    final hasData = _categoryBreakdown.isNotEmpty ||
        (_stats['totalIncome'] ?? 0) > 0 ||
        (_stats['totalExpense'] ?? 0) > 0;

    if (!hasData) {
      return StatisticsEmptyState(
        icon: Icons.repeat_outlined,
        title: 'Tekrarlayan İşlem Yok',
        message:
            'Henüz tekrarlayan gelir veya gider tanımlanmamış.\nTekrarlayan işlem ekleyerek takip edin.',
        actionLabel: 'İşlem Ekle',
        onAction: () {},
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: AppSpacing.xxl),
          _buildCategoryChart(),
          const SizedBox(height: AppSpacing.xxl),
          _buildCategoryList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;
    final net = _stats['net'] ?? 0;
    final netColor = net >= 0 ? successColor : errorColor;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Gelir',
                _stats['totalIncome'] ?? 0,
                successColor,
                Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                'Toplam Gider',
                _stats['totalExpense'] ?? 0,
                errorColor,
                Icons.arrow_downward,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildStatCard(
          'Net',
          net,
          netColor,
          Icons.account_balance,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    Color color,
    IconData icon, {
    bool isWide = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${amount.toStringAsFixed(2)} ₺',
              style: (isWide
                      ? AppTextStyles.headlineLarge
                      : AppTextStyles.headlineMedium)
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total =
        _categoryBreakdown.values.fold(0.0, (sum, value) => sum + value);
    final colors = _chartColors(isDark);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori Dağılımı', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _categoryBreakdown.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final amount = entry.value.value;
                    final percentage = (amount / total * 100);

                    return PieChartSectionData(
                      value: amount,
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: colors[index % colors.length],
                      radius: 80,
                      titleStyle: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimary,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total =
        _categoryBreakdown.values.fold(0.0, (sum, value) => sum + value);
    final colors = _chartColors(isDark);

    final sortedEntries = _categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori Detayları', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final category = entry.key;
                final amount = entry.value;
                final percentage = (amount / total * 100);
                final color = colors[index % colors.length];

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
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              color: color,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${amount.toStringAsFixed(2)} ₺',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: AppTextStyles.bodySmall.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _chartColors(bool isDark) {
    return isDark
        ? [
            AppColors.primaryDark,
            AppColors.successDark,
            AppColors.warningDark,
            AppColors.primaryVariantDark,
            AppColors.errorDark,
            AppColors.primaryDark,
            AppColors.expenseColor,
            AppColors.incomeColor,
            AppColors.secondary,
            AppColors.onSurfaceDark,
          ]
        : [
            AppColors.primary,
            AppColors.success,
            AppColors.warning,
            AppColors.primaryVariant,
            AppColors.error,
            AppColors.primaryDark,
            AppColors.expenseColor,
            AppColors.incomeColor,
            AppColors.secondary,
            AppColors.onSurface,
          ];
  }
}
