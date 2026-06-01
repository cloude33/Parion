import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/loan.dart';
import '../models/credit_card_transaction.dart';
import '../models/asset_analysis.dart';
import '../models/comparison_data.dart';
import '../services/data_service.dart';
import '../services/statistics_service.dart';
import '../services/bill_payment_service.dart';
import '../services/bill_template_service.dart';
import '../widgets/statistics/spending_tab.dart';
import '../widgets/statistics/cash_flow_tab.dart';
import '../widgets/statistics/time_filter_bar.dart';
import '../widgets/statistics/statistics_state_builder.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_text_styles.dart';

import '../utils/cache_manager.dart';
import '../widgets/statistics/interactive_pie_chart.dart';
import '../widgets/statistics/debt_statistics_tab.dart';
import '../widgets/statistics/card_reporting_tab.dart';
import '../widgets/statistics/recurring_statistics_tab.dart';
import '../widgets/statistics/financial_health_score_card.dart';
import '../widgets/statistics/savings_rate_trend_chart.dart';
import '../widgets/statistics/budget_tracker_card.dart';
import '../widgets/statistics/period_comparison_card.dart';
import '../widgets/statistics/bill_history_summary_card.dart';
import '../widgets/statistics/statistics_loading_state.dart';
import '../widgets/statistics/statistics_empty_state.dart';
import '../widgets/statistics/statistics_error_state.dart';
import '../models/savings_rate_trend_data.dart';
import '../models/bill_history_summary.dart';
import '../models/cash_flow_data.dart' show SpendingAnalysis;
import '../widgets/statistics/kmh_dashboard.dart';
import '../widgets/statistics/kmh_asset_card.dart';
import '../widgets/statistics/net_worth_trend_chart.dart';

enum TimeFilter { daily, weekly, monthly, yearly, custom }

class StatisticsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Wallet> wallets;
  final List<Loan> loans;
  final List<CreditCardTransaction> creditCardTransactions;

  const StatisticsScreen({
    super.key,
    required this.transactions,
    required this.wallets,
    this.loans = const [],
    this.creditCardTransactions = const [],
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<bool> _tabLoaded = List.filled(7, false);
  TimeFilter _selectedTimeFilter = TimeFilter.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final String _selectedWalletId = 'all';
  final String _selectedCategory = 'all';
  final String _selectedTransactionType = 'all';

  // Sekme indeksleri
  static const int kTabSummary   = 0;
  static const int kTabSpending  = 1;
  static const int kTabCashFlow  = 2;
  static const int kTabAssets    = 3;
  static const int kTabDebt      = 4;
  static const int kTabCards     = 5;
  static const int kTabRecurring = 6;

  late final DataService _dataService;
  late final StatisticsService _statisticsService;
  List<Category> _categories = [];

  static const Map<TimeFilter, String> _timeFilterLabels = {
    TimeFilter.daily: 'Günlük',
    TimeFilter.weekly: 'Haftalık',
    TimeFilter.monthly: 'Aylık',
    TimeFilter.yearly: 'Yıllık',
    TimeFilter.custom: 'Özel',
  };

  /// Seçili zaman filtresine göre başlangıç/bitiş tarihini hesaplar
  DateTimeRange _getCurrentPeriod() {
    final now = DateTime.now();

    switch (_selectedTimeFilter) {
      case TimeFilter.daily:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case TimeFilter.weekly:
        final start = now.subtract(const Duration(days: 7));
        return DateTimeRange(start: start, end: now);
      case TimeFilter.monthly:
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
      case TimeFilter.yearly:
        final start = DateTime(now.year, 1, 1);
        return DateTimeRange(start: start, end: now);
      case TimeFilter.custom:
        final start = _customStartDate ?? DateTime(now.year, now.month, 1);
        final end = _customEndDate ?? now;
        return DateTimeRange(start: start, end: end);
    }
  }


  @override
  void initState() {
    super.initState();
    
    // Initialize services with GetIt if available, otherwise create new instances
    try {
      _dataService = GetIt.I<DataService>();
      _statisticsService = GetIt.I<StatisticsService>();
    } catch (e) {
      // If GetIt is not configured (e.g., in tests), create new instances
      _dataService = DataService();
      _statisticsService = StatisticsService();
    }
    
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    _tabLoaded[0] = true; // Özet sekmesi varsayılan olarak yüklü
    _tabController.index = 0;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = (await _dataService.getCategories()).cast<Category>();
    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
  }

  /// Sekme değiştiğinde çağrılır; ziyaret edilen sekmeyi yüklü olarak işaretler.
  void _onTabChanged() {
    final i = _tabController.index;
    if (!_tabLoaded[i]) {
      setState(() => _tabLoaded[i] = true);
    } else {
      // Sekme zaten yüklüyse sadece rebuild tetikle (UI güncellemesi için)
      setState(() {});
    }
  }

  /// Zaman filtresi değiştiğinde tüm sekmeleri sıfırlar, aktif sekmeyi hemen yükler.
  void _onFilterChanged(TimeFilter filter) {
    setState(() {
      _selectedTimeFilter = filter;
      for (int i = 0; i < _tabLoaded.length; i++) {
        _tabLoaded[i] = false;
      }
      _tabLoaded[_tabController.index] = true;
    });
  }

  /// Belirtilen sekmeyi yeniden yüklemek için sıfırlar ve bir sonraki frame'de yeniden işaretler.
  void _retryTab(int tabIndex) {
    setState(() {
      _tabLoaded[tabIndex] = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _tabLoaded[tabIndex] = true);
      }
    });
  }

  /// Pull-to-refresh: stats önbelleğini temizler ve tüm sekmeleri sıfırlar.
  Future<void> _onRefresh() async {
    CacheManager().clearPattern('stats_');
    setState(() {
      for (int i = 0; i < _tabLoaded.length; i++) {
        _tabLoaded[i] = false;
      }
      _tabLoaded[_tabController.index] = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredTransactions {
    final period = _getCurrentPeriod();
    final startDate = period.start;
    final endDate = period.end;

    final regularFiltered = widget.transactions
        .where(
          (t) =>
              t.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(endDate.add(const Duration(seconds: 1))) &&
              (_selectedWalletId == 'all' || t.walletId == _selectedWalletId) &&
              (_selectedCategory == 'all' || t.category == _selectedCategory) &&
              (_selectedTransactionType == 'all' ||
                  t.type == _selectedTransactionType),
        )
        .toList();
    final creditCardFiltered = widget.creditCardTransactions
        .where(
          (t) =>
              t.transactionDate.isAfter(
                startDate.subtract(const Duration(seconds: 1)),
              ) &&
              t.transactionDate.isBefore(
                endDate.add(const Duration(seconds: 1)),
              ) &&
              (_selectedCategory == 'all' || t.category == _selectedCategory) &&
              (_selectedWalletId == 'all' || t.cardId == _selectedWalletId),
        )
        .toList();
    return [...regularFiltered, ...creditCardFiltered];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final period = _getCurrentPeriod();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              elevation: 4,
              color: Theme.of(context).appBarTheme.backgroundColor ??
                  (isDark ? AppColors.surfaceDark : AppColors.surface),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kaydırılabilir sekme başlıkları (7 sekme) en üstte
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent, // Alt çizgiyi gizle
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppColors.onPrimary,
                      unselectedLabelColor: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
                      labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                      unselectedLabelStyle: AppTextStyles.bodySmall,
                      tabs: const [
                        Tab(text: 'Özet'),
                        Tab(text: 'Harcama'),
                        Tab(text: 'Nakit Akışı'),
                        Tab(text: 'Varlıklar'),
                        Tab(text: 'Borç/Alacak'),
                        Tab(text: 'Kartlar'),
                        Tab(text: 'Tekrarlayan'),
                      ],
                    ),
                  ),
                  // Evrensel zaman filtresi (Aşağı açılan dropdown)
                  TimeFilterBar(
                    selectedFilter: _selectedTimeFilter,
                    onFilterChanged: _onFilterChanged,
                    customStartDate: _customStartDate,
                    customEndDate: _customEndDate,
                    onStartDateChanged: (d) =>
                        setState(() => _customStartDate = d),
                    onEndDateChanged: (d) =>
                        setState(() => _customEndDate = d),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
                child: IndexedStack(
                  key: const Key('statistics_indexed_stack'),
                  index: _tabController.index,
                  children: [
                    // [0] Özet
                    _tabLoaded[kTabSummary]
                        ? _buildSummaryTab()
                        : const SizedBox.shrink(),
                    // [1] Harcama
                    _tabLoaded[kTabSpending]
                        ? SpendingTab(
                            startDate: period.start,
                            endDate: period.end,
                          )
                        : const SizedBox.shrink(),
                    // [2] Nakit Akışı
                    _tabLoaded[kTabCashFlow]
                        ? CashFlowTab(
                            startDate: period.start,
                            endDate: period.end,
                            walletId: _selectedWalletId == 'all'
                                ? null
                                : _selectedWalletId,
                            category: _selectedCategory == 'all'
                                ? null
                                : _selectedCategory,
                          )
                        : const SizedBox.shrink(),
                    // [3] Varlıklar
                    _tabLoaded[kTabAssets]
                        ? _buildAssetsTab()
                        : const SizedBox.shrink(),
                    // [4] Borç/Alacak
                    _tabLoaded[kTabDebt]
                        ? DebtStatisticsTab(
                            startDate: period.start,
                            endDate: period.end,
                          )
                        : const SizedBox.shrink(),
                    // [5] Kartlar
                    _tabLoaded[kTabCards]
                        ? CardReportingTab(
                            startDate: period.start,
                            endDate: period.end,
                          )
                        : const SizedBox.shrink(),
                    // [6] Tekrarlayan
                    _tabLoaded[kTabRecurring]
                        ? RecurringStatisticsTab(
                            startDate: period.start,
                            endDate: period.end,
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Özet sekmesi — Finansal genel bakış.
  Widget _buildSummaryTab() {
    // Compute income/expense from filtered transactions
    double income = 0;
    double expense = 0;
    for (var item in _filteredTransactions) {
      if (item is Transaction) {
        if (item.type == 'income') {
          income += item.amount;
        } else if (item.type == 'expense') {
          expense += item.amount;
        }
      } else if (item is CreditCardTransaction) {
        expense += item.amount;
      }
    }
    final netCashFlow = income - expense;
    final hasData = _filteredTransactions.isNotEmpty;

    // Build payment method distribution data
    final paymentMethodExpenses = <String, double>{};
    final paymentMethodColors = <String, Color>{};
    for (var item in _filteredTransactions) {
      if (item is Transaction && item.type == 'expense') {
        final wallet = widget.wallets.firstWhere(
          (w) => w.id == item.walletId,
          orElse: () => Wallet(
            id: '',
            name: 'Diğer',
            balance: 0,
            type: 'other',
            color: '0xFF78909C',
            icon: 'wallet',
            creditLimit: 0.0,
          ),
        );
        final walletName = wallet.name.isEmpty ? 'Diğer' : wallet.name;
        Color walletColor;
        try {
          walletColor = Color(int.parse(wallet.color));
        } catch (_) {
          walletColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
        }
        paymentMethodExpenses[walletName] =
            (paymentMethodExpenses[walletName] ?? 0) + item.amount;
        paymentMethodColors[walletName] = walletColor;
      } else if (item is CreditCardTransaction) {
        const walletName = 'Kredi Kartı';
        paymentMethodExpenses[walletName] =
            (paymentMethodExpenses[walletName] ?? 0) + item.amount;
        paymentMethodColors[walletName] = AppColors.error;
      }
    }

    // Income/debt ratio
    final creditWallets = widget.wallets.where((w) => w.type == 'credit_card');
    final totalDebt = creditWallets.fold(0.0, (sum, w) => sum + w.balance.abs());
    final debtRatio = income > 0 ? (totalDebt / income) * 100 : 0.0;

    // Previous period for comparison
    final current = _getCurrentPeriod();
    final duration = current.end.difference(current.start);
    final previousEnd = current.start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(duration);

    // Savings rate
    final savingsRate = income > 0 ? ((income - expense) / income) * 100 : null;

    // Build last 12 months savings rate trend data
    final now = DateTime.now();
    final trendData = List.generate(12, (i) {
      final month = DateTime(now.year, now.month - 11 + i, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      double monthIncome = 0;
      double monthExpense = 0;
      for (var item in widget.transactions) {
        if (item.date.isAfter(month.subtract(const Duration(seconds: 1))) &&
            item.date.isBefore(monthEnd.add(const Duration(seconds: 1)))) {
          if (item.type == 'income') {
            monthIncome += item.amount;
          } else if (item.type == 'expense') {
            monthExpense += item.amount;
          }
        }
      }
      for (var item in widget.creditCardTransactions) {
        if (item.transactionDate.isAfter(month.subtract(const Duration(seconds: 1))) &&
            item.transactionDate.isBefore(monthEnd.add(const Duration(seconds: 1)))) {
          monthExpense += item.amount;
        }
      }
      return SavingsRateTrendData.fromMonthlyData(
        month: month,
        income: monthIncome,
        expense: monthExpense,
      );
    });

    // Empty state: no transactions
    if (!hasData) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: StatisticsEmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'Veri Bulunamadı',
            message:
                'Seçilen dönemde işlem bulunmuyor. İşlem ekleyerek istatistiklerinizi görüntüleyin.',
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Summary cards: income, expense, net cash flow
            _buildSummarySectionCards(income, expense, netCashFlow, savingsRate),
            const SizedBox(height: AppSpacing.md),

            // 2. Financial Health Score Card
            StatisticsFutureBuilder<AssetAnalysis>(
              future: _statisticsService.analyzeAssets(),
              onRetry: () => _retryTab(kTabSummary),
              builder: (context, analysis) {
                return FinancialHealthScoreCard(
                  healthScore: analysis.healthScore,
                );
              },
              loadingBuilder: (context) => const StatisticsLoadingState(
                message: 'Finansal sağlık skoru hesaplanıyor...',
                showLogo: false,
              ),
              errorBuilder: (context, error) => StatisticsErrorState(
                message: 'Finansal Sağlık Skoru Yüklenemedi',
                details: error.toString(),
                onRetry: () => _retryTab(kTabSummary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Savings Rate Trend Chart
            SavingsRateTrendChart(trendData: trendData),
            const SizedBox(height: AppSpacing.md),

            // 4. Budget Tracker Card
            StatisticsFutureBuilder<SpendingAnalysis>(
              future: _statisticsService.analyzeSpending(
                startDate: current.start,
                endDate: current.end,
              ),
              onRetry: () => _retryTab(kTabSummary),
              builder: (context, spending) {
                if (spending.budgetComparisons.isEmpty) {
                  return BudgetTrackerCard(
                    budgetComparisons: const {},
                    categoryColors: const {},
                  );
                }
                final colors = <String, Color>{};
                for (final cat in spending.budgetComparisons.keys) {
                  colors[cat] = _getCategoryColor(cat);
                }
                return Column(
                  children: [
                    BudgetSummaryCard(
                      budgetComparisons: spending.budgetComparisons,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    BudgetTrackerCard(
                      budgetComparisons: spending.budgetComparisons,
                      categoryColors: colors,
                    ),
                  ],
                );
              },
              loadingBuilder: (context) => const StatisticsLoadingState(
                message: 'Bütçe verileri yükleniyor...',
                showLogo: false,
              ),
              errorBuilder: (context, error) => StatisticsErrorState(
                message: 'Bütçe Verileri Yüklenemedi',
                details: error.toString(),
                onRetry: () => _retryTab(kTabSummary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. Period Comparison Card
            StatisticsFutureBuilder<ComparisonData>(
              future: _statisticsService.comparePeriods(
                period1Start: previousStart,
                period1End: previousEnd,
                period2Start: current.start,
                period2End: current.end,
              ),
              onRetry: () => _retryTab(kTabSummary),
              builder: (context, comparison) {
                return Column(
                  children: [
                    PeriodComparisonCard(
                      title: 'Gelir Karşılaştırması',
                      currentValue: comparison.income.period2Value,
                      previousValue: comparison.income.period1Value,
                      subtitle: '${comparison.period1Label} vs ${comparison.period2Label}',
                      icon: Icons.trending_up,
                      color: AppColors.success,
                      higherIsBetter: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PeriodComparisonCard(
                      title: 'Gider Karşılaştırması',
                      currentValue: comparison.expense.period2Value,
                      previousValue: comparison.expense.period1Value,
                      subtitle: '${comparison.period1Label} vs ${comparison.period2Label}',
                      icon: Icons.trending_down,
                      color: AppColors.error,
                      higherIsBetter: false,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PeriodComparisonCard(
                      title: 'Net Nakit Akışı Karşılaştırması',
                      currentValue: comparison.netCashFlow.period2Value,
                      previousValue: comparison.netCashFlow.period1Value,
                      subtitle: '${comparison.period1Label} vs ${comparison.period2Label}',
                      icon: Icons.account_balance_wallet,
                      color: AppColors.primary,
                      higherIsBetter: true,
                    ),
                  ],
                );
              },
              loadingBuilder: (context) => const StatisticsLoadingState(
                message: 'Dönem karşılaştırması yükleniyor...',
                showLogo: false,
              ),
              errorBuilder: (context, error) => StatisticsErrorState(
                message: 'Dönem Karşılaştırması Yüklenemedi',
                details: error.toString(),
                onRetry: () => _retryTab(kTabSummary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 6. Payment method distribution pie chart
            _buildSummaryPaymentMethodCard(
              paymentMethodExpenses,
              paymentMethodColors,
            ),
            const SizedBox(height: AppSpacing.md),

            // 7. Income/Debt ratio card
            _buildSummaryIncomeDebtRatioCard(income, totalDebt, debtRatio),
            const SizedBox(height: AppSpacing.md),

            // 8. Bill History Summary Card
            _buildSummaryBillHistoryCard(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Summary section: income, expense, net cash flow, savings rate cards.
  Widget _buildSummarySectionCards(
    double income,
    double expense,
    double netCashFlow,
    double? savingsRate,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Toplam Gelir',
                amount: income,
                color: AppColors.success,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSummaryCard(
                title: 'Toplam Gider',
                amount: expense,
                color: AppColors.error,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Net Nakit Akışı',
                amount: netCashFlow,
                color: netCashFlow >= 0 ? AppColors.success : AppColors.error,
                icon: netCashFlow >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.success.withValues(alpha: 0.5)
                        : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.savings, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tasarruf Oranı',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      savingsRate != null
                          ? '%${savingsRate.toStringAsFixed(1)}'
                          : 'Veri Yok',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: savingsRate != null
                            ? (savingsRate >= 0 ? AppColors.success : AppColors.error)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Payment method distribution card for summary tab.
  Widget _buildSummaryPaymentMethodCard(
    Map<String, double> paymentMethodExpenses,
    Map<String, Color> paymentMethodColors,
  ) {
    final sortedMethods = paymentMethodExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalExpense = paymentMethodExpenses.values.fold(0.0, (s, v) => s + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_outline, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Ödeme Yöntemi Dağılımı',
                  style: AppTextStyles.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Harcamaların hangi hesaptan/karttan yapıldığı',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (sortedMethods.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: Text('Bu dönemde harcama bulunmamaktadır.')),
              )
            else ...[
              Semantics(
                label: 'Ödeme yöntemi dağılımı pasta grafiği. ${sortedMethods.length} farklı ödeme yöntemi.',
                excludeSemantics: true,
                child: SizedBox(
                  height: 220,
                  child: InteractivePieChart(
                    data: Map.fromEntries(sortedMethods),
                    colors: paymentMethodColors,
                    radius: 70,
                    centerSpaceRadius: 50,
                    enableTouch: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...sortedMethods.map((entry) {
                final percentage = totalExpense > 0
                    ? (entry.value / totalExpense) * 100
                    : 0.0;
                final color = paymentMethodColors[entry.key] ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
                        child: Text(
                          entry.key,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        '₺${NumberFormat('#,##0', 'tr_TR').format(entry.value)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '%${percentage.toStringAsFixed(1)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Income/debt ratio card for summary tab.
  Widget _buildSummaryIncomeDebtRatioCard(
    double income,
    double totalDebt,
    double debtRatio,
  ) {
    final chartValue = debtRatio > 100 ? 100.0 : debtRatio;
    final remainingValue = (100 - debtRatio) < 0 ? 0.0 : (100 - debtRatio);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.balance, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('Gelir / Borç Oranı', style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Seçili dönemdeki gelire göre toplam borç oranı',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Gelir borç oranı: %${debtRatio.toStringAsFixed(1)}. Toplam borç: ₺${NumberFormat('#,##0', 'tr_TR').format(totalDebt)}, Toplam gelir: ₺${NumberFormat('#,##0', 'tr_TR').format(income)}',
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: chartValue,
                                color: AppColors.error,
                                radius: 15,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: remainingValue > 0 ? remainingValue : 0.001,
                                color: AppColors.success.withValues(alpha: 0.3),
                                radius: 15,
                                showTitle: false,
                              ),
                            ],
                            centerSpaceRadius: 35,
                            sectionsSpace: 0,
                          ),
                        ),
                        Center(
                          child: Text(
                            '%${debtRatio.toStringAsFixed(1)}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toplam Borç',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(totalDebt)}',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Toplam Gelir',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(income)}',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  /// Bill history summary card for summary tab.
  Widget _buildSummaryBillHistoryCard() {
    final billPaymentService = BillPaymentService();
    final billTemplateService = BillTemplateService();

    return StatisticsFutureBuilder<List<BillHistorySummary>>(
      future: _loadBillHistorySummaries(billPaymentService, billTemplateService),
      onRetry: () => _retryTab(kTabSummary),
      builder: (context, summaries) {
        return BillHistorySummaryCard(
          summaries: summaries,
        );
      },
      loadingBuilder: (context) => const StatisticsLoadingState(
        message: 'Fatura geçmişi yükleniyor...',
        showLogo: false,
      ),
      errorBuilder: (context, error) => StatisticsErrorState(
        message: 'Fatura Geçmişi Yüklenemedi',
        details: error.toString(),
        onRetry: () => _retryTab(kTabSummary),
      ),
    );
  }

  /// Loads bill history summaries from bill payment and template services.
  Future<List<BillHistorySummary>> _loadBillHistorySummaries(
    BillPaymentService billPaymentService,
    BillTemplateService billTemplateService,
  ) async {
    final templates = await billTemplateService.getActiveTemplates();
    if (templates.isEmpty) return [];

    final allPayments = await billPaymentService.getPayments();
    final summaries = <BillHistorySummary>[];

    for (final template in templates) {
      final templatePayments = allPayments
          .where((p) => p.templateId == template.id)
          .toList();
      final totalPayments = templatePayments.length;
      final paidPayments = templatePayments.where((p) => p.isPaid).length;
      final paymentRate = BillHistorySummary.calculatePaymentRate(
        paidPayments,
        totalPayments,
      );

      // Last paid date
      final paidList = templatePayments
          .where((p) => p.isPaid && p.paidDate != null)
          .toList()
        ..sort((a, b) => b.paidDate!.compareTo(a.paidDate!));
      final lastPaidDate = paidList.isNotEmpty ? paidList.first.paidDate : null;

      // Next due date: earliest pending payment
      final pendingList = templatePayments
          .where((p) => !p.isPaid)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final nextDueDate = pendingList.isNotEmpty ? pendingList.first.dueDate : null;

      summaries.add(BillHistorySummary(
        templateId: template.id,
        templateName: template.name,
        category: template.category,
        totalPayments: totalPayments,
        paidPayments: paidPayments,
        paymentRate: paymentRate,
        lastPaidDate: lastPaidDate,
        nextDueDate: nextDueDate,
      ));
    }

    return summaries;
  }



  /// Varlıklar sekmesi — Net değer, cüzdanlar ve KMH hesapları.
  Widget _buildAssetsTab() {
    // Cüzdan yoksa boş durum göster (Gereksinim 11.7)
    if (widget.wallets.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: StatisticsEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cüzdan Bulunamadı',
            message:
                'Varlık analizi için henüz cüzdan eklenmemiş. Cüzdan ekleyerek varlıklarınızı takip edin.',
          ),
        ),
      );
    }

    // Varlık hesaplamaları (Gereksinim 11.1, 11.2)
    final nonCreditWallets = widget.wallets
        .where((w) => w.type != 'credit_card')
        .toList();
    final kmhWallets = nonCreditWallets.where((w) => w.isKmhAccount).toList();
    final normalWallets =
        nonCreditWallets.where((w) => !w.isKmhAccount).toList();

    final totalPositiveAssets = nonCreditWallets
        .where((w) => w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);
    final totalKmhDebt = kmhWallets
        .where((w) => w.balance < 0)
        .fold(0.0, (sum, w) => sum + w.balance.abs());
    final netAssets = totalPositiveAssets - totalKmhDebt;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Özet kartlar: toplam pozitif varlık, KMH borcu, net varlık (Gereksinim 11.2)
            _buildAssetSummaryCards(
              totalPositiveAssets: totalPositiveAssets,
              totalKmhDebt: totalKmhDebt,
              netAssets: netAssets,
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Normal cüzdanlar bölümü (Gereksinim 11.1, 11.3)
            if (normalWallets.isNotEmpty) ...[
              _buildWalletSection(
                title: 'Cüzdanlar',
                subtitle: 'Nakit ve banka hesapları',
                icon: Icons.account_balance_wallet,
                wallets: normalWallets,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 3. KMH hesapları bölümü — KmhAssetCard ile (Gereksinim 11.1, 11.4, 11.6)
            if (kmhWallets.isNotEmpty) ...[
              Semantics(
                label: 'KMH hesapları analizi. ${kmhWallets.length} hesap.',
                child: KmhAssetCard(kmhAccounts: kmhWallets),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 4. KMH Dashboard — limit kullanım yüzdesi ve faiz bilgisi (Gereksinim 11.4, 11.6)
            if (kmhWallets.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'KMH Analizi',
                            style: AppTextStyles.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Kredili mevduat hesabı detayları ve faiz bilgisi',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const SizedBox(
                        height: 400,
                        child: KmhDashboard(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 5. Net Varlık Trendi grafiği (Gereksinim 6.1, 11.5)
            StatisticsFutureBuilder<AssetAnalysis>(
              future: _statisticsService.analyzeAssets(),
              onRetry: () => _retryTab(kTabAssets),
              builder: (context, analysis) {
                if (analysis.netWorthTrend.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Semantics(
                  label:
                      'Net varlık trendi grafiği. Son 12 aya ait net varlık, toplam varlık ve borç değerleri.',
                  excludeSemantics: true,
                  child: NetWorthTrendChart(
                    trendData: analysis.netWorthTrend,
                  ),
                );
              },
              loadingBuilder: (context) => const StatisticsLoadingState(
                message: 'Net varlık trendi yükleniyor...',
                showLogo: false,
              ),
              errorBuilder: (context, error) => StatisticsErrorState(
                message: 'Net Varlık Trendi Yüklenemedi',
                details: error.toString(),
                onRetry: () => _retryTab(kTabAssets),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Varlıklar sekmesi özet kartları: toplam pozitif varlık, KMH borcu, net varlık.
  Widget _buildAssetSummaryCards({
    required double totalPositiveAssets,
    required double totalKmhDebt,
    required double netAssets,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Toplam Varlık',
                amount: totalPositiveAssets,
                color: AppColors.success,
                icon: Icons.account_balance_wallet,
                subtitle: 'Pozitif bakiyeler',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildSummaryCard(
                title: 'KMH Borcu',
                amount: totalKmhDebt,
                color: AppColors.error,
                icon: Icons.credit_card,
                subtitle: 'Toplam KMH borcu',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryCard(
          title: 'Net Varlık',
          amount: netAssets,
          color: netAssets >= 0 ? AppColors.primary : AppColors.warning,
          icon: netAssets >= 0 ? Icons.trending_up : Icons.trending_down,
          subtitle: netAssets >= 0
              ? 'Varlıklar borçlardan fazla'
              : 'Borçlar varlıklardan fazla',
        ),
      ],
    );
  }

  /// Normal cüzdanlar veya KMH hesapları için liste bölümü.
  Widget _buildWalletSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Wallet> wallets,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primaryDark : AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${wallets.length} hesap',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...wallets.map((w) => _buildWalletListItem(w, isDark)),
          ],
        ),
      ),
    );
  }

  /// Tek bir cüzdan satırı — bakiye, ikon, renk ve KMH için limit kullanım çubuğu.
  Widget _buildWalletListItem(Wallet w, bool isDark) {
    Color walletColor;
    try {
      walletColor = Color(int.parse(w.color));
    } catch (_) {
      walletColor = AppColors.primary;
    }

    final isNegative = w.balance < 0;
    final balanceColor = isNegative ? AppColors.error : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              // Cüzdan ikonu (Gereksinim 11.3)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: walletColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  w.type == 'cash'
                      ? Icons.money
                      : w.isKmhAccount
                          ? Icons.account_balance
                          : Icons.account_balance_wallet,
                  color: walletColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (w.isKmhAccount && w.creditLimit > 0)
                      Text(
                        'Limit: ₺${NumberFormat('#,##0', 'tr_TR').format(w.creditLimit)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      )
                    else
                      Text(
                        w.type == 'cash' ? 'Nakit' : 'Banka',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              // Bakiye (Gereksinim 11.3)
              Semantics(
                label:
                    '${w.name} bakiyesi: ${isNegative ? 'eksi' : ''} ${NumberFormat('#,##0', 'tr_TR').format(w.balance.abs())} lira',
                child: Text(
                  '${isNegative ? '-' : ''}₺${NumberFormat('#,##0', 'tr_TR').format(w.balance.abs())}',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
              ),
            ],
          ),
          // KMH limit kullanım çubuğu (Gereksinim 11.4)
          if (w.isKmhAccount && w.creditLimit > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Limit kullanımı',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '%${w.utilizationRate.toStringAsFixed(1)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _kmhUtilizationColor(w.utilizationRate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (w.utilizationRate / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor:
                          isDark ? AppColors.surfaceDark : AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _kmhUtilizationColor(w.utilizationRate),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: AppSpacing.md),
        ],
      ),
    );
  }

  /// KMH kullanım oranına göre renk döner.
  Color _kmhUtilizationColor(double rate) {
    if (rate <= 30) return AppColors.success;
    if (rate <= 60) return AppColors.primary;
    if (rate <= 80) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    Color color = Colors.blue,
    IconData icon = Icons.info,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : color.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    // Try to find category in loaded categories
    for (var cat in _categories) {
      if (cat.name == categoryName) {
        return cat.color;
      }
    }
    // Fallback to default categories
    for (var cat in defaultCategories) {
      if (cat.name == categoryName) {
        return cat.color;
      }
    }
    // Generate consistent color from hash
    return Colors.primaries[categoryName.hashCode % Colors.primaries.length];
  }
}
