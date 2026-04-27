import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../services/credit_card_service.dart';
import 'edit_credit_card_transaction_screen.dart';
import 'installment_detail_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  final CreditCard card;

  const AllTransactionsScreen({super.key, required this.card});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final CreditCardService _cardService = CreditCardService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  bool _isLoading = true;
  List<CreditCardTransaction> _allTransactions = [];
  List<CreditCardTransaction> _filteredTransactions = [];
  String _selectedFilter = 'all';

  final Map<String, String> _filterOptions = {
    'all': 'Tümü',
    'installment': 'Taksitli',
    'single': 'Tek Çekim',
    'deferred': 'Ertelenmiş',
  };

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _cardService.getCardTransactions(widget.card.id);
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      setState(() {
        _allTransactions = transactions;
        _filteredTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      
      switch (filter) {
        case 'installment':
          _filteredTransactions = _allTransactions
              .where((t) => t.installmentCount > 1 && t.installmentStartDate == null)
              .toList();
          break;
        case 'single':
          _filteredTransactions = _allTransactions
              .where((t) => t.installmentCount == 1)
              .toList();
          break;
        case 'deferred':
          _filteredTransactions = _allTransactions
              .where((t) => t.installmentStartDate != null)
              .toList();
          break;
        default:
          _filteredTransactions = _allTransactions;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm İşlemler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _applyFilter(entry.key);
                  }
                },
                selectedColor: widget.card.color.withValues(alpha: 0.3),
                checkmarkColor: widget.card.color,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'İşlem bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seçili filtreye uygun işlem yok',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Group transactions by month
    final groupedTransactions = <String, List<CreditCardTransaction>>{};
    
    for (final transaction in _filteredTransactions) {
      final monthKey = DateFormat('MMMM yyyy', 'tr_TR').format(transaction.transactionDate);
      groupedTransactions.putIfAbsent(monthKey, () => []);
      groupedTransactions[monthKey]!.add(transaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final monthKey = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[monthKey]!;
        final monthTotal = transactions.fold<double>(
          0,
          (sum, t) => sum + t.amount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthKey,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(monthTotal),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildTransactionItem(transactions[index]);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(CreditCardTransaction transaction) {
    final isInstallment = transaction.installmentCount > 1;
    final isDeferred = transaction.installmentStartDate != null;

    IconData icon;
    Color iconColor;

    if (isDeferred) {
      icon = Icons.schedule_outlined;
      iconColor = Colors.orange;
    } else if (isInstallment) {
      icon = Icons.credit_card;
      iconColor = widget.card.color;
    } else {
      icon = Icons.shopping_bag;
      iconColor = Colors.blue;
    }

    return ListTile(
      onTap: () => _navigateToTransaction(transaction),
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.2),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd MMM yyyy', 'tr_TR').format(transaction.transactionDate)} • ${transaction.category}',
            style: const TextStyle(fontSize: 12),
          ),
          if (isInstallment) ...[
            const SizedBox(height: 2),
            Text(
              isDeferred
                  ? 'Ertelenmiş: ${transaction.installmentCount}x ${_currencyFormat.format(transaction.installmentAmount)}'
                  : '${transaction.installmentsPaid}/${transaction.installmentCount} taksit',
              style: TextStyle(
                fontSize: 11,
                color: isDeferred ? Colors.orange[700] : Colors.grey[600],
                fontWeight: isDeferred ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _currencyFormat.format(transaction.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (isInstallment && !isDeferred)
            Text(
              _currencyFormat.format(transaction.remainingAmount),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToTransaction(CreditCardTransaction transaction) async {
    Widget screen;
    
    if (transaction.installmentCount > 1) {
      screen = InstallmentDetailScreen(
        card: widget.card,
        transaction: transaction,
      );
    } else {
      screen = EditCreditCardTransactionScreen(
        card: widget.card,
        transaction: transaction,
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (result == true) {
      _loadTransactions();
    }
  }
}
