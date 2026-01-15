import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../models/credit_card_payment.dart';
import '../services/credit_card_service.dart';
import '../repositories/credit_card_payment_repository.dart';

class EditCreditCardPaymentScreen extends StatefulWidget {
  final CreditCard card;
  final CreditCardPayment payment;

  const EditCreditCardPaymentScreen({
    super.key,
    required this.card,
    required this.payment,
  });

  @override
  State<EditCreditCardPaymentScreen> createState() =>
      _EditCreditCardPaymentScreenState();
}

class _EditCreditCardPaymentScreenState
    extends State<EditCreditCardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final CreditCardService _cardService = CreditCardService();
  final CreditCardPaymentRepository _paymentRepo =
      CreditCardPaymentRepository();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late DateTime _selectedDate;
  late String _selectedPaymentMethod;
  bool _isLoading = false;

  final Map<String, String> _paymentMethods = {
    'bank_transfer': 'Banka Havalesi',
    'atm': 'ATM',
    'auto_payment': 'Otomatik Ödeme',
    'other': 'Diğer',
  };

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.payment.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.payment.note);
    _selectedDate = widget.payment.paymentDate;
    _selectedPaymentMethod = widget.payment.paymentMethod;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödemeyi Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Ödemeyi Sil',
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
                  _buildCardInfo(),
                  const SizedBox(height: 16),
                  _buildPaymentInfo(),
                  const SizedBox(height: 24),
                  _buildAmountField(),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildPaymentMethodField(),
                  const SizedBox(height: 16),
                  _buildNoteField(),
                  const SizedBox(height: 24),
                  _buildWarningCard(),
                  const SizedBox(height: 16),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildCardInfo() {
    return Card(
      color: widget.card.color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.credit_card, color: widget.card.color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.card.bankName} ${widget.card.cardName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '•••• ${widget.card.last4Digits}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mevcut Ödeme Bilgileri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Orijinal Tutar',
              _currencyFormat.format(widget.payment.amount),
            ),
            _buildInfoRow(
              'Orijinal Tarih',
              DateFormat('dd MMMM yyyy', 'tr_TR')
                  .format(widget.payment.paymentDate),
            ),
            _buildInfoRow(
              'Ödeme Türü',
              widget.payment.paymentTypeText,
            ),
            if (widget.payment.statementId == 'manual')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ekstre dışı manuel ödeme',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Ödeme Tutarı',
        hintText: '0.00',
        prefixIcon: Icon(Icons.attach_money),
        suffixText: '₺',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ödeme tutarı gerekli';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Geçerli bir tutar giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ödeme Tarihi',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPaymentMethod,
      decoration: const InputDecoration(
        labelText: 'Ödeme Yöntemi',
        prefixIcon: Icon(Icons.payment),
        border: OutlineInputBorder(),
      ),
      items: _paymentMethods.entries.map((entry) {
        return DropdownMenuItem(value: entry.key, child: Text(entry.value));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        }
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Not (Opsiyonel)',
        hintText: 'Ödeme ile ilgili not',
        prefixIcon: Icon(Icons.note),
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ödeme bilgilerini değiştirmek kart borç hesaplamalarını etkileyebilir. Lütfen dikkatli olun.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveChanges,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16)),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newAmount = double.parse(_amountController.text);
      final oldAmount = widget.payment.amount;
      final amountDifference = newAmount - oldAmount;

      // Create updated payment
      final updatedPayment = CreditCardPayment(
        id: widget.payment.id,
        cardId: widget.payment.cardId,
        statementId: widget.payment.statementId,
        amount: newAmount,
        paymentDate: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        note: _noteController.text.trim(),
        paymentType: widget.payment.paymentType,
        remainingDebtAfterPayment: widget.payment.remainingDebtAfterPayment,
        createdAt: widget.payment.createdAt,
      );

      // Update payment in repository
      await _paymentRepo.update(updatedPayment);

      // If amount changed and this is a manual payment, update card's initial debt
      if (amountDifference != 0 && widget.payment.statementId == 'manual') {
        final card = await _cardService.getCard(widget.card.id);
        if (card != null) {
          final newInitialDebt = (card.initialDebt + amountDifference).clamp(0.0, double.infinity);
          
          final updatedCard = CreditCard(
            id: card.id,
            bankName: card.bankName,
            cardName: card.cardName,
            last4Digits: card.last4Digits,
            creditLimit: card.creditLimit,
            statementDay: card.statementDay,
            dueDateOffset: card.dueDateOffset,
            monthlyInterestRate: card.monthlyInterestRate,
            lateInterestRate: card.lateInterestRate,
            cardColor: card.cardColor,
            createdAt: card.createdAt,
            isActive: card.isActive,
            initialDebt: newInitialDebt,
            cardImagePath: card.cardImagePath,
            iconName: card.iconName,
            rewardType: card.rewardType,
            pointsConversionRate: card.pointsConversionRate,
            cashAdvanceRate: card.cashAdvanceRate,
            cashAdvanceLimit: card.cashAdvanceLimit,
            overLimitInterestRate: card.overLimitInterestRate,
            cashAdvanceOverdueInterestRate: card.cashAdvanceOverdueInterestRate,
            minimumPaymentRate: card.minimumPaymentRate,
          );
          
          await _cardService.updateCard(updatedCard);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme başarıyla güncellendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödemeyi Sil'),
        content: const Text(
          'Bu ödemeyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePayment();
    }
  }

  Future<void> _deletePayment() async {
    setState(() => _isLoading = true);

    try {
      // If this is a manual payment, restore the debt to the card
      if (widget.payment.statementId == 'manual') {
        final card = await _cardService.getCard(widget.card.id);
        if (card != null) {
          final newInitialDebt = card.initialDebt + widget.payment.amount;
          
          final updatedCard = CreditCard(
            id: card.id,
            bankName: card.bankName,
            cardName: card.cardName,
            last4Digits: card.last4Digits,
            creditLimit: card.creditLimit,
            statementDay: card.statementDay,
            dueDateOffset: card.dueDateOffset,
            monthlyInterestRate: card.monthlyInterestRate,
            lateInterestRate: card.lateInterestRate,
            cardColor: card.cardColor,
            createdAt: card.createdAt,
            isActive: card.isActive,
            initialDebt: newInitialDebt,
            cardImagePath: card.cardImagePath,
            iconName: card.iconName,
            rewardType: card.rewardType,
            pointsConversionRate: card.pointsConversionRate,
            cashAdvanceRate: card.cashAdvanceRate,
            cashAdvanceLimit: card.cashAdvanceLimit,
            overLimitInterestRate: card.overLimitInterestRate,
            cashAdvanceOverdueInterestRate: card.cashAdvanceOverdueInterestRate,
            minimumPaymentRate: card.minimumPaymentRate,
          );
          
          await _cardService.updateCard(updatedCard);
        }
      }

      // Delete the payment
      await _paymentRepo.delete(widget.payment.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme başarıyla silindi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
