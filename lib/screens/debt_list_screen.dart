import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';
import 'debt_statistics_screen.dart';
import '../models/user.dart';
import '../services/data_service.dart';
import '../utils/currency_helper.dart';
import '../l10n/app_localizations.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen>
    with SingleTickerProviderStateMixin {
  final DebtService _debtService = DebtService();
  late TabController _tabController;

  List<Debt> _allDebts = [];
  List<Debt> _filteredDebts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  double _totalLent = 0;
  double _totalBorrowed = 0;
  double _netBalance = 0;
  User? _currentUser;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadDebts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _filterDebts();
    }
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);

    try {
      final debts = await _debtService.getDebts(forceRefresh: true);
      final user = await _dataService.getCurrentUser();
      final lent = await _debtService.getTotalLent();
      final borrowed = await _debtService.getTotalBorrowed();
      final net = await _debtService.getNetBalance();

      setState(() {
        _allDebts = debts;
        _currentUser = user;
        _totalLent = lent;
        _totalBorrowed = borrowed;
        _netBalance = net;
        _isLoading = false;
      });

      _filterDebts();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _filterDebts() {
    List<Debt> filtered = _allDebts;
    switch (_tabController.index) {
      case 0:
        break;
      case 1:
        filtered = filtered.where((d) => d.type == DebtType.lent).toList();
        break;
      case 2:
        filtered = filtered.where((d) => d.type == DebtType.borrowed).toList();
        break;
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (d) =>
                d.personName.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    filtered.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      return b.createdDate.compareTo(a.createdDate);
    });

    setState(() => _filteredDebts = filtered);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterDebts();
  }

  Future<void> _navigateToAddDebt() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDebtScreen()),
    );

    if (result == true) {
      _loadDebts();
    }
  }

  Future<void> _navigateToDebtDetail(Debt debt) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DebtDetailScreen(debtId: debt.id),
      ),
    );

    if (result == true) {
      _loadDebts();
    }
  }

  String _getLocalizedCategory(DebtCategory category) {
    switch (category) {
      case DebtCategory.friend:
        return AppLocalizations.of(context)!.debtCategoryFriend;
      case DebtCategory.family:
        return AppLocalizations.of(context)!.debtCategoryFamily;
      case DebtCategory.business:
        return AppLocalizations.of(context)!.debtCategoryBusiness;
      case DebtCategory.other:
        return AppLocalizations.of(context)!.debtCategoryOther;
    }
  }

  String _getLocalizedDueDateStatus(Debt debt) {
    if (debt.dueDate == null) return AppLocalizations.of(context)!.noDueDate;
    if (debt.isPaid) return AppLocalizations.of(context)!.paid;

    final now = DateTime.now();
    final difference = debt.dueDate!.difference(now).inDays;

    if (difference < 0) {
      return AppLocalizations.of(context)!.daysOverdue(difference.abs().toString());
    } else if (difference == 0) {
      return AppLocalizations.of(context)!.dueToday;
    } else if (difference <= 3) {
      return AppLocalizations.of(context)!.daysLeft(difference.toString());
    } else {
      final dateStr = DateFormat('dd.MM.yyyy').format(debt.dueDate!);
      return AppLocalizations.of(context)!.dueDateLabel(dateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.debtsTracking),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebtStatisticsScreen(),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.stats,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchPerson,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.white.withValues(alpha: 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.all),
                  Tab(text: AppLocalizations.of(context)!.lent),
                  Tab(text: AppLocalizations.of(context)!.borrowed),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDebts,
              child: Column(
                children: [
                  _buildSummaryCard(),
                  Expanded(
                    child: _filteredDebts.isEmpty
                        ? _buildEmptyState()
                        : _buildDebtList(),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddDebt,
        child: const Icon(Icons.add),
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
            Text(
              AppLocalizations.of(context)!.summary,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  AppLocalizations.of(context)!.asset,
                  CurrencyHelper.formatAmountCompact(_totalLent, _currentUser),
                  Colors.green,
                  Icons.trending_up,
                ),
                _buildSummaryItem(
                  AppLocalizations.of(context)!.borrowed, // Borrowed as label
                  CurrencyHelper.formatAmountCompact(_totalBorrowed, _currentUser),
                  Colors.red,
                  Icons.trending_down,
                ),
                _buildSummaryItem(
                  AppLocalizations.of(context)!.net,
                  CurrencyHelper.formatAmountCompact(_netBalance, _currentUser),
                  _netBalance >= 0 ? Colors.green : Colors.red,
                  _netBalance >= 0 ? Icons.add_circle : Icons.remove_circle,
                ),
              ],
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
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noDebts,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.clickToAddDebt,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredDebts.length,
      itemBuilder: (context, index) {
        final debt = _filteredDebts[index];
        return _buildDebtCard(debt);
      },
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final isLent = debt.type == DebtType.lent;
    final color = isLent ? Colors.green : Colors.red;
    final icon = isLent ? Icons.trending_up : Icons.trending_down;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDebtDetail(debt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLocalizedCategory(debt.category),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyHelper.formatAmountCompact(debt.remainingAmount, _currentUser),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (debt.originalAmount != debt.remainingAmount)
                        Text(
                        '/ ${CurrencyHelper.formatAmountCompact(debt.originalAmount, _currentUser)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        ),
                    ],
                  ),
                ],
              ),
              if (debt.dueDate != null || debt.description != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
              ],
              if (debt.dueDate != null)
                Row(
                  children: [
                    Icon(
                      debt.isOverdue ? Icons.warning : Icons.calendar_today,
                      size: 16,
                      color: debt.isOverdue ? Colors.orange : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getLocalizedDueDateStatus(debt),
                      style: TextStyle(
                        fontSize: 12,
                        color: debt.isOverdue
                            ? Colors.orange
                            : Colors.grey[600],
                        fontWeight: debt.isOverdue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              if (debt.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  debt.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (debt.paymentPercentage > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: debt.paymentPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.paidPercentage(debt.paymentPercentage.toStringAsFixed(0)),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


