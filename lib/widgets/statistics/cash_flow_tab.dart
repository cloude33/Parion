import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../models/cash_flow_data.dart';
import '../../services/statistics_service.dart';
import 'summary_card.dart';
import 'metric_card.dart';
import 'responsive_statistics_layout.dart';
class CashFlowTab extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? walletId;
  final String? category;

  const CashFlowTab({
    super.key,
    required this.startDate,
    required this.endDate,
    this.walletId,
    this.category,
  });

  @override
  State<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends State<CashFlowTab> {
  final StatisticsService _statisticsService = GetIt.I<StatisticsService>();
  CashFlowData? _cashFlowData;
  bool _isLoading = true;
  String? _error;
  int? _selectedMonthIndex;

  @override
  void initState() {
    super.initState();
    _loadCashFlowData();
  }

  @override
  void didUpdateWidget(CashFlowTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.walletId != widget.walletId ||
        oldWidget.category != widget.category) {
      _loadCashFlowData();
    }
  }

  Future<void> _loadCashFlowData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _statisticsService.calculateCashFlow(
        startDate: widget.startDate,
        endDate: widget.endDate,
        walletId: widget.walletId,
        category: widget.category,
        includePreviousPeriod: true,
      );

      if (mounted) {
        setState(() {
          _cashFlowData = data;
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
              onPressed: _loadCashFlowData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_cashFlowData == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    return RefreshIndicator(
      onRefresh: _loadCashFlowData,
      child: ResponsiveStatisticsLayout(
        children: [
          _buildSummaryCards(),
          _buildDetailedTable(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final data = _cashFlowData!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Toplam Gelir',
                value: _formatCurrency(data.totalIncome),
                subtitle: _buildChangeText(
                  data.previousPeriodIncome,
                  data.totalIncome,
                ),
                icon: Icons.arrow_downward,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Toplam Gider',
                value: _formatCurrency(data.totalExpense),
                subtitle: _buildChangeText(
                  data.previousPeriodExpense,
                  data.totalExpense,
                ),
                icon: Icons.arrow_upward,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Net Akış',
                value: _formatCurrency(data.netCashFlow),
                change: data.changePercentage != null
                    ? '${data.changePercentage! >= 0 ? '+' : ''}${data.changePercentage!.toStringAsFixed(1)}%'
                    : null,
                trend: data.trend,
                color: data.netCashFlow >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Aylık Ortalama',
                value: _formatCurrency(data.averageMonthly),
                color: data.averageMonthly >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (data.predictedNetFlow != null) ...[
          const SizedBox(height: 12),
          _buildTrendAnalysisCard(),
        ],
      ],
    );
  }

  Widget _buildTrendAnalysisCard() {
    final data = _cashFlowData!;
    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (data.trend) {
      case TrendDirection.up:
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = 'Yükseliş Trendi';
        break;
      case TrendDirection.down:
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = 'Düşüş Trendi';
        break;
      case TrendDirection.stable:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.orange;
        trendText = 'Stabil Trend';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(trendIcon, color: trendColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  trendText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Gelecek Dönem Tahmini',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPredictionItem(
                  'Gelir',
                  data.predictedIncome!,
                  Colors.green,
                ),
                _buildPredictionItem(
                  'Gider',
                  data.predictedExpense!,
                  Colors.red,
                ),
                _buildPredictionItem(
                  'Net',
                  data.predictedNetFlow!,
                  data.predictedNetFlow! >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(String label, double value, Color color) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.auto_graph,
              size: 14,
              color: color.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              _formatCurrency(value),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedTable() {
    final data = _cashFlowData!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detaylı Aylık Dökümü',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Ay',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Gelir',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Gider',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Net',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Data rows
            ...data.monthlyData.asMap().entries.map((entry) {
              final index = entry.key;
              final monthData = entry.value;
              final isSelected = _selectedMonthIndex == index;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedMonthIndex = isSelected ? null : index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.1))
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          DateFormat('MMM yy', 'tr_TR').format(monthData.month),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCompactCurrency(monthData.income),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCompactCurrency(monthData.expense),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCompactCurrency(monthData.netFlow),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: monthData.netFlow >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            // Total row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'TOPLAM',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatCompactCurrency(data.totalIncome),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatCompactCurrency(data.totalExpense),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatCompactCurrency(data.netCashFlow),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: data.netCashFlow >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
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

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }

  String _formatCompactCurrency(double value) {
    if (value.abs() >= 1000000) {
      return '₺${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '₺${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '₺${value.toStringAsFixed(0)}';
    }
  }

  String? _buildChangeText(double? previousValue, double currentValue) {
    if (previousValue == null) return null;

    final change = currentValue - previousValue;
    final changePercent = previousValue != 0
        ? (change / previousValue.abs()) * 100
        : (currentValue != 0 ? 100.0 : 0.0);

    final sign = change >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(1)}% önceki döneme göre';
  }
}


