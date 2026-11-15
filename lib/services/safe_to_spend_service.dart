import '../models/bill_payment.dart';
import '../models/transaction.dart';
import '../utils/money.dart';
import 'bill_payment_service.dart';
import 'bill_template_service.dart';
import 'credit_card_service.dart';
import 'data_service.dart';

/// A single fixed payment that still has to be covered this month.
class SafeToSpendItem {
  final String label;
  final double amount;
  final DateTime dueDate;

  const SafeToSpendItem({
    required this.label,
    required this.amount,
    required this.dueDate,
  });
}

/// Result of the safe-to-spend calculation.
///
/// [available] is what is left of this month's income after everything already
/// spent plus every unpaid fixed obligation that falls due before the month
/// ends. [perDay] spreads that amount over the remaining days so the user gets
/// a number they can act on today.
class SafeToSpendBreakdown {
  final double monthlyIncome;
  final double spentSoFar;
  final double upcomingFixed;
  final double available;
  final int remainingDays;
  final double perDay;
  final bool usesBalanceFallback;
  final List<SafeToSpendItem> upcomingItems;

  const SafeToSpendBreakdown({
    required this.monthlyIncome,
    required this.spentSoFar,
    required this.upcomingFixed,
    required this.available,
    required this.remainingDays,
    required this.perDay,
    required this.usesBalanceFallback,
    required this.upcomingItems,
  });

  bool get hasFixedObligations => upcomingFixed > 0;
}

/// Calculates how much the user can still spend per day without missing a
/// payment. Fixed obligations are loan installments, bill payments and
/// credit-card statement debts due in the current month.
class SafeToSpendService {
  final DataService _dataService;
  final BillPaymentService _billPaymentService;
  final BillTemplateService _billTemplateService;
  final CreditCardService _creditCardService;

  SafeToSpendService({
    DataService? dataService,
    BillPaymentService? billPaymentService,
    BillTemplateService? billTemplateService,
    CreditCardService? creditCardService,
  }) : _dataService = dataService ?? DataService(),
       _billPaymentService = billPaymentService ?? BillPaymentService(),
       _billTemplateService = billTemplateService ?? BillTemplateService(),
       _creditCardService = creditCardService ?? CreditCardService();

