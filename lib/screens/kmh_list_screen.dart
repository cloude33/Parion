import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';
import '../services/sensitive_data_handler.dart';
import 'add_wallet_screen.dart';
import 'kmh_account_detail_screen.dart';
import 'kmh_comparison_screen.dart';

class KmhListScreen extends StatefulWidget {
  const KmhListScreen({super.key});

  @override
  State<KmhListScreen> createState() => _KmhListScreenState();
}

class _KmhListScreenState extends State<KmhListScreen> {
  final DataService _dataService = DataService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  List<Wallet> _allKmhAccounts = [];
  List<Wallet> _filteredKmhAccounts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  double _totalDebt = 0;
  double _totalAvailableCredit = 0;
  double _totalCreditLimit = 0;
  double _averageUtilization = 0;

  @override
  void initState() {
    super.initState();
    _loadKmhAccounts();
  }

  Future<void> _loadKmhAccounts() async {
    setState(() => _isLoading = true);

    try {
      final wallets = await _dataService.getWallets();
      final kmhAccounts = wallets.where((w) => w.isKmhAccount).toList();
      double totalDebt = 0;
      double totalAvailableCredit = 0;
      double totalCreditLimit = 0;
      double totalUtilization = 0;

      for (var account in kmhAccounts) {
        totalDebt += account.usedCredit;
        totalAvailableCredit += account.availableCredit;
        totalCreditLimit += account.creditLimit;
        totalUtilization += account.utilizationRate;
      }

      final averageUtilization = kmhAccounts.isNotEmpty
          ? totalUtilization / kmhAccounts.length
          : 0.0;

      setState(() {
        _allKmhAccounts = kmhAccounts;
        _filteredKmhAccounts = kmhAccounts;
        _totalDebt = totalDebt;
        _totalAvailableCredit = totalAvailableCredit;
        _totalCreditLimit = totalCreditLimit;
        _averageUtilization = averageUtilization;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _filterAccounts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredKmhAccounts = _allKmhAccounts;
      } else {
        _filteredKmhAccounts = _allKmhAccounts.where((account) {
          final nameLower = account.name.toLowerCase();
          final queryLower = query.toLowerCase();
          final accountNumber = account.accountNumber ?? '';
          return nameLower.contains(queryLower) ||
              accountNumber.contains(queryLower);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddWalletScreen(initialType: 'overdraft'),
      ),
    );

    if (result == true) {
      _loadKmhAccounts();
    }
  }

  Future<void> _navigateToAccountDetail(Wallet account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KmhAccountDetailScreen(account: account),
      ),
    );

    if (result == true) {
      _loadKmhAccounts();
    }
  }

  Future<void> _navigateToComparison() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KmhComparisonScreen()),
    );

    if (result == true) {
      _loadKmhAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'KMH Hesaplarım',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1A1D2E),
          ),
        ),
        actions: [
          if (_allKmhAccounts.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFF1A1D2E).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.compare_arrows),
                onPressed: _navigateToComparison,
                tooltip: 'Hesapları Karşılaştır',
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFF1A1D2E).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadKmhAccounts,
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadKmhAccounts,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeaderSection()),
                  if (_allKmhAccounts.isNotEmpty)
                    SliverToBoxAdapter(child: _buildSearchSection()),
                  if (_filteredKmhAccounts.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final account = _filteredKmhAccounts[index];
                            return _buildAccountCard(account, index);
                          },
                          childCount: _filteredKmhAccounts.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BFA5).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddAccount,
          backgroundColor: const Color(0xFF00BFA5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add, size: 22),
          label: const Text(
            'KMH Ekle',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D2E).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1D2E), Color(0xFF2D3250)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam KMH Borcu',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currencyFormat.format(_totalDebt),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricColumn(
                        'Kullanılabilir',
                        _currencyFormat.format(_totalAvailableCredit),
                        Colors.greenAccent,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _buildMetricColumn(
                        'Toplam Limit',
                        _currencyFormat.format(_totalCreditLimit),
                        Colors.amberAccent,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _buildMetricColumn(
                        'Kullanım',
                        '${_averageUtilization.toStringAsFixed(1)}%',
                        _utilizationColor(_averageUtilization),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildUtilizationBar(_averageUtilization),
                  const SizedBox(width: 12),
                  Text(
                    '${_allKmhAccounts.length} hesap',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildUtilizationBar(double utilization) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 6,
          color: Colors.white.withValues(alpha: 0.1),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (utilization / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    Colors.greenAccent,
                    if (utilization > 50) Colors.orangeAccent,
                    if (utilization > 80) Colors.redAccent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _utilizationColor(double utilization) {
    if (utilization >= 80) return Colors.redAccent;
    if (utilization >= 50) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D2E).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Hesap ara...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[400]),
                    onPressed: () => _filterAccounts(''),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: _filterAccounts,
        ),
      ),
    );
  }

  Widget _buildAccountCard(Wallet account, int index) {
    final accountColor = Color(int.parse(account.color));
    final utilizationColor = _getUtilizationColor(account.utilizationRate);
    final maskedAccountNumber = _maskAccountNumber(account.accountNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _navigateToAccountDetail(account),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1D2E).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  color: accountColor.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accountColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color: accountColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (maskedAccountNumber != null)
                            Text(
                              maskedAccountNumber,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                letterSpacing: 0.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: utilizationColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '%${account.utilizationRate.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: utilizationColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildAccountMetric(
                            'Bakiye',
                            _currencyFormat.format(account.balance),
                            account.balance < 0 ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAccountMetric(
                            'Kullanılan',
                            _currencyFormat.format(account.usedCredit),
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAccountMetric(
                            'Limit',
                            _currencyFormat.format(account.creditLimit),
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProgressBar(
                            account.utilizationRate,
                            utilizationColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (account.interestRate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.percent,
                                  size: 13,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '%${account.interestRate!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Kullanılabilir: ${_currencyFormat.format(account.availableCredit)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double utilization, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 6,
          color: Colors.grey.withValues(alpha: 0.1),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (utilization / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    if (utilization < 50)
                      Colors.green
                    else if (utilization < 80)
                      Colors.orange
                    else
                      Colors.red,
                    color,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Arama kriterlerinizi değiştirip tekrar deneyin',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.account_balance,
              size: 48,
              color: const Color(0xFF00BFA5).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz KMH hesabı eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'KMH hesaplarınızı takip etmek için\nalt taraftaki butona tıklayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.4),
          ),
        ],
      ),
    );
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization >= 80) return Colors.red;
    if (utilization >= 50) return Colors.orange;
    return Colors.green;
  }

  String? _maskAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) {
      return null;
    }

    final masked = SensitiveDataHandler.maskAccountNumber(accountNumber);
    return masked != null
        ? SensitiveDataHandler.formatMaskedNumber(masked)
        : null;
  }
}
