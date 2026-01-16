import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';

class AddLoanScreen extends StatefulWidget {
  final List<Wallet> wallets;
  final Loan? existingLoan; // For editing existing loan

  const AddLoanScreen({super.key, required this.wallets, this.existingLoan});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _installmentCountController =
      TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _monthlyPaymentController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedWalletId;
  DateTime _startDate = DateTime.now();
  DateTime? _firstPaymentDate;
  String _selectedLoanType = 'ihtiyac';
  bool _isCalculatingFromRate =
      true; // true = calculate monthly from rate, false = calculate rate from monthly
  bool _isLoading = false;

  // Loan types
  final List<Map<String, dynamic>> _loanTypes = [
    {'id': 'ihtiyac', 'name': 'İhtiyaç Kredisi', 'icon': Icons.shopping_bag},
    {'id': 'konut', 'name': 'Konut Kredisi', 'icon': Icons.home},
    {'id': 'tasit', 'name': 'Taşıt Kredisi', 'icon': Icons.directions_car},
    {'id': 'egitim', 'name': 'Eğitim Kredisi', 'icon': Icons.school},
    {'id': 'esnaf', 'name': 'Esnaf Kredisi', 'icon': Icons.store},
    {'id': 'tarim', 'name': 'Tarım Kredisi', 'icon': Icons.agriculture},
    {'id': 'diger', 'name': 'Diğer', 'icon': Icons.more_horiz},
  ];

  // Popular banks
  final List<String> _popularBanks = [
    'Ziraat Bankası',
    'İş Bankası',
    'Garanti BBVA',
    'Yapı Kredi',
    'Akbank',
    'Halkbank',
    'Vakıfbank',
    'QNB Finansbank',
    'Denizbank',
    'TEB',
    'ING',
    'HSBC',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.wallets.isNotEmpty) {
      _selectedWalletId = widget.wallets.first.id;
    }

    // If editing existing loan, populate fields
    if (widget.existingLoan != null) {
      _populateFromExistingLoan();
    }

