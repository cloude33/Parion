import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';

class AddInvestmentScreen extends StatefulWidget {
  final Investment? existing;
  const AddInvestmentScreen({super.key, this.existing});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = InvestmentService();
  final _symbolCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  InvestmentType _type = InvestmentType.crypto;
  InvestmentCurrency _currency = InvestmentCurrency.try_;
  DateTime _buyDate = DateTime.now();
  bool _loading = false;
  List<Map<String, String>> _cryptoCoins = [];
  bool _loadingCoins = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _type = e.type;
      _symbolCtrl.text = e.symbol;
      _nameCtrl.text = e.name;
      _quantityCtrl.text = e.quantity.toString();
      _priceCtrl.text = e.buyPrice.toStringAsFixed(2);
      _notesCtrl.text = e.notes ?? '';
      _currency = e.currency;
      _buyDate = e.buyDate;
    }
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    if (_cryptoCoins.isNotEmpty) return;
    setState(() => _loadingCoins = true);
    final coins = await _service.fetchTopCryptos();
    if (mounted) setState(() { _cryptoCoins = coins; _loadingCoins = false; });
  }

  void _showCoinPicker() {
    _loadCoins();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = searchCtrl.text.isEmpty
                ? _cryptoCoins
                : _cryptoCoins.where((c) =>
                    c['symbol']!.toLowerCase().contains(searchCtrl.text.toLowerCase()) ||
                    c['name']!.toLowerCase().contains(searchCtrl.text.toLowerCase())).toList();

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SizedBox(
                height: 500,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Kripto ara...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                    Expanded(
                      child: _loadingCoins
                          ? const Center(child: CircularProgressIndicator())
                          : filtered.isEmpty
                              ? const Center(child: Text('Kripto bulunamadı'))
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (_, i) {
                                    final coin = filtered[i];
                                    return ListTile(
                                      leading: CircleAvatar(child: Text(coin['symbol']![0], style: const TextStyle(fontSize: 12))),
                                      title: Text(coin['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('${coin['symbol']}  •  ₺${coin['current_price']}'),
                                      onTap: () {
                                        _symbolCtrl.text = coin['symbol']!;
                                        _nameCtrl.text = coin['name']!;
                                        Navigator.pop(ctx);
                                        setState(() {});
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final inv = Investment(
      id: widget.existing?.id ?? const Uuid().v4(),
      type: _type,
      symbol: _symbolCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      quantity: double.tryParse(_quantityCtrl.text.replaceAll(',', '.')) ?? 0,
      buyPrice: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0,
      currency: _currency,
      buyDate: _buyDate,
      notes: _notesCtrl.text.trim(),
    );

    if (widget.existing != null) {
      await _service.update(inv);
    } else {
      await _service.add(inv);
    }

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Yatırım Düzenle' : 'Yatırım Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<InvestmentType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: 'Tür', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: InvestmentType.crypto, child: Text('Kripto Para')),
                DropdownMenuItem(value: InvestmentType.stock, child: Text('Hisse Senedi')),
                DropdownMenuItem(value: InvestmentType.gold, child: Text('Altın')),
                DropdownMenuItem(value: InvestmentType.fund, child: Text('Fon')),
                DropdownMenuItem(value: InvestmentType.etf, child: Text('ETF')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _symbolCtrl,
              decoration: InputDecoration(
                labelText: 'Sembol',
                hintText: _type == InvestmentType.crypto ? 'BTC' : _type == InvestmentType.stock ? 'THYAO' : _type == InvestmentType.gold ? 'GRAM' : 'örn. AFA',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _type == InvestmentType.crypto
                    ? IconButton(icon: const Icon(Icons.search), onPressed: _showCoinPicker)
                    : null,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Ad',
                hintText: _type == InvestmentType.crypto ? 'Bitcoin' : _type == InvestmentType.stock ? 'Türk Hava Yolları' : 'Gram Altın',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityCtrl,
                    decoration: InputDecoration(
                      labelText: 'Miktar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Alış Fiyatı',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InvestmentCurrency>(
              initialValue: _currency,
              decoration: InputDecoration(labelText: 'Para Birimi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: InvestmentCurrency.try_, child: Text('₺ (TL)')),
                DropdownMenuItem(value: InvestmentCurrency.usd, child: Text('\$ (USD)')),
                DropdownMenuItem(value: InvestmentCurrency.eur, child: Text('€ (EUR)')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _currency = v);
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _buyDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _buyDate = date);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Alış Tarihi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(dateFormat.format(_buyDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'Notlar (isteğe bağlı)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.existing != null ? 'Güncelle' : 'Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
