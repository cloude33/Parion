import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/savings_rate_trend_data.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/design/app_spacing.dart';

/// Displays the last 12 months of savings rate trend as a line chart.
///
/// - Positive rates are filled with [AppColors.success] (green)
/// - Negative rates are filled with [AppColors.error] (red)
/// - Average rate is shown as a dashed horizontal reference line
/// - Touch tooltip shows month name, income, expense, and savings rate
/// - Months with income = 0 show a "Veri Yok" label
class SavingsRateTrendChart extends StatefulWidget {
  final List<SavingsRateTrendData> trendData;

  /// Optional override for the average reference line.
  /// If null, computed from [trendData] where savingsRate != null.
  final double? averageRate;

  const SavingsRateTrendChart({
    super.key,
    required this.trendData,
    this.averageRate,
  });

  @override
  State<SavingsRateTrendChart> createState() => _SavingsRateTrendChartState();
}

class _SavingsRateTrendChartState extends State<SavingsRateTrendChart> {
  int? _touchedIndex;

  double get _computedAverage {
    if (widget.averageRate != null) return widget.averageRate!;
    final validRates = widget.trendData
        .where((d) => d.savingsRate != null)
        .map((d) => d.savingsRate!)
        .toList();
    if (validRates.isEmpty) return 0;
    return validRates.reduce((a, b) => a + b) / validRates.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build semantic description
    final validCount =
        widget.trendData.where((d) => d.savingsRate != null).length;
    final semanticLabel =
        'Tasarruf oranı trendi grafiği. ${widget.trendData.length} aylık veri, '
        '$validCount ay geçerli veri içeriyor. '
        'Ortalama tasarruf oranı: ${_computedAverage.toStringAsFixed(1)}%.';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: AppSpacing.md),
              if (widget.trendData.isEmpty)
                _buildEmptyState(theme)
              else ...[
                SizedBox(
                  height: 220,
                  child: _buildChart(theme, isDark),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildNoDataLabels(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tasarruf Oranı Trendi',
                style: AppTextStyles.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Son 12 ay',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildAverageBadge(theme),
      ],
    );
  }

