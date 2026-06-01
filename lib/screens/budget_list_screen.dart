import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cash_flow_data.dart';
import '../services/budget_service.dart';
import '../services/data_service.dart';
import '../widgets/statistics/budget_tracker_card.dart';
import 'add_budget_screen.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  final _budgetService = BudgetService();
  final _dataService = DataService();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  DateTime _selectedMonth = DateTime.now();
  Map<String, BudgetComparison> _comparisons = {};
  Map<String, Color> _categoryColors = {};
  double _totalBudget = 0;
  double _totalSpent = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final comparisons = await _budgetService.getComparisons(_selectedMonth.year, _selectedMonth.month);
      final categories = await _dataService.getCategories();
      final colors = <String, Color>{};
      for (final c in categories.where((c) => c.type == 'expense')) {
        colors[c.name] = c.color;
      }
      final totalBudget = await _budgetService.getTotalBudget(_selectedMonth.year, _selectedMonth.month);
      final totalSpent = await _budgetService.getTotalSpent(_selectedMonth.year, _selectedMonth.month);

      setState(() {
        _comparisons = comparisons;
        _categoryColors = colors;
        _totalBudget = totalBudget;
        _totalSpent = totalSpent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToAddBudget() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _editBudget(BudgetComparison comparison) async {
    final existing = (await _budgetService.getBudgets(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    )).where((b) => b.category == comparison.category).firstOrNull;

    if (existing == null) return;

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddBudgetScreen(existingBudget: existing)),
    );
    if (!mounted) return;
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Bütçe Yönetimi'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _navigateToAddBudget),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 16),
                  _buildSummaryRow(),
                  const SizedBox(height: 16),
                  _comparisons.isEmpty
                      ? _buildEmptyState()
                      : BudgetTrackerCard(
                          budgetComparisons: _comparisons,
                          categoryColors: _categoryColors,
                        ),
                  if (_comparisons.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showEditDialog(),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Bütçeleri Düzenle'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddBudget,
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Bütçe Ekle'),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month),
        title: Text(DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
                _load();
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final remaining = _totalBudget - _totalSpent;
    final usage = _totalBudget > 0 ? (_totalSpent / _totalBudget) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildMetric('Bütçe', _currencyFormat.format(_totalBudget), Colors.blue)),
                Expanded(child: _buildMetric('Harcanan', _currencyFormat.format(_totalSpent), Colors.orange)),
                Expanded(
                  child: _buildMetric(
                    remaining >= 0 ? 'Kalan' : 'Fazla',
                    _currencyFormat.format(remaining.abs()),
                    remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (usage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(usage > 100 ? Colors.red : Colors.green),
              ),
            ),
            const SizedBox(height: 4),
            Text('${usage.toStringAsFixed(1)}% kullanıldı', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Henüz bütçe belirlenmemiş', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Alt taraftaki butona tıklayarak\nkategorilere bütçe ekleyin',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Bütçeler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._comparisons.entries.map((e) => ListTile(
            leading: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: _categoryColors[e.key] ?? Colors.grey, shape: BoxShape.circle),
            ),
            title: Text(e.key),
            subtitle: Text('${_currencyFormat.format(e.value.budget)} → ${_currencyFormat.format(e.value.actual)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                final budgets = await _budgetService.getBudgets(year: _selectedMonth.year, month: _selectedMonth.month);
                final b = budgets.where((b) => b.category == e.key).firstOrNull;
                if (b != null) {
                  await _budgetService.deleteBudget(b.id);
                  if (!mounted) return;
                  _load();
                }
                if (context.mounted) Navigator.pop(ctx);
              },
            ),
            onTap: () {
              Navigator.pop(ctx);
              _editBudget(e.value);
            },
          )),
        ],
      ),
    );
  }
}
