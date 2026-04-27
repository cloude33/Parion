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
import '../utils/currency_helper.dart';
import '../widgets/statistics/spending_tab.dart';
import '../widgets/statistics/cash_flow_tab.dart';
import '../widgets/statistics/time_filter_bar.dart';
import '../widgets/statistics/responsive_statistics_layout.dart';
import '../widgets/statistics/statistics_state_builder.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_text_styles.dart';

import 'manage_goals_screen.dart';
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
  final Set<String> _expandedCategories = {};

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

  // Fatura kategorileri için renk haritası — AppColors token'larına taşındı (Gereksinim 13.6)
  final Map<String, Color> _billCategoryColors = {
    'Elektrik': AppColors.warning,
    'Doğalgaz': AppColors.primary,
    'Su': AppColors.primaryVariantDark,
    'İnternet': AppColors.primaryVariant,
    'Telefon': AppColors.success,
    'Kira': AppColors.error,
    'Aidat': AppColors.warning,
    'Sigorta': AppColors.primaryVariant,
    'Abonelik': AppColors.expenseColor,
    'Diğer': AppColors.onSurface,
  };

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

  // Eski nakit akışı grafik/tablo implementasyonu CashFlowTab ile değiştirildi.

  Widget _buildCreditTab() {
    // Kredi kartları ve taksitler "Kredi Kartlarım" ekranında takip edildiği için
    // burada sadece kişisel kredileri (Loans) gösteriyoruz.
    return ResponsiveStatisticsLayout(
      children: [
        const SizedBox(height: 16),
        _buildLoanTrackingCard(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLoanTrackingCard() {
    if (widget.loans.isEmpty) {
      return _buildEmptyState(
        'Aktif kredi bulunmuyor',
        Icons.check_circle,
        Colors.green,
      );
    }

    final activeLoans = widget.loans
        .where((l) => l.remainingAmount > 0)
        .toList();
    if (activeLoans.isEmpty) {
      return _buildEmptyState(
        'Tebrikler! Tüm krediler ödendi',
        Icons.celebration,
        Colors.amber,
      );
    }

    // İstatistikler
    final totalRemaining = activeLoans.fold(
      0.0,
      (sum, l) => sum + l.remainingAmount,
    );
    final totalMonthly = activeLoans.fold(0.0, (sum, l) {
      final next = l.installments.where((i) => !i.isPaid).firstOrNull;
      return sum + (next?.amount ?? 0);
    });

    return Column(
      children: [
        // Özet Kartı
        _buildLoanSummaryCard(totalRemaining, totalMonthly, activeLoans.length),
        const SizedBox(height: 24),

        // Liste Başlığı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Text(
                'Aktif Kredilerim',
                style: AppTextStyles.headlineMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${activeLoans.length} Adet',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Kredi Listesi
        ...activeLoans.map((loan) => _buildEnhancedLoanCard(loan)),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanSummaryCard(
    double totalDebt,
    double monthlyPayment,
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade800,
            Colors.indigo.shade600,
          ], // Premium Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam Kredi Borcu',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺${NumberFormat('#,##0', 'tr_TR').format(totalDebt)}',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.onPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: AppColors.onPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aylık Ödeme',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${NumberFormat('#,##0', 'tr_TR').format(monthlyPayment)}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.onPrimary.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kredi Sayısı',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count Adet',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLoanCard(Loan loan) {
    final progress = loan.totalAmount > 0
        ? (loan.totalAmount - loan.remainingAmount) / loan.totalAmount
        : 0.0;

    final nextInstallment = loan.installments.where((i) => !i.isPaid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final upcoming = nextInstallment.firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Kredi tipine göre ikon belirleme
    IconData loanIcon = Icons.request_quote;
    Color iconBgColor = AppColors.warning;

    final nameLower = loan.name.toLowerCase();
    if (nameLower.contains('konut') || nameLower.contains('ev')) {
      loanIcon = Icons.home;
      iconBgColor = AppColors.primaryVariant;
    } else if (nameLower.contains('taşıt') ||
        nameLower.contains('araç') ||
        nameLower.contains('araba')) {
      loanIcon = Icons.directions_car;
      iconBgColor = AppColors.primary;
    } else if (nameLower.contains('ihtiyaç')) {
      loanIcon = Icons.shopping_bag;
      iconBgColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(loanIcon, color: iconBgColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loan.bankName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₺${NumberFormat('#,##0', 'tr_TR').format(loan.remainingAmount)}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    Text(
                      'Kalan Borç',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ödenen: ${(progress * 100).toInt()}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: iconBgColor,
                      ),
                    ),
                    Text(
                      'Toplam: ₺${NumberFormat('#,##0', 'tr_TR').format(loan.totalAmount)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.background,
                    color: iconBgColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Alt Detay (Sıradaki Taksit)
          if (upcoming != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sıradaki: ${DateFormat('d MMM yyyy', 'tr_TR').format(upcoming.dueDate)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.8) : AppColors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₺${NumberFormat('#,##0', 'tr_TR').format(upcoming.amount)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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



  Widget _buildReportsView() {
    return ResponsiveStatisticsLayout(
      children: [
        _buildOverviewSummaryCards(),
        _buildBillTrackingCard(),
        _buildDebtReceivablePanel(),
        _buildPaymentMethodDistributionCard(),
        _buildFinancialHealthScoreCard(),
        _buildPeriodComparisonCard(),
        _buildGoalsSummaryCard(),
        _buildAverageComparisonCard(),
        _buildCashFlowTableCard(),
        _buildIncomeExpenseLedgerCard(),
        _buildIncomeDebtRatioCard(),
      ],
    );
  }

  Widget _buildFinancialHealthScoreCard() {
    return StatisticsFutureBuilder<AssetAnalysis>(
      future: _statisticsService.analyzeAssets(),
      builder: (context, analysis) {
        final score = analysis.healthScore;

        Color scoreColor;
        if (score.overallScore >= 80) {
          scoreColor = Colors.green;
        } else if (score.overallScore >= 60) {
          scoreColor = Colors.lightGreen;
        } else if (score.overallScore >= 40) {
          scoreColor = Colors.orange;
        } else {
          scoreColor = Colors.red;
        }

        final recommendation = score.recommendations.isNotEmpty
            ? score.recommendations.first
            : null;

        return _buildCard(
          title: 'Finansal Sağlık Skoru',
          subtitle: 'Genel durumunuzun hızlı özeti',
          content: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tooltip(
                      message:
                          'Varlık, borç, likidite ve borç yönetimi skorlarının birleşimi',
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.pinkAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '0-100 arası skor: 80+ çok iyi, 60-80 iyi, 40-60 geliştirmeye açık',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.red,
                            Colors.orange,
                            Colors.yellow,
                            Colors.lightGreen,
                            Colors.green,
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              score.overallScore.toStringAsFixed(0),
                              style: AppTextStyles.headlineMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam Varlık: ₺${NumberFormat('#,##0', 'tr_TR').format(analysis.totalAssets)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toplam Borç: ₺${NumberFormat('#,##0', 'tr_TR').format(analysis.totalLiabilities)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Net Varlık: ₺${NumberFormat('#,##0', 'tr_TR').format(analysis.netWorth)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Likidite Oranı: ${analysis.liquidityRatio.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (recommendation != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Öneri',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(recommendation, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodComparisonCard() {
    final current = _getCurrentPeriod();
    final duration = current.end.difference(current.start);
    final previousEnd = current.start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(duration);

    return StatisticsFutureBuilder<ComparisonData>(
      future: _statisticsService.comparePeriods(
        period1Start: previousStart,
        period1End: previousEnd,
        period2Start: current.start,
        period2End: current.end,
      ),
      builder: (context, comparison) {
        final income = comparison.income;
        final expense = comparison.expense;
        final net = comparison.netCashFlow;

        Widget buildMetricRow(
          String label,
          ComparisonMetric metric, {
          bool higherIsBetter = true,
        }) {
          final change = metric.percentageChange;
          final isPositive = change >= 0;
          final isGood = higherIsBetter ? isPositive : !isPositive;
          final color = isGood ? Colors.green : Colors.red;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(label, style: AppTextStyles.bodySmall),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₺${NumberFormat('#,##0', 'tr_TR').format(metric.period2Value)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}% önceki döneme göre',
                      style: AppTextStyles.labelSmall.copyWith(color: color),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return _buildCard(
          title: 'Dönem Karşılaştırması',
          subtitle: '${comparison.period1Label} vs ${comparison.period2Label}',
          content: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.compare_arrows,
                      size: 20,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seçili dönemi bir önceki eş dönemle karşılaştırır.',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildMetricRow('Gelir', income, higherIsBetter: true),
                const SizedBox(height: 8),
                buildMetricRow('Gider', expense, higherIsBetter: false),
                const SizedBox(height: 8),
                buildMetricRow('Net Nakit Akışı', net, higherIsBetter: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalsSummaryCard() {
    return StatisticsFutureBuilder<GoalComparisonSummary>(
      future: _statisticsService.compareGoals(),
      builder: (context, summary) {
        final achievedRate = summary.overallAchievementRate.toStringAsFixed(1);
        final insight = summary.insights.isNotEmpty
            ? summary.insights.first
            : null;

        return _buildCard(
          title: 'Hedef Performansı',
          subtitle: 'Biriken hedeflerinizin genel durumu',
          headerAction: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageGoalsScreen(),
                ),
              ).then((_) {
                // Clear cache to show updated data
                CacheManager().invalidateRelated('goal');
                if (mounted) {
                  setState(() {});
                }
              });
            },
            child: const Text('Yönet'),
          ),
          content: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, size: 20, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tasarruf / yatırım hedeflerinizin sayısı ve tamamlama oranı.',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam Hedef',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary.totalGoals.toString(),
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tamamlanan',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary.achievedGoals.toString(),
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geciken',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary.overdueGoals.toString(),
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Genel Tamamlama Oranı',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6)),
                    ),
                    Text(
                      '%$achievedRate',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: summary.overallAchievementRate / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  color: summary.overallAchievementRate >= 70
                      ? Colors.green
                      : (summary.overallAchievementRate >= 40
                            ? Colors.orange
                            : Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                if (insight != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Özet',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(insight, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAverageComparisonCard() {
    final current = _getCurrentPeriod();

    return StatisticsFutureBuilder<AverageComparisonData>(
      future: _statisticsService.compareWithAverages(
        currentPeriodStart: current.start,
        currentPeriodEnd: current.end,
      ),
      builder: (context, data) {
        Widget buildRow(String label, AverageBenchmark benchmark) {
          final deviation = benchmark.netFlowDeviation;
          final isPositive = deviation >= 0;
          final Color color;
          if (benchmark.performanceRating == PerformanceRating.excellent ||
              benchmark.performanceRating == PerformanceRating.good) {
            color = Colors.green;
          } else if (benchmark.performanceRating == PerformanceRating.below ||
              benchmark.performanceRating == PerformanceRating.poor) {
            color = Colors.red;
          } else {
            color = Colors.orange;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(label, style: AppTextStyles.bodyMedium),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Net: ₺${NumberFormat('#,##0', 'tr_TR').format(benchmark.currentNetFlow)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${deviation.toStringAsFixed(1)}% ortalamaya göre',
                      style: AppTextStyles.labelSmall.copyWith(color: color),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return _buildCard(
          title: 'Ortalama Karşılaştırmaları',
          subtitle: 'Seçili dönem, son 3/6/12 ay ortalamasına göre',
          content: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights, size: 20, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Net nakit akışınız, geçmiş ortalamalara göre ne durumda gösterir.',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildRow(
                  data.threeMonthBenchmark.periodLabel,
                  data.threeMonthBenchmark,
                ),
                const SizedBox(height: 6),
                buildRow(
                  data.sixMonthBenchmark.periodLabel,
                  data.sixMonthBenchmark,
                ),
                const SizedBox(height: 6),
                buildRow(
                  data.twelveMonthBenchmark.periodLabel,
                  data.twelveMonthBenchmark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebtReceivablePanel() {
    final totalLoanDebt = widget.loans.fold(
      0.0,
      (sum, loan) => sum + loan.remainingAmount,
    );
    final creditCardDebts = widget.wallets
        .where((w) => w.type == 'credit_card')
        .fold(0.0, (sum, w) => sum + w.balance.abs());
    final kmhDebts = widget.wallets
        .where((w) => w.isKmhAccount && w.balance < 0)
        .fold(0.0, (sum, w) => sum + w.balance.abs());
    final totalDebt = totalLoanDebt + creditCardDebts + kmhDebts;
    final receivableTransactions = widget.transactions
        .where(
          (t) =>
              t.category.toLowerCase().contains('alacak') ||
              t.description.toLowerCase().contains('alacak') ||
              t.category.toLowerCase().contains('receivable'),
        )
        .toList();

    final totalReceivables = receivableTransactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
    final upcomingPayments = _getUpcomingPayments();
    final upcomingReceivables = _getUpcomingReceivables();

    return _buildCard(
      title: 'Borç ve Alacak Durumu',
      subtitle: 'Finansal yükümlülükleriniz ve alacaklarınız',
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDebtReceivableSummaryItem(
                  title: 'Toplam Borç',
                  amount: totalDebt,
                  isDebt: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDebtReceivableSummaryItem(
                  title: 'Toplam Alacak',
                  amount: totalReceivables,
                  isDebt: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (totalDebt > 0) ...[
            const Text(
              'Borç Detayları',
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: 8),
            if (creditCardDebts > 0)
              _buildDebtReceivableDetailItem(
                title: 'Kredi Kartı Borçları',
                amount: creditCardDebts,
                color: Colors.red,
                icon: Icons.credit_card,
              ),
            if (totalLoanDebt > 0)
              _buildDebtReceivableDetailItem(
                title: 'Kredi Borçları',
                amount: totalLoanDebt,
                color: Colors.orange,
                icon: Icons.account_balance,
              ),
            if (kmhDebts > 0)
              _buildDebtReceivableDetailItem(
                title: 'KMH Borçları',
                amount: kmhDebts,
                color: Colors.deepOrange,
                icon: Icons.account_balance_wallet,
              ),
            const SizedBox(height: 16),
          ],
          if (upcomingPayments.isNotEmpty) ...[
            Text(
              'Yaklaşan Ödemeler (30 gün)',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...upcomingPayments
                .take(3)
                .map(
                  (payment) => _buildUpcomingItem(
                    title: payment['title'],
                    amount: payment['amount'],
                    date: payment['date'],
                    isDebt: true,
                  ),
                ),
            const SizedBox(height: 16),
          ],
          if (upcomingReceivables.isNotEmpty) ...[
            Text(
              'Yaklaşan Alacaklar (30 gün)',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...upcomingReceivables
                .take(3)
                .map(
                  (receivable) => _buildUpcomingItem(
                    title: receivable['title'],
                    amount: receivable['amount'],
                    date: receivable['date'],
                    isDebt: false,
                  ),
                ),
          ],
          if (totalDebt == 0 &&
              totalReceivables == 0 &&
              upcomingPayments.isEmpty &&
              upcomingReceivables.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Şu anda bekleyen borç veya alacak bulunmamaktadır.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebtReceivableSummaryItem({
    required String title,
    required double amount,
    required bool isDebt,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDebt ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : (isDebt
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.5)
              : (isDebt
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount.abs())}',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtReceivableDetailItem({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem({
    required String title,
    required double amount,
    required DateTime date,
    required bool isDebt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDebt ? Colors.red : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd.MM.yyyy', 'tr_TR').format(date),
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isDebt ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getUpcomingPayments() {
    final List<Map<String, dynamic>> upcomingPayments = [];
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    for (var loan in widget.loans) {
      for (var installment in loan.installments) {
        if (!installment.isPaid &&
            installment.dueDate.isAfter(now) &&
            installment.dueDate.isBefore(thirtyDaysFromNow)) {
          upcomingPayments.add({
            'title': '${loan.name} Taksiti',
            'amount': installment.amount,
            'date': installment.dueDate,
          });
        }
      }
    }
    for (var wallet in widget.wallets.where((w) => w.type == 'credit_card')) {
      final cutoffDay = wallet.cutOffDay;
      final paymentDay = wallet.paymentDay;

      if (cutoffDay > 0 && paymentDay > 0) {
        final nextPaymentDate = DateTime(now.year, now.month + 1, paymentDay);
        if (nextPaymentDate.isAfter(now) &&
            nextPaymentDate.isBefore(thirtyDaysFromNow)) {
          upcomingPayments.add({
            'title': '${wallet.name} Ödemesi',
            'amount': wallet.balance,
            'date': nextPaymentDate,
          });
        }
      }
    }
    upcomingPayments.sort((a, b) => a['date'].compareTo(b['date']));
    return upcomingPayments;
  }

  List<Map<String, dynamic>> _getUpcomingReceivables() {
    final List<Map<String, dynamic>> upcomingReceivables = [];
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    final receivableTransactions = widget.transactions
        .where(
          (t) =>
              t.category.toLowerCase().contains('alacak') ||
              t.description.toLowerCase().contains('alacak') ||
              t.category.toLowerCase().contains('receivable'),
        )
        .toList();

    for (var transaction in receivableTransactions) {
      if (transaction.date.isAfter(now) &&
          transaction.date.isBefore(thirtyDaysFromNow)) {
        upcomingReceivables.add({
          'title': transaction.description,
          'amount': transaction.amount,
          'date': transaction.date,
        });
      }
    }
    final receivableCCTransactions = widget.creditCardTransactions
        .where(
          (t) =>
              t.category.toLowerCase().contains('alacak') ||
              t.description.toLowerCase().contains('alacak') ||
              t.category.toLowerCase().contains('receivable'),
        )
        .toList();

    for (var transaction in receivableCCTransactions) {
      if (transaction.transactionDate.isAfter(now) &&
          transaction.transactionDate.isBefore(thirtyDaysFromNow)) {
        upcomingReceivables.add({
          'title': transaction.description,
          'amount': transaction.amount,
          'date': transaction.transactionDate,
        });
      }
    }
    upcomingReceivables.sort((a, b) => a['date'].compareTo(b['date']));
    return upcomingReceivables;
  }

  Widget _buildOverviewSummaryCards() {
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

    final cashFlow = income - expense;
    final expenseCategories = <String, double>{};
    for (var item in _filteredTransactions) {
      if (item is Transaction && item.type == 'expense') {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
      } else if (item is CreditCardTransaction) {
        expenseCategories[item.category] =
            (expenseCategories[item.category] ?? 0) + item.amount;
      }
    }

    final sortedCategories = expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = sortedCategories.isNotEmpty
        ? sortedCategories.first
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Genel Bakış',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seçili dönem özeti',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Toplam Gelir',
                        amount: income,
                        color: Colors.green,
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Toplam Gider',
                        amount: expense,
                        color: Colors.red,
                        icon: Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Net Bakiye',
                        amount: cashFlow,
                        color: cashFlow >= 0 ? Colors.green : Colors.red,
                        icon: cashFlow >= 0 ? Icons.add : Icons.remove,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'En Çok Harcama',
                        amount: topCategory?.value ?? 0,
                        subtitle: topCategory?.key ?? 'Yok',
                        color: Colors.blue,
                        icon: Icons.category,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget content,
    Widget? headerAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (headerAction != null) headerAction, // ignore: use_null_aware_elements
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedTimeFilter == TimeFilter.custom
                      ? '${DateFormat('dd.MM.yyyy').format(_getCurrentPeriod().start)} - ${DateFormat('dd.MM.yyyy').format(_getCurrentPeriod().end)}'
                      : (_timeFilterLabels[_selectedTimeFilter] ?? '').toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          content,
        ],
      ),
    );
  }

  Widget _buildCashFlowTableCard() {
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

    final cashFlow = income - expense;

    return _buildCard(
      title: 'Nakit Akışı Tablosu',
      subtitle: 'Çok mu fazla harcıyorum?',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Hızlı genel bakış',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Gelir',
                    textAlign: TextAlign.end,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Gider',
                    textAlign: TextAlign.end,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.red[300]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTableRow(
              'Sayım',
              _filteredTransactions
                  .where((t) => t is Transaction && t.type == 'income')
                  .length
                  .toString(),
              _filteredTransactions
                  .where(
                    (t) =>
                        (t is Transaction && t.type == 'expense') ||
                        t is CreditCardTransaction,
                  )
                  .length
                  .toString(),
            ),
            _buildTableRow(
              'Günlük Ort.',
              CurrencyHelper.formatAmountCompact(income / 30),
              CurrencyHelper.formatAmountCompact(expense / 30),
            ),
            _buildTableRow(
              'Genel Ort.',
              CurrencyHelper.formatAmountCompact(income),
              CurrencyHelper.formatAmountCompact(expense),
            ),
            _buildTableRow(
              'Toplam',
              CurrencyHelper.formatAmountCompact(income),
              CurrencyHelper.formatAmountCompact(expense),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Nakit akışı', style: AppTextStyles.bodyLarge),
                const SizedBox(width: 8),
                Text(
                  CurrencyHelper.formatAmountCompact(cashFlow),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, String col1, String col2) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              col1,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.8) : AppColors.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              col2,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseLedgerCard() {
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

    // Group expenses by main category
    final categoryTotals = <String, double>{};
    final subCategoryTotals = <String, Map<String, double>>{};
    
    for (var item in _filteredTransactions) {
      String? category;
      String? subCategory;
      double amount = 0;
      
      if (item is Transaction && item.type == 'expense') {
        category = item.category;
        subCategory = item.subCategory;
        amount = item.amount;
      } else if (item is CreditCardTransaction) {
        category = item.category;
        subCategory = item.subCategory;
        amount = item.amount;
      }
      
      if (category != null) {
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
        
        if (subCategory != null && subCategory.isNotEmpty) {
          subCategoryTotals[category] ??= {};
          subCategoryTotals[category]![subCategory] = 
              (subCategoryTotals[category]![subCategory] ?? 0) + amount;
        }
      }
    }

    // Group income by main category  
    final incomeCategoryTotals = <String, double>{};
    final incomeSubCategoryTotals = <String, Map<String, double>>{};
    
    for (var item in _filteredTransactions) {
      if (item is Transaction && item.type == 'income') {
        final category = item.category;
        final subCategory = item.subCategory;
        final amount = item.amount;
        
        incomeCategoryTotals[category] = (incomeCategoryTotals[category] ?? 0) + amount;
        
        if (subCategory != null && subCategory.isNotEmpty) {
          incomeSubCategoryTotals[category] ??= {};
          incomeSubCategoryTotals[category]![subCategory] = 
              (incomeSubCategoryTotals[category]![subCategory] ?? 0) + amount;
        }
      }
    }

    // Sort categories by total amount (descending)
    final sortedExpenseCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedIncomeCategories = incomeCategoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildCard(
      title: 'Gelir ve Gider Defteri (TRY)',
      subtitle: 'Kategorilere tıklayarak alt kategorileri görüntüleyin',
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '₺${NumberFormat('#,##0', 'tr_TR').format(income - expense)}',
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildExpandableLedgerSection(
            'Gelir', 
            income, 
            Colors.green,
            sortedIncomeCategories,
            incomeSubCategoryTotals,
            isIncome: true,
          ),
          _buildExpandableLedgerSection(
            'Gider', 
            expense, 
            Colors.red,
            sortedExpenseCategories,
            subCategoryTotals,
            isIncome: false,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableLedgerSection(
    String title,
    double total,
    Color headerColor,
    List<MapEntry<String, double>> categories,
    Map<String, Map<String, double>> subCategories, {
    required bool isIncome,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: headerColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.background : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '₺${NumberFormat('#,##0', 'tr_TR').format(total)}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
            ],
          ),
        ),
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isIncome ? 'Henüz gelir yok' : 'Henüz gider yok',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceDark.withValues(alpha: 0.5)),
            ),
          )
        else
          ...categories.map((entry) {
            final categoryName = entry.key;
            final categoryTotal = entry.value;
            final subs = subCategories[categoryName] ?? {};
            final hasSubCategories = subs.isNotEmpty;
            final isExpanded = _expandedCategories.contains(categoryName);
            final categoryColor = _getCategoryColor(categoryName);
            final percentage = total > 0 ? (categoryTotal / total * 100) : 0;

            return Column(
              children: [
                InkWell(
                  onTap: hasSubCategories
                      ? () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCategories.remove(categoryName);
                            } else {
                              _expandedCategories.add(categoryName);
                            }
                          });
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryIcon(categoryName),
                            color: categoryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      categoryName,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (hasSubCategories)
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: AppColors.onSurface.withValues(alpha: 0.5),
                                      size: 20,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: isDark 
                                            ? AppColors.surfaceDark 
                                            : AppColors.background,
                                        valueColor: AlwaysStoppedAnimation(categoryColor),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(categoryTotal)}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Subcategories (expandable)
                if (isExpanded && hasSubCategories)
                  Container(
                    color: isDark ? AppColors.surfaceDark : AppColors.background,
                    child: Column(
                      children: subs.entries.map((subEntry) {
                        final subPercentage = categoryTotal > 0 
                            ? (subEntry.value / categoryTotal * 100) 
                            : 0;
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 56, right: 16, top: 8, bottom: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  subEntry.key,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              Text(
                                '${subPercentage.toStringAsFixed(0)}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceDark.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₺${NumberFormat('#,##0', 'tr_TR').format(subEntry.value)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.8) : AppColors.surfaceDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Divider(height: 1, color: AppColors.onSurface.withValues(alpha: 0.5).withValues(alpha: 0.2)),
              ],
            );
          }),
      ],
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

  IconData _getCategoryIcon(String categoryName) {
    String searchName = categoryName;
    if (categoryName.contains(' > ')) {
      searchName = categoryName.split(' > ')[0];
    }

    if (_categories.isEmpty) {
      final cat = defaultCategories.firstWhere(
        (c) => c.name == searchName,
        orElse: () => defaultCategories.first,
      );
      return cat.icon;
    }

    final cat = _categories.firstWhere(
      (c) => c.name == searchName,
      orElse: () =>
          _categories.isNotEmpty ? _categories.first : defaultCategories.first,
    );
    return cat.icon;
  }



  Widget _buildIncomeDebtRatioCard() {
    double totalIncome = 0;
    
    // Use filtered transactions to respect the selected time period
    // Filter for regular income transactions
    totalIncome += _filteredTransactions
        .where((t) => t is Transaction && t.type == 'income')
        .fold(0.0, (sum, t) => sum + (t as Transaction).amount);

    final creditWallets = widget.wallets.where((w) => w.type == 'credit_card');
    // Debt is typically negative balance, so we take absolute value
    final totalDebt = creditWallets.fold(0.0, (sum, w) => sum + w.balance.abs());

    // Calculate ratio
    final ratio = totalIncome > 0 ? (totalDebt / totalIncome) * 100 : 0.0;
    
    // Ensure chart values are valid
    final chartValue = ratio > 100 ? 100.0 : ratio;
    final remainingValue = (100 - ratio) < 0 ? 0.0 : (100 - ratio);

    return _buildCard(
      title: 'Gelir / Borç Oranı',
      subtitle: 'Seçili dönemdeki gelire göre toplam borç oranı',
      content: Padding(
        padding: const EdgeInsets.all(24),
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
                          color: Colors.red,
                          radius: 15,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: remainingValue,
                          color: AppColors.background,
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
                      '${ratio.toStringAsFixed(1)}%',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam borçlar',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    '₺${NumberFormat('#,##0', 'tr_TR').format(totalDebt)}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toplam Gelir',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    '₺${NumberFormat('#,##0', 'tr_TR').format(totalIncome)}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
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



  Widget _buildFinancialAssetsCard() {
    final assetWallets = widget.wallets
        .where((w) => w.type != 'credit_card')
        .toList();

    // Sadece pozitif bakiyeler
    final positiveAssets = assetWallets
        .where((w) => w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);
    
    // Alt kırılımlar
    final cashAssets = assetWallets
        .where((w) => w.type == 'cash' && w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);
    
    final bankAssets = assetWallets
        .where((w) => w.type == 'bank' && w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);
    
    final otherAssets = assetWallets
        .where((w) => w.type != 'cash' && w.type != 'bank' && w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);

    final totalForChart = positiveAssets;
    
    double cashPercentage = 0;
    double bankPercentage = 0;
    double otherPercentage = 0;

    if (totalForChart > 0) {
      cashPercentage = (cashAssets / totalForChart) * 100;
      bankPercentage = (bankAssets / totalForChart) * 100;
      otherPercentage = (otherAssets / totalForChart) * 100;
    }

    return _buildCard(
      title: 'Finansal Varlıklar',
      subtitle: 'Varlık dağılımı (Sadece pozitif bakiyeler)',
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
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
                            if (cashPercentage > 0)
                              PieChartSectionData(
                                value: cashPercentage,
                                color: Colors.green,
                                radius: 15,
                                showTitle: false,
                              ),
                            if (bankPercentage > 0)
                              PieChartSectionData(
                                value: bankPercentage,
                                color: Colors.blue,
                                radius: 15,
                                showTitle: false,
                              ),
                             if (otherPercentage > 0)
                              PieChartSectionData(
                                value: otherPercentage,
                                color: Colors.orange,
                                radius: 15,
                                showTitle: false,
                              ),
                             if (totalForChart == 0)
                               PieChartSectionData(
                                 value: 100,
                                 color: AppColors.background,
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
                          '₺${NumberFormat.compact(locale: 'tr_TR').format(positiveAssets)}',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      if (cashPercentage > 0)
                        _buildLegendItem('Nakit', cashPercentage, Colors.green),
                      if (bankPercentage > 0)
                        _buildLegendItem('Banka', bankPercentage, Colors.blue),
                      if (otherPercentage > 0)
                         _buildLegendItem('Diğer', otherPercentage, Colors.orange),
                      if (totalForChart == 0)
                         Text('Varlık bulunamadı', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTimeFilter() {
    return TimeFilterBar(
      selectedFilter: _selectedTimeFilter,
      onFilterChanged: _onFilterChanged,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      onStartDateChanged: (d) => setState(() => _customStartDate = d),
      onEndDateChanged: (d) => setState(() => _customEndDate = d),
    );
  }

  void _onTimeFilterChanged(String label) {
    if (label == _timeFilterLabels[TimeFilter.custom]) {
      _selectDateRange();
      return;
    }

    final matchedEntry = _timeFilterLabels.entries.firstWhere(
      (entry) => entry.value == label,
      orElse: () => const MapEntry(TimeFilter.monthly, 'Aylık'),
    );

    setState(() {
      _selectedTimeFilter = matchedEntry.key;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedTimeFilter = TimeFilter.custom;
      });
    }
  }

  Widget _buildPaymentMethodDistributionCard() {
    final paymentMethodExpenses = <String, double>{};
    final paymentMethodColors = <String, Color>{};
    double totalExpense = 0;

    for (var item in _filteredTransactions) {
      if (item is Transaction && item.type == 'expense') {
        final wallet = widget.wallets.firstWhere(
          (w) => w.id == item.walletId,
          orElse: () => Wallet(
            id: '',
            name: 'Bilinmeyen',
            balance: 0,
            type: 'unknown',
            color: '0xFF9E9E9E',
            icon: 'money',
            creditLimit: 0.0,
          ),
        );

        final walletName = wallet.name;
        paymentMethodExpenses[walletName] =
            (paymentMethodExpenses[walletName] ?? 0) + item.amount;

        try {
          paymentMethodColors[walletName] = Color(int.parse(wallet.color));
        } catch (_) {
          paymentMethodColors[walletName] = AppColors.onSurface.withValues(alpha: 0.5);
        }

        totalExpense += item.amount;
      } else if (item is CreditCardTransaction) {
        // Kredi kartı wallet'ları cc_cardId formatında saklanıyor
        final ccWalletId = 'cc_${item.cardId}';
        var wallet = widget.wallets.firstWhere(
          (w) => w.id == ccWalletId,
          orElse: () => Wallet(
            id: '',
            name: '',
            balance: 0,
            type: 'credit_card',
            color: '0xFFF44336',
            icon: 'credit_card',
            creditLimit: 0.0,
          ),
        );

        // Eğer wallet bulunamadıysa, kredi kartı adını doğrudan CreditCardService'den al
        String walletName;
        Color walletColor;

        if (wallet.name.isEmpty) {
          // Asenkron olmayan alternatif olarak, cardId'den varsayılan isim oluştur
          // veya widget'a geçirilen creditCardTransactions'dan bilgi al
          walletName = 'Kredi Kartı';
          walletColor = Colors.red;
        } else {
          walletName = wallet.name;
          try {
            walletColor = Color(int.parse(wallet.color));
          } catch (_) {
            walletColor = Colors.red;
          }
        }

        paymentMethodExpenses[walletName] =
            (paymentMethodExpenses[walletName] ?? 0) + item.amount;
        paymentMethodColors[walletName] = walletColor;

        totalExpense += item.amount;
      }
    }

    final sortedMethods = paymentMethodExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildCard(
      title: 'Ödeme Yöntemi Dağılımı',
      subtitle: 'Harcamaların hangi hesaptan/karttan yapıldığı',
      content: Column(
        children: [
          if (sortedMethods.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu dönemde harcama bulunmamaktadır.'),
            )
          else ...[
            SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InteractivePieChart(
                  data: Map.fromEntries(sortedMethods),
                  colors: paymentMethodColors,
                  radius: 70,
                  centerSpaceRadius: 50,
                  enableTouch: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: sortedMethods.map((entry) {
                  final percentage = totalExpense > 0
                      ? (entry.value / totalExpense) * 100
                      : 0.0;
                  final color = paymentMethodColors[entry.key] ?? AppColors.onSurface.withValues(alpha: 0.5);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(entry.value)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildBillTrackingCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadBillStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildCard(
            title: 'Fatura Takibi',
            subtitle: 'Yükleniyor...',
            content: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final totalPaid = data['totalPaid'] as double;
        final totalPending = data['totalPending'] as double;
        final totalOverdue = data['totalOverdue'] as double;
        final paidCount = data['paidCount'] as int;
        final pendingCount = data['pendingCount'] as int;
        final overdueCount = data['overdueCount'] as int;
        final paymentsByCategory =
            data['paymentsByCategory'] as Map<String, double>;

        final totalAmount = totalPaid + totalPending + totalOverdue;

        if (totalAmount == 0) {
          return _buildCard(
            title: 'Fatura Takibi',
            subtitle: 'Bu dönemde fatura bulunmamaktadır',
            content: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Bu dönemde ödenen veya bekleyen fatura bulunmamaktadır.',
                style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return _buildCard(
          title: 'Kategori Bazlı Fatura Dağılımı',
          subtitle: 'Faturalarınızın kategori dağılımı',
          content: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildBillSummaryCard(
                        'Ödendi',
                        totalPaid,
                        paidCount,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBillSummaryCard(
                        'Bekliyor',
                        totalPending,
                        pendingCount,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBillSummaryCard(
                        'Gecikmiş',
                        totalOverdue,
                        overdueCount,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              if (paymentsByCategory.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InteractivePieChart(
                      data: Map.fromEntries(
                        paymentsByCategory.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)),
                      ),
                      colors: Map.fromEntries(
                        paymentsByCategory.keys.map(
                          (cat) => MapEntry(cat, _getBillCategoryColor(cat)),
                        ),
                      ),
                      radius: 70,
                      centerSpaceRadius: 50,
                      enableTouch: true,
                      onSectionTap: (category, value) {
                        _showBillCategoryDetails(category, value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: paymentsByCategory.entries.map((entry) {
                      final percentage = totalAmount > 0
                          ? (entry.value / totalAmount) * 100
                          : 0.0;
                      final color = _getBillCategoryColor(entry.key);
                      return InkWell(
                        onTap: () =>
                            _showBillCategoryDetails(entry.key, entry.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              FutureBuilder(
                                future: _dataService.getCurrentUser(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox();
                                  }
                                  return Text(
                                    CurrencyHelper.formatAmountCompact(
                                      entry.value,
                                      snapshot.data,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.onSurface.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillSummaryCard(
    String title,
    double amount,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FutureBuilder(
            future: _dataService.getCurrentUser(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return Text(
                CurrencyHelper.formatAmount(amount, snapshot.data),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            '$count adet',
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadBillStatistics() async {
    try {
      final paymentService = BillPaymentService();
      final templateService = BillTemplateService();
      final allPayments = await paymentService.getPayments();
      final now = DateTime.now();
      DateTime startDate;
      DateTime? endDate;

      switch (_selectedTimeFilter) {
        case TimeFilter.daily:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case TimeFilter.weekly:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case TimeFilter.monthly:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case TimeFilter.yearly:
          startDate = DateTime(now.year, 1, 1);
          break;
        case TimeFilter.custom:
          if (_customStartDate != null && _customEndDate != null) {
            startDate = _customStartDate!;
            endDate = _customEndDate;
          } else {
            startDate = DateTime(now.year, now.month, 1);
          }
          break;
      }

      final filteredPayments = allPayments.where((payment) {
        final paymentDate = payment.paidDate ?? payment.dueDate;
        if (endDate != null) {
          return paymentDate.isAfter(
                startDate.subtract(const Duration(seconds: 1)),
              ) &&
              paymentDate.isBefore(endDate.add(const Duration(seconds: 1)));
        }
        return paymentDate.isAfter(
          startDate.subtract(const Duration(seconds: 1)),
        );
      }).toList();
      double totalPaid = 0;
      double totalPending = 0;
      double totalOverdue = 0;
      int paidCount = 0;
      int pendingCount = 0;
      int overdueCount = 0;
      final Map<String, double> paymentsByCategory = {};
      final templates = await templateService.getTemplates();
      final templateMap = {for (var t in templates) t.id: t};

      for (var payment in filteredPayments) {
        final template = templateMap[payment.templateId];
        final categoryName = template?.categoryDisplayName ?? 'Diğer';

        if (payment.isPaid) {
          totalPaid += payment.amount;
          paidCount++;
        } else if (payment.isOverdue) {
          totalOverdue += payment.amount;
          overdueCount++;
        } else {
          totalPending += payment.amount;
          pendingCount++;
        }

        paymentsByCategory[categoryName] =
            (paymentsByCategory[categoryName] ?? 0) + payment.amount;
      }

      return {
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'totalOverdue': totalOverdue,
        'paidCount': paidCount,
        'pendingCount': pendingCount,
        'overdueCount': overdueCount,
        'paymentsByCategory': paymentsByCategory,
      };
    } catch (e) {
      return {
        'totalPaid': 0.0,
        'totalPending': 0.0,
        'totalOverdue': 0.0,
        'paidCount': 0,
        'pendingCount': 0,
        'overdueCount': 0,
        'paymentsByCategory': <String, double>{},
      };
    }
  }

  void _showBillCategoryDetails(String category, double totalAmount) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getBillCategoryColor(
                          category,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: _getBillCategoryColor(category),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FutureBuilder(
                            future: _dataService.getCurrentUser(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              return Text(
                                CurrencyHelper.formatAmount(
                                  totalAmount,
                                  snapshot.data,
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _getBillCategoryColor(category),
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu kategorideki faturalar:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Detaylı fatura listesi için Ayarlar > Faturalarım bölümünü ziyaret edin.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Fatura kategorisi için renk döndürür
  Color _getBillCategoryColor(String category) {
    // Önce tanımlı renk haritasından kontrol et
    if (_billCategoryColors.containsKey(category)) {
      return _billCategoryColors[category]!;
    }

    // Eğer tanımlı değilse, benzersiz bir renk üret
    // Ancak her zaman aynı kategori için aynı rengi üretmek için
    // hashCode kullanıyoruz ama daha geniş bir renk paleti ile
    final colorIndex = category.hashCode.abs() % 20;
    final colors = [
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF2196F3), // Blue
      const Color(0xFF03A9F4), // Light Blue
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF009688), // Teal
      const Color(0xFF4CAF50), // Green
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFCDDC39), // Lime
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFFFFC107), // Amber
      const Color(0xFFFF9800), // Orange
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE57373), // Light Red
      const Color(0xFF81C784), // Light Green
      const Color(0xFF64B5F6), // Light Blue
    ];

    return colors[colorIndex];
  }
}
