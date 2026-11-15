// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_text_styles.dart';
import '../models/category.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import '../services/credit_card_service.dart';
import '../services/data_service.dart';
import '../utils/app_icons.dart';
import '../utils/currency_helper.dart';
import '../widgets/common/amount_display.dart';
import '../utils/responsive_helper.dart';

import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';
import '../widgets/common/app_loading_state.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/premium_widgets.dart';
import 'budget_list_screen.dart';
import 'subscription_list_screen.dart';
import 'net_worth_screen.dart';

/// Dashboard screen that shows the user's financial summary at a glance.
///
/// Displays:
/// - Greeting with user name
/// - Net Balance card
/// - This Month income/expense side by side
/// - Credit Card Debt metric
/// - KMH (Overdraft) Value metric
/// - Last 5 Transactions list
///
/// Handles loading, empty, and error states.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataService _dataService = DataService();
  final CreditCardService _creditCardService = CreditCardService();

  // State
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Data
  User? _currentUser;
  List<Wallet> _wallets = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<CreditCardTransaction> _creditCardTransactions = [];
  Map<String, CreditCard> _creditCards = {};
  double _totalCreditCardDebt = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await _dataService.init();

      User? user = await _dataService.getCurrentUser();
      user ??= User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Kullanıcı',
        currencyCode: 'TRY',
        currencySymbol: '₺',
      );

      List<Wallet> loadedWallets = const [];
      List<Transaction> loadedTransactions = const [];
      List<Category> loadedCategories = const [];
      List<CreditCard> cards = const [];

      try {
        loadedWallets = await _dataService.getWallets();
      } catch (e) {
        debugPrint('WARN DashboardScreen: wallets $e');
      }
      try {
        loadedTransactions = await _dataService.getTransactions();
      } catch (e) {
        debugPrint('WARN DashboardScreen: transactions $e');
      }
      try {
        final cats = await _dataService.getCategories();
        loadedCategories = List<Category>.from(cats);
      } catch (e) {
        debugPrint('WARN DashboardScreen: categories $e');
      }
      try {
        cards = await _creditCardService.getAllCards();
      } catch (e) {
        debugPrint('WARN DashboardScreen: cards $e');
      }

      final Map<String, CreditCard> cardMap = {};
      final List<CreditCardTransaction> allCCTransactions = [];

      for (final card in cards) {
        cardMap[card.id] = card;
        try {
          final ccTxs = await _creditCardService.getCardTransactions(card.id);
          allCCTransactions.addAll(ccTxs);
        } catch (e) {
          debugPrint('WARN DashboardScreen: cc tx for ${card.id} $e');
        }
      }

      double totalCCDebt = 0.0;
      for (final card in cards) {
        try {
          totalCCDebt += await _creditCardService.getCurrentDebt(card.id);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _wallets = loadedWallets;
          _transactions = loadedTransactions;
          _categories = loadedCategories;
          _creditCardTransactions = allCCTransactions;
          _creditCards = cardMap;
          _totalCreditCardDebt = totalCCDebt;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('ERROR DashboardScreen._loadData: $e\n$st');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
        });
      }
    }
  }

  // ── Computed values ──────────────────────────────────────────────────────

  /// Total balance across all non-KMH, non-credit-card wallets.
  double get _netBalance {
    return _wallets
        .where((w) => !w.isKmhAccount && w.type != 'credit_card')
        .fold(0.0, (sum, w) => sum + w.balance);
  }

  /// Monthly income for the current month (regular transactions only).
  double get _monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.type == 'income' &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Monthly expense for the current month (regular transactions only).
  double get _monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total KMH (overdraft) debt — sum of negative balances on KMH accounts.
  double get _kmhDebt {
    return _wallets
        .where((w) => w.isKmhAccount && w.balance < 0)
        .fold(0.0, (sum, w) => sum + w.balance.abs());
  }

  /// Whether the user has no wallets at all (empty state trigger).
  bool get _isEmpty =>
      _wallets.isEmpty && _creditCardTransactions.isEmpty && _transactions.isEmpty;

  /// Last 5 transactions sorted by date descending (regular + credit card).
  List<Map<String, dynamic>> get _last5Transactions {
    final all = <Map<String, dynamic>>[];

    for (final t in _transactions) {
      all.add({'type': 'normal', 'data': t, 'date': t.date});
    }
    for (final t in _creditCardTransactions) {
      all.add({'type': 'credit_card', 'data': t, 'date': t.transactionDate});
    }

    all.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    return all.take(5).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: AppLoadingState(itemCount: 5, itemHeight: 80),
      );
    }

    if (_hasError) {
      return AppErrorState(
        message: _errorMessage,
        onRetry: _loadData,
      );
    }

    if (_isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.wallet,
        title: 'Henüz cüzdan yok',
        description:
            'Finansal durumunuzu takip etmek için bir cüzdan ekleyin.',
        actionLabel: 'Cüzdan Ekle',
        onAction: () {
          // Navigate to add wallet — handled by parent HomeScreen
          // We pop back to let the parent handle navigation if needed.
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: AppSpacing.xl),
              _buildNetBalanceCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildThisMonthSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildMetricsRow(),
              const SizedBox(height: AppSpacing.lg),
              _buildQuickAccessCards(),
              const SizedBox(height: AppSpacing.xl),
              _buildLastTransactionsSection(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Greeting ──────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = 'Günaydın';
    } else if (hour < 18) {
      greeting = 'İyi günler';
    } else {
      greeting = 'İyi akşamlar';
    }

    final name = _currentUser?.name ?? 'Kullanıcı';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: AppTextStyles.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          name,
          style: AppTextStyles.headlineLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ── Net Balance Card ──────────────────────────────────────────────────────

  Widget _buildNetBalanceCard() {
    final balance = _netBalance;
    final isPositive = balance >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.primaryDarkGradient : AppColors.primaryGradient;

    return AnimatedPressScale(
      onTap: () {
        // Aesthetic feed-back, trigger data reload as action
        _loadData();
      },
      semanticLabel: 'Net Bakiye Kartı',
      child: PremiumGradientCard(
        gradient: gradient,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Net Bakiye',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AmountDisplay(
              amount: balance,
              isIncome: isPositive,
              style: AppTextStyles.displayMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              color: Colors.white,
              showSign: false,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CurrencyHelper.formatAmount(balance.abs(), _currentUser),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── This Month Section ────────────────────────────────────────────────────

  Widget _buildThisMonthSection() {
    final monthName = DateFormat.MMMM(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Bu Ay — $monthName'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildIncomeCard()),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildExpenseCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incomeGrad = LinearGradient(
      colors: isDark 
          ? [const Color(0x1F34C759), const Color(0x0534C759)] 
          : [const Color(0x2E34C759), const Color(0x0A34C759)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedPressScale(
      onTap: () {},
      child: GlassmorphicCard(
        gradient: incomeGrad,
        borderRadius: 16.0,
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.incomeColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.trendingUp,
                    size: 16,
                    color: AppColors.incomeColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Gelir',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AmountDisplay(
              amount: _monthlyIncome,
              isIncome: true,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CurrencyHelper.formatAmount(_monthlyIncome, _currentUser),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseGrad = LinearGradient(
      colors: isDark 
          ? [const Color(0x1FFF3B30), const Color(0x05FF3B30)] 
          : [const Color(0x2EFF3B30), const Color(0x0AFF3B30)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedPressScale(
      onTap: () {},
      child: GlassmorphicCard(
        gradient: expenseGrad,
        borderRadius: 16.0,
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.expenseColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.trendingDown,
                    size: 16,
                    color: AppColors.expenseColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Gider',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AmountDisplay(
              amount: _monthlyExpense,
              isIncome: false,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CurrencyHelper.formatAmount(_monthlyExpense, _currentUser),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Metrics Row (Credit Card Debt + KMH Value) ────────────────────────────

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(child: _buildCreditCardDebtCard()),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildKmhValueCard()),
      ],
    );
  }

  Widget _buildCreditCardDebtCard() {
    final debt = _totalCreditCardDebt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final ccGrad = LinearGradient(
      colors: isDark 
          ? [const Color(0x1FFF3B30), const Color(0x05FF3B30)] 
          : [const Color(0x2EFF3B30), const Color(0x0AFF3B30)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedPressScale(
      onTap: () {},
      child: GlassmorphicCard(
        gradient: ccGrad,
        borderRadius: 16.0,
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.expenseColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.creditCard,
                    size: 16,
                    color: AppColors.expenseColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Kredi Kartı Borcu',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AmountDisplay(
              amount: debt,
              isIncome: false,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CurrencyHelper.formatAmount(debt, _currentUser),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKmhValueCard() {
    final kmhDebt = _kmhDebt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final warningGrad = LinearGradient(
      colors: isDark 
          ? [const Color(0x1FFF9500), const Color(0x05FF9500)] 
          : [const Color(0x2EFF9500), const Color(0x0AFF9500)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedPressScale(
      onTap: () {},
      child: GlassmorphicCard(
        gradient: warningGrad,
        borderRadius: 16.0,
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.landmark,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'KMH Değeri',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AmountDisplay(
              amount: kmhDebt,
              isIncome: false,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CurrencyHelper.formatAmount(kmhDebt, _currentUser),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Access Cards ─────────────────────────────────────────────────────

  Widget _buildQuickAccessCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Hızlı Erişim'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildQuickCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Bütçe',
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetListScreen())),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickCard(
              icon: Icons.subscriptions_outlined,
              label: 'Abonelikler',
              color: const Color(0xFFE91E63),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionListScreen())),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickCard(
              icon: Icons.show_chart,
              label: 'Net Değer',
              color: Colors.purple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NetWorthScreen())),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPressScale(
      onTap: onTap,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.22 : 0.15),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? color.withValues(alpha: 0.9) : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Last 5 Transactions ───────────────────────────────────────────────────

  Widget _buildLastTransactionsSection() {
    final items = _last5Transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Son İşlemler',
          actionLabel: items.isNotEmpty ? 'Tümünü Gör' : null,
          onAction: items.isNotEmpty ? () {} : null,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                'Henüz işlem yok.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          // ListView.builder with lazy loading (Requirement 10.4)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item['type'] == 'normal') {
                return _buildTransactionTile(item['data'] as Transaction);
              } else {
                return _buildCreditCardTransactionTile(
                  item['data'] as CreditCardTransaction,
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isIncome = transaction.type == 'income';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Category? category;
    try {
      category = _categories.firstWhere(
        (c) => c.name.toLowerCase() == transaction.category.toLowerCase(),
      );
    } catch (_) {}

    final Color categoryColor;
    final Widget iconWidget;

    if (category != null) {
      categoryColor = category.color;
      iconWidget = Icon(category.icon, size: 20, color: categoryColor);
    } else {
      final rawColor = AppIcons.getCategoryColor(transaction.category);
      categoryColor =
          rawColor == Colors.grey
              ? (isIncome ? AppColors.incomeColor : AppColors.expenseColor)
              : rawColor;
      iconWidget = AppIcons.getCategoryIcon(
        transaction.category,
        size: 20,
        color: categoryColor,
      );
    }

    final tileGrad = LinearGradient(
      colors: isDark
          ? [Colors.white.withValues(alpha: 0.04), Colors.white.withValues(alpha: 0.01)]
          : [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.65)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassmorphicCard(
        blur: 5.0,
        gradient: tileGrad,
        borderRadius: 14.0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: isDark ? 0.16 : 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.22),
                  width: 1.5,
                ),
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.category,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountDisplay(
                  amount: transaction.amount,
                  isIncome: isIncome,
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                  showSign: true,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardTransactionTile(CreditCardTransaction transaction) {
    final card = _creditCards[transaction.cardId];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Category? category;
    try {
      category = _categories.firstWhere(
        (c) => c.name.toLowerCase() == transaction.category.toLowerCase(),
      );
    } catch (_) {}

    final Color categoryColor;
    final Widget iconWidget;

    if (category != null) {
      categoryColor = category.color;
      iconWidget = Icon(category.icon, size: 20, color: categoryColor);
    } else {
      final rawColor = AppIcons.getCategoryColor(transaction.category);
      categoryColor =
          rawColor == Colors.grey
              ? (card?.color ?? AppColors.expenseColor)
              : rawColor;
      iconWidget = AppIcons.getCategoryIcon(
        transaction.category,
        size: 20,
        color: categoryColor,
      );
    }

    final cardLabel = card != null
        ? '${card.bankName} •••• ${card.last4Digits}'
        : 'Kredi Kartı';

    final tileGrad = LinearGradient(
      colors: isDark
          ? [Colors.white.withValues(alpha: 0.04), Colors.white.withValues(alpha: 0.01)]
          : [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.65)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassmorphicCard(
        blur: 5.0,
        gradient: tileGrad,
        borderRadius: 14.0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: isDark ? 0.16 : 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.22),
                  width: 1.5,
                ),
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cardLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountDisplay(
                  amount: transaction.amount,
                  isIncome: false,
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                  showSign: true,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.transactionDate),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Bugün';
    if (d == yesterday) return 'Dün';
    return DateFormat('d MMM', Localizations.localeOf(context).toString())
        .format(date);
  }
}
