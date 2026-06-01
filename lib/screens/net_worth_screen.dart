import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../models/loan.dart';
import '../services/data_service.dart';
import '../services/kmh_service.dart';
import '../services/credit_card_service.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  final _dataService = DataService();
  final _kmhService = KmhService();
  final _ccService = CreditCardService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  bool _isLoading = true;

  // Varlıklar
  double _cashBalance = 0;
  double _bankBalance = 0;

  // Borçlar
  double _kmhDebt = 0;
  double _creditCardDebt = 0;
  double _loanDebt = 0;
  final double _otherDebt = 0;

  List<Wallet> _wallets = [];
  List<Loan> _loans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final wallets = await _dataService.getWallets();
      final loans = await _dataService.getLoans();

      double cash = 0, bank = 0;
      for (final w in wallets) {
        if (w.type == 'cash') {
          cash += w.balance;
        } else if (w.type == 'bank' && !w.isKmhAccount) {
          bank += w.balance;
        }
      }

      double kmhDebt = 0;
      for (final w in wallets.where((w) => w.isKmhAccount)) {
        if (w.balance < 0) kmhDebt += w.balance.abs();
        final summary = await _kmhService.getAccountSummary(w.id);
        kmhDebt += summary.accruedInterest;
      }

      final ccDebt = await _ccService.getTotalDebtAllCards();
      final loanDebt = loans.fold<double>(0, (sum, l) => sum + l.remainingAmount);

      setState(() {
        _cashBalance = cash;
        _bankBalance = bank;
        _kmhDebt = kmhDebt;
        _creditCardDebt = ccDebt;
        _loanDebt = loanDebt;
        _wallets = wallets;
        _loans = loans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalAssets => _cashBalance + _bankBalance;
  double get _totalLiabilities => _kmhDebt + _creditCardDebt + _loanDebt;
  double get _netWorth => _totalAssets - _totalLiabilities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Net Değer'), centerTitle: false, actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildNetWorthCard(theme),
                  const SizedBox(height: 16),
                  _buildSection(theme, 'Varlıklar', Icons.trending_up, Colors.green, [
                    _item('Nakit', _cashBalance, Colors.green),
                    _item('Banka Hesabı', _bankBalance, Colors.blue),
                  ], _totalAssets),
                  const SizedBox(height: 12),
                  _buildSection(theme, 'Borçlar', Icons.trending_down, Colors.red, [
                    _item('KMH Borcu', _kmhDebt, Colors.red),
                    _item('Kredi Kartı', _creditCardDebt, Colors.orange),
                    _item('Krediler', _loanDebt, Colors.deepOrange),
                  ], _totalLiabilities),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Net Değer = Varlıklar - Borçlar',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNetWorthCard(ThemeData theme) {
    final isPositive = _netWorth >= 0;
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isPositive
                ? [Colors.green.withValues(alpha: 0.1), Colors.teal.withValues(alpha: 0.05)]
                : [Colors.red.withValues(alpha: 0.1), Colors.orange.withValues(alpha: 0.05)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Net Değer', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(_netWorth.abs()),
              style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w800,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(isPositive ? 'Pozitif' : 'Negatif', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _netWorthMetric('Varlıklar', _currencyFormat.format(_totalAssets), Colors.green)),
                Container(width: 1, height: 30, color: Colors.grey[200]),
                Expanded(child: _netWorthMetric('Borçlar', _currencyFormat.format(_totalLiabilities), Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _netWorthMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, Color color, List<Widget> items, double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(_currencyFormat.format(total), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _item(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(_currencyFormat.format(amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
