import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/debt.dart';
import '../../services/debt_service.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import 'statistics_loading_state.dart';
import 'statistics_empty_state.dart';
import 'statistics_error_state.dart';

/// Wrapper widget for debt statistics content.
/// Wraps the debt_statistics_screen.dart content as a StatelessWidget tab.
class DebtStatisticsTab extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const DebtStatisticsTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<DebtStatisticsTab> createState() => _DebtStatisticsTabState();
}

class _DebtStatisticsTabState extends State<DebtStatisticsTab> {
  final DebtService _debtService = DebtService();

  bool _isLoading = true;
  String? _error;
  double _totalLent = 0;
  double _totalBorrowed = 0;
  double _netBalance = 0;
  int _activeCount = 0;
  int _overdueCount = 0;
  List<Debt> _allDebts = [];
  Map<DebtCategory, double> _categoryBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void didUpdateWidget(DebtStatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadStatistics();
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lent = await _debtService.getTotalLent();
      final borrowed = await _debtService.getTotalBorrowed();
      final net = await _debtService.getNetBalance();
      final activeCount = await _debtService.getActiveCount();
      final overdueCount = await _debtService.getOverdueCount();
      final debts = await _debtService.getDebts();

      final categoryBreakdown = <DebtCategory, double>{};
      for (final debt in debts) {
        if (debt.status != DebtStatus.paid) {
          categoryBreakdown[debt.category] =
              (categoryBreakdown[debt.category] ?? 0) + debt.remainingAmount;
        }
      }

      if (mounted) {
        setState(() {
          _totalLent = lent;
          _totalBorrowed = borrowed;
          _netBalance = net;
          _activeCount = activeCount;
          _overdueCount = overdueCount;
          _allDebts = debts;
          _categoryBreakdown = categoryBreakdown;
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
        message: 'Borç/Alacak verileri yükleniyor...',
      );
    }

    if (_error != null) {
      return StatisticsErrorState(
        message: 'Veriler yüklenemedi',
        details: _error,
        onRetry: _loadStatistics,
      );
    }

    if (_allDebts.isEmpty) {
      return StatisticsEmptyState(
        icon: Icons.handshake_outlined,
        title: 'Borç/Alacak Kaydı Yok',
        message: 'Henüz borç veya alacak kaydı bulunmuyor.',
        actionLabel: 'Kayıt Ekle',
        onAction: () {},
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: AppSpacing.md),
          _buildCategoryChart(),
          const SizedBox(height: AppSpacing.md),
          _buildTopDebts(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final warningColor = isDark ? AppColors.warningDark : AppColors.warning;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Alacak',
                '₺${formatter.format(_totalLent)}',
                Icons.trending_up,
                successColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                'Toplam Borç',
                '₺${formatter.format(_totalBorrowed)}',
                Icons.trending_down,
                errorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Net Durum',
                '₺${formatter.format(_netBalance)}',
                _netBalance >= 0 ? Icons.add_circle : Icons.remove_circle,
                _netBalance >= 0 ? successColor : errorColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                'Aktif',
                '$_activeCount',
                Icons.account_balance_wallet,
                primaryColor,
              ),
            ),
          ],
        ),
        if (_overdueCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildStatCard(
            'Vadesi Geçmiş',
            '$_overdueCount',
            Icons.warning,
            warningColor,
            fullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: (fullWidth ? AppTextStyles.headlineMedium : AppTextStyles.titleLarge)
                  .copyWith(color: color),
              textAlign: TextAlign.center,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori Dağılımı',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(isDark),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLegend(isDark),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(bool isDark) {
    final total = _categoryBreakdown.values.fold<double>(0, (sum, v) => sum + v);
    final colors = _categoryColors(isDark);

    return _categoryBreakdown.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[entry.key],
        radius: 60,
        titleStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Map<DebtCategory, Color> _categoryColors(bool isDark) {
    return {
      DebtCategory.friend: isDark ? AppColors.primaryDark : AppColors.primary,
      DebtCategory.family: isDark ? AppColors.successDark : AppColors.success,
      DebtCategory.business: isDark ? AppColors.warningDark : AppColors.warning,
      DebtCategory.other: isDark ? AppColors.primaryVariantDark : AppColors.primaryVariant,
    };
  }

  Widget _buildLegend(bool isDark) {
    final colors = _categoryColors(isDark);
    final labels = {
      DebtCategory.friend: 'Arkadaş',
      DebtCategory.family: 'Aile',
      DebtCategory.business: 'İş',
      DebtCategory.other: 'Diğer',
    };

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: _categoryBreakdown.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(labels[entry.key]!, style: AppTextStyles.bodySmall),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTopDebts() {
    final sortedDebts = List<Debt>.from(_allDebts)
      ..sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    final topDebts = sortedDebts.take(5).toList();

    if (topDebts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('En Yüksek Tutarlar', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            ...topDebts.map((debt) => _buildDebtItem(debt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtItem(Debt debt) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLent = debt.type == DebtType.lent;
    final color = isLent
        ? (isDark ? AppColors.successDark : AppColors.success)
        : (isDark ? AppColors.errorDark : AppColors.error);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 20,
            child: Icon(
              isLent ? Icons.trending_up : Icons.trending_down,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.personName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  debt.categoryText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₺${formatter.format(debt.remainingAmount)}',
            style: AppTextStyles.titleMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
