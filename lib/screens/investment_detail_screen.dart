import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';
import 'add_investment_screen.dart';

class InvestmentDetailScreen extends StatefulWidget {
  final Investment investment;
  const InvestmentDetailScreen({super.key, required this.investment});

  @override
  State<InvestmentDetailScreen> createState() => _InvestmentDetailScreenState();
}

class _InvestmentDetailScreenState extends State<InvestmentDetailScreen> {
  final InvestmentService _service = InvestmentService();
  late Investment _inv;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _inv = widget.investment;
  }

  Future<void> _refreshPrice() async {
    setState(() => _updating = true);
    final price = await _service.fetchPrice(_inv);
    if (price > 0) {
      _inv.currentPrice = price;
      await _service.update(_inv);
    }
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final pnl = _inv.profitLoss;
    final pnlPercent = _inv.profitLossPercent;
    final isPositive = pnl != null && pnl >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_inv.name} (${_inv.symbol})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (context) => AddInvestmentScreen(existing: _inv),
              ));
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Güncel Değer', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(format.format(_inv.currentValue ?? _inv.costBasis),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (pnl != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${format.format(pnl)} (${pnlPercent?.toStringAsFixed(2) ?? '0'}%)',
                          style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _updating ? null : _refreshPrice,
                icon: _updating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(_updating ? 'Güncelleniyor...' : 'Fiyatı Güncelle'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Detaylar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow('Tür', _typeLabel(_inv.type)),
            _detailRow('Sembol', _inv.symbol),
            _detailRow('Miktar', _inv.quantity.toString()),
            _detailRow('Alış Fiyatı', format.format(_inv.buyPrice)),
            _detailRow('Maliyet', format.format(_inv.costBasis)),
            _detailRow('Güncel Fiyat', _inv.currentPrice != null ? format.format(_inv.currentPrice!) : 'Henüz sorgulanmadı'),
            _detailRow('Alış Tarihi', DateFormat('dd.MM.yyyy').format(_inv.buyDate)),
            if (_inv.notes != null && _inv.notes!.isNotEmpty) _detailRow('Notlar', _inv.notes!),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _typeLabel(InvestmentType type) {
    switch (type) {
      case InvestmentType.crypto: return 'Kripto Para';
      case InvestmentType.stock: return 'Hisse Senedi';
      case InvestmentType.gold: return 'Altın';
      case InvestmentType.fund: return 'Fon';
      case InvestmentType.etf: return 'ETF';
    }
  }
}
