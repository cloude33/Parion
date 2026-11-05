import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KmhAccountDetailScreen(account: account),
      ),
    );
    if (mounted) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'KMH Hesaplarım',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_allKmhAccounts.length > 1)
            _buildAppBarAction(
              icon: Icons.compare_arrows_rounded,
              onPressed: _navigateToComparison,
              tooltip: 'Hesapları Karşılaştır',
            ),
          _buildAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadKmhAccounts,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: AppSpacing.sm),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddAccount,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'KMH Ekle',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
      ),
    );
  }

  Widget _buildHeaderSection() {
    final utilizationColor = _getUtilizationColor(_averageUtilization);
    final utilizationLabel = _getUtilizationLabel(_averageUtilization);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1424).withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF0F1424).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F1424),
                Color(0xFF1A1D2E),
                Color(0xFF2D3250),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -90,
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.goldAccent.withValues(alpha: 0.10),
                          AppColors.goldAccent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -70,
                left: -50,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.goldAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TOPLAM KMH BORCU',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'GÜNCEL',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _currencyFormat.format(_totalDebt),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _allKmhAccounts.isEmpty
                          ? 'Henüz hesap eklenmedi'
                          : '${_allKmhAccounts.length} aktif hesap • Ort. kullanım ${_averageUtilization.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            AppColors.goldAccent.withValues(alpha: 0.5),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeaderMetric(
                            'KULLANILABILIR',
                            _currencyFormat.format(_totalAvailableCredit),
                            AppColors.success,
                            Icons.check_circle_outline_rounded,
                          ),
                        ),
                        _buildMetricDivider(),
                        Expanded(
                          child: _buildHeaderMetric(
                            'TOPLAM LIMIT',
                            _currencyFormat.format(_totalCreditLimit),
                            AppColors.goldAccent,
                            Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        _buildMetricDivider(),
                        Expanded(
                          child: _buildHeaderMetric(
                            'KULLANIM',
                            '%${_averageUtilization.toStringAsFixed(1)}',
                            utilizationColor,
                            Icons.pie_chart_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlowProgressBar(
                            _averageUtilization,
                            utilizationColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: utilizationColor.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            utilizationLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: utilizationColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
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

  Widget _buildHeaderMetric(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowProgressBar(double utilization, Color color) {
    final widthFactor = (utilization / 100).clamp(0.0, 1.0);
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.7),
                      color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getUtilizationLabel(double utilization) {
    if (utilization >= 80) return 'KRİTİK';
    if (utilization >= 50) return 'YÜKSEK';
    if (utilization >= 30) return 'ORTA';
    return 'DÜŞÜK';
  }

  Widget _buildSearchSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Hesap ara...',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 18,
                    ),
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
    final utilizationLabel = _getUtilizationLabel(account.utilizationRate);
    final maskedAccountNumber = _maskAccountNumber(account.accountNumber);
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(accountColor, Colors.black, 0.25)!,
        Color.lerp(accountColor, Colors.black, 0.55)!,
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAccountDetail(account),
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accountColor.withValues(alpha: 0.45),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accountColor.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -70,
                  child: IgnorePointer(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAccountIconContainer(),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (maskedAccountNumber != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    maskedAccountNumber,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.6),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildStatusChip(
                            account.utilizationRate,
                            utilizationColor,
                            utilizationLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildBalanceSection(account),
                      const SizedBox(height: AppSpacing.md),
                      _buildMetricsGrid(account),
                      const SizedBox(height: AppSpacing.lg),
                      _buildAccountProgressBar(
                        account.utilizationRate,
                        utilizationColor,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCardFooter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountIconContainer() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.account_balance_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildStatusChip(
    double utilization,
    Color color,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '%${utilization.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(Wallet account) {
    final isNegative = account.balance < 0;
    final balanceColor = isNegative
        ? const Color(0xFFFF8A95)
        : Colors.white;
    final pillColor = isNegative
        ? const Color(0xFFFF8A95)
        : const Color(0xFF6FE895);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GÜNCEL BAKİYE',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFormat.format(account.balance),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: balanceColor,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNegative
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 12,
                  color: pillColor,
                ),
                const SizedBox(width: 3),
                Text(
                  isNegative ? 'BORÇ' : 'VARLIK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: pillColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Wallet account) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGridCell(
                  'Kullanılan',
                  _currencyFormat.format(account.usedCredit),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildGridCell(
                  'Kullanılabilir',
                  _currencyFormat.format(account.availableCredit),
                ),
              ),
            ],
          ),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Row(
            children: [
              Expanded(
                child: _buildGridCell(
                  'Toplam Limit',
                  _currencyFormat.format(account.creditLimit),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildGridCell(
                  'Faiz Oranı',
                  account.interestRate != null
                      ? '%${account.interestRate!.toStringAsFixed(2)}'
                      : '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountProgressBar(double utilization, Color color) {
    final widthFactor = (utilization / 100).clamp(0.0, 1.0);
    return Stack(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.65),
                      Colors.white,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter() {
    return Row(
      children: [
        Container(
          width: 24,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.25),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Detayları görüntüle',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.arrow_forward_rounded,
          size: 16,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.withValues(alpha: 0.08),
                    Colors.grey.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Arama kriterlerinizi değiştirip tekrar deneyin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
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
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: isDark ? 0.5 : 0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz KMH hesabı eklenmedi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'KMH hesaplarınızı takip etmek için\nalt taraftaki butona tıklayın',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization >= 80) return AppColors.error;
    if (utilization >= 50) return AppColors.warning;
    if (utilization >= 30) return AppColors.primary;
    return AppColors.success;
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
