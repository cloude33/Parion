import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/bill_template.dart';
import '../services/bill_template_service.dart';
import '../services/bill_payment_service.dart';
import '../services/data_service.dart';
import 'bill_templates_screen.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final BillTemplateService _templateService = BillTemplateService();
  final BillPaymentService _paymentService = BillPaymentService();

  final _amountController = TextEditingController();

  List<BillTemplate> _templates = [];
  BillTemplate? _selectedTemplate;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _periodStart;
  DateTime? _periodEnd;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Payment methods
  List<Map<String, dynamic>> _paymentMethodOptions = [];
  String? _selectedPaymentMethodId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _calculatePeriod();
  }

  Future<void> _loadData() async {
    try {
       // Load templates
       final templates = await _templateService.getActiveTemplates();
       
       // Load wallets and cards (DataService puts cards into wallets list with cc_ prefix)
       final dataService = DataService(); 
       await dataService.init(); // Ensure init
       final wallets = await dataService.getWallets();
       
       final options = wallets.map((w) => {
         'id': w.id,
         'name': w.name,
         'icon': IconData(
            w.icon == 'credit_card' ? 0xe19f : 0xe041, // basic mapping
            fontFamily: 'MaterialIcons'
         ),
         'color': Color(int.parse(w.color.replaceAll('#', '0xFF'))),
       }).toList();

       // Add cash/other fallback?? No, stick to wallets.

      setState(() {
        _templates = templates;
        _paymentMethodOptions = options;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DEBUG AddBillScreen: Error loading data: $e');
      setState(() {
        _templates = [];
        _paymentMethodOptions = [];
        _isLoading = false;
      });
    }
  }

  void _calculatePeriod() {
    final day = _selectedTemplate?.paymentDay ?? 1;
    
    // Dönem başlangıcı: Seçilen tarihin ayı ve şablondaki ödeme günü
    final start = DateTime(_dueDate.year, _dueDate.month, day);
    // Dönem bitişi: Bir sonraki ayın aynı günü
    final end = DateTime(_dueDate.year, _dueDate.month + 1, day);

    setState(() {
      _periodStart = start;
      _periodEnd = end;
    });
  }

  // Old method replaced by _loadData
  Future<void> _loadTemplates() async {
      await _loadData();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    // Geriye dönük fatura ekleme her zaman aktif: 5 yıl geriye kadar
    final firstDate = DateTime(now.year - 5, 1, 1);
    // 5 yıl ileriye kadar fatura eklenebilir
    final lastDate = DateTime(now.year + 5, 12, 31);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00BFA5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _calculatePeriod();
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectBill),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_periodStart == null || _periodEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fatura dönemi hesaplanamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      await _paymentService.addPayment(
        templateId: _selectedTemplate!.id,
        amount: amount,
        dueDate: _dueDate,
        periodStart: _periodStart!,
        periodEnd: _periodEnd!,
        targetWalletId: _selectedPaymentMethodId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.billAdded),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addBill),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? _buildEmptyState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.blue.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.billFormInfo,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade200
                                    : const Color(0xFF0D47A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<BillTemplate>(
                    initialValue: _selectedTemplate,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '${AppLocalizations.of(context)!.bill} *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.receipt_long),
                    ),
                    items: _templates.map((template) {
                      // Ayırt edici bilgiyi belirle
                      String subtitle = '';
                      if (template.phoneNumber != null && template.phoneNumber!.isNotEmpty) {
                        subtitle = template.phoneNumber!;
                      } else if (template.accountNumber != null && template.accountNumber!.isNotEmpty) {
                        subtitle = template.accountNumber!;
                      } else if (template.description != null && template.description!.isNotEmpty) {
                        subtitle = template.description!;
                      }
                      
                      // Ana başlık: provider veya name
                      final title = template.provider ?? template.name;
                      
                      // Eğer name, provider'dan farklıysa ve subtitle boşsa, name'i subtitle olarak kullan
                      if (subtitle.isEmpty && template.name != title) {
                        subtitle = template.name;
                      }
                      
                      return DropdownMenuItem<BillTemplate>(
                        value: template,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                         _selectedTemplate = value;
                         // Şablon değişince varsayılan ödeme aracını güncelle
                         if (value?.walletId != null) {
                            if (value!.walletId!.startsWith('cc_')) {
                               _selectedPaymentMethodId = value.walletId;
                            } else {
                               // Normal cüzdan mı kredi kartı mı kontrol et
                               // ID çakışması olmaması için kredi kartı prefixi eklenmeli mi? 
                               // Hayır, DataService.getWallets zaten cc_ ekliyor.
                               // Biz burada UI listesindeki ID ile eşleşeni bulmalıyız.
                               
                               // Check if this ID exists in our loaded options
                               bool exists = _paymentMethodOptions.any((o) => o['id'] == value.walletId);
                               if (exists) {
                                  _selectedPaymentMethodId = value.walletId;
                               } else {
                                  // Maybe it's a credit card without prefix in template?
                                  String ccPrefixed = 'cc_${value.walletId}';
                                  if (_paymentMethodOptions.any((o) => o['id'] == ccPrefixed)) {
                                     _selectedPaymentMethodId = ccPrefixed;
                                  } else {
                                     _selectedPaymentMethodId = null; 
                                  }
                               }
                            }
                         }
                          if (value != null) {
                             _calculatePeriod();
                          }
                       });
                    },
                    validator: (value) {
                      if (value == null) return AppLocalizations.of(context)!.pleaseSelectBill;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Ödeme Aracı Seçimi
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedPaymentMethodId),
                    initialValue: _selectedPaymentMethodId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.paymentMethod,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      helperText: AppLocalizations.of(context)!.paymentMethodDesc,
                    ),
                    items: _paymentMethodOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['id'] as String,
                        child: Row(
                          children: [
                            Icon(
                              option['icon'] as IconData, 
                              color: option['color'] as Color,
                              size: 16
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(option['name'] as String)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPaymentMethodId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: '${AppLocalizations.of(context)!.amount} *',
                      hintText: '0.00',
                      border: const OutlineInputBorder(),
                      prefixText: '₺ ',
                      prefixIcon: const Icon(Icons.payments),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tutar gerekli';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Geçerli bir tutar girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDueDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context)!.dueTally} *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                            ).format(_dueDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.date_range,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _periodStart != null && _periodEnd != null
                                ? '${AppLocalizations.of(context)!.billPeriod}: ${DateFormat('dd MMM').format(_periodStart!)} - ${DateFormat('dd MMM yyyy').format(_periodEnd!)}'
                                : '${AppLocalizations.of(context)!.billPeriod}: -',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.addBill,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noBillsDefined,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.noBillsDefinedDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillTemplatesScreen(),
                ),
              );
              if (result == true && mounted) {
                _loadTemplates();
              }
            },
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.defineBill),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: Text(AppLocalizations.of(context)!.back),
          ),
        ],
      ),
    );
  }
}


