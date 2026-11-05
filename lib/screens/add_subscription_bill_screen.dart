import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/bill_template.dart';
import '../models/category.dart';
import '../models/recurrence_frequency.dart';
import '../models/recurring_transaction.dart';
import '../models/wallet.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../services/bill_template_service.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../models/app_notification.dart';
import 'add_category_screen.dart';

class AddSubscriptionBillScreen extends StatefulWidget {
  final int initialTabIndex; // 0: Abonelik, 1: Fatura
  const AddSubscriptionBillScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AddSubscriptionBillScreen> createState() =>
      _AddSubscriptionBillScreenState();
}

class _AddSubscriptionBillScreenState extends State<AddSubscriptionBillScreen> {
  late int _selectedTab; // 0: Abonelik, 1: Fatura
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _providerController = TextEditingController();

  final BillTemplateService _billTemplateService = BillTemplateService();
  final RecurringTransactionRepository _recurringRepo =
      RecurringTransactionRepository();
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();

  // State
  int _paymentDay = 10;
  String _subscriptionFrequency = '1 Ay (Her Ay)';
  String _subscriptionDuration = 'Süresiz (Sürekli)';
  String _billType = 'Elektrik';
  bool _hasAutoPayment = false;
  DateTime? _customDueDate;

  // Reminder
  bool _reminderEnabled = true;
  String _reminderDaysBefore = '1 Gün Önce';

  // Lists
  List<Wallet> _wallets = [];
  List<Category> _categories = [];
  String? _selectedWalletId;
  String _selectedCategoryName = 'Abonelik & Dijital';

  bool _isLoading = true;
  bool _isSaving = false;

  // Templates
  final List<Map<String, dynamic>> _subscriptionTemplates = [
    {
      'title': 'Netflix',
      'icon': '🍿',
      'amount': '149.99',
      'category': 'Dijital Abonelik',
      'day': 15,
    },
    {
      'title': 'Spotify',
      'icon': '🎵',
      'amount': '59.99',
      'category': 'Dijital Abonelik',
      'day': 10,
    },
    {
      'title': 'YouTube Premium',
      'icon': '▶️',
      'amount': '79.99',
      'category': 'Dijital Abonelik',
      'day': 12,
    },
    {
      'title': 'Amazon Prime',
      'icon': '📦',
      'amount': '39.00',
      'category': 'Dijital Abonelik',
      'day': 5,
    },
    {
      'title': 'Disney+',
      'icon': '🎬',
      'amount': '134.99',
      'category': 'Dijital Abonelik',
      'day': 18,
    },
    {
      'title': 'BluTV / Exxen',
      'icon': '⚽',
      'amount': '129.90',
      'category': 'Dijital Abonelik',
      'day': 1,
    },
    {
      'title': 'Spor Salonu',
      'icon': '🏋️',
      'amount': '1000.00',
      'category': 'Eğlence & Hobi',
      'day': 1,
    },
    {
      'title': 'Ev Kirası',
      'icon': '🏠',
      'amount': '',
      'category': 'Kira & Ev Aidatı',
      'day': 1,
    },
  ];

  final List<Map<String, dynamic>> _billTemplates = [
    {
      'title': 'Elektrik Faturası',
      'icon': '⚡',
      'provider': 'Elektrik Dağıtım',
      'type': 'Elektrik',
      'category': 'Fatura & Telekom',
      'day': 15,
    },
    {
      'title': 'Su Faturası',
      'icon': '💧',
      'provider': 'Su İdaresi',
      'type': 'Su',
      'category': 'Fatura & Telekom',
      'day': 10,
    },
    {
      'title': 'Doğalgaz Faturası',
      'icon': '🔥',
      'provider': 'Gaz Dağıtım',
      'type': 'Doğalgaz',
      'category': 'Fatura & Telekom',
      'day': 20,
    },
    {
      'title': 'İnternet Faturası',
      'icon': '🌐',
      'provider': 'Türk Telekom / Fiber',
      'type': 'İnternet',
      'category': 'Fatura & Telekom',
      'day': 1,
    },
    {
      'title': 'Cep Telefonu (GSM)',
      'icon': '📱',
      'provider': 'GSM Operatörü',
      'type': 'Telefon',
      'category': 'Fatura & Telekom',
      'day': 25,
    },
    {
      'title': 'Apartman Aidatı',
      'icon': '🏢',
      'provider': 'Bina Yönetimi',
      'type': 'Kira',
      'category': 'Kira & Ev Aidatı',
      'day': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _paymentDay = DateTime.now().day;
    _initData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _accountNoController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      await _dataService.init();
      await _recurringRepo.init();

      final wallets = await _dataService.getWallets();
      final categories = (await _dataService.getCategories()).cast<Category>();

      if (mounted) {
        setState(() {
          _wallets = wallets;
          _categories = categories;
          if (wallets.isNotEmpty) {
            _selectedWalletId = wallets.first.id;
          }
          _selectedCategoryName = _selectedTab == 0
              ? 'Dijital Abonelik'
              : 'Fatura & Telekom';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySubscriptionTemplate(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['title'] as String;
      if ((template['amount'] as String).isNotEmpty) {
        _amountController.text = template['amount'] as String;
      }
      _selectedCategoryName = template['category'] as String;
      _paymentDay = template['day'] as int;
    });
  }

  void _applyBillTemplate(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['title'] as String;
      _providerController.text = template['provider'] as String;
      _billType = template['type'] as String;
      _selectedCategoryName = template['category'] as String;
      _paymentDay = template['day'] as int;
    });
  }

  DateTime _calculateNextPaymentDate(int day) {
    final now = DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, day);
    if (candidate.isBefore(DateTime(now.year, now.month, now.day))) {
      candidate = DateTime(now.year, now.month + 1, day);
    }
    return candidate;
  }