  Widget _buildAverageBadge(ThemeData theme) {
    final avg = _computedAverage;
    final isPositive = avg >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 16,
            semanticLabel: isPositive ? 'Pozitif trend' : 'Negatif trend',
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Ort. ${avg.toStringAsFixed(1)}%',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Veri yok',
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds "Veri Yok" labels for months where income = 0.
  Widget _buildNoDataLabels(ThemeData theme) {
    final noDataMonths = widget.trendData
        .where((d) => d.income <= 0)
        .map((d) => DateFormat('MMM', 'tr_TR').format(d.month))
        .toList();

    if (noDataMonths.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: noDataMonths
          .map(
            (month) => Chip(
              label: Text(
                '$month: Veri Yok',
                style: AppTextStyles.labelSmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              backgroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.08),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
          .toList(),
    );
  }

  Widget _buildChart(ThemeData theme, bool isDark) {
    // Separate positive and negative spots for dual-color fill
    final positiveSpots = <FlSpot>[];
    final negativeSpots = <FlSpot>[];

    for (int i = 0; i < widget.trendData.length; i++) {
      final d = widget.trendData[i];
      if (d.savingsRate != null) {
        final spot = FlSpot(i.toDouble(), d.savingsRate!);
        if (d.savingsRate! >= 0) {
          positiveSpots.add(spot);
        } else {
          negativeSpots.add(spot);
        }
      }
    }

    // All valid spots for the main line
    final allSpots = widget.trendData
        .asMap()
        .entries
        .where((e) => e.value.savingsRate != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.savingsRate!))
        .toList();

    if (allSpots.isEmpty) return _buildEmptyState(theme);

    final yValues = allSpots.map((s) => s.y).toList();
    double minY = yValues.reduce((a, b) => a < b ? a : b);
    double maxY = yValues.reduce((a, b) => a > b ? a : b);
    final avg = _computedAverage;
    // Ensure average line is visible
    minY = [minY, avg].reduce((a, b) => a < b ? a : b);
    maxY = [maxY, avg].reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.15 : 10.0;
    minY -= padding;
    maxY += padding;

    return LineChart(
      _buildLineChartData(
        allSpots: allSpots,
        minY: minY,
        maxY: maxY,
        isDark: isDark,
        theme: theme,
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  LineChartData _buildLineChartData({
    required List<FlSpot> allSpots,
    required double minY,
    required double maxY,
    required bool isDark,
    required ThemeData theme,
  }) {
    final avg = _computedAverage;
    final gridColor =
        (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.12);

    // Build two bar data sets: positive fill (green) and negative fill (red)
    // We use a single line with two overlapping area fills clipped by y=0
    final lineBars = <LineChartBarData>[
      // Positive area fill
      LineChartBarData(
        spots: allSpots,
        isCurved: true,
        color: AppColors.success,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final isSelected = _touchedIndex == _spotOriginalIndex(spot);
            return FlDotCirclePainter(
              radius: isSelected ? 6 : 3.5,
              color: spot.y >= 0 ? AppColors.success : AppColors.error,
              strokeWidth: isSelected ? 2 : 0,
              strokeColor: isDark ? Colors.black : Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          cutOffY: 0,
          applyCutOffY: true,
          color: AppColors.success.withValues(alpha: 0.25),
        ),
        aboveBarData: BarAreaData(
          show: true,
          cutOffY: 0,
          applyCutOffY: true,
          color: AppColors.error.withValues(alpha: 0.25),
        ),
      ),
    ];

    return LineChartData(
      lineBarsData: lineBars,
      minX: 0,
      maxX: (widget.trendData.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: avg,
            color: (isDark ? Colors.white : Colors.grey[600]!)
                .withValues(alpha: 0.7),
            strokeWidth: 1.5,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: AppSpacing.xs, bottom: 2),
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
              labelResolver: (line) => 'Ort. ${avg.toStringAsFixed(1)}%',
            ),
          ),
          // Zero baseline
          HorizontalLine(
            y: 0,
            color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ],
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 5 : 10,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: gridColor, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: (maxY - minY) > 0 ? (maxY - minY) / 5 : 10,
            getTitlesWidget: (value, meta) => Text(
              '${value.toStringAsFixed(0)}%',
              style: AppTextStyles.labelSmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.trendData.length) {
                return const SizedBox.shrink();
              }
              final month = widget.trendData[index].month;
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  DateFormat('MMM', 'tr_TR').format(month),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: gridColor),
          left: BorderSide(color: gridColor),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
          setState(() {
            if (response?.lineBarSpots == null ||
                response!.lineBarSpots!.isEmpty) {
              _touchedIndex = null;
            } else {
              _touchedIndex = response.lineBarSpots!.first.x.toInt();
            }
          });
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) =>
              (Theme.of(context).brightness == Brightness.dark)
                  ? Colors.grey[850]!
                  : Colors.black87,
          tooltipBorderRadius: BorderRadius.circular(8),
          tooltipPadding: const EdgeInsets.all(AppSpacing.sm),
          getTooltipItems: (List<LineBarSpot> spots) {
            return spots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= widget.trendData.length) return null;
              final d = widget.trendData[index];
              final monthName =
                  DateFormat('MMMM yyyy', 'tr_TR').format(d.month);
              final rateText = d.savingsRate != null
                  ? '${d.savingsRate!.toStringAsFixed(1)}%'
                  : 'Veri Yok';
              final rateColor =
                  (d.savingsRate ?? 0) >= 0 ? AppColors.success : AppColors.error;
              return LineTooltipItem(
                '$monthName\n'
                'Gelir: ${_formatCurrency(d.income)}\n'
                'Gider: ${_formatCurrency(d.expense)}\n'
                'Tasarruf: $rateText',
                AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: '',
                    style: AppTextStyles.bodySmall.copyWith(color: rateColor),
                  ),
                ],
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  /// Maps a FlSpot back to its original index in trendData.
  int _spotOriginalIndex(FlSpot spot) => spot.x.toInt();

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0', 'tr_TR').format(value)}';
  }
}