  Future<SafeToSpendBreakdown> calculate({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final remainingDays = monthEnd.day - today.day + 1;

    final transactions = await _dataService.getTransactions();
    final wallets = await _dataService.getWallets();
    final loans = await _dataService.getLoans();
    final payments = await _billPaymentService.getPayments();
    final templates = await _billTemplateService.getTemplates();

    final templateNames = <String, String>{
      for (final template in templates) template.id: template.name,
    };

    var income = 0.0;
    var spent = 0.0;
    for (final transaction in transactions) {
      if (transaction.type == 'transfer') continue;
      if (transaction.date.year != now.year ||
          transaction.date.month != now.month) {
        continue;
      }
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else if (transaction.type == 'expense') {
        spent += transaction.amount;
      }
    }

    final upcomingItems = <SafeToSpendItem>[];

    for (final loan in loans) {
      for (final installment in loan.installments) {
        if (installment.isPaid) continue;
        final due = DateTime(
          installment.dueDate.year,
          installment.dueDate.month,
          installment.dueDate.day,
        );
        if (due.isAfter(monthEnd)) continue;
        upcomingItems.add(
          SafeToSpendItem(
            label: '${loan.name} · ${installment.installmentNumber}. taksit',
            amount: installment.amount,
            dueDate: due,
          ),
        );
      }
    }

    for (final payment in payments) {
      if (_isSettled(payment)) continue;
      final due = DateTime(
        payment.dueDate.year,
        payment.dueDate.month,
        payment.dueDate.day,
      );
      if (due.isAfter(monthEnd)) continue;
      upcomingItems.add(
        SafeToSpendItem(
          label: templateNames[payment.templateId] ?? 'Fatura ödemesi',
          amount: payment.amount,
          dueDate: due,
        ),
      );
    }

    try {
      await _addCreditCardObligations(
        today: today,
        monthEnd: monthEnd,
        upcomingItems: upcomingItems,
      );
    } catch (_) {
      // Credit-card boxes may be unavailable (for example in tests that do not
      // initialize Hive). Too brief to show separately; keep other numbers.
    }

    upcomingItems.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final upcomingFixed = sumMoney(upcomingItems.map((item) => item.amount));
    final regularWalletBalance = sumMoney(
      wallets
          .where(
            (wallet) =>
                wallet.type != 'credit_card' && !wallet.id.startsWith('cc_'),
          )
          .map((wallet) => wallet.balance),
    );
    final walletBalance = regularWalletBalance;

    // If no income has been recorded this month yet, fall back to the current
    // wallet balance so the card is still meaningful early in the month.
    final usesBalanceFallback = income <= 0;
    final available = roundMoney(
      (usesBalanceFallback ? walletBalance : income) - spent - upcomingFixed,
    );
    final clampedAvailable = available < 0 ? 0.0 : available;
    final perDay = remainingDays <= 0
        ? 0.0
        : roundMoney(clampedAvailable / remainingDays);

    return SafeToSpendBreakdown(
      monthlyIncome: sumMoney([income]),
      spentSoFar: sumMoney([spent]),
      upcomingFixed: upcomingFixed,
      available: clampedAvailable,
      remainingDays: remainingDays,
      perDay: perDay,
      usesBalanceFallback: usesBalanceFallback,
      upcomingItems: upcomingItems,
    );
  }

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _nextStatementDateOnOrAfter(DateTime from, int statementDay) {
    final thisMonthLastDay = DateTime(from.year, from.month + 1, 0).day;
    final thisMonthDay = statementDay.clamp(1, thisMonthLastDay).toInt();
    final thisMonthCutoff = DateTime(from.year, from.month, thisMonthDay);
    if (!thisMonthCutoff.isBefore(from)) return thisMonthCutoff;

    final nextMonthLastDay = DateTime(from.year, from.month + 2, 0).day;
    final nextMonthDay = statementDay.clamp(1, nextMonthLastDay).toInt();
    return DateTime(from.year, from.month + 1, nextMonthDay);
  }

  Future<void> _addCreditCardObligations({
    required DateTime today,
    required DateTime monthEnd,
    required List<SafeToSpendItem> upcomingItems,
  }) async {
    final cards = await _creditCardService.getActiveCards();

    for (final card in cards) {
      final cardLabel =
          '${card.bankName} ${card.cardName} •••• ${card.last4Digits}';
      final statements = await _creditCardService.getCardStatements(card.id);

      for (final statement in statements) {
        final due = _day(statement.dueDate);
        final amount = roundMoney(statement.remainingDebt);
        if (statement.isPaidFully || amount <= 0 || due.isAfter(monthEnd)) {
          continue;
        }
        upcomingItems.add(
          SafeToSpendItem(
            label: '$cardLabel · ekstre borcu',
            amount: amount,
            dueDate: due,
          ),
        );
      }

      // Statement generation moves this into the first statement. Until that
      // statement exists, it is still an obligation for this month.
      if (statements.isEmpty && card.initialDebt > 0) {
        upcomingItems.add(
          SafeToSpendItem(
            label: '$cardLabel · başlangıç borcu',
            amount: roundMoney(card.initialDebt),
            dueDate: today,
          ),
        );
      }

      DateTime? latestPeriodEnd;
      for (final statement in statements) {
        final periodEnd = _day(statement.periodEnd);
        if (latestPeriodEnd == null || periodEnd.isAfter(latestPeriodEnd)) {
          latestPeriodEnd = periodEnd;
        }
      }

      final transactions = await _creditCardService.getAllCardTransactions(
        card.id,
      );
      if (transactions.isEmpty) continue;

      final baseDate =
          latestPeriodEnd == null || latestPeriodEnd.isBefore(today)
          ? today
          : latestPeriodEnd;
      final projectedCutoff = _nextStatementDateOnOrAfter(
        baseDate,
        card.statementDay,
      );
      final projectedDue = projectedCutoff.add(
        Duration(days: card.dueDateOffset),
      );
      if (projectedDue.isAfter(monthEnd)) continue;

      final projectedAmounts = <double>[];
      for (final transaction in transactions) {
        final transactionDate = _day(transaction.transactionDate);
        if (transactionDate.isAfter(projectedCutoff)) continue;

        double amount;
        if (transaction.installmentCount > 1) {
          if (transaction.isCompleted) continue;
          // The next statement can contain only one pending installment for a
          // purchase, not the purchase's full remaining balance.
          amount = transaction.installmentAmount;
        } else {
          // Purchases already captured by the latest statement must not be
          // counted again in the projected next statement.
          if (latestPeriodEnd != null &&
              !transactionDate.isAfter(latestPeriodEnd)) {
            continue;
          }
          amount = transaction.amount;
        }

        if (amount > 0) projectedAmounts.add(amount);
      }

      final projectedTotal = sumMoney(projectedAmounts);
      if (projectedTotal > 0) {
        upcomingItems.add(
          SafeToSpendItem(
            label: '$cardLabel · yeni ekstre',
            amount: projectedTotal,
            dueDate: projectedDue,
          ),
        );
      }
    }
  }

  bool _isSettled(BillPayment payment) =>
      payment.isPaid || payment.status == BillPaymentStatus.paid;

  /// Kept for callers that only need the per-day figure.
  Future<double> getDailyLimit({DateTime? referenceDate}) async {
    final breakdown = await calculate(referenceDate: referenceDate);
    return breakdown.perDay;
  }

  /// Total of this month's expense transactions. Exposed for widgets that show
  /// a "spent so far" line next to the daily limit.
  Future<double> getMonthlySpend({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    final transactions = await _dataService.getTransactions();
    final expenses = transactions.where(
      (transaction) =>
          transaction.type == 'expense' &&
          transaction.date.year == now.year &&
          transaction.date.month == now.month,
    );
    return sumMoney(expenses.map((transaction) => transaction.amount));
  }

  /// Utility used by tests and by the breakdown sheet.
  static List<Transaction> expensesBetween(
    List<Transaction> transactions,
    DateTime start,
    DateTime end,
  ) => transactions
      .where(
        (transaction) =>
            transaction.type == 'expense' &&
            !transaction.date.isBefore(start) &&
            transaction.date.isBefore(end),
      )
      .toList();
}
