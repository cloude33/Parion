import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/credit_card_transaction.dart';
import '../models/user.dart';
import '../utils/currency_helper.dart';
import '../services/data_service.dart';
import '../services/credit_card_service.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final DataService _dataService = DataService();
  final CreditCardService _creditCardService = CreditCardService();
  final TextEditingController _searchController = TextEditingController();
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  List<CreditCardTransaction> _creditCardTransactions = [];
  bool _loading = true;
  bool _showIncome = false;
  String _searchQuery = '';
  bool _showStats = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final user = await _dataService.getCurrentUser();
    final categories = (await _dataService.getCategories()).cast<Category>();
    final transactions = await _dataService.getTransactions();
    
    final cards = await _creditCardService.getActiveCards();
    final ccTransactions = <CreditCardTransaction>[];
    for (var card in cards) {
      final txs = await _creditCardService.getCardTransactions(card.id);
      ccTransactions.addAll(txs);
    }

    setState(() {
      _currentUser = user;
      _categories = categories;
      _transactions = transactions;
      _creditCardTransactions = ccTransactions;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, int> _getCategoryUsageCount() {
    final usageMap = <String, int>{};
    for (var transaction in _transactions) {
      final key = transaction.category.trim().toLowerCase();
      usageMap[key] = (usageMap[key] ?? 0) + 1;
    }
    for (var transaction in _creditCardTransactions) {
      final key = transaction.category.trim().toLowerCase();
      usageMap[key] = (usageMap[key] ?? 0) + 1;
    }
    return usageMap;
  }

  Map<String, double> _getCategoryTotalAmount() {
    final amountMap = <String, double>{};
    for (var transaction in _transactions) {
      final key = transaction.category.trim().toLowerCase();
      amountMap[key] = (amountMap[key] ?? 0) + transaction.amount;
    }
    for (var transaction in _creditCardTransactions) {
      final key = transaction.category.trim().toLowerCase();
      amountMap[key] = (amountMap[key] ?? 0) + transaction.amount;
    }
    return amountMap;
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _editCategory(Category category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(category: category),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final usageCount = _getCategoryUsageCount()[category.name] ?? 0;

    if (usageCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.categoryInUse),
          content: Text(
            '${category.name} ${AppLocalizations.of(context)!.categoryInUseDesc(usageCount)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.deleteAnyway),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.delete),
          content: Text(
            '${category.name} kategorisini silmek istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await _dataService.deleteCategory(category.id);
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCategoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _showIncome
            ? const Color(0xFFFF5252) // Kırmızı header gider için
            : const Color(0xFF4CAF50), // Yeşil header gelir için
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.categories,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showStats ? Icons.bar_chart : Icons.bar_chart_outlined,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showStats = !_showStats),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _addCategory,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showIncome = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showIncome
                          ? Colors
                                .white // Beyaz zemin aktif gelir butonu için
                          : Colors.white.withValues(
                              alpha: 0.2,
                            ), // Şeffaf beyaz pasif için
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_categories.where((c) => c.type == 'income').length} ${AppLocalizations.of(context)!.income.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_showIncome
                            ? const Color(
                                0xFF4CAF50,
                              ) // Yeşil yazı aktif gelir için
                            : Colors.white.withValues(
                                alpha: 0.7,
                              ), // Şeffaf beyaz yazı pasif için
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showIncome = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showIncome
                          ? Colors
                                .white // Beyaz zemin aktif gider butonu için
                          : Colors.white.withValues(
                              alpha: 0.2,
                            ), // Şeffaf beyaz pasif için
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_categories.where((c) => c.type == 'expense').length} ${AppLocalizations.of(context)!.expense.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _showIncome
                            ? const Color(
                                0xFFFF5252,
                              ) // Kırmızı yazı aktif gider için
                            : Colors.white.withValues(
                                alpha: 0.7,
                              ), // Şeffaf beyaz yazı pasif için
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchCategory,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00BFA5)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade50,
        ),
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildCategoryList() {
    var filteredCategories = _categories
        .where((c) => _showIncome ? c.type == 'expense' : c.type == 'income')
        .toList();
    if (_searchQuery.isNotEmpty) {
      filteredCategories = filteredCategories
          .where((c) => c.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? AppLocalizations.of(context)!.noCategories
                  : AppLocalizations.of(context)!.noData,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addCategory),
              ),
            ],
          ],
        ),
      );
    }

    final usageCount = _getCategoryUsageCount();
    final totalAmount = _getCategoryTotalAmount();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        final normalizedName = category.name.trim().toLowerCase();
        final count = usageCount[normalizedName] ?? 0;
        final amount = totalAmount[normalizedName] ?? 0;

        return Container(
          key: ValueKey(category.id),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: category.type == 'income'
                ? const Color(0xFF4CAF50).withValues(
                    alpha: 0.2,
                  ) // Yeşil zemin gelir için
                : const Color(
                    0xFFFF5252,
                  ).withValues(alpha: 0.2), // Kırmızı zemin gider için
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: category.type == 'income'
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                  : const Color(0xFFFF5252).withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(category.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (_showStats) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalizations.of(context)!.transactionCount(count)} • ${CurrencyHelper.formatAmountCompact(amount, _currentUser)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF00BFA5)),
                      onPressed: () => _editCategory(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCategory(category),
                    ),
                  ],
                ),
              ),
              if (_showStats)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          AppLocalizations.of(context)!.usage,
                          '$count',
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          AppLocalizations.of(context)!.total,
                          CurrencyHelper.formatAmountCompact(amount, _currentUser),
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          AppLocalizations.of(context)!.average,
                          CurrencyHelper.formatAmountCompact(count > 0 ? amount / count : 0, _currentUser),
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}


