import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/budget_service.dart';
import '../services/data_service.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? existingBudget;

  const AddBudgetScreen({super.key, this.existingBudget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _budgetService = BudgetService();
  final _dataService = DataService();

  String _selectedCategory = '';
  DateTime _selectedMonth = DateTime.now();
  List<Category> _expenseCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.existingBudget != null) {
      _selectedCategory = widget.existingBudget!.category;
      _amountController.text = widget.existingBudget!.amount.toStringAsFixed(2);
      _selectedMonth = DateTime(widget.existingBudget!.year, widget.existingBudget!.month);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final all = await _dataService.getCategories();
    setState(() {
      _expenseCategories = all.where((c) => c.type == 'expense').toList();
      if (_selectedCategory.isEmpty && _expenseCategories.isNotEmpty) {
        _selectedCategory = _expenseCategories.first.name;
      }
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    await _budgetService.setBudget(Budget(
      id: widget.existingBudget?.id ?? const Uuid().v4(),
      category: _selectedCategory,
      amount: amount,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    ));

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingBudget != null ? 'Bütçeyi Düzenle' : 'Bütçe Ekle'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _expenseCategories
                        .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? ''),
                    validator: (v) => v == null || v.isEmpty ? 'Kategori seçin' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Bütçe Tutarı',
                      hintText: '0.00',
                      prefixText: '₺ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Tutar girin';
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Geçerli bir tutar girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Ay'),
                    subtitle: Text(DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        helpText: 'Ay seçin',
                      );
                      if (picked != null) {
                        setState(() => _selectedMonth = DateTime(picked.year, picked.month));
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
