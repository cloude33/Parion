import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/cash_flow_data.dart';
class SpendingHabitsCard extends StatefulWidget {
  final SpendingAnalysis spendingData;
  final DateTime startDate;
  final DateTime endDate;

  const SpendingHabitsCard({
    super.key,
    required this.spendingData,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<SpendingHabitsCard> createState() => _SpendingHabitsCardState();
}

class _SpendingHabitsCardState extends State<SpendingHabitsCard> {
  bool _showDayChart = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Harcama Alışkanlıkları',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Gün', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.calendar_today, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Saat', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.access_time, size: 16),
                    ),
                  ],
                  selected: {_showDayChart},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _showDayChart = selection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildKeyInsights(theme),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _showDayChart
                  ? _buildDayOfWeekChart(theme)
                  : _buildHourOfDayChart(theme),
            ),
            const SizedBox(height: 16),
            _buildAdditionalInsights(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyInsights(ThemeData theme) {
    const dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    // Calculate actual most spending day from real data
    int actualMostSpendingDayNum = 1;
    double maxDaySpending = 0;
    
    widget.spendingData.dailySpending.forEach((day, amount) {
      if (amount > maxDaySpending) {
        maxDaySpending = amount;
        actualMostSpendingDayNum = day;
      }
    });

    // Calculate actual most spending hour from real data
    int actualMostSpendingHour = 12;
    double maxHourSpending = 0;
    
    widget.spendingData.hourlySpending.forEach((hour, amount) {
      if (amount > maxHourSpending) {
        maxHourSpending = amount;
        actualMostSpendingHour = hour;
      }
    });

    // Day index is 1-7 (Monday=1), convert to 0-6 for array
    final dayIndex = (actualMostSpendingDayNum - 1).clamp(0, 6);
    final dayName = maxDaySpending > 0 ? dayNames[dayIndex] : '-';
    
    final daysDiff = widget.endDate.difference(widget.startDate).inDays + 1;
    final avgDaily = widget.spendingData.totalSpending / daysDiff;

    // Format hour display
    final hourDisplay = maxHourSpending > 0 
        ? '${actualMostSpendingHour.toString().padLeft(2, '0')}:00'
        : '-';

    return Row(
      children: [
        Expanded(
          child: _buildInsightBox(
            icon: Icons.calendar_today,
            label: 'En Çok Harcama',
            value: dayName,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightBox(
            icon: Icons.access_time,
            label: 'Yoğun Saat',
            value: hourDisplay,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightBox(
            icon: Icons.trending_up,
            label: 'Günlük Ort.',
            value: _formatCurrency(avgDaily),
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDayOfWeekChart(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    // Calculate max spenging for normalization
    double maxSpending = 0;
    for (int i = 1; i <= 7; i++) {
      final amount = widget.spendingData.dailySpending[i] ?? 0.0;
      if (amount > maxSpending) maxSpending = amount;
    }

    final barGroups = List.generate(7, (index) {
      final weekday = index + 1;
      final amount = widget.spendingData.dailySpending[weekday] ?? 0.0;
      // Normalize to 0-100 range
      final percentage = maxSpending > 0 ? (amount / maxSpending) * 100 : 0.0;
      
      final isHighest = amount == maxSpending && maxSpending > 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: percentage,
            color: isHighest ? Colors.red : Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 105,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 25 != 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dayNames.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: index + 1 == widget.spendingData.mostSpendingDay.index + 1 // Fix index comparison if needed, but simple comparison should work if enum matches 0-based index or logic
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white12 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white24 : Colors.black26,
              width: 1,
            ),
            left: BorderSide(
              color: isDark ? Colors.white24 : Colors.black26,
              width: 1,
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? Colors.grey[800]! : Colors.white,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final weekday = group.x.toInt() + 1;
              final amount = widget.spendingData.dailySpending[weekday] ?? 0.0;
              return BarTooltipItem(
                _formatCurrency(amount),
                TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHourOfDayChart(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final hourLabels = ['00', '03', '06', '09', '12', '15', '18', '21'];
    
    // Aggregate data into 3-hour buckets
    final bucketSpending = List.generate(8, (index) => 0.0);
    double maxBucketSpending = 0;
    
    for (int i = 0; i < 8; i++) {
       final startHour = i * 3;
       double sum = 0;
       for (int h = 0; h < 3; h++) {
         sum += widget.spendingData.hourlySpending[startHour + h] ?? 0.0;
       }
       bucketSpending[i] = sum;
       if (sum > maxBucketSpending) maxBucketSpending = sum;
    }

    final barGroups = List.generate(8, (index) {
      final amount = bucketSpending[index];
      // Normalize to 0-100 range
      final percentage = maxBucketSpending > 0 ? (amount / maxBucketSpending) * 100 : 0.0;
      final isHighest = amount == maxBucketSpending && maxBucketSpending > 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: percentage,
            color: isHighest ? Colors.red : Colors.orange,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 105,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 25 != 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= hourLabels.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    hourLabels[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white12 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white24 : Colors.black26,
              width: 1,
            ),
            left: BorderSide(
              color: isDark ? Colors.white24 : Colors.black26,
              width: 1,
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? Colors.grey[800]! : Colors.white,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final bucketAmount = bucketSpending[group.x.toInt()];
              return BarTooltipItem(
                _formatCurrency(bucketAmount),
                TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInsights(ThemeData theme) {
    // Calculate actual most spending hour from real data
    int actualMostSpendingHour = 12;
    double maxHourSpending = 0;
    
    widget.spendingData.hourlySpending.forEach((hour, amount) {
      if (amount > maxHourSpending) {
        maxHourSpending = amount;
        actualMostSpendingHour = hour;
      }
    });

    // Calculate actual most spending day from real data
    int actualMostSpendingDayNum = 1;
    double maxDaySpending = 0;
    
    widget.spendingData.dailySpending.forEach((day, amount) {
      if (amount > maxDaySpending) {
        maxDaySpending = amount;
        actualMostSpendingDayNum = day;
      }
    });

    // Check if there's any spending data
    final hasHourlyData = maxHourSpending > 0;
    final hasDailyData = maxDaySpending > 0;
    
    if (!hasHourlyData && !hasDailyData) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Yeterli harcama verisi bulunmamaktadır. Daha fazla işlem ekledikçe alışkanlık analizi görüntülenecektir.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }

    String timePattern;
    IconData timeIcon;
    Color timeColor;

    if (actualMostSpendingHour >= 6 && actualMostSpendingHour < 12) {
      timePattern = 'Sabah saatlerinde daha çok harcama yapıyorsunuz';
      timeIcon = Icons.wb_sunny;
      timeColor = Colors.orange;
    } else if (actualMostSpendingHour >= 12 && actualMostSpendingHour < 18) {
      timePattern = 'Öğleden sonra harcamalarınız artıyor';
      timeIcon = Icons.wb_sunny_outlined;
      timeColor = Colors.amber;
    } else if (actualMostSpendingHour >= 18 && actualMostSpendingHour < 22) {
      timePattern = 'Akşam saatlerinde daha çok harcama yapıyorsunuz';
      timeIcon = Icons.nights_stay;
      timeColor = Colors.indigo;
    } else {
      timePattern = 'Gece geç saatlerde harcama yapıyorsunuz';
      timeIcon = Icons.bedtime;
      timeColor = Colors.deepPurple;
    }
    
    String dayPattern;
    if (actualMostSpendingDayNum <= 5) {
      dayPattern = 'Hafta içi harcamalarınız daha yüksek';
    } else {
      dayPattern = 'Hafta sonu daha çok harcama yapıyorsunuz';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: timeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: timeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: timeColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Alışkanlık Analizi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: timeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasHourlyData)
            Row(
              children: [
                Icon(
                  timeIcon,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    timePattern,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          if (hasHourlyData && hasDailyData)
            const SizedBox(height: 6),
          if (hasDailyData)
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dayPattern,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0', 'tr_TR').format(value.abs())}';
  }
}


