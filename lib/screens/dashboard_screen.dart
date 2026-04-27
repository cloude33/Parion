// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';
import '../widgets/common/app_loading_state.dart';
import '../widgets/common/section_header.dart';

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
        padding: EdgeInsets.all(AppSpacing.lg),
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Net Bakiye',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmountDisplay(
            amount: balance,
            isIncome: isPositive,
            style: AppTextStyles.displayMedium,
            showSign: false,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyHelper.formatAmount(balance.abs(), _currentUser),
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
          ),
        ],
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.incomeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AmountDisplay(
            amount: _monthlyIncome,
            isIncome: true,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyHelper.formatAmount(_monthlyIncome, _currentUser),
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.expenseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AmountDisplay(
            amount: _monthlyExpense,
            isIncome: false,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyHelper.formatAmount(_monthlyExpense, _currentUser),
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.expenseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
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
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyHelper.formatAmount(debt, _currentUser),
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKmhValueCard() {
    final kmhDebt = _kmhDebt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
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
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyHelper.formatAmount(kmhDebt, _currentUser),
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
      iconWidget = Icon(category.icon, size: 22, color: categoryColor);
    } else {
      final rawColor = AppIcons.getCategoryColor(transaction.category);
      categoryColor =
          rawColor == Colors.grey
              ? (isIncome ? AppColors.incomeColor : AppColors.expenseColor)
              : rawColor;
      iconWidget = AppIcons.getCategoryIcon(
        transaction.category,
        size: 22,
        color: categoryColor,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
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
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
                  style: AppTextStyles.labelLarge,
                  showSign: true,
                ),
                const SizedBox(height: AppSpacing.xs),
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
      iconWidget = Icon(category.icon, size: 22, color: categoryColor);
    } else {
      final rawColor = AppIcons.getCategoryColor(transaction.category);
      categoryColor =
          rawColor == Colors.grey
              ? (card?.color ?? AppColors.expenseColor)
              : rawColor;
      iconWidget = AppIcons.getCategoryIcon(
        transaction.category,
        size: 22,
        color: categoryColor,
      );
    }

    final cardLabel = card != null
        ? '${card.bankName} •••• ${card.last4Digits}'
        : 'Kredi Kartı';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
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
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
                  style: AppTextStyles.labelLarge,
                  showSign: true,
                ),
                const SizedBox(height: AppSpacing.xs),
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
