import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../services/credit_card_service.dart';

class InstallmentTrackingScreen extends StatefulWidget {
  const InstallmentTrackingScreen({super.key});

  @override
  State<InstallmentTrackingScreen> createState() => _InstallmentTrackingScreenState();
}

class _InstallmentTrackingScreenState extends State<InstallmentTrackingScreen> {
  final CreditCardService _cardService = CreditCardService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  List<CreditCard> _cards = [];
  List<CreditCardTransaction> _allInstallments = [];
  Map<String, List<CreditCardTransaction>> _installmentsByCard = {};
  bool _isLoading = true;
  String _selectedFilter = 'active'; // active, completed, all

  // Summary values
  double _totalRemainingDebt = 0;
  double _monthlyPayment = 0;
  int _activeInstallmentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  Future<void> _loadInstallments() async {
    setState(() => _isLoading = true);

    try {
      final cards = await _cardService.getActiveCards();
      final allInstallments = <CreditCardTransaction>[];
      final installmentsByCard = <String, List<CreditCardTransaction>>{};

      for (var card in cards) {
        final transactions = await _cardService.getCardTransactions(card.id);
        // Sadece taksitli işlemleri filtrele (installmentCount > 1)
        final installments = transactions
            .where((t) => t.installmentCount > 1)
            .toList();

        if (installments.isNotEmpty) {
          installmentsByCard[card.id] = installments;
          allInstallments.addAll(installments);
        }
      }

      // Özet değerleri hesapla
      double totalRemaining = 0;
      double monthlyPayment = 0;
      int activeCount = 0;

      for (var t in allInstallments) {
        if (!t.isCompleted) {
          totalRemaining += t.remainingAmount;
          monthlyPayment += t.installmentAmount;
          activeCount++;
        }
      }

      setState(() {
        _cards = cards;
        _allInstallments = allInstallments;
        _installmentsByCard = installmentsByCard;
        _totalRemainingDebt = totalRemaining;
        _monthlyPayment = monthlyPayment;
        _activeInstallmentCount = activeCount;
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

  List<CreditCardTransaction> get _filteredInstallments {
    switch (_selectedFilter) {
      case 'active':
        return _allInstallments.where((t) => !t.isCompleted).toList();
      case 'completed':
        return _allInstallments.where((t) => t.isCompleted).toList();
      default:
        return _allInstallments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _allInstallments.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  _buildSummaryCard(),
                  _buildFilterChips(),
                  Expanded(child: _buildInstallmentList()),
                ],
              );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Kalan Taksit Borcu',
                    _currencyFormat.format(_totalRemainingDebt),
                    Colors.red,
                    Icons.credit_score,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Aylık Ödeme',
                    _currencyFormat.format(_monthlyPayment),
                    Colors.orange,
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.format_list_numbered, color: Color(0xFF00BFA5)),
                  const SizedBox(width: 8),
                  Text(
                    '$_activeInstallmentCount Aktif Taksitli İşlem',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BFA5),
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

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Aktif', 'active'),
          const SizedBox(width: 8),
          _buildFilterChip('Tamamlanan', 'completed'),
          const SizedBox(width: 8),
          _buildFilterChip('Tümü', 'all'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: const Color(0xFF00BFA5).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFF00BFA5),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_score, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Taksitli işlem bulunamadı',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Kredi kartlarınıza taksitli harcama\neklendiğinde burada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentList() {
    final filteredList = _filteredInstallments;
    
    // Kartlara göre grupla
    final groupedByCard = <String, List<CreditCardTransaction>>{};
    for (var t in filteredList) {
      groupedByCard.putIfAbsent(t.cardId, () => []);
      groupedByCard[t.cardId]!.add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedByCard.length,
      itemBuilder: (context, index) {
        final cardId = groupedByCard.keys.elementAt(index);
        final installments = groupedByCard[cardId]!;
        final card = _cards.firstWhere(
          (c) => c.id == cardId,
          orElse: () => CreditCard(
            id: '',
            bankName: 'Bilinmeyen',
            cardName: 'Kart',
            last4Digits: '0000',
            creditLimit: 0,
            statementDay: 1,
            dueDateOffset: 10,
            monthlyInterestRate: 0,
            lateInterestRate: 0,
            cardColor: 0xFF424242,
            createdAt: DateTime.now(),
          ),
        );

        return _buildCardSection(card, installments);
      },
    );
  }

  Widget _buildCardSection(CreditCard card, List<CreditCardTransaction> installments) {
    // Karta ait toplam kalan borç
    final cardRemainingDebt = installments
        .where((t) => !t.isCompleted)
        .fold<double>(0, (sum, t) => sum + t.remainingAmount);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kart başlığı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(card.cardColor).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(card.cardColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${card.bankName} ${card.cardName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '•••• ${card.last4Digits}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Kalan',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      _currencyFormat.format(cardRemainingDebt),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Taksitli işlemler listesi
          ...installments.map((t) => _buildInstallmentItem(t)),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(CreditCardTransaction transaction) {
    final progress = transaction.installmentsPaid / transaction.installmentCount;
    final isCompleted = transaction.isCompleted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.grey : Colors.black87,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy', 'tr_TR').format(transaction.transactionDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(transaction.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  Text(
                    '${_currencyFormat.format(transaction.installmentAmount)}/ay',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // İlerleme çubuğu
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : const Color(0xFF00BFA5),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.1)
                      : const Color(0xFF00BFA5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${transaction.installmentsPaid}/${transaction.installmentCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : const Color(0xFF00BFA5),
                  ),
                ),
              ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kalan: ${_currencyFormat.format(transaction.remainingAmount)}',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
                Text(
                  '${transaction.remainingInstallments} taksit kaldı',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