  int _getReminderDaysInt() {
    switch (_reminderDaysBefore) {
      case 'Aynı Gün':
        return 0;
      case '1 Gün Önce':
        return 1;
      case '2 Gün Önce':
        return 2;
      case '3 Gün Önce':
        return 3;
      case '1 Hafta Önce':
        return 7;
      default:
        return 1;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amountText = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final calculatedFirstDate = _calculateNextPaymentDate(_paymentDay);

      if (_selectedTab == 0) {
        // --- ABONELİK KAYDI ---
        RecurrenceFrequency freq = RecurrenceFrequency.monthly;
        if (_subscriptionFrequency.contains('3 Ay')) {
          freq = RecurrenceFrequency.monthly;
        } else if (_subscriptionFrequency.contains('Yıllık')) {
          freq = RecurrenceFrequency.yearly;
        }

        int? occurrenceCount;
        DateTime? endDate;
        if (_subscriptionDuration == '3 Ay') {
          occurrenceCount = 3;
          endDate = DateTime(now.year, now.month + 3, _paymentDay);
        } else if (_subscriptionDuration == '6 Ay') {
          occurrenceCount = 6;
          endDate = DateTime(now.year, now.month + 6, _paymentDay);
        } else if (_subscriptionDuration.contains('12 Ay')) {
          occurrenceCount = 12;
          endDate = DateTime(now.year + 1, now.month, _paymentDay);
        } else if (_subscriptionDuration.contains('24 Ay')) {
          occurrenceCount = 24;
          endDate = DateTime(now.year + 2, now.month, _paymentDay);
        }

        final recurring = RecurringTransaction(
          id: const Uuid().v4(),
          title: title,
          amount: amount,
          category: _selectedCategoryName,
          description: 'Abonelik: $title',
          frequency: freq,
          startDate: calculatedFirstDate,
          endDate: endDate,
          occurrenceCount: occurrenceCount,
          isActive: true,
          isIncome: false,
          createdAt: now,
          notificationEnabled: _reminderEnabled,
          reminderDaysBefore: _reminderEnabled ? _getReminderDaysInt() : null,
        );

        await _recurringRepo.add(recurring);

        await _billTemplateService.addTemplate(
          name: title,
          provider: 'Abonelik',
          category: BillTemplateCategory.subscription,
          description: 'Abonelik ödemesi',
          walletId: _selectedWalletId,
          monthlyAmount: amount > 0 ? amount : null,
          paymentDay: _paymentDay,
        );
      } else {
        // --- FATURA KAYDI ---
        BillTemplateCategory cat = BillTemplateCategory.electricity;
        switch (_billType) {
          case 'Su':
            cat = BillTemplateCategory.water;
            break;
          case 'Doğalgaz':
            cat = BillTemplateCategory.gas;
            break;
          case 'İnternet':
            cat = BillTemplateCategory.internet;
            break;
          case 'Telefon':
            cat = BillTemplateCategory.phone;
            break;
          case 'Kira':
            cat = BillTemplateCategory.rent;
            break;
          default:
            cat = BillTemplateCategory.electricity;
        }

        final billDesc = _hasAutoPayment
            ? 'Otomatik Ödeme Talimatı Var | Abone No: ${_accountNoController.text.trim()}'
            : 'Abone No: ${_accountNoController.text.trim()}';

        await _billTemplateService.addTemplate(
          name: title,
          provider: _providerController.text.isNotEmpty
              ? _providerController.text.trim()
              : _billType,
          category: cat,
          accountNumber: _accountNoController.text.isNotEmpty
              ? _accountNoController.text.trim()
              : null,
          description: billDesc,
          walletId: _selectedWalletId,
          monthlyAmount: amount > 0 ? amount : null,
          paymentDay: _paymentDay,
        );

        if (_reminderEnabled) {
          final notif = AppNotification(
            id: const Uuid().v4(),
            type: NotificationType.billReminder,
            title: 'Fatura Hatırlatıcı: $title',
            message:
                '$title faturanızın son ödeme günü yaklaşıyor. (${DateFormat('dd MMMM yyyy', 'tr_TR').format(calculatedFirstDate)})',
            createdAt: now,
            data: {
              'dueDate': calculatedFirstDate.toIso8601String(),
              'amount': amount,
            },
          );
          await _notificationService.addNotification(notif);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _selectedTab == 0
                      ? 'Abonelik başarıyla kaydedildi!'
                      : 'Fatura başarıyla kaydedildi!',
                ),
              ],
            ),
            backgroundColor: _selectedTab == 0
                ? const Color(0xFFFFA000)
                : const Color(0xFF1E88E5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilirken hata oluştu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = _selectedTab == 0
        ? const Color(0xFFFFA000)
        : const Color(0xFF1E88E5);

    final calculatedDate = _calculateNextPaymentDate(_paymentDay);
    final formattedDate =
        DateFormat('dd MMMM yyyy', 'tr_TR').format(calculatedDate);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.titleLarge?.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Abonelik & Fatura Ekle',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopSegmentedTabs(),
                      const SizedBox(height: 16),
                      _buildHeaderCard(primaryColor, isDark),
                      const SizedBox(height: 16),
                      _buildQuickTemplatesSection(primaryColor, isDark),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 0 : 8),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTab == 0
                                  ? 'Abonelik Adı'
                                  : 'Fatura / Kurum Adı',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: _selectedTab == 0
                                    ? 'Örn: Netflix, Spotify, Spor Salonu...'
                                    : 'Örn: Elektrik Faturası, Su Faturası...',
                                prefixIcon: Icon(
                                  _selectedTab == 0
                                      ? Icons.subscriptions_outlined
                                      : Icons.receipt_long_outlined,
                                  color: primaryColor,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF5F7FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'Lütfen bir isim girin'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ödeme Tutarı',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '₺',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF5F7FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_selectedTab == 0) ...[
                              const Text(
                                'Kaç Ayda Bir Ödeniyor? (Tekrar Sıklığı)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildDropdownField(
                                value: _subscriptionFrequency,
                                icon: Icons.repeat,
                                items: [
                                  '1 Ay (Her Ay)',
                                  '3 Ayda Bir',
                                  '6 Ayda Bir',
                                  'Yıllık (12 Ay)',
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(
                                        () => _subscriptionFrequency = val);
                                  }
                                },
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_selectedTab == 1) ...[
                              const Text(
                                'Fatura Tipi / Kurum',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildDropdownField(
                                value: _billType,
                                icon: Icons.account_balance,
                                items: [
                                  'Elektrik',
                                  'Su',
                                  'Doğalgaz',
                                  'İnternet',
                                  'Telefon',
                                  'Kira',
                                  'Diğer',
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _billType = val);
                                  }
                                },
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildPaymentDaySlider(
                              primaryColor: primaryColor,
                              isDark: isDark,
                              formattedDate: formattedDate,
                            ),
                            const SizedBox(height: 16),
                            if (_selectedTab == 0) ...[
                              const Text(
                                'Kaç Ay Sürecek? (Toplam Ödeme Süresi)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildDropdownField(
                                value: _subscriptionDuration,
                                icon: Icons.all_inclusive,
                                items: [
                                  'Süresiz (Sürekli)',
                                  '3 Ay',
                                  '6 Ay',
                                  '12 Ay (1 Yıl)',
                                  '24 Ay (2 Yıl)',
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _subscriptionDuration = val);
                                  }
                                },
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_selectedTab == 1) ...[
                              const Text(
                                'Fatura Özel Son Ödeme Tarihi (İsteğe Bağlı)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _customDueDate ?? calculatedDate,
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365 * 3)),
                                  );
                                  if (picked != null) {
                                    setState(() => _customDueDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_month,
                                          color: primaryColor),
                                      const SizedBox(width: 10),
                                      Text(
                                        _customDueDate != null
                                            ? DateFormat('dd MMMM yyyy', 'tr_TR')
                                                .format(_customDueDate!)
                                            : 'Tarih Seçilmedi (Her ayın $_paymentDay. günü)',
                                        style: TextStyle(
                                          color: _customDueDate != null
                                              ? theme
                                                  .textTheme.bodyLarge?.color
                                              : Colors.grey,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.edit_calendar,
                                          size: 18, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Otomatik Ödeme Talimatı var mı?',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Bankanız bu faturayı otomatik ödüyorsa işaretleyin',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _hasAutoPayment,
                                      activeThumbColor: primaryColor,
                                      onChanged: (val) =>
                                          setState(() => _hasAutoPayment = val),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '# Abone / Tesisat No (Opsiyonel)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _accountNoController,
                                decoration: InputDecoration(
                                  hintText: 'Örn: 100234589',
                                  prefixIcon:
                                      Icon(Icons.tag, color: primaryColor),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFF5F7FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Kategori',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AddCategoryScreen()),
                                    );
                                    if (res == true) _initData();
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline,
                                          size: 16, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Yeni Kategori Ekle',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildCategoryDropdown(primaryColor, isDark),
                            const SizedBox(height: 16),
                            if (_wallets.isNotEmpty) ...[
                              const Text(
                                'Ödeme Yöntemi / Kasa',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              _buildWalletDropdown(primaryColor, isDark),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildReminderCard(primaryColor, isDark),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: primaryColor.withAlpha(100),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedTab == 0
                                          ? 'Aboneliği Kaydet'
                                          : 'Faturayı Kaydet',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTopSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedTab = 0;
                _selectedCategoryName = 'Dijital Abonelik';
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFFFFA000)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFA000).withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 18,
                      color: _selectedTab == 0 ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Abonelik Ekle',
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedTab = 1;
                _selectedCategoryName = 'Fatura & Telekom';
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFF1E88E5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E88E5).withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: _selectedTab == 1 ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fatura Ekle',
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withAlpha(40),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _selectedTab == 0 ? Icons.calendar_month : Icons.receipt,
              color: primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTab == 0
                      ? 'Abonelik & Düzenli Hizmet'
                      : 'Fatura & Kurum Ödemesi',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedTab == 0
                      ? 'Netflix, Spotify, spor salonu, ev kirası veya dijital üyelikleriniz.'
                      : 'Elektrik, su, doğalgaz, internet, telefon ve kurum faturalarınız.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplatesSection(Color primaryColor, bool isDark) {
    final templates =
        _selectedTab == 0 ? _subscriptionTemplates : _billTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.bolt, color: Colors.amber, size: 20),
            SizedBox(width: 6),
            Text(
              'Hızlı Şablon Seçimi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final t = templates[index];
              final title = t['title'] as String;
              final icon = t['icon'] as String;
              return InkWell(
                onTap: () {
                  if (_selectedTab == 0) {
                    _applySubscriptionTemplate(t);
                  } else {
                    _applyBillTemplate(t);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDaySlider({
    required Color primaryColor,
    required bool isDark,
    required String formattedDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Her ayın $_paymentDay. günü',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ayın $_paymentDay. Günü',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              thumbColor: primaryColor,
              overlayColor: primaryColor.withAlpha(40),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _paymentDay.toDouble(),
              min: 1,
              max: 31,
              divisions: 30,
              label: '$_paymentDay',
              onChanged: (val) => setState(() => _paymentDay = val.round()),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTab == 0
                    ? 'İlk Ödeme Tarihi:'
                    : 'Sonraki Fatura Ödeme Tarihi:',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withAlpha(50),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Son Ödeme Günü Bildirimi & Hatırlatıcı',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ödeme günü yaklaşınca cihazınıza yerel otomatik bildirim gönderir',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _reminderEnabled,
                activeThumbColor: primaryColor,
                onChanged: (val) => setState(() => _reminderEnabled = val),
              ),
            ],
          ),
          if (_reminderEnabled) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Text(
                  'Hatırlatma Zamanı:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _reminderDaysBefore,
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      items: [
                        'Aynı Gün',
                        '1 Gün Önce',
                        '2 Gün Önce',
                        '3 Gün Önce',
                        '1 Hafta Önce',
                      ]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _reminderDaysBefore = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bildirim ödemeden ${_reminderDaysBefore.toLowerCase()} saat 09:00\'da cihazınızda çalacak',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: primaryColor),
                      const SizedBox(width: 10),
                      Text(e, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(Color primaryColor, bool isDark) {
    final categoryNames = _categories.map((c) => c.name).toSet().toList();
    if (!categoryNames.contains(_selectedCategoryName)) {
      categoryNames.insert(0, _selectedCategoryName);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategoryName,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
          items: categoryNames
              .map(
                (name) => DropdownMenuItem(
                  value: name,
                  child: Row(
                    children: [
                      Icon(Icons.category, size: 18, color: primaryColor),
                      const SizedBox(width: 10),
                      Text(name, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCategoryName = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWalletDropdown(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedWalletId,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
          items: _wallets
              .map(
                (w) => DropdownMenuItem(
                  value: w.id,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          size: 18, color: primaryColor),
                      const SizedBox(width: 10),
                      Text(w.name, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedWalletId = val);
            }
          },
        ),
      ),
    );
  }
}
