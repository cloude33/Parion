import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../services/credit_card_service.dart';
import '../widgets/icon_picker_dialog.dart';
import '../utils/category_icons.dart';
import '../utils/bank_card_helper.dart';
import '../widgets/cards/bank_card_visual_widget.dart';
import '../services/data_service.dart';

class AddCreditCardScreen extends StatefulWidget {
  final CreditCard? card;

  const AddCreditCardScreen({super.key, this.card});

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final CreditCardService _cardService = CreditCardService();
  late TextEditingController _bankNameController;
  late TextEditingController _cardNameController;
  late TextEditingController _last4DigitsController;
  late TextEditingController _creditLimitController;
  late TextEditingController _statementDayController;
  late TextEditingController _dueDateOffsetController;
  late TextEditingController _monthlyInterestRateController;
  late TextEditingController _lateInterestRateController;
  late TextEditingController _initialDebtController;
  late TextEditingController _pointsConversionRateController;
  late TextEditingController _cashAdvanceRateController;
  late TextEditingController _cashAdvanceLimitController;
  late TextEditingController _overLimitInterestRateController;
  late TextEditingController _cashAdvanceOverdueInterestRateController;
  late TextEditingController _minimumPaymentRateController;
  late TextEditingController _expirationDateController;

  bool _isLoading = false;
  String? _cardImageBase64;
  String? _selectedRewardType;
  Color _selectedColor = const Color(0xFF212121);
  IconData? _selectedIcon;
  String _userName = '';

