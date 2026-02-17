import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/wallet.dart';
import '../services/credit_card_service.dart';
import '../services/data_service.dart';
import 'add_credit_card_screen.dart';
import 'credit_card_detail_screen.dart';
import 'card_reporting_screen.dart';
import 'kmh_list_screen.dart';
import 'kmh_account_detail_screen.dart';
import 'add_wallet_screen.dart';
import 'installment_tracking_screen.dart';
import '../widgets/cards/bank_card_visual_widget.dart';

class CreditCardListScreen extends StatefulWidget {
  const CreditCardListScreen({super.key});

  @override
  State<CreditCardListScreen> createState() => _CreditCardListScreenState();
}

class _CreditCardListScreenState extends State<CreditCardListScreen> {
  final CreditCardService _cardService = CreditCardService();
  final DataService _dataService = DataService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  List<CreditCard> _cards = [];
  Map<String, Map<String, dynamic>> _cardDetails = {};
  List<Wallet> _kmhAccounts = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Credit Cards, 1: KMH Accounts, 2: Installments

  double _totalDebt = 0;
  double _totalAvailableCredit = 0;
  double _totalDueThisMonth = 0;

  double _totalKmhDebt = 0;
  double _totalKmhAvailableCredit = 0;
  double _totalKmhCreditLimit = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);

    try {
      final cards = await _cardService.getActiveCards();
      final totalDebt = await _cardService.getTotalDebtAllCards();
      final totalAvailable = await _cardService.getTotalAvailableCredit();
      final totalDue = await _cardService.getTotalDueThisMonth();
      final details = <String, Map<String, dynamic>>{};
      for (var card in cards) {
        details[card.id] = await _cardService.getCardWithDetails(card.id);
      }

      // Load KMH accounts
      final wallets = await _dataService.getWallets();
      final kmhAccounts = wallets.where((w) => w.isKmhAccount).toList();

      double totalKmhDebt = 0;
      double totalKmhAvailableCredit = 0;
      double totalKmhCreditLimit = 0;

      for (var account in kmhAccounts) {
        totalKmhDebt += account.usedCredit;
        totalKmhAvailableCredit += account.availableCredit;
        totalKmhCreditLimit += account.creditLimit;
      }

      setState(() {
        _cards = cards;
        _cardDetails = details;
        _totalDebt = totalDebt;
        _totalAvailableCredit = totalAvailable;
        _totalDueThisMonth = totalDue;
        _kmhAccounts = kmhAccounts;
        _totalKmhDebt = totalKmhDebt;
        _totalKmhAvailableCredit = totalKmhAvailableCredit;
        _totalKmhCreditLimit = totalKmhCreditLimit;
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

  Future<void> _deleteCard(CreditCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı Sil'),
        content: Text(
          '${card.bankName} ${card.cardName} kartını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cardService.deleteCard(card.id);
        _loadCards();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Kart silindi')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _selectedTab == 0
              ? 'Kredi Kartlarım'
              : _selectedTab == 1
              ? 'KMH Hesaplarım'
              : 'Taksit Takibi',
        ),
        actions: [
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Raporlar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CardReportingScreen(),
                  ),
                );
              },
            ),
          if (_selectedTab == 1 && _kmhAccounts.length > 1)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Hesapları Karşılaştır',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KmhListScreen(),
                  ),
                ).then((_) => _loadCards());
              },
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCards),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabSelector(),
                if (_selectedTab == 0) _buildSummaryCard(),
                if (_selectedTab == 1) _buildKmhSummaryCard(),
                Expanded(
                  child: _selectedTab == 0
                      ? (_cards.isEmpty ? _buildEmptyState() : _buildCardList())
                      : _selectedTab == 1
                      ? (_kmhAccounts.isEmpty
                            ? _buildKmhEmptyState()
                            : _buildKmhAccountList())
                      : const InstallmentTrackingScreen(),
                ),
              ],
            ),
      floatingActionButton: _selectedTab != 2
          ? FloatingActionButton(
              onPressed: _selectedTab == 0
                  ? _navigateToAddCard
                  : _navigateToAddKmhAccount,
              tooltip: _selectedTab == 0 ? 'Kart Ekle' : 'KMH Hesabı Ekle',
              child: Icon(_selectedTab == 0 ? Icons.add_card : Icons.add),
            )
          : null,
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2E)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF00BFA5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: _selectedTab == 0
                          ? Colors.white
                          : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kartlar',
                      style: TextStyle(
                        color: _selectedTab == 0
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: _selectedTab == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFF00BFA5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: _selectedTab == 1
                          ? Colors.white
                          : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'KMH',
                      style: TextStyle(
                        color: _selectedTab == 1
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: _selectedTab == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 2
                      ? const Color(0xFF00BFA5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      color: _selectedTab == 2
                          ? Colors.white
                          : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Taksitler',
                      style: TextStyle(
                        color: _selectedTab == 2
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: _selectedTab == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Toplam Borç',
                  _currencyFormat.format(_totalDebt),
                  Colors.red,
                  Icons.credit_card,
                ),
                _buildSummaryItem(
                  'Kullanılabilir Limit',
                  _currencyFormat.format(_totalAvailableCredit),
                  Colors.green,
                  Icons.account_balance_wallet,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Bu Ay Ödenecek: ${_currencyFormat.format(_totalDueThisMonth)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
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

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz kredi kartı eklenmemiş',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Kredi kartlarınızı takip etmeye başlamak için\n"Kart Ekle" butonuna tıklayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _cards.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = _cards.removeAt(oldIndex);
          _cards.insert(newIndex, item);
        });

        // Save the new order
        await _cardService.reorderCards(_cards);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue = Curves.easeInOut.transform(
              animation.value,
            );
            final double elevation = lerpDouble(0, 6, animValue)!;
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final card = _cards[index];
        final details = _cardDetails[card.id];
        return Padding(
          key: ValueKey(card.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCardItemContent(card, details),
        );
      },
    );
  }

  Widget _buildCardItemContent(CreditCard card, Map<String, dynamic>? details) {
    if (details == null) {
      return const Card(child: ListTile(title: Text('Yükleniyor...')));
    }

    final currentDebt = details['currentDebt'] as double;
    final nextDueDate = details['nextDueDate'] as DateTime;

    return BankCardVisualWidget(
      bankName: card.bankName,
      cardName: card.cardName,
      last4Digits: card.last4Digits,
      currentDebt: currentDebt,
      limit: card.creditLimit,
      colorHex: card.cardColor.toString(),
      cutOffDay: card.statementDay,
      fullPaymentDate: nextDueDate,
      onTap: () => _navigateToCardDetail(card),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderableDragStartListener(
            index: _cards.indexOf(card),
            child: const Icon(
              Icons.drag_handle,
              color: Colors.white70,
              size: 24,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteCard(card);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  Future<void> _navigateToAddCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCreditCardScreen()),
    );

    if (result == true) {
      _loadCards();
    }
  }

  Future<void> _navigateToCardDetail(CreditCard card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditCardDetailScreen(card: card),
      ),
    );

    if (result == true) {
      _loadCards();
    }
  }

  // KMH Account Methods
  Future<void> _navigateToAddKmhAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddWalletScreen(initialType: 'overdraft'),
      ),
    );

    if (result == true) {
      _loadCards();
    }
  }

  Future<void> _navigateToKmhAccountDetail(Wallet account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KmhAccountDetailScreen(account: account),
      ),
    );

    if (result == true) {
      _loadCards();
    }
  }

  Widget _buildKmhSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Toplam Borç',
                  _currencyFormat.format(_totalKmhDebt),
                  Colors.red,
                  Icons.trending_down,
                ),
                _buildSummaryItem(
                  'Kullanılabilir Limit',
                  _currencyFormat.format(_totalKmhAvailableCredit),
                  Colors.green,
                  Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Toplam Limit: ${_currencyFormat.format(_totalKmhCreditLimit)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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

  Widget _buildKmhEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz KMH hesabı eklenmemiş',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'KMH hesaplarınızı takip etmeye başlamak için\n"KMH Hesabı Ekle" butonuna tıklayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildKmhAccountList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _kmhAccounts.length,
      itemBuilder: (context, index) {
        final account = _kmhAccounts[index];
        return _buildKmhAccountCard(account);
      },
    );
  }

  Widget _buildKmhAccountCard(Wallet account) {
    final utilizationColor = _getUtilizationColor(account.utilizationRate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToKmhAccountDetail(account),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(account.color),
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Color(int.parse(account.color)),
                      size: 28,
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
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (account.accountNumber != null)
                          Text(
                            '•••• ${account.accountNumber!.substring(account.accountNumber!.length - 4)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: utilizationColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${account.utilizationRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: utilizationColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Mevcut Bakiye',
                      _currencyFormat.format(account.balance),
                      account.balance < 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Kullanılan Kredi',
                      _currencyFormat.format(account.usedCredit),
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: account.utilizationRate / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(utilizationColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Kullanılabilir: ${_currencyFormat.format(account.availableCredit)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (account.interestRate != null)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.percent,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Faiz: %${account.interestRate!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  Color _getUtilizationColor(double utilization) {
    if (utilization >= 80) {
      return Colors.red;
    } else if (utilization >= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
