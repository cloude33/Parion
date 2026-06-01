import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class KmhInterestCalculatorScreen extends StatefulWidget {
  final double? initialAmount;
  final double? initialRate;

  const KmhInterestCalculatorScreen({
    super.key,
    this.initialAmount,
    this.initialRate,
  });

  @override
  State<KmhInterestCalculatorScreen> createState() =>
      _KmhInterestCalculatorScreenState();
}

class _KmhInterestCalculatorScreenState
    extends State<KmhInterestCalculatorScreen> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _daysController = TextEditingController(text: '1');
  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  double? _grossInterest;
  double? _kkdf;
  double? _bsmv;
  double? _total;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = widget.initialAmount.toString();
    }
    if (widget.initialRate != null) {
      _rateController.text = widget.initialRate.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _calculate() {
    final amountText = _amountController.text.replaceAll(',', '.');
    final rateText = _rateController.text.replaceAll(',', '.');
    final daysText = _daysController.text.replaceAll(',', '.');

    final amount = double.tryParse(amountText);
    final rate = double.tryParse(rateText);
    final days = double.tryParse(daysText);

    if (amount == null || rate == null || days == null || amount <= 0) {
      return;
    }

    final gross = (amount * rate * days) / 3000;
    final kkdf = gross * 0.15;
    final bsmv = gross * 0.15;
    final total = gross + kkdf + bsmv;

    setState(() {
      _grossInterest = gross;
      _kkdf = kkdf;
      _bsmv = bsmv;
      _total = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KMH Faiz Hesaplama'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildInputCard(),
          const SizedBox(height: 16),
          _buildCalculateButton(),
          if (_total != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(),
            const SizedBox(height: 16),
            _buildFormulaCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Nasıl Hesaplanır?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'KMH faizi günlük olarak hesaplanır. Borcu aynı gün kapatsanız '
              'dahi en az 1 günlük faiz işler.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesaplama Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Kullanılan Tutar',
                hintText: 'Örn: 5000',
                prefixText: '₺ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'Aylık Faiz Oranı',
                hintText: 'Örn: 4.5',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _daysController,
              decoration: InputDecoration(
                labelText: 'Gün Sayısı',
                hintText: '1',
                border: const OutlineInputBorder(),
                suffixText: ' gün',
                helperText: 'En az 1 gün (borcu aynı gün kapatsanız bile)',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate),
        label: const Text(
          'Faiz Hesapla',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BFA5),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesaplama Sonucu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResultRow('Brüt Faiz', _grossInterest!, Colors.teal),
            const Divider(height: 24),
            _buildResultRow(
                'KKDF (%15)', _kkdf!, Colors.orange.shade700),
            _buildResultRow(
                'BSMV (%15)', _bsmv!, Colors.orange.shade700),
            const Divider(height: 24),
            _buildResultRow('Toplam Faiz', _total!, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formül',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Brüt Faiz = (Tutar × Aylık Faiz × Gün) / 3000\n'
              'KKDF = Brüt Faiz × %15\n'
              'BSMV = Brüt Faiz × %15\n'
              'Toplam = Brüt Faiz + KKDF + BSMV',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
