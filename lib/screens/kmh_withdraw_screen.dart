import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../services/kmh_service.dart';

/// KMH hesabından para çekme ekranı
class KmhWithdrawScreen extends StatefulWidget {
  final Wallet account;

  const KmhWithdrawScreen({super.key, required this.account});

  @override
  State<KmhWithdrawScreen> createState() => _KmhWithdrawScreenState();
}

class _KmhWithdrawScreenState extends State<KmhWithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final KmhService _kmhService = KmhService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  bool _isLoading = false;
  double _availableCredit = 0;
  double _currentBalance = 0;
  double _creditLimit = 0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadAccountData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountData() async {
    setState(() => _isLoading = true);
    try {
      final availableCredit = await _kmhService.getAvailableCredit(widget.account.id);
      setState(() {
        _availableCredit = availableCredit;
        _currentBalance = widget.account.balance;
        _creditLimit = widget.account.creditLimit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final description = _descriptionController.text.trim().isEmpty
          ? 'Para Çekme'
          : _descriptionController.text.trim();

      await _kmhService.recordWithdrawal(
        widget.account.id,
        amount,
        description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currencyFormat.format(amount)} başarıyla çekildi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _setQuickAmount(double percentage) {
    final amount = _availableCredit * percentage;
    _amountController.text = amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Para Çek'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAccountCard(),
                  const SizedBox(height: 16),
                  _buildLimitInfoCard(),
                  const SizedBox(height: 24),
                  _buildAmountField(),
                  const SizedBox(height: 16),
                  _buildQuickAmountButtons(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),
                  _buildWithdrawButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance,
                color: Colors.red.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.account.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Para Çekme İşlemi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.remove_circle_outline,
              color: Colors.red.shade400,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitInfoCard() {
    final double utilizationRate = _creditLimit > 0 ? ((_creditLimit - _availableCredit) / _creditLimit) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Limit Bilgileri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(utilizationRate).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '%${utilizationRate.toStringAsFixed(1)} kullanımda',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(utilizationRate),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Mevcut Bakiye',
                    _currencyFormat.format(_currentBalance),
                    _currentBalance < 0 ? Colors.red : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Kredi Limiti',
                    _currencyFormat.format(_creditLimit),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kullanılabilir Kredi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _currencyFormat.format(_availableCredit),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
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

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(double utilizationRate) {
    if (utilizationRate >= 90) return Colors.red;
    if (utilizationRate >= 70) return Colors.orange;
    if (utilizationRate >= 50) return Colors.yellow.shade700;
    return Colors.green;
  }

  Widget _buildAmountField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Çekilecek Tutar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Tutar',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: '₺',
                border: const OutlineInputBorder(),
                helperText: 'Maksimum: ${_currencyFormat.format(_availableCredit)}',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tutar gerekli';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Geçerli bir tutar giriniz';
                }
                if (amount > _availableCredit) {
                  return 'Kullanılabilir kredi limitini aşıyor';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _availableCredit > 0 ? () => _setQuickAmount(0.25) : null,
            child: const Text('%25'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _availableCredit > 0 ? () => _setQuickAmount(0.50) : null,
            child: const Text('%50'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _availableCredit > 0 ? () => _setQuickAmount(0.75) : null,
            child: const Text('%75'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _availableCredit > 0 ? () => _setQuickAmount(1.0) : null,
            child: const Text('Tümü'),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Açıklama (İsteğe Bağlı)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Para Çekme',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _withdraw,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.remove_circle_outline),
        label: Text(_isLoading ? 'İşlem yapılıyor...' : 'Para Çek'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.shade400,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
