import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
import '../widgets/cards/bank_card_visual_widget.dart';
import 'manage_goals_screen.dart';
import '../utils/cache_manager.dart';
import '../widgets/statistics/interactive_pie_chart.dart';

enum TimeFilter {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

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
  TimeFilter _selectedTimeFilter = TimeFilter.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final String _selectedWalletId = 'all';
  final String _selectedCategory = 'all';
  final String _selectedTransactionType = 'all';

  final DataService _dataService = DataService();
  final StatisticsService _statisticsService = StatisticsService();
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

  // Fatura kategorileri için renk haritası
  final Map<String, Color> _billCategoryColors = {
    'Elektrik': const Color(0xFFFFA726), // Turuncu
    'Doğalgaz': const Color(0xFF42A5F5), // Mavi
    'Su': const Color(0xFF26C6DA), // Açık Mavi
    'İnternet': const Color(0xFF9C27B0), // Mor
    'Telefon': const Color(0xFF66BB6A), // Yeşil
    'Kira': const Color(0xFFEF5350), // Kırmızı
    'Aidat': const Color(0xFFFF7043), // Koyu Turuncu
    'Sigorta': const Color(0xFF5C6BC0), // İndigo
    'Abonelik': const Color(0xFFEC407A), // Pembe
    'Diğer': const Color(0xFF78909C), // Gri
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
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
              t.date.isAfter(
                startDate.subtract(const Duration(seconds: 1)),
              ) &&
              t.date.isBefore(
                endDate.add(const Duration(seconds: 1)),
              ) &&
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
              (_selectedCategory == 'all' || t.category == _selectedCategory),
        )
        .toList();
    return [...regularFiltered, ...creditCardFiltered];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: _buildHeaderTimeFilter(),
                  ),
                  AdaptiveTabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Raporlar'),
                      Tab(text: 'Harcama'),
                      Tab(text: 'Kredi'),
                      Tab(text: 'Nakit Akışı'),
                      Tab(text: 'Varlıklar'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReportsView(),
                  _buildSpendingTab(),
                  _buildCreditTab(),
                  _buildCashFlowTab(),
                  _buildAssetsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowTab() {
    final period = _getCurrentPeriod();

    return CashFlowTab(
      startDate: period.start,
      endDate: period.end,
      walletId: _selectedWalletId == 'all' ? null : _selectedWalletId,
      category: _selectedCategory == 'all' ? null : _selectedCategory,
    );
  }

  // Eski nakit akışı grafik/tablo implementasyonu CashFlowTab ile değiştirildi.

  Widget _buildSpendingTab() {
    final period = _getCurrentPeriod();

    return SpendingTab(
      startDate: period.start,
      endDate: period.end,
    );
  }

  Widget _buildCreditTab() {
    final creditWallets = widget.wallets
        .where((w) => w.type == 'credit_card')
        .toList();
    
    final totalDebt = creditWallets.fold(0.0, (sum, w) => sum + (w.balance < 0 ? w.balance.abs() : 0));
    final totalLimit = creditWallets.fold(0.0, (sum, w) => sum + w.creditLimit);
    final totalAvailable = totalLimit - totalDebt;
    final utilization = totalLimit > 0 ? (totalDebt / totalLimit) * 100 : 0.0;

    final installmentTransactions = widget.transactions
        .where((t) => t.installments != null)
        .toList();

    return ResponsiveStatisticsLayout(
      children: [
        // Üst Özet Kartları
        Row(
          children: [
            Expanded(
              child: _buildSummaryInfoCard(
                title: 'Toplam Borç',
                amount: totalDebt,
                color: Colors.red,
                icon: Icons.money_off,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryInfoCard(
                title: 'Kullanılabilir',
                amount: totalAvailable,
                color: Colors.green,
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildUtilizationBar(utilization),
        
        const SizedBox(height: 24),
        
        // Kartlarım Başlığı ve Kart Listesi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kartlarım',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
               Text(
                '${creditWallets.length} Kart',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: creditWallets.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildCreditCardWidget(creditWallets[index]),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Kredi ve Taksitler
        _buildLoanTrackingCard(),
        
        if (installmentTransactions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInstallmentsListCard(installmentTransactions),
        ],
        
        const SizedBox(height: 80), // Bottom padding
      ],
    );
  }

  Widget _buildSummaryInfoCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilizationBar(double percentage) {
    // 0-30% Green, 30-70% Orange, 70%+ Red
    Color color = Colors.green;
    if (percentage > 70) {
      color = Colors.red;
    } else if (percentage > 30) {
      color = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Limit Doluluk Oranı',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              '%${percentage.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardWidget(Wallet wallet) {
    return SizedBox(
      width: 300,
      child: BankCardVisualWidget(
        bankName: wallet.bankName ?? '',
        cardName: wallet.name,
        last4Digits: wallet.id.length >= 4 ? wallet.id.substring(wallet.id.length - 4) : '****',
        currentDebt: wallet.balance.abs(),
        limit: wallet.creditLimit,
        colorHex: wallet.color,
        cutOffDay: wallet.cutOffDay,
        paymentDay: wallet.paymentDay,
      ),
    );
  }

  Widget _buildInstallmentsListCard(List<Transaction> installments) {
    return _buildCard(
      title: 'Taksitli İşlemler',
      subtitle: '${installments.length} adet aktif taksit',
      content: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: installments.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final t = installments[index];
          final progress = t.currentInstallment! / t.installments!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.calendar_month, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.grey[200],
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.currentInstallment}/${t.installments} Taksit ödendi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-₺${NumberFormat('#,##0', 'tr_TR').format(t.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      'Aylık',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoanTrackingCard() {
    if (widget.loans.isEmpty) {
      return _buildCard(
        title: 'Krediler',
        subtitle: 'Aktif kredi bulunmuyor',
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Harika! Aktif bir kredi borcunuz bulunmuyor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final activeLoans = widget.loans
        .where((loan) => loan.remainingAmount > 0)
        .toList();

    if (activeLoans.isEmpty) {
       return _buildCard(
        title: 'Krediler',
        subtitle: 'Tümü ödendi',
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.celebration, size: 48, color: Colors.amber.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Tebrikler! Tüm kredilerinizi ödediniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Aktif Krediler',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...activeLoans.map((loan) {
          final progress = loan.totalAmount > 0
              ? (loan.totalAmount - loan.remainingAmount) / loan.totalAmount
              : 0.0;
          
          final nextInstallment = loan.installments
              .where((i) => !i.isPaid)
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
            
          final upcoming = nextInstallment.firstOrNull;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.indigo),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              loan.bankName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Kalan',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '₺${NumberFormat('#,##0', 'tr_TR').format(loan.remainingAmount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ödeme İlerlemesi',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '%${(progress * 100).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          color: progress > 0.8 ? Colors.green : Colors.indigo,
                        ),
                      ),
                      if (upcoming != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sonraki Taksit: ${DateFormat('dd MMM', 'tr_TR').format(upcoming.dueDate)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₺${NumberFormat('#,##0', 'tr_TR').format(upcoming.amount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }



  Widget _buildAssetsTab() {
    final assetWallets = widget.wallets
        .where((w) => w.type != 'credit_card')
        .toList();
    final kmhWallets = assetWallets.where((w) => w.isKmhAccount).toList();
    final totalPositiveAssets = assetWallets
        .where((w) => w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);
    final totalKmhDebt = kmhWallets
        .where((w) => w.balance < 0)
        .fold(0.0, (sum, w) => sum + w.balance.abs());
    final totalAssets = totalPositiveAssets - totalKmhDebt;
    final totalForChart = assetWallets.fold(
      0.0,
      (sum, w) => sum + w.balance.abs(),
    );

    return ResponsiveStatisticsLayout(
      children: [
        if (kmhWallets.isNotEmpty) _buildKmhUsageChart(kmhWallets),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: totalForChart > 0
              ? PieChart(
                  PieChartData(
                    sections: assetWallets.map((w) {
                      final percentage =
                          (w.balance.abs() / totalForChart) * 100;
                      final color = Color(int.parse(w.color));
                      return PieChartSectionData(
                        color: color,
                        value: percentage,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const Center(child: Text('Varlık yok')),
        ),
        _buildCard(
          title: 'Varlık Listesi',
          subtitle:
              'Net Toplam: ₺${NumberFormat('#,##0', 'tr_TR').format(totalAssets)}',
          content: Column(
            children: [
              ...assetWallets
                  .where((w) => w.balance >= 0)
                  .map(
                    (w) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(int.parse(w.color)),
                        child: Icon(
                          w.type == 'cash'
                              ? Icons.money
                              : Icons.account_balance,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(w.name),
                      subtitle: w.isKmhAccount
                          ? Text(
                              'KMH - Limit: ₺${NumberFormat('#,##0', 'tr_TR').format(w.creditLimit)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                      trailing: Text(
                        '₺${NumberFormat('#,##0', 'tr_TR').format(w.balance)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
              if (totalKmhDebt > 0) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'KMH Borçları',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                ...kmhWallets
                    .where((w) => w.balance < 0)
                    .map(
                      (w) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: const Icon(
                            Icons.account_balance,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(w.name),
                        subtitle: Text(
                          'KMH Borcu - Limit: ₺${NumberFormat('#,##0', 'tr_TR').format(w.creditLimit)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Text(
                          '-₺${NumberFormat('#,##0', 'tr_TR').format(w.balance.abs())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKmhUsageChart(List<Wallet> kmhWallets) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalUsed = kmhWallets.fold(0.0, (sum, w) => sum + w.usedCredit);
    final totalLimit = kmhWallets.fold(0.0, (sum, w) => sum + w.creditLimit);

    final overallUtilization = totalLimit > 0
        ? (totalUsed / totalLimit) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KMH Kullanım Durumu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: overallUtilization > 80
                      ? Colors.red.withValues(alpha: 0.1)
                      : (overallUtilization > 50
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${overallUtilization.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: overallUtilization > 80
                        ? Colors.red
                        : (overallUtilization > 50
                              ? Colors.orange
                              : Colors.green),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Toplam Kullanım',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  Text(
                    '₺${NumberFormat('#,##0', 'tr_TR').format(totalUsed)} / ₺${NumberFormat('#,##0', 'tr_TR').format(totalLimit)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: totalLimit > 0 ? totalUsed / totalLimit : 0,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                color: overallUtilization > 80
                    ? Colors.red
                    : (overallUtilization > 50 ? Colors.orange : Colors.green),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...kmhWallets.map((w) {
            final utilizationColor = w.utilizationRate > 80
                ? Colors.red
                : (w.utilizationRate > 50 ? Colors.orange : Colors.green);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          w.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${w.utilizationRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: utilizationColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kullanılan: ₺${NumberFormat('#,##0', 'tr_TR').format(w.usedCredit)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Kalan: ₺${NumberFormat('#,##0', 'tr_TR').format(w.availableCredit)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: w.creditLimit > 0 ? w.usedCredit / w.creditLimit : 0,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    color: utilizationColor,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReportsView() {
    return ResponsiveStatisticsLayout(
      children: [
        _buildFinancialHealthScoreCard(),
        _buildPeriodComparisonCard(),
        _buildGoalsSummaryCard(),
        _buildAverageComparisonCard(),
        _buildOverviewSummaryCards(),
        _buildBillTrackingCard(),
        _buildDebtReceivablePanel(),
        _buildPaymentMethodDistributionCard(),
        _buildCashFlowTableCard(),
        _buildIncomeExpenseLedgerCard(),
        _buildIncomeDebtRatioCard(),
        _buildRecurringEventsCard(),
        _buildFinancialAssetsCard(),
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

        final recommendation =
            score.recommendations.isNotEmpty ? score.recommendations.first : null;

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
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
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
                              style: TextStyle(
                                fontSize: 22,
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
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toplam Borç: ₺${NumberFormat('#,##0', 'tr_TR').format(analysis.totalLiabilities)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Net Varlık: ₺${NumberFormat('#,##0', 'tr_TR').format(analysis.netWorth)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Likidite Oranı: ${analysis.liquidityRatio.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  Text(
                    recommendation,
                    style: const TextStyle(fontSize: 12),
                  ),
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

        Widget buildMetricRow(String label, ComparisonMetric metric,
            {bool higherIsBetter = true}) {
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
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₺${NumberFormat('#,##0', 'tr_TR').format(metric.period2Value)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}% önceki döneme göre',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return _buildCard(
          title: 'Dönem Karşılaştırması',
          subtitle:
              '${comparison.period1Label} vs ${comparison.period2Label}',
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
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
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
        final achievedRate =
            summary.overallAchievementRate.toStringAsFixed(1);
        final insight =
            summary.insights.isNotEmpty ? summary.insights.first : null;

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
                    const Icon(
                      Icons.flag,
                      size: 20,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tasarruf / yatırım hedeflerinizin sayısı ve tamamlama oranı.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary.totalGoals.toString(),
                            style: const TextStyle(
                              fontSize: 18,
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary.achievedGoals.toString(),
                            style: const TextStyle(
                              fontSize: 18,
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary.overdueGoals.toString(),
                            style: const TextStyle(
                              fontSize: 18,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '%$achievedRate',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: summary.overallAchievementRate / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
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
                  Text(
                    insight,
                    style: const TextStyle(fontSize: 12),
                  ),
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
          } else if (benchmark.performanceRating ==
                  PerformanceRating.below ||
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
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Net: ₺${NumberFormat('#,##0', 'tr_TR').format(benchmark.currentNetFlow)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${deviation.toStringAsFixed(1)}% ortalamaya göre',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                      ),
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
                    const Icon(
                      Icons.insights,
                      size: 20,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Net nakit akışınız, geçmiş ortalamalara göre ne durumda gösterir.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
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
              style: TextStyle(fontWeight: FontWeight.bold),
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
            const Text(
              'Yaklaşan Ödemeler (30 gün)',
              style: TextStyle(fontWeight: FontWeight.bold),
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
            const Text(
              'Yaklaşan Alacaklar (30 gün)',
              style: TextStyle(fontWeight: FontWeight.bold),
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Şu anda bekleyen borç veya alacak bulunmamaktadır.',
                style: TextStyle(color: Colors.grey),
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
            ? const Color(0xFF1C1C1E)
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
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount.abs())}',
            style: TextStyle(
              fontSize: 16,
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
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
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
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd.MM.yyyy', 'tr_TR').format(date),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: TextStyle(
              fontSize: 13,
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seçili dönem özeti',
                  style: TextStyle(
                    fontSize: 13,
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
        color: isDark ? const Color(0xFF1C1C1E) : color.withValues(alpha: 0.1),
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
                  style: TextStyle(
                    fontSize: 12,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : color.withValues(alpha: 0.8),
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
        color: isDark ? const Color(0xFF1C1C1E) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (headerAction != null) headerAction,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SON 12 AY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey,
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Gelir',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Gider',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.red[300]),
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
                const Text('Nakit akışı', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  CurrencyHelper.formatAmountCompact(cashFlow),
                  style: const TextStyle(
                    fontSize: 18,
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
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              col1,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              col2,
              textAlign: TextAlign.end,
              style: const TextStyle(
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

    return _buildCard(
      title: 'Gelir ve Gider Defteri (TRY)',
      subtitle: 'Paranızın nereye gittiğini görmek ister misiniz?',
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '₺${(income - expense).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildLedgerSection('Gelir', income, [
            _buildLedgerItem(
              'Gelir',
              income,
              Icons.monetization_on,
              Colors.amber,
            ),
            _buildLedgerItem(
              'Bilinmeyen Gelir',
              0,
              Icons.help_outline,
              Colors.grey,
            ),
          ]),
          _buildLedgerSection('Gider', expense, [
            ...expenseCategories.entries.map(
              (e) => _buildLedgerItem(
                e.key,
                e.value,
                _getCategoryIcon(e.key),
                Colors.primaries[e.key.hashCode % Colors.primaries.length],
              ),
            ),
            if (expenseCategories.isEmpty)
              _buildLedgerItem(
                'Henüz gider yok',
                0,
                Icons.money_off,
                Colors.grey,
              ),
          ]),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    if (_categories.isEmpty) {
      final cat = defaultCategories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => defaultCategories.first,
      );
      return cat.icon;
    }

    final cat = _categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () =>
          _categories.isNotEmpty ? _categories.first : defaultCategories.first,
    );
    return cat.icon;
  }

  Widget _buildLedgerSection(String title, double total, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.grey[200] : Colors.black87,
                ),
              ),
              Text(
                total.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[200] : Colors.black87,
                ),
              ),
              Text(
                '---',
                style: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildLedgerItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 16,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(amount.toStringAsFixed(0), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          const Text('---', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildIncomeDebtRatioCard() {
    double totalIncome = 0;
    totalIncome += widget.transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final creditWallets = widget.wallets.where((w) => w.type == 'credit_card');
    final totalDebt = creditWallets.fold(0.0, (sum, w) => sum + w.balance);

    final ratio = totalIncome > 0 ? (totalDebt / totalIncome) * 100 : 0.0;

    return _buildCard(
      title: 'Gelir / Borç Oranı',
      subtitle: 'Toplam gelirimin yüzde kaçı borç?',
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
                          value: ratio > 100 ? 100 : ratio,
                          color: Colors.red,
                          radius: 15,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (100 - ratio) < 0 ? 0 : (100 - ratio),
                          color: Colors.grey[200],
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
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                  const Text(
                    'Toplam borçlar',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '₺${totalDebt.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Toplam Gelir (Tümü)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '₺${totalIncome.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Widget _buildRecurringEventsCard() {
    final installmentTransactions = widget.transactions
        .where((t) => t.installments != null)
        .toList();

    return _buildCard(
      title: 'Taksitli İşlemler',
      subtitle: 'Aktif taksit ödemeleri',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (installmentTransactions.isEmpty)
              const Text(
                'Aktif taksitli işlem yok',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...installmentTransactions.map(
                (t) => _buildRecurringItem(
                  '${t.description} (${t.currentInstallment}/${t.installments})',
                  t.amount,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringItem(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Text(
                '₺${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialAssetsCard() {
    final assetWallets = widget.wallets
        .where((w) => w.type != 'credit_card')
        .toList();
    final kmhWallets = assetWallets.where((w) => w.isKmhAccount).toList();
    final positiveAssets = assetWallets
        .where((w) => w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);
    final kmhDebts = kmhWallets
        .where((w) => w.balance < 0)
        .fold(0.0, (sum, w) => sum + w.balance.abs());
    final totalAssets = positiveAssets - kmhDebts;
    final cashAssets = assetWallets
        .where((w) => w.type == 'cash' && w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);
    final bankAssets = assetWallets
        .where((w) => w.type == 'bank' && w.balance > 0)
        .fold(0.0, (sum, w) => sum + w.balance);

    final totalForChart = positiveAssets + kmhDebts;
    final cashPercentage = totalForChart > 0
        ? (cashAssets / totalForChart) * 100
        : 0.0;
    final bankPercentage = totalForChart > 0
        ? (bankAssets / totalForChart) * 100
        : 0.0;
    final debtPercentage = totalForChart > 0
        ? (kmhDebts / totalForChart) * 100
        : 0.0;

    return _buildCard(
      title: 'Finansal Varlıklar',
      subtitle: 'Varlık dağılımı',
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
                            if (debtPercentage > 0)
                              PieChartSectionData(
                                value: debtPercentage,
                                color: Colors.red,
                                radius: 15,
                                showTitle: false,
                              ),
                            if (totalForChart == 0)
                              PieChartSectionData(
                                value: 100,
                                color: Colors.grey[200],
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
                          '₺${NumberFormat.compact().format(totalAssets)}',
                          style: TextStyle(
                            color: totalAssets >= 0
                                ? Colors.black87
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                      const Text(
                        'Net finansal varlık',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '₺${NumberFormat('#,##0', 'tr_TR').format(totalAssets)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: totalAssets >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildAssetRow(
            'Nakit Varlıklar',
            '₺${NumberFormat('#,##0', 'tr_TR').format(cashAssets)}',
            '${cashPercentage.toStringAsFixed(1)}%',
          ),
          _buildAssetRow(
            'Banka Hesapları',
            '₺${NumberFormat('#,##0', 'tr_TR').format(bankAssets)}',
            '${bankPercentage.toStringAsFixed(1)}%',
          ),
          if (kmhDebts > 0)
            _buildAssetRow(
              'KMH Borçları',
              '-₺${NumberFormat('#,##0', 'tr_TR').format(kmhDebts)}',
              '${debtPercentage.toStringAsFixed(1)}%',
            ),
        ],
      ),
    );
  }

  Widget _buildAssetRow(
    String label,
    String amount,
    String percentage, {
    bool isSubItem = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isSubItem
          ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
          : (isDark ? const Color(0xFF2C2C2E) : Colors.grey[100]),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSubItem ? FontWeight.normal : FontWeight.bold,
                fontSize: isSubItem ? 16 : 14,
                color: isDark ? Colors.grey[200] : Colors.black87,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[200] : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              percentage,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTimeFilter() {
    final selectedLabel = _timeFilterLabels[_selectedTimeFilter]!;
    final filters = _timeFilterLabels.values.toList();

    return TimeFilterBar(
      selectedFilter: selectedLabel,
      filters: filters,
      onFilterChanged: _onTimeFilterChanged,
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
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
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

  String _getWalletTypeName(String type) {
    switch (type) {
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Kartı';
      case 'bank':
        return 'Banka Hesabı';
      default:
        return 'Diğer';
    }
  }



  Color _getWalletTypeColor(String type) {
    switch (type) {
      case 'Nakit':
        return Colors.green;
      case 'Kredi Kartı':
        return Colors.red;
      case 'Banka Hesabı':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaymentMethodDistributionCard() {
    final paymentMethodExpenses = <String, double>{};
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
            color: '0xFF000000',
            icon: 'money',
            creditLimit: 0.0,
          ),
        );

        final walletType = _getWalletTypeName(wallet.type);
        paymentMethodExpenses[walletType] =
            (paymentMethodExpenses[walletType] ?? 0) + item.amount;
        totalExpense += item.amount;
      } else if (item is CreditCardTransaction) {
        paymentMethodExpenses['Kredi Kartı'] =
            (paymentMethodExpenses['Kredi Kartı'] ?? 0) + item.amount;
        totalExpense += item.amount;
      }
    }

    final sortedMethods = paymentMethodExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildCard(
      title: 'Ödeme Yöntemi Dağılımı',
      subtitle: 'Harcamaların ödeme yöntemine göre dağılımı',
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
                  colors: Map.fromEntries(
                    sortedMethods.map(
                      (entry) =>
                          MapEntry(entry.key, _getWalletTypeColor(entry.key)),
                    ),
                  ),
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
                  final percentage =
                      totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                  final color = _getWalletTypeColor(entry.key);
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(entry.value)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
            content: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bu dönemde ödenen veya bekleyen fatura bulunmamaktadır.',
                style: TextStyle(color: Colors.grey),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey,
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
                        const Text(
                          'Bu kategorideki faturalar:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
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
                      backgroundColor: const Color(0xFF5E5CE6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        color: Colors.white,
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
