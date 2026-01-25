import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import '../models/loan.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';

class AddCustomLoanScreen extends StatefulWidget {
  final List<Wallet> wallets;
  
  const AddCustomLoanScreen({super.key, required this.wallets});

  @override
  State<AddCustomLoanScreen> createState() => _AddCustomLoanScreenState();
}

class _AddCustomLoanScreenState extends State<AddCustomLoanScreen> {
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController(); // e.g. "Okul Taksidi"
  final TextEditingController _providerController = TextEditingController(); // e.g. "Çiğli Final"
  
  String? _selectedWalletId;
  bool _isLoading = false;
  
  // List of installments (Date, Amount)
  final List<ManualInstallmentItem> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.wallets.isNotEmpty) {
      _selectedWalletId = widget.wallets.first.id;
    }
    // Add one empty row by default
    _addNewRow();
  }

  void _addNewRow() {
    setState(() {
      DateTime nextDate = DateTime.now();
      if (_items.isNotEmpty) {
        // Default to next month of last item
        final last = _items.last.date;
        nextDate = DateTime(last.year, last.month + 1, last.day);
      }
      
      _items.add(ManualInstallmentItem(
        date: nextDate,
        amountController: TextEditingController(),
      ));
    });
  }

  void _removeRow(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) {
       final val = double.tryParse(item.amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
       return sum + val;
    });
  }

  Future<void> _selectDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _items[index].date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _items[index].date = picked;
      });
    }
  }
  
  // Helper to generate multiple rows
  Future<void> _showGenerateDialog() async {
    final countController = TextEditingController(text: '12');
    final amountController = TextEditingController();
    DateTime startDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Otomatik Taksit Oluştur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: countController,
                decoration: const InputDecoration(labelText: 'Taksit Sayısı'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Aylık Tutar'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Başlangıç Tarihi'),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final count = int.tryParse(countController.text) ?? 0;
      final amount = amountController.text; // Keep as string to set controller text
      
      if (count > 0) {
        setState(() {
          _items.clear();
          for (int i = 0; i < count; i++) {
             _items.add(ManualInstallmentItem(
               date: DateTime(startDate.year, startDate.month + i, startDate.day),
               amountController: TextEditingController(text: amount),
             ));
          }
        });
      }
    }
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedWalletId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Lütfen bir cüzdan seçin')),
       );
       return;
    }
    
    if (_totalAmount <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Lütfen taksit tutarlarını girin')),
       );
       return;
    }

    setState(() => _isLoading = true);

    try {
      final installments = <LoanInstallment>[];
      
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final amount = double.tryParse(item.amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
        
        // Taksit vadesi geçmiş mi?
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isPastDue = item.date.isBefore(today) || item.date.isAtSameMomentAs(today);
        
        installments.add(LoanInstallment(
          installmentNumber: i + 1,
          amount: amount,
          dueDate: item.date,
          paymentDate: isPastDue ? item.date : null,
          isPaid: isPastDue,
          principalAmount: amount, // No interest
          interestAmount: 0,
          kkdfAmount: 0,
          bsmvAmount: 0,
          remainingPrincipalAmount: 0, // Not calculated for custom simple plans
        ));
      }
      
      // Calculate remaining installments properly based on Paid status
      final paidInstallments = installments.where((i) => i.isPaid).toList();
      final paidAmount = paidInstallments.fold(0.0, (sum, i) => sum + i.amount);
      final remainingAmount = _totalAmount - paidAmount;

      final loan = Loan(
        id: const Uuid().v4(),
        name: _nameController.text,
        bankName: _providerController.text.isEmpty ? 'Özel Ödeme' : _providerController.text,
        totalAmount: _totalAmount,
        remainingAmount: remainingAmount < 0 ? 0 : remainingAmount,
        totalInstallments: installments.length,
        remainingInstallments: installments.length - paidInstallments.length,
        currentInstallment: paidInstallments.length + 1,
        installmentAmount: installments.isEmpty ? 0 : installments.first.amount, // Approximate
        startDate: installments.first.dueDate,
        endDate: installments.last.dueDate,
        walletId: _selectedWalletId!,
        installments: installments,
      );
      
      await _dataService.addLoan(loan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme planı kaydedildi'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel Ödeme Planı'),
        actions: [
           IconButton(
             icon: const Icon(Icons.flash_on),
             tooltip: 'Otomatik Oluştur',
             onPressed: _showGenerateDialog,
           )
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Plan Adı (Örn: Okul)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.label),
                            ),
                            validator: (v) => v?.isEmpty == true ? 'Gerekli' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _providerController,
                            decoration: const InputDecoration(
                              labelText: 'Kurum/Kişi (Örn: Çiğli Final)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedWalletId,
                            decoration: const InputDecoration(
                              labelText: 'Ödeme Kaynağı',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.account_balance_wallet),
                            ),
                            items: widget.wallets.map((w) {
                              return DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedWalletId = v),
                            validator: (v) => v == null ? 'Gerekli' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Taksitler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Installment List
                  ...List.generate(_items.length, (index) {
                     return Card(
                       margin: const EdgeInsets.only(bottom: 8),
                       child: ListTile(
                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                         leading: CircleAvatar(
                           child: Text('${index + 1}'),
                           backgroundColor: Colors.blue.shade100,
                           radius: 14,
                         ),
                         title: Row(
                           children: [
                             Expanded(
                               child: InkWell(
                                 onTap: () => _selectDate(index),
                                 child: Container(
                                   padding: const EdgeInsets.all(8),
                                   decoration: BoxDecoration(
                                     border: Border.all(color: Colors.grey.shade300),
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                   child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16),
                                        const SizedBox(width: 4),
                                        Text(DateFormat('dd.MM.yy').format(_items[index].date)),
                                      ],
                                   ),
                                 ),
                               ),
                             ),
                             const SizedBox(width: 8),
                             Expanded(
                               child: TextFormField(
                                 controller: _items[index].amountController,
                                 keyboardType: TextInputType.number,
                                 decoration: const InputDecoration(
                                   hintText: 'Tutar',
                                   isDense: true,
                                   contentPadding: EdgeInsets.all(12),
                                   border: OutlineInputBorder(),
                                   suffixText: '₺',
                                 ),
                                 inputFormatters: [
                                   CurrencyTextInputFormatter.currency(
                                      locale: 'tr_TR',
                                      symbol: '',
                                      decimalDigits: 0,
                                   ),
                                 ],
                                 onChanged: (_) => setState((){}), // Trigger rebuild for total calc
                               ),
                             ),
                           ],
                         ),
                         trailing: _items.length > 1 
                             ? IconButton(
                                 icon: const Icon(Icons.delete, color: Colors.red),
                                 onPressed: () => _removeRow(index),
                               )
                             : null,
                       ),
                     );
                  }),
                  
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addNewRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Taksit Ekle'),
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                   BoxShadow(
                     color: Colors.grey.withValues(alpha: 0.2),
                     offset: const Offset(0, -2),
                     blurRadius: 10,
                   )
                ],
              ),
              child: Row(
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('Toplam Tutar', style: TextStyle(color: Colors.grey)),
                       Text(
                         '₺${NumberFormat('#,##0', 'tr_TR').format(_totalAmount)}',
                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                       ),
                     ],
                   ),
                   const Spacer(),
                   ElevatedButton(
                     onPressed: _isLoading ? null : _saveLoan,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                       backgroundColor: const Color(0xFF5E5CE6),
                       foregroundColor: Colors.white,
                     ),
                     child: _isLoading 
                       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                       : const Text('Kaydet'),
                   ),
                 ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManualInstallmentItem {
  DateTime date;
  TextEditingController amountController;

  ManualInstallmentItem({required this.date, required this.amountController});
}
