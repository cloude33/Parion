import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';
import 'investment_detail_screen.dart';
import 'add_investment_screen.dart';

class InvestmentListScreen extends StatefulWidget {
  const InvestmentListScreen({super.key});

  @override
  State<InvestmentListScreen> createState() => _InvestmentListScreenState();
}

class _InvestmentListScreenState extends State<InvestmentListScreen> {
  final InvestmentService _service = InvestmentService();
  List<Investment> _investments = [];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final investments = await _service.getAll();
    if (mounted) setState(() { _investments = investments; _loading = false; });
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _service.updateAllPrices();
    await _load();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _delete(Investment inv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yatırımı Sil'),
        content: Text('${inv.name} (${inv.symbol}) silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirm == true) {
      await _service.delete(inv.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yatırımlar'),
        actions: [
          if (_refreshing)
            const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _investments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Henüz yatırım eklenmemiş', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _addInvestment(),
                        icon: const Icon(Icons.add),
                        label: const Text('Yatırım Ekle'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _investments.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildPortfolioSummary(format);
                      final inv = _investments[index - 1];
                      return _buildInvestmentCard(inv, format);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addInvestment(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPortfolioSummary(NumberFormat format) {
    final totalCost = _investments.fold<double>(0, (s, i) => s + i.costBasis);
    final totalValue = _investments.fold<double>(0, (s, i) => s + (i.currentValue ?? 0));
    final totalPnL = totalValue - totalCost;
    final pnlPercent = totalCost > 0 ? (totalPnL / totalCost) * 100 : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Portföy Değeri', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(format.format(totalValue), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric('Maliyet', format.format(totalCost), Colors.grey),
                _metric('K/Z', format.format(totalPnL.abs()), totalPnL >= 0 ? Colors.green : Colors.red),
                _metric('Getiri', '${pnlPercent.toStringAsFixed(1)}%', totalPnL >= 0 ? Colors.green : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildInvestmentCard(Investment inv, NumberFormat format) {
    final pnl = inv.profitLoss;
    final pnlPercent = inv.profitLossPercent;
    final isPositive = pnl != null && pnl >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _typeColor(inv.type).withValues(alpha: 0.15),
          child: Text(_typeIcon(inv.type), style: TextStyle(fontSize: 18)),
        ),
        title: Text('${inv.name} (${inv.symbol})', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${inv.quantity} adet × ${format.format(inv.currentPrice ?? inv.buyPrice)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(format.format(inv.currentValue ?? inv.costBasis), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (pnl != null)
              Text(
                '${isPositive ? '+' : ''}${format.format(pnl)} (${pnlPercent?.toStringAsFixed(1) ?? '0'}%)',
                style: TextStyle(fontSize: 12, color: isPositive ? Colors.green : Colors.red),
              ),
          ],
        ),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (context) => InvestmentDetailScreen(investment: inv),
          ));
          _load();
        },
        onLongPress: () => _delete(inv),
      ),
    );
  }

  Color _typeColor(InvestmentType type) {
    switch (type) {
      case InvestmentType.crypto: return Colors.orange;
      case InvestmentType.stock: return Colors.blue;
      case InvestmentType.gold: return Colors.amber;
      case InvestmentType.fund: return Colors.purple;
      case InvestmentType.etf: return Colors.teal;
    }
  }

  String _typeIcon(InvestmentType type) {
    switch (type) {
      case InvestmentType.crypto: return '₿';
      case InvestmentType.stock: return '📈';
      case InvestmentType.gold: return '🥇';
      case InvestmentType.fund: return '🏦';
      case InvestmentType.etf: return '📊';
    }
  }

  Future<void> _addInvestment() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (context) => const AddInvestmentScreen(),
    ));
    _load();
  }
}
