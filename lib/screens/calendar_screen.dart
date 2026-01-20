import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card.dart';
import '../models/bill_payment.dart';
import '../models/bill_template.dart';
import '../models/loan.dart';
import '../services/data_service.dart';
import '../services/credit_card_service.dart';
import '../services/bill_payment_service.dart';
import '../services/bill_template_service.dart';
import '../utils/currency_helper.dart';
import 'edit_bill_payment_screen.dart';
import 'loan_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final bool isEmbedded;

  const CalendarScreen({
    super.key,
    required this.transactions,
    this.isEmbedded = false,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DataService _dataService = DataService();
  final CreditCardService _creditCardService = CreditCardService();
  final BillPaymentService _billPaymentService = BillPaymentService();
  final BillTemplateService _billTemplateService = BillTemplateService();
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  User? _currentUser;
  List<Category> _categories = [];
  List<CreditCardTransaction> _creditCardTransactions = [];
  Map<String, CreditCard> _creditCards = {};
  List<BillPayment> _billPayments = [];
  Map<String, BillTemplate> _billTemplates = {};
  List<Loan> _loans = [];
  late PageController _pageController;
  final int _initialPage = 1200;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await _dataService.getCurrentUser();
    final categories = (await _dataService.getCategories()).cast<Category>();
    final cards = await _creditCardService.getAllCards();
    final Map<String, CreditCard> cardMap = {};
    final List<CreditCardTransaction> allCCTransactions = [];

    for (var card in cards) {
      cardMap[card.id] = card;
      final transactions = await _creditCardService.getCardTransactions(
        card.id,
      );
      allCCTransactions.addAll(transactions);
    }

    // Load bill payments
    final billPayments = await _billPaymentService.getPayments();
    final billTemplates = await _billTemplateService.getTemplates();
    final Map<String, BillTemplate> templateMap = {};
    for (var template in billTemplates) {
      templateMap[template.id] = template;
    }

    // Load loans
    final loans = await _dataService.getLoans();

    setState(() {
      _currentUser = user;
      _categories = categories;
      _creditCardTransactions = allCCTransactions;
      _creditCards = cardMap;
      _billPayments = billPayments;
      _billTemplates = templateMap;
      _loans = loans;
    });
  }

  List<dynamic> _getTransactionsForDay(DateTime date) {
    final normalTransactions = widget.transactions.where((t) {
      if (t.installments != null) {
        return t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day;
      }
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    }).toList();
    final ccTransactions = _creditCardTransactions.where((t) {
      return t.transactionDate.year == date.year &&
          t.transactionDate.month == date.month &&
          t.transactionDate.day == date.day;
    }).toList();
    final billPayments = _billPayments.where((b) {
      return b.dueDate.year == date.year &&
          b.dueDate.month == date.month &&
          b.dueDate.day == date.day;
    }).toList();

    final loanInstallments = <Map<String, dynamic>>[];
    for (var loan in _loans) {
      for (var installment in loan.installments) {
        if (installment.dueDate.year == date.year &&
            installment.dueDate.month == date.month &&
            installment.dueDate.day == date.day) {
          loanInstallments.add({
            'type': 'loan_installment',
            'loan': loan,
            'installment': installment,
          });
        }
      }
    }

    return [
      ...normalTransactions,
      ...ccTransactions,
      ...billPayments,
      ...loanInstallments,
    ];
  }

  // Removed unused method _getDayTotal to resolve analyzer warning

  double _getDayIncome(DateTime date) {
    final dayTransactions = _getTransactionsForDay(date);
    return dayTransactions
        .where((t) => t is Transaction && t.type == 'income')
        .fold(0.0, (sum, t) => sum + (t as Transaction).amount);
  }

  double _getDayExpense(DateTime date) {
    final dayTransactions = _getTransactionsForDay(date);
    double expense = 0;
    expense += dayTransactions
        .where((t) => t is Transaction && t.type == 'expense')
        .fold(0.0, (sum, t) => sum + (t as Transaction).amount);
    expense += dayTransactions.whereType<CreditCardTransaction>().fold(
      0.0,
      (sum, t) => sum + (t).amount,
    );
    expense += dayTransactions
        .where((t) => t is BillPayment && !t.isPaid)
        .fold(0.0, (sum, t) => sum + (t as BillPayment).amount);

    expense += dayTransactions
        .where(
          (t) => t is Map<String, dynamic> && t['type'] == 'loan_installment',
        )
        .fold(
          0.0,
          (sum, t) => sum + (t['installment'] as LoanInstallment).amount,
        );

    return expense;
  }

  double get _monthIncome {
    return widget.transactions
        .where(
          (t) =>
              t.type == 'income' &&
              t.date.month == _selectedMonth.month &&
              t.date.year == _selectedMonth.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _monthExpense {
    double normalExpense = widget.transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.month == _selectedMonth.month &&
              t.date.year == _selectedMonth.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    double ccExpense = _creditCardTransactions
        .where(
          (t) =>
              t.transactionDate.month == _selectedMonth.month &&
              t.transactionDate.year == _selectedMonth.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    double loanExpense = 0;
    for (var loan in _loans) {
      for (var installment in loan.installments) {
        if (installment.dueDate.month == _selectedMonth.month &&
            installment.dueDate.year == _selectedMonth.year) {
          loanExpense += installment.amount;
        }
      }
    }

    return normalExpense + ccExpense + loanExpense;
  }

  double get _monthTotal {
    return _monthIncome - _monthExpense;
  }

  DateTime _getMonthForPage(int page) {
    final monthsFromNow = page - _initialPage;
    final now = DateTime.now();
    return DateTime(now.year, now.month + monthsFromNow);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final content = Column(
      children: [
        _buildHeader(),
        _buildSummary(),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _selectedMonth = _getMonthForPage(page);
                _selectedDate = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  _selectedDate.day.clamp(
                    1,
                    DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      0,
                    ).day,
                  ),
                );
              });
            },
            itemBuilder: (context, page) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCalendarHeader(),
                    _buildCalendarGrid(),
                    Container(height: 1, color: Theme.of(context).dividerColor),
                    SizedBox(
                      height: screenHeight * 0.4,
                      child: _buildDayTransactions(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(child: content),
    );
  }

  Widget _buildDayTransactions() {
    final dayTransactions = _getTransactionsForDay(_selectedDate);
    final dayIncome = _getDayIncome(_selectedDate);
    final dayExpense = _getDayExpense(_selectedDate);

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFFCF8F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5E5CE6),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_selectedDate.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE', 'tr_TR').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[200]
                            : const Color(0xFF1C1C1E),
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
                            AppLocalizations.of(context)!.income,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          Text(
                            CurrencyHelper.formatAmountCompact(
                              dayIncome,
                              _currentUser,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34C759),
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
                            AppLocalizations.of(context)!.expense,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          Text(
                            CurrencyHelper.formatAmountCompact(
                              dayExpense,
                              _currentUser,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: dayTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'İşlem yok',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: dayTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = dayTransactions[index];
                      if (transaction is Transaction) {
                        return _buildTransactionItem(transaction);
                      } else if (transaction is CreditCardTransaction) {
                        return _buildCreditCardTransactionItem(transaction);
                      } else if (transaction is BillPayment) {
                        return _buildBillPaymentItem(transaction);
                      } else if (transaction is Map<String, dynamic> &&
                          transaction['type'] == 'loan_installment') {
                        return _buildLoanInstallmentItem(
                          transaction['loan'] as Loan,
                          transaction['installment'] as LoanInstallment,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final category = _categories.firstWhere(
      (c) => c.name.toLowerCase() == transaction.category.toLowerCase(),
      orElse: () =>
          _categories.isNotEmpty ? _categories.first : defaultCategories.first,
    );

    final isIncome = transaction.type == 'income';
    final color = isIncome ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[200]
                        : const Color(0xFF1C1C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  transaction.subCategory != null
                      ? '${transaction.category} > ${transaction.subCategory}'
                      : transaction.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                if (transaction.installments != null)
                  Text(
                    '${transaction.currentInstallment}/${transaction.installments} ${AppLocalizations.of(context)!.installment}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyHelper.formatAmountCompact(transaction.amount, _currentUser)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardTransactionItem(CreditCardTransaction transaction) {
    final card = _creditCards[transaction.cardId];
    final color = const Color(0xFFFF3B30);
    final isInstallment = transaction.installmentCount > 1;

    // Try to find the category in the loaded categories list
    Category? category;
    try {
      category = _categories.firstWhere(
        (c) => c.name.toLowerCase() == transaction.category.toLowerCase(),
      );
    } catch (_) {
      // Category not found
    }

    Color categoryColor;
    IconData iconData;

    if (category != null) {
      categoryColor = category.color;
      iconData = category.icon;
    } else {
      categoryColor = card?.color ?? Colors.blue;
      iconData = Icons.credit_card;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: card?.color ?? Colors.blue, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[200]
                        : const Color(0xFF1C1C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (card != null) ...[
                      Text(
                        '${card.bankName} •••• ${card.last4Digits}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      if (isInstallment) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        Text(
                          '${transaction.installmentsPaid}/${transaction.installmentCount} ${AppLocalizations.of(context)!.installment}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ] else ...[
                      Text(
                        transaction.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '-${CurrencyHelper.formatAmountCompact(transaction.amount, _currentUser)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1C1C1E),
                  size: 16,
                ),
              ),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1C1C1E),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1C1C1E),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Theme.of(context).cardColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _buildSummaryItem(
                  'Gelir',
                  _monthIncome,
                  const Color(0xFF34C759),
                ),
              ),
              Flexible(
                child: _buildSummaryItem(
                  'Gider',
                  _monthExpense,
                  const Color(0xFFFF3B30),
                ),
              ),
              Flexible(
                child: _buildSummaryItem(
                  'Toplam',
                  _monthTotal,
                  Theme.of(context).textTheme.bodyLarge?.color ??
                      const Color(0xFF1C1C1E),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            CurrencyHelper.formatAmount(amount, _currentUser),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final days = ['Pz', 'Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.asMap().entries.map((entry) {
          final day = entry.value;
          final isWeekend = day == 'Cu' || day == 'Ct';
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWeekend
                      ? Colors.red
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstDayWeekday = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    ).weekday;
    final firstDayOfWeek = firstDayWeekday == 7 ? 6 : firstDayWeekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: List.generate((daysInMonth + firstDayOfWeek) ~/ 7 + 1, (
          weekIndex,
        ) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              if (cellIndex < firstDayOfWeek ||
                  cellIndex >= daysInMonth + firstDayOfWeek) {
                return Expanded(child: Container());
              }

              final day = cellIndex - firstDayOfWeek + 1;
              return Expanded(child: _buildDayCell(day, dayIndex));
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(int day, int dayOfWeek) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    final isSelected =
        date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    final isWeekend = dayOfWeek == 5 || dayOfWeek == 6;
    final income = _getDayIncome(date);
    final expense = _getDayExpense(date);
    final hasTransactions = income > 0 || expense > 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF007AFF), width: 2)
              : null,
        ),
        constraints: const BoxConstraints(minHeight: 60, minWidth: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: isWeekend
                    ? Colors.red
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (hasTransactions) ...[
              const SizedBox(height: 2),
              if (income > 0)
                Text(
                  '+${CurrencyHelper.formatAmount(income, _currentUser)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF34C759),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (expense > 0)
                Text(
                  '-${CurrencyHelper.formatAmount(expense, _currentUser)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBillPaymentItem(BillPayment billPayment) {
    final template = _billTemplates[billPayment.templateId];
    final color = billPayment.isPaid
        ? const Color(0xFF34C759)
        : billPayment.isOverdue
        ? const Color(0xFFFF3B30)
        : const Color(0xFFFF9500);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditBillPaymentScreen(payment: billPayment),
            ),
          );
          if (result == true) {
            await _loadData();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template?.name ?? 'Fatura',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[200]
                            : const Color(0xFF1C1C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          billPayment.statusDisplayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (template != null) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          Text(
                            template.categoryDisplayName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '-${CurrencyHelper.formatAmountCompact(billPayment.amount, _currentUser)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditBillPaymentScreen(payment: billPayment),
                      ),
                    );
                    if (result == true) {
                      await _loadData();
                    }
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Faturayı Sil'),
                        content: const Text(
                          'Bu fatura kaydını silmek istediğinizden emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Sil'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _billPaymentService.deletePayment(billPayment.id);
                      await _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fatura silindi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  const PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanInstallmentItem(Loan loan, LoanInstallment installment) {
    final color = installment.isPaid
        ? const Color(0xFF34C759)
        : const Color(0xFFFF3B30);
    final bankName = loan.bankName;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5E5CE6).withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoanDetailScreen(loan: loan),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF5E5CE6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[200]
                            : const Color(0xFF1C1C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          bankName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        Text(
                          '${installment.installmentNumber}/${loan.totalInstallments} Taksit',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-${CurrencyHelper.formatAmountCompact(installment.amount, _currentUser)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (installment.isPaid)
                    const Text(
                      'Ödendi',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF34C759),
                        fontWeight: FontWeight.bold,
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
}
