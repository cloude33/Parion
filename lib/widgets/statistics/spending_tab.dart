import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cash_flow_data.dart';
import '../../services/statistics_service.dart';
import 'package:get_it/get_it.dart';

import 'interactive_pie_chart.dart';

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
  SpendingAnalysis? _spendingData;
  SpendingAnalysis? _previousPeriodData;
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  bool _showComparison = false;
  static const Map<String, Color> categoryColors = {
    'Market': Color(0xFF4CAF50),
    'Restoran': Color(0xFFFF9800),
    'Ulaşım': Color(0xFF2196F3),
    'Eğlence': Color(0xFF9C27B0),
    'Sağlık': Color(0xFFF44336),
    'Giyim': Color(0xFFE91E63),
    'Faturalar': Color(0xFF00BCD4),
    'Eğitim': Color(0xFFFFEB3B),
    'Diğer': Color(0xFF607D8B),
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

      if (mounted) {
        setState(() {
          _spendingData = data;
          _previousPeriodData = previousData;
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Hata: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSpendingData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_spendingData == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    return RefreshIndicator(
      onRefresh: _loadSpendingData,
      child: ResponsiveStatisticsLayout(
        children: [
          _buildComparisonToggle(),
          _buildSummaryCards(),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1E1E24) : Colors.blue.shade800,
            isDark ? const Color(0xFF2D2D35) : Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Toplam Harcama',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(data.totalSpending),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSummaryItem(
                'Günlük Ort.',
                _formatCurrency(dailyAverage),
                Icons.calendar_today,
                Colors.white,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildSummaryItem(
                'En Çok',
                data.topCategory.isNotEmpty ? data.topCategory : '-',
                Icons.star,
                Colors.amberAccent,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildSummaryItem(
                'Kategori',
                '${data.categoryBreakdown.length} Adet',
                Icons.category,
                Colors.lightGreenAccent,
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
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
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
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Bu dönem için harcama bulunmamaktadır',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    final colors = <String, Color>{};
    int colorIndex = 0;
    final defaultColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
      const Color(0xFFE91E63),
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
        const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _buildSelectedCategoryDetails(_selectedCategory!),
        ] else ...[
          const SizedBox(height: 24),
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
        final color = colors[category] ?? Colors.grey;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$category (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 11),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Tutar', amount, Colors.red),
              _buildDetailItem('Oran', percentage, Colors.blue, suffix: '%'),
              if (budgetComparison != null)
                _buildDetailItem(
                  'Bütçe',
                  budgetComparison.usagePercentage,
                  budgetComparison.exceeded ? Colors.red : Colors.green,
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
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          suffix != null
              ? '${value.toStringAsFixed(1)}$suffix'
              : _formatCurrency(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ödeme Yöntemi Dağılımı',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...data.paymentMethodBreakdown.entries.map((entry) {
              final method = entry.key;
              final amount = entry.value;
              final percentage = data.totalSpending > 0
                  ? (amount / data.totalSpending) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
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
                              color: method == 'Kredi Kartı'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
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
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                method == 'Kredi Kartı'
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
                    color: Colors.black.withValues(alpha: 0.03),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(categoryIcon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${percentage.toStringAsFixed(1)}% pay',
                              style: TextStyle(
                                fontSize: 12,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (budgetComparison != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              budgetComparison.exceeded
                                  ? 'Bütçe Aşıldı'
                                  : 'Bütçe Uygun',
                              style: TextStyle(
                                fontSize: 11,
                                color: budgetComparison.exceeded
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      color: color,
                    ),
                  ),
                  if (_selectedCategory == category) ...[
                    const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Harcama Alışkanlıkları',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInsightRow(
              icon: Icons.calendar_today,
              label: 'En Çok Harcama Yapılan Gün',
              value: dayName,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              icon: Icons.access_time,
              label: 'En Çok Harcama Yapılan Saat',
              value: '${data.mostSpendingHour}:00',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              icon: Icons.trending_up,
              label: 'Günlük Ortalama Harcama',
              value: _formatCurrency(
                data.totalSpending /
                    (widget.endDate.difference(widget.startDate).inDays + 1),
              ),
              color: Colors.purple,
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 20,
                  color: _showComparison ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dönemsel Karşılaştırma',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _showComparison ? Colors.blue : null,
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
        color: Colors.red,
        higherIsBetter: false,
      ),
      PeriodComparisonData(
        label: 'En Çok Harcanan Kategori',
        currentValue: _spendingData!.topCategoryAmount,
        previousValue: _previousPeriodData!.topCategoryAmount,
        icon: Icons.star,
        color: Colors.orange,
        higherIsBetter: false,
      ),
      PeriodComparisonData(
        label: 'Kategori Sayısı',
        currentValue: _spendingData!.categoryBreakdown.length.toDouble(),
        previousValue: _previousPeriodData!.categoryBreakdown.length.toDouble(),
        icon: Icons.category,
        color: Colors.blue,
        higherIsBetter: false,
      ),
    ];

    return PeriodComparisonList(comparisons: comparisons);
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