  final List<String> _turkishBanks = [
    'Garanti BBVA',
    'İş Bankası',
    'Yapı Kredi',
    'Akbank',
    'Ziraat Bankası',
    'Halkbank',
    'Vakıfbank',
    'QNB Finansbank',
    'TEB',
    'Denizbank',
    'ING',
    'HSBC',
    'Kuveyt Türk',
    'Albaraka Türk',
  ];
  final List<String> _cardTypes = [
    'Bonus',
    'Axess',
    'World',
    'Maximum',
    'Paraf',
    'CardFinans',
    'Bankkart Combo',
    'Miles&Smiles',
    'Advantage',
  ];
  final List<Map<String, String>> _rewardTypes = [
    {'value': 'bonus', 'label': 'Bonus Puan'},
    {'value': 'worldpuan', 'label': 'WorldPuan'},
    {'value': 'miles', 'label': 'Mil'},
    {'value': 'cashback', 'label': 'Cashback'},
    {'value': 'none', 'label': 'Puan Yok'},
  ];
  final List<Color> _cardColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
    Colors.deepPurpleAccent,
    Colors.amberAccent,
    Colors.lime,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.yellow.shade700,
    Colors.grey.shade800,
  ];

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _bankNameController = TextEditingController(text: card?.bankName ?? '');
    _cardNameController = TextEditingController(text: card?.cardName ?? '');
    _last4DigitsController = TextEditingController(
      text: card?.last4Digits ?? '',
    );
    _creditLimitController = TextEditingController(
      text: card != null ? _formatNumber(card.creditLimit) : '',
    );
    _statementDayController = TextEditingController(
      text: card?.statementDay.toString() ?? '',
    );
    _dueDateOffsetController = TextEditingController(
      text: card?.dueDateOffset.toString() ?? '10',
    );
    _monthlyInterestRateController = TextEditingController(
      text: card?.monthlyInterestRate.toString() ?? '3.5',
    );
    _lateInterestRateController = TextEditingController(
      text: card?.lateInterestRate.toString() ?? '4.5',
    );
    _initialDebtController = TextEditingController(
      text: card != null && card.initialDebt > 0
          ? _formatNumber(card.initialDebt)
          : '',
    );
    _pointsConversionRateController = TextEditingController(
      text: card?.pointsConversionRate?.toString() ?? '',
    );
    _cashAdvanceRateController = TextEditingController(
      text: card?.cashAdvanceRate?.toString() ?? '',
    );
    _cashAdvanceLimitController = TextEditingController(
      text: card != null && card.cashAdvanceLimit != null
          ? _formatNumber(card.cashAdvanceLimit!)
          : '',
    );
    _overLimitInterestRateController = TextEditingController(
      text: card?.overLimitInterestRate?.toString() ?? '3.50',
    );
    _cashAdvanceOverdueInterestRateController = TextEditingController(
      text: card?.cashAdvanceOverdueInterestRate?.toString() ?? '4.80',
    );
    _minimumPaymentRateController = TextEditingController(
      text: card?.minimumPaymentRate?.toString() ?? '40',
    );
    _expirationDateController = TextEditingController(
      text: card?.expirationDate ?? '',
    );

    // Real-time preview listeners
    _bankNameController.addListener(_updatePreview);
    _cardNameController.addListener(_updatePreview);
    _last4DigitsController.addListener(_updatePreview);
    _creditLimitController.addListener(_updatePreview);
    _initialDebtController.addListener(_updatePreview);
    _expirationDateController.addListener(_updatePreview);

    if (card != null) {
      _selectedColor = card.color;
      _cardImageBase64 = card.cardImagePath;
      _selectedRewardType = card.rewardType;
      if (card.iconName != null) {
        _selectedIcon = _getIconFromName(card.iconName!);
      }
    }
    
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = await DataService().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userName = user.name;
      });
    }
  }

  IconData? _getIconFromName(String iconName) {
    for (var icon in CategoryIcons.allIcons) {
      if (icon.codePoint.toString() == iconName) {
        return icon;
      }
    }
    return null;
  }

  String _formatNumber(double number) {
    return NumberFormat('#,##0.##', 'tr_TR').format(number);
  }

  double _parseNumber(String text) {
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  void _updatePreview() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _cardNameController.dispose();
    _last4DigitsController.dispose();
    _creditLimitController.dispose();
    _statementDayController.dispose();
    _dueDateOffsetController.dispose();
    _monthlyInterestRateController.dispose();
    _lateInterestRateController.dispose();
    _initialDebtController.dispose();
    _pointsConversionRateController.dispose();
    _cashAdvanceRateController.dispose();
    _cashAdvanceLimitController.dispose();
    _overLimitInterestRateController.dispose();
    _cashAdvanceOverdueInterestRateController.dispose();
    _minimumPaymentRateController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Kredi Kartı Düzenle' : 'Kredi Kartı Ekle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_selectedColor, _selectedColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardImageSection(),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Temel Bilgiler',
                      icon: Icons.credit_card,
                      children: [
                        _buildBankNameField(),
                        const SizedBox(height: 16),
                        _buildCardNameField(),
                        const SizedBox(height: 16),
                        _buildLast4DigitsField(),
                        const SizedBox(height: 16),
                        _buildExpirationDateField(),
                        const SizedBox(height: 16),
                        _buildCreditLimitField(),
                        const SizedBox(height: 16),
                        _buildInitialDebtField(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Ekstre ve Ödeme Bilgileri',
                      icon: Icons.description,
                      children: [
                        _buildStatementDayField(),
                        const SizedBox(height: 16),
                        _buildDueDateOffsetField(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Faiz Oranları',
                      icon: Icons.percent,
                      children: [
                        _buildMonthlyInterestRateField(),
                        const SizedBox(height: 16),
                        _buildLateInterestRateField(),
                        const SizedBox(height: 16),
                        _buildOverLimitInterestRateField(),
                        const SizedBox(height: 16),
                        _buildMinimumPaymentRateField(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Nakit Avans Bilgileri (Opsiyonel)',
                      icon: Icons.atm,
                      children: [
                        _buildCashAdvanceRateField(),
                        const SizedBox(height: 16),
                        _buildCashAdvanceOverdueInterestRateField(),
                        const SizedBox(height: 16),
                        _buildCashAdvanceLimitField(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Puan/Ödül Sistemi (Opsiyonel)',
                      icon: Icons.card_giftcard,
                      children: [
                        _buildRewardTypeField(),
                        if (_selectedRewardType != null &&
                            _selectedRewardType != 'none') ...[
                          const SizedBox(height: 16),
                          _buildPointsConversionRateField(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Görünüm',
                      icon: Icons.palette,
                      children: [
                        _buildColorPicker(),
                        const SizedBox(height: 16),
                        _buildIconPicker(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSaveButton(isEdit),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: _selectedColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCardImageSection() {
    final cardImage = _cardImageBase64;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kart Önizleme',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Center(
          child: BankCardVisualWidget(
            bankName: _bankNameController.text,
            cardName: _cardNameController.text,
            last4Digits: _last4DigitsController.text,
            currentDebt: _parseNumber(_initialDebtController.text),
            limit: _parseNumber(_creditLimitController.text),
            colorHex: '0x${_selectedColor.toARGB32().toRadixString(16)}',
            cardImagePath: cardImage,
            cardHolderName: _userName,
            expirationDate: _expirationDateController.text,
          ),
        ),
      ],
    );
  }

  void _updateCardStyleFromInput() {
    final bankName = _bankNameController.text;
    
    setState(() {
      _selectedColor = BankCardHelper.getBankColor(bankName);
      _cardImageBase64 = null; // Always use coded card
    });
  }

  Widget _buildRewardTypeField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRewardType,
      decoration: const InputDecoration(
        labelText: 'Puan Türü',
        hintText: 'Puan türü seçin',
        prefixIcon: Icon(Icons.card_giftcard),
        border: OutlineInputBorder(),
      ),
      items: _rewardTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type['value'],
          child: Text(type['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRewardType = value;
        });
      },
    );
  }

  Widget _buildPointsConversionRateField() {
    return TextFormField(
      controller: _pointsConversionRateController,
      decoration: const InputDecoration(
        labelText: 'Puan Dönüşüm Oranı',
        hintText: '0.01',
        helperText: '1 puan = X TL (örn: 0.01 = 100 puan = 1 TL)',
        prefixIcon: Icon(Icons.currency_exchange),
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
      ],
      validator: (value) {
        if (_selectedRewardType != null && _selectedRewardType != 'none') {
          if (value == null || value.isEmpty) {
            return 'Puan dönüşüm oranı gerekli';
          }
          final rate = double.tryParse(value);
          if (rate == null || rate <= 0) {
            return 'Geçerli bir oran giriniz';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCashAdvanceRateField() {
    return TextFormField(
      controller: _cashAdvanceRateController,
      decoration: const InputDecoration(
        labelText: 'Nakit Avans Faiz Oranı',
        hintText: '4.5',
        helperText: 'Nakit avans için uygulanan aylık faiz oranı',
        prefixIcon: Icon(Icons.money_off),
        suffixText: '%',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final rate = double.tryParse(value);
          if (rate == null || rate < 0) {
            return 'Geçerli bir oran giriniz';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCashAdvanceLimitField() {
    return TextFormField(
      controller: _cashAdvanceLimitController,
      decoration: const InputDecoration(
        labelText: 'Nakit Avans Limiti',
        hintText: '10.000,00',
        helperText: 'Maksimum nakit avans çekme limiti',
        prefixIcon: Icon(Icons.atm),
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        _DecimalThousandsSeparatorInputFormatter(),
      ],
      onChanged: (value) {
        final cursorPos = _cashAdvanceLimitController.selection.base.offset;
        final formatted = _formatNumberInput(value);
        if (formatted != value) {
          _cashAdvanceLimitController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: cursorPos + (formatted.length - value.length),
            ),
          );
        }
      },
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final limit = _parseNumber(value);
          if (limit < 0) {
            return 'Geçerli bir limit giriniz';
          }
        }
        return null;
      },
    );
  }

  Widget _buildIconPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kart İkonu (Opsiyonel)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickIcon,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _selectedIcon ?? Icons.credit_card,
                    color: _selectedColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedIcon != null ? 'İkon seçildi' : 'İkon seç',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedIcon != null
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        if (_selectedIcon != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedIcon = null;
              });
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('İkonu Kaldır'),
          ),
        ],
      ],
    );
  }

  Future<void> _pickIcon() async {
    final icon = await showDialog<IconData>(
      context: context,
      builder: (context) => IconPickerDialog(
        initialIcon: _selectedIcon,
        selectedColor: _selectedColor,
      ),
    );
    if (icon != null) {
      setState(() {
        _selectedIcon = icon;
      });
    }
  }

  Widget _buildBankNameField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _bankNameController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _turkishBanks;
        }
        return _turkishBanks.where((String bank) {
          return bank.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        _bankNameController.text = selection;
        _updateCardStyleFromInput();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _bankNameController = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Banka Adı',
            hintText: 'Örn: Garanti BBVA',
            prefixIcon: Icon(Icons.account_balance),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Lütfen banka adını seçiniz veya giriniz';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildCardNameField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _cardNameController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _cardTypes;
        }
        return _cardTypes.where((String type) {
          return type.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        _cardNameController.text = selection;
        _updateCardStyleFromInput();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _cardNameController = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Kart Adı',
            hintText: 'Örn: Bonus, Axess, World',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Lütfen kart adını giriniz (Örn: Bonus, Axess)';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildLast4DigitsField() {
    return TextFormField(
      controller: _last4DigitsController,
      decoration: const InputDecoration(
        labelText: 'Son 4 Hane',
        hintText: '1234',
        prefixIcon: Icon(Icons.pin),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen kartınızın son 4 hanesini giriniz';
        }
        if (value.length != 4) {
          return 'Son 4 hane eksik, lütfen kontrol ediniz';
        }
        return null;
      },
    );
  }

  Widget _buildExpirationDateField() {
    return TextFormField(
      controller: _expirationDateController,
      decoration: const InputDecoration(
        labelText: 'Son Kullanma Tarihi',
        hintText: 'AA/YY',
        prefixIcon: Icon(Icons.event),
        border: OutlineInputBorder(),
        helperText: 'Ay/Yıl formatında (örn: 12/28)',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
        _ExpirationDateFormatter(),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          // Validate MM/YY format
          if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
            return 'Lütfen AA/YY formatında girin (örn: 12/28)';
          }
          
          final parts = value.split('/');
          final month = int.tryParse(parts[0]);
          final year = int.tryParse(parts[1]);
          
          if (month == null || year == null) {
            return 'Geçersiz tarih formatı';
          }
          
          if (month < 1 || month > 12) {
            return 'Ay 1-12 arasında olmalıdır';
          }
          
          final currentYear = DateTime.now().year % 100;
          final currentMonth = DateTime.now().month;
          
          if (year < currentYear || (year == currentYear && month < currentMonth)) {
            return 'Kartın süresi dolmuş olamaz';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCreditLimitField() {
    return TextFormField(
      controller: _creditLimitController,
      decoration: const InputDecoration(
        labelText: 'Kredi Limiti',
        hintText: '50.000,00',
        helperText: 'Ondalık sayı için virgül (,) kullanın',
        prefixIcon: Icon(Icons.account_balance_wallet),
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        _DecimalThousandsSeparatorInputFormatter(),
      ],
      onChanged: (value) {
        final cursorPos = _creditLimitController.selection.base.offset;
        final formatted = _formatNumberInput(value);
        if (formatted != value) {
          _creditLimitController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: cursorPos + (formatted.length - value.length),
            ),
          );
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen kart limitinizi giriniz';
        }
        final limit = _parseNumber(value);
        if (limit <= 0) {
          return 'Lütfen geçerli bir limit tutarı giriniz';
        }
        return null;
      },
    );
  }

  String _formatNumberInput(String value) {
    if (value.isEmpty) return value;
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null) return value;
    return NumberFormat('#,##0', 'tr_TR').format(number).replaceAll(',', '.');
  }

  Widget _buildInitialDebtField() {
    return TextFormField(
      controller: _initialDebtController,
      decoration: const InputDecoration(
        labelText: 'Mevcut Borç (Opsiyonel)',
        hintText: 'Örn: 102.250,38',
        helperText:
            'Önceki dönemden kalan borç varsa giriniz. Binlik ayırıcı otomatik eklenir.',
        prefixIcon: Icon(Icons.credit_card_outlined),
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        _ThousandsSeparatorInputFormatter(),
      ],
      onChanged: (value) {
        final cursorPos = _initialDebtController.selection.base.offset;
        final formatted = _formatNumberInput(value);
        if (formatted != value) {
          _initialDebtController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: cursorPos + (formatted.length - value.length),
            ),
          );
        }
      },
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final debt = _parseNumber(value);
          if (debt < 0) {
            return 'Geçerli bir tutar giriniz';
          }
        }
        return null;
      },
    );
  }

  Widget _buildStatementDayField() {
    return TextFormField(
      controller: _statementDayController,
      decoration: const InputDecoration(
        labelText: 'Ekstre Kesim Günü',
        hintText: '1-31 arası',
        helperText: 'Her ayın kaçında ekstre kesilir',
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen hesap kesim tarihini giriniz (Ayın kaçı?)';
        }
        final day = int.tryParse(value);
        if (day == null || day < 1 || day > 31) {
          return 'Lütfen 1 ile 31 arasında bir gün giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildDueDateOffsetField() {
    return TextFormField(
      controller: _dueDateOffsetController,
      decoration: const InputDecoration(
        labelText: 'Son Ödeme Günü (Gün Sayısı)',
        hintText: '10',
        helperText: 'Ekstre kesiminden kaç gün sonra son ödeme',
        prefixIcon: Icon(Icons.event),
        suffixText: 'gün',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen son ödeme günü aralığını giriniz';
        }
        final offset = int.tryParse(value);
        if (offset == null || offset < 0) {
          return 'Lütfen geçerli bir gün sayısı giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildMonthlyInterestRateField() {
    return TextFormField(
      controller: _monthlyInterestRateController,
      decoration: const InputDecoration(
        labelText: 'Aylık Faiz Oranı',
        hintText: '3.5',
        helperText: 'Normal faiz oranı (aylık %)',
        prefixIcon: Icon(Icons.percent),
        suffixText: '%',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen aylık akdi faiz oranını giriniz';
        }
        final rate = double.tryParse(value);
        if (rate == null || rate < 0) {
          return 'Geçersiz oran, lütfen kontrol ediniz';
        }
        return null;
      },
    );
  }

  Widget _buildLateInterestRateField() {
    return TextFormField(
      controller: _lateInterestRateController,
      decoration: const InputDecoration(
        labelText: 'Gecikme Faiz Oranı',
        hintText: '4.5',
        helperText: 'Gecikme durumunda uygulanan faiz (aylık %)',
        prefixIcon: Icon(Icons.warning),
        suffixText: '%',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen gecikme faiz oranını giriniz';
        }
        final rate = double.tryParse(value);
        if (rate == null || rate < 0) {
          return 'Geçersiz oran, lütfen kontrol ediniz';
        }
        return null;
      },
    );
  }

  Widget _buildOverLimitInterestRateField() {
    return TextFormField(
      controller: _overLimitInterestRateController,
      decoration: const InputDecoration(
        labelText: 'Limit Aşım Faiz Oranı',
        hintText: '3.50',
        helperText: 'Limit aşımı durumunda uygulanan faiz (aylık %)',
        prefixIcon: Icon(Icons.error_outline),
        suffixText: '%',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final rate = double.tryParse(value);
          if (rate == null || rate < 0) {
            return 'Geçersiz oran';
          }
        }
        return null; // Optional
      },
    );
  }

  Widget _buildCashAdvanceOverdueInterestRateField() {
    return TextFormField(
      controller: _cashAdvanceOverdueInterestRateController,
      decoration: const InputDecoration(
        labelText: 'Nakit Avans Gecikme Faiz Oranı',
        hintText: '4.80',
        helperText: 'Nakit avans gecikmesi durumunda uygulanan faiz (aylık %)',
        prefixIcon: Icon(Icons.money_off),
        suffixText: '%',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final rate = double.tryParse(value);
          if (rate == null || rate < 0) {
            return 'Geçersiz oran';
          }
        }
        return null;
      },
    );
  }

  Widget _buildMinimumPaymentRateField() {
    return TextFormField(
      controller: _minimumPaymentRateController,
      decoration: const InputDecoration(
        labelText: 'Minimum Ödeme Oranı',
        hintText: '40',
        helperText: 'Dönem borcunun asgari ödeme oranı (%)',
        prefixIcon: Icon(Icons.pie_chart),
        suffixText: '%',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final rate = double.tryParse(value);
          if (rate == null || rate < 0 || rate > 100) {
            return 'Geçersiz oran (0-100)';
          }
        }
        return null;
      },
    );
  }

  Widget _buildColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _cardColors.map((color) {
        final isSelected = color.toARGB32() == _selectedColor.toARGB32();
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(bool isEdit) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedColor, _selectedColor.withValues(alpha: 0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEdit ? Icons.save : Icons.add,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isEdit ? 'Güncelle' : 'Kaydet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _safeParseRate(String text) {
    if (text.isEmpty) return 0;
    text = text.trim();
    // Önce standart formatı dene (örn: 3.5)
    var val = double.tryParse(text);
    if (val != null) return val;
    // Başarısız olursa virgülü noktaya çevirip dene (örn: 3,5 -> 3.5)
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  int _safeParseInt(String text) {
    if (text.isEmpty) return 0;
    return int.tryParse(text.trim()) ?? 0;
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final initialDebt = _initialDebtController.text.isEmpty
          ? 0.0
          : _parseNumber(_initialDebtController.text);

      final pointsConversionRate = _pointsConversionRateController.text.isEmpty
          ? null
          : _safeParseRate(_pointsConversionRateController.text);

      final cashAdvanceRate = _cashAdvanceRateController.text.isEmpty
          ? null
          : _safeParseRate(_cashAdvanceRateController.text);

      final cashAdvanceLimit = _cashAdvanceLimitController.text.isEmpty
          ? null
          : _parseNumber(_cashAdvanceLimitController.text);

      final overLimitInterestRate = _overLimitInterestRateController.text.isEmpty
          ? null
          : _safeParseRate(_overLimitInterestRateController.text);

      final cashAdvanceOverdueInterestRate = _cashAdvanceOverdueInterestRateController.text.isEmpty
          ? null
          : _safeParseRate(_cashAdvanceOverdueInterestRateController.text);

      final minimumPaymentRate = _minimumPaymentRateController.text.isEmpty
          ? null
          : _safeParseRate(_minimumPaymentRateController.text);

      final card = CreditCard(
        id: widget.card?.id ?? const Uuid().v4(),
        bankName: _bankNameController.text.trim(),
        cardName: _cardNameController.text.trim(),
        last4Digits: _last4DigitsController.text.trim(),
        creditLimit: _parseNumber(_creditLimitController.text),
        statementDay: _safeParseInt(_statementDayController.text),
        dueDateOffset: _safeParseInt(_dueDateOffsetController.text),
        monthlyInterestRate: _safeParseRate(
          _monthlyInterestRateController.text,
        ),
        lateInterestRate: _safeParseRate(_lateInterestRateController.text),
        cardColor: _selectedColor.toARGB32(),
        createdAt: widget.card?.createdAt ?? DateTime.now(),
        isActive: widget.card?.isActive ?? true,
        initialDebt: initialDebt,
        cardImagePath: _cardImageBase64,
        iconName: _selectedIcon?.codePoint.toString(),
        rewardType: _selectedRewardType != 'none' ? _selectedRewardType : null,
        pointsConversionRate: pointsConversionRate,
        cashAdvanceRate: cashAdvanceRate,
        cashAdvanceLimit: cashAdvanceLimit,
        overLimitInterestRate: overLimitInterestRate,
        cashAdvanceOverdueInterestRate: cashAdvanceOverdueInterestRate,
        minimumPaymentRate: minimumPaymentRate,
        expirationDate: _expirationDateController.text.trim().isEmpty 
            ? null 
            : _expirationDateController.text.trim(),
      );

      if (widget.card == null) {
        await _cardService.createCard(card);
      } else {
        await _cardService.updateCard(card);
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.card == null
                ? 'Kredi kartı başarıyla eklendi'
                : 'Kredi kartı başarıyla güncellendi',
          ),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      debugPrint('Error saving credit card: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text;
    final hasComma = text.contains(',');
    String integerPart;
    String decimalPart = '';

    if (hasComma) {
      final parts = text.split(',');
      integerPart = parts[0].replaceAll('.', '');
      if (parts.length > 1) {
        decimalPart = parts[1].replaceAll('.', '');
        if (decimalPart.length > 2) {
          decimalPart = decimalPart.substring(0, 2);
        }
      }
    } else {
      integerPart = text.replaceAll('.', '');
    }
    if (!RegExp(r'^\d+$').hasMatch(integerPart) ||
        (decimalPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(decimalPart))) {
      return oldValue;
    }
    final number = int.tryParse(integerPart);
    if (number == null) {
      return oldValue;
    }

    String formatted = NumberFormat(
      '#,##0',
      'tr_TR',
    ).format(number).replaceAll(',', '.');
    if (hasComma) {
      formatted += ',$decimalPart';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _DecimalThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text;
    text = text.replaceAll('.', '');
    text = text.replaceAll(',', '.');
    final parts = text.split('.');
    if (parts.length > 2) {
      text = '${parts[0]}.${parts.sublist(1).join('')}';
    }
    if (parts.length == 2 && parts[1].length > 2) {
      text = '${parts[0]}.${parts[1].substring(0, 2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('/', '');
    
    if (text.length > 4) {
      text = text.substring(0, 4);
    }
    
    String formatted = text;
    if (text.length >= 3) {
      formatted = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}


