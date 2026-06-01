import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../models/recurrence_frequency.dart';
import '../repositories/recurring_transaction_repository.dart';

class SubscriptionListScreen extends StatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  final _repo = RecurringTransactionRepository();
  List<RecurringTransaction> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      await _repo.init();
      final all = _repo.getAll();
      setState(() {
        _subscriptions = all.where((s) =>
          !s.isIncome && s.isActive && (s.category == 'Abonelik' || s.category == 'Eğlence')
        ).toList();
        _subscriptions.sort((a, b) => a.nextDate?.compareTo(b.nextDate ?? DateTime(9999)) ?? 0);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalMonthly {
    double total = 0;
    for (final s in _subscriptions) {
      switch (s.frequency) {
        case RecurrenceFrequency.daily:
          total += s.amount * 30;
        case RecurrenceFrequency.weekly:
          total += s.amount * 4.3;
        case RecurrenceFrequency.monthly:
          total += s.amount;
        case RecurrenceFrequency.yearly:
          total += s.amount / 12;
      }
    }
    return total;
  }

  double get _totalYearly => _totalMonthly * 12;

  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');

  IconData _iconForCategory(String category) {
    if (category == 'Abonelik') return Icons.subscriptions;
    if (category == 'Eğlence') return Icons.movie;
    return Icons.repeat;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Aboneliklerim'), centerTitle: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(theme),
                  const SizedBox(height: 16),
                  if (_subscriptions.isEmpty) _buildEmptyState()
                  else ..._subscriptions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildSubscriptionCard(s, theme),
                  )),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFE91E63).withValues(alpha: 0.1), const Color(0xFF9C27B0).withValues(alpha: 0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aylık Abonelik', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(_currencyFormat.format(_totalMonthly),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFE91E63))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Yıllık', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(_currencyFormat.format(_totalYearly),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF9C27B0))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.subscriptions, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('${_subscriptions.length} aktif abonelik', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(RecurringTransaction sub, ThemeData theme) {
    final nextDate = sub.nextDate;
    final isDueSoon = nextDate != null && nextDate.difference(DateTime.now()).inDays <= 3;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDueSoon ? Colors.red.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: sub.category == 'Abonelik' ? const Color(0xFFE91E63).withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_iconForCategory(sub.category), color: sub.category == 'Abonelik' ? const Color(0xFFE91E63) : Colors.blue),
        ),
        title: Text(sub.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          nextDate != null ? 'Sonraki: ${_dateFormat.format(nextDate)}' : 'Süresi doldu',
          style: TextStyle(fontSize: 12, color: isDueSoon ? Colors.red : Colors.grey[500]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_currencyFormat.format(sub.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(_frequencyLabel(sub.frequency), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        isThreeLine: false,
      ),
    );
  }

  String _frequencyLabel(RecurrenceFrequency f) {
    switch (f) {
      case RecurrenceFrequency.daily: return '/gün';
      case RecurrenceFrequency.weekly: return '/hafta';
      case RecurrenceFrequency.monthly: return '/ay';
      case RecurrenceFrequency.yearly: return '/yıl';
    }
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Aktif abonelik bulunamadı', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Düzenli harcamalarınıza abonelik\nkategorisi ekleyin, burada görünsün',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }
}