    // Add listeners for auto-calculation
    _totalAmountController.addListener(_onAmountChanged);
    _installmentCountController.addListener(_onAmountChanged);
    _interestRateController.addListener(_onRateChanged);
    _monthlyPaymentController.addListener(_onMonthlyPaymentChanged);
  }

  void _populateFromExistingLoan() {
    final loan = widget.existingLoan!;
    _nameController.text = loan.name;
    _bankNameController.text = loan.bankName;
    _totalAmountController.text = loan.totalAmount.toStringAsFixed(2);
    _installmentCountController.text = loan.totalInstallments.toString();
    _monthlyPaymentController.text = loan.installmentAmount.toStringAsFixed(2);
    _selectedWalletId = loan.walletId;
    _startDate = loan.startDate;
    _firstPaymentDate = loan.installments.isNotEmpty
        ? loan.installments.first.dueDate
        : null;
  }

  void _onAmountChanged() {
    if (_isCalculatingFromRate) {
      _calculateMonthlyPayment();
    }
  }

  void _onRateChanged() {
    if (_isCalculatingFromRate && _interestRateController.text.isNotEmpty) {
      _calculateMonthlyPayment();
    }
  }

  void _onMonthlyPaymentChanged() {
    if (!_isCalculatingFromRate && _monthlyPaymentController.text.isNotEmpty) {
      _calculateInterestRate();
    }
  }

  void _calculateMonthlyPayment() {
    final totalAmount = _parseAmount(_totalAmountController.text);
    final installmentCount =
        int.tryParse(_installmentCountController.text) ?? 0;
    final yearlyRate =
        double.tryParse(_interestRateController.text.replaceAll(',', '.')) ?? 0;

    if (totalAmount > 0 && installmentCount > 0) {
      double monthlyPayment;

      if (yearlyRate > 0) {
        // With interest - PMT formula
        final monthlyRate = yearlyRate / 12 / 100;
        monthlyPayment =
            totalAmount *
            (monthlyRate * pow(1 + monthlyRate, installmentCount)) /
            (pow(1 + monthlyRate, installmentCount) - 1);
      } else {
        // Without interest
        monthlyPayment = totalAmount / installmentCount;
      }

      setState(() {
        _monthlyPaymentController.text = monthlyPayment.toStringAsFixed(2);
      });
    }
  }

  void _calculateInterestRate() {
    final totalAmount = _parseAmount(_totalAmountController.text);
    final installmentCount =
        int.tryParse(_installmentCountController.text) ?? 0;
    final monthlyPayment = _parseAmount(_monthlyPaymentController.text);

    if (totalAmount > 0 && installmentCount > 0 && monthlyPayment > 0) {
      final totalPayment = monthlyPayment * installmentCount;
      final totalInterest = totalPayment - totalAmount;

      // Simple approximation for display
      final avgMonthlyRate = (totalInterest / totalAmount) / installmentCount;
      final yearlyRate = avgMonthlyRate * 12 * 100;

      setState(() {
        _interestRateController.text = yearlyRate.toStringAsFixed(2);
      });
    }
  }

  double pow(double x, int n) {
    double result = 1;
    for (int i = 0; i < n; i++) {
      result *= x;
    }
    return result;
  }

  double _parseAmount(String text) {
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate
          : (_firstPaymentDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5E5CE6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Auto-set first payment date to next month
          _firstPaymentDate ??= DateTime(
            picked.year,
            picked.month + 1,
            picked.day,
          );
        } else {
          _firstPaymentDate = picked;
        }
      });
    }
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir cüzdan seçin')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalAmount = _parseAmount(_totalAmountController.text);
      final installmentCount =
          int.tryParse(_installmentCountController.text) ?? 1;
      final monthlyPayment = _parseAmount(_monthlyPaymentController.text);

      final firstPayment =
          _firstPaymentDate ??
          DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
      final endDate = DateTime(
        firstPayment.year,
        firstPayment.month + installmentCount - 1,
        firstPayment.day,
      );

      // Generate installments
      final List<LoanInstallment> installments = [];
      for (int i = 0; i < installmentCount; i++) {
        final dueDate = DateTime(
          firstPayment.year,
          firstPayment.month + i,
          firstPayment.day,
        );
        installments.add(
          LoanInstallment(
            installmentNumber: i + 1,
            amount: monthlyPayment,
            dueDate: dueDate,
          ),
        );
      }

      final loan = Loan(
        id: widget.existingLoan?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        bankName: _bankNameController.text.trim(),
        totalAmount: totalAmount,
        remainingAmount: monthlyPayment * installmentCount,
        totalInstallments: installmentCount,
        remainingInstallments: installmentCount,
        currentInstallment: 0,
        installmentAmount: monthlyPayment,
        startDate: _startDate,
        endDate: endDate,
        walletId: _selectedWalletId!,
        installments: installments,
      );

      if (widget.existingLoan != null) {
        await _dataService.updateLoan(loan);
      } else {
        await _dataService.addLoan(loan);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingLoan != null
                  ? 'Kredi güncellendi'
                  : 'Kredi eklendi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          widget.existingLoan != null ? 'Kredi Düzenle' : 'Yeni Kredi Ekle',
        ),
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveLoan,
              child: const Text(
                'Kaydet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan Type Selection
              _buildSectionTitle('Kredi Türü', Icons.category),
              const SizedBox(height: 12),
              _buildLoanTypeSelector(),

              const SizedBox(height: 24),

              // Bank Selection
              _buildSectionTitle('Banka Bilgileri', Icons.account_balance),
              const SizedBox(height: 12),
              _buildBankSelector(),

              const SizedBox(height: 16),

              // Loan Name
              _buildTextField(
                controller: _nameController,
                label: 'Kredi Adı',
                hint: 'Örn: Ev Kredisi, Araba Kredisi',
                icon: Icons.label_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kredi adı gerekli';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Amount & Terms
              _buildSectionTitle('Kredi Detayları', Icons.attach_money),
              const SizedBox(height: 12),

              // Total Amount
              _buildTextField(
                controller: _totalAmountController,
                label: 'Kredi Tutarı',
                hint: '0.00',
                icon: Icons.payments_outlined,
                prefix: '₺ ',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kredi tutarı gerekli';
                  }
                  final amount = _parseAmount(value);
                  if (amount <= 0) {
                    return 'Geçerli bir tutar girin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Installment Count
              _buildTextField(
                controller: _installmentCountController,
                label: 'Taksit Sayısı (Ay)',
                hint: 'Örn: 12, 24, 36, 48, 60',
                icon: Icons.calendar_month,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Taksit sayısı gerekli';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0 || count > 360) {
                    return 'Geçerli bir taksit sayısı girin (1-360)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Interest Rate & Monthly Payment
              _buildInterestSection(),

              const SizedBox(height: 24),

              // Dates
              _buildSectionTitle('Tarihler', Icons.event),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector('Kredi Tarihi', _startDate, true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateSelector(
                      'İlk Taksit',
                      _firstPaymentDate ??
                          DateTime(
                            _startDate.year,
                            _startDate.month + 1,
                            _startDate.day,
                          ),
                      false,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Wallet Selection
              _buildSectionTitle('Bağlı Hesap', Icons.account_balance_wallet),
              const SizedBox(height: 12),
              _buildWalletSelector(),

              const SizedBox(height: 24),

              // Summary Card
              if (_totalAmountController.text.isNotEmpty &&
                  _installmentCountController.text.isNotEmpty &&
                  _monthlyPaymentController.text.isNotEmpty)
                _buildSummaryCard(),

              const SizedBox(height: 24),

              // Notes
              _buildTextField(
                controller: _notesController,
                label: 'Notlar (Opsiyonel)',
                hint: 'Ek bilgiler...',
                icon: Icons.note_alt_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLoan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E5CE6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.existingLoan != null
                              ? 'Krediyi Güncelle'
                              : 'Kredi Ekle',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5E5CE6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5E5CE6),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanTypeSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _loanTypes.length,
        itemBuilder: (context, index) {
          final type = _loanTypes[index];
          final isSelected = _selectedLoanType == type['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedLoanType = type['id']),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5E5CE6) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5E5CE6)
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF5E5CE6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'],
                    size: 32,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type['name'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBankSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: InputBorder.none,
            icon: Icon(Icons.account_balance, color: Color(0xFF5E5CE6)),
          ),
          initialValue: _popularBanks.contains(_bankNameController.text)
              ? _bankNameController.text
              : null,
          hint: const Text('Banka Seçin'),
          isExpanded: true,
          items: _popularBanks.map((bank) {
            return DropdownMenuItem(value: bank, child: Text(bank));
          }).toList(),
          onChanged: (value) {
            if (value == 'Diğer') {
              _showCustomBankDialog();
            } else if (value != null) {
              setState(() => _bankNameController.text = value);
            }
          },
          validator: (value) {
            if (_bankNameController.text.isEmpty) {
              return 'Banka seçimi gerekli';
            }
            return null;
          },
        ),
      ),
    );
  }

  Future<void> _showCustomBankDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Banka Adı Girin'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Banka adı...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _bankNameController.text = result);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF5E5CE6))
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5E5CE6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildInterestSection() {
    return Column(
      children: [
        // Toggle between calculation modes
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isCalculatingFromRate = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isCalculatingFromRate
                          ? const Color(0xFF5E5CE6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Faiz Oranından Hesapla',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isCalculatingFromRate
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isCalculatingFromRate = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isCalculatingFromRate
                          ? const Color(0xFF5E5CE6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Taksit Tutarından Hesapla',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_isCalculatingFromRate
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            // Interest Rate
            Expanded(
              child: _buildTextField(
                controller: _interestRateController,
                label: 'Yıllık Faiz (%)',
                hint: '0.00',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                readOnly: !_isCalculatingFromRate,
              ),
            ),
            const SizedBox(width: 12),
            // Monthly Payment
            Expanded(
              child: _buildTextField(
                controller: _monthlyPaymentController,
                label: 'Aylık Taksit',
                hint: '0.00',
                icon: Icons.payments,
                prefix: '₺ ',
                keyboardType: TextInputType.number,
                readOnly: _isCalculatingFromRate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Taksit tutarı gerekli';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector(String label, DateTime date, bool isStartDate) {
    return GestureDetector(
      onTap: () => _selectDate(context, isStartDate),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF5E5CE6),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy', 'tr_TR').format(date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelector() {
    if (widget.wallets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Henüz cüzdan eklenmemiş. Önce bir cüzdan ekleyin.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedWalletId,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          hint: const Text('Cüzdan seçin'),
          items: widget.wallets.map((wallet) {
            return DropdownMenuItem(
              value: wallet.id,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(wallet.color),
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 18,
                      color: Color(int.parse(wallet.color)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(wallet.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedWalletId = value),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalAmount = _parseAmount(_totalAmountController.text);
    final installmentCount =
        int.tryParse(_installmentCountController.text) ?? 0;
    final monthlyPayment = _parseAmount(_monthlyPaymentController.text);
    final totalPayment = monthlyPayment * installmentCount;
    final totalInterest = totalPayment - totalAmount;

    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5E5CE6),
            const Color(0xFF5E5CE6).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E5CE6).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Kredi Özeti',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Kredi Tutarı', currencyFormat.format(totalAmount)),
          _buildSummaryRow('Taksit Sayısı', '$installmentCount ay'),
          _buildSummaryRow(
            'Aylık Taksit',
            currencyFormat.format(monthlyPayment),
          ),
          const Divider(color: Colors.white38, height: 24),
          _buildSummaryRow(
            'Toplam Ödeme',
            currencyFormat.format(totalPayment),
            isBold: true,
          ),
          _buildSummaryRow(
            'Toplam Faiz',
            currencyFormat.format(totalInterest),
            valueColor: totalInterest > 0 ? Colors.amber : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: isBold ? 15 : 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _totalAmountController.dispose();
    _installmentCountController.dispose();
    _interestRateController.dispose();
    _monthlyPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
