import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/exchange_rate_service.dart';

class ExchangeRatesScreen extends StatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  State<ExchangeRatesScreen> createState() => _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends State<ExchangeRatesScreen> {
  final ExchangeRateService _service = ExchangeRateService();
  List<ExchangeRate> _rates = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _fromCurrency = 'TRY';
  String _toCurrency = 'USD';
  double? _conversionResult;
  double? _parsedAmount;
  String? _conversionError;
  String _searchQuery = '';

  static const List<String> _currencyList = [
    'TRY', 'USD', 'EUR', 'GBP', 'CHF', 'JPY', 'AUD', 'CAD',
    'CNY', 'SEK', 'NOK', 'DKK', 'RUB', 'AED', 'SAR', 'KWD',
    'BGN', 'RON', 'INR', 'BRL', 'ZAR', 'PLN', 'CZK', 'HUF',
  ];

  static const Map<String, String> _flags = {
    'TRY': '🇹🇷',
    'USD': '🇺🇸',
    'EUR': '🇪🇺',
    'GBP': '🇬🇧',
    'CHF': '🇨🇭',
    'JPY': '🇯🇵',
    'AUD': '🇦🇺',
    'CAD': '🇨🇦',
    'CNY': '🇨🇳',
    'SEK': '🇸🇪',
    'NOK': '🇳🇴',
    'DKK': '🇩🇰',
    'RUB': '🇷🇺',
    'AED': '🇦🇪',
    'SAR': '🇸🇦',
    'KWD': '🇰🇼',
    'BGN': '🇧🇬',
    'RON': '🇷🇴',
    'INR': '🇮🇳',
    'BRL': '🇧🇷',
    'ZAR': '🇿🇦',
    'MXN': '🇲🇽',
    'PLN': '🇵🇱',
    'CZK': '🇨🇿',
    'HUF': '🇭🇺',
    'ILS': '🇮🇱',
    'KRW': '🇰🇷',
    'SGD': '🇸🇬',
    'HKD': '🇭🇰',
    'MYR': '🇲🇾',
    'THB': '🇹🇭',
    'PHP': '🇵🇭',
    'IDR': '🇮🇩',
    'NZD': '🇳🇿',
    'KZT': '🇰🇿',
    'UAH': '🇺🇦',
  };

  static const List<String> _featuredCodes = ['USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final rates = await _service.fetchRates();
    if (mounted) {
      setState(() {
        _rates = rates;
        _loading = false;
        if (rates.isEmpty) _error = 'Döviz kurları alınamadı.';
      });
    }
  }

  double? _parseAmount(String input) {
    input = input.trim();
    if (input.isEmpty) return null;

    if (input.contains('.') && input.contains(',')) {
      final dotIndex = input.indexOf('.');
      final commaIndex = input.indexOf(',');
      if (dotIndex < commaIndex) {
        return double.tryParse(input.replaceAll('.', '').replaceAll(',', '.'));
      } else {
        return double.tryParse(input.replaceAll(',', ''));
      }
    }

    if (input.contains('.')) {
      final lastDotIndex = input.lastIndexOf('.');
      final afterDot = input.substring(lastDotIndex + 1);
      if (afterDot.length == 3 && input.length - afterDot.length > 1) {
        return double.tryParse(input.replaceAll('.', ''));
      } else {
        return double.tryParse(input);
      }
    }

    if (input.contains(',')) {
      final lastCommaIndex = input.lastIndexOf(',');
      final afterComma = input.substring(lastCommaIndex + 1);
      if (afterComma.length == 3 && input.length - afterComma.length > 1) {
        return double.tryParse(input.replaceAll(',', ''));
      } else {
        return double.tryParse(input.replaceAll(',', '.'));
      }
    }

    return double.tryParse(input);
  }

  void _convert() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _conversionError = 'Lütfen bir tutar girin.';
        _conversionResult = null;
        _parsedAmount = null;
      });
      return;
    }
    final amount = _parseAmount(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _conversionError = 'Geçersiz tutar.';
        _conversionResult = null;
        _parsedAmount = null;
      });
      return;
    }
    setState(() {
      _conversionError = null;
      _conversionResult = null;
      _parsedAmount = amount;
    });
    _service.convert(amount: amount, from: _fromCurrency, to: _toCurrency).then((result) {
      if (mounted) {
        setState(() {
          _conversionResult = result;
          if (result == null) _conversionError = 'Dönüşüm yapılamadı.';
        });
      }
    });
  }

  double _tryPerUnit(ExchangeRate rate) {
    if (rate.code == 'TRY') return 1.0;
    if (rate.rate == 0) return 0;
    return 1.0 / rate.rate;
  }

  String _formatTry(double value) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '',
      decimalDigits: value >= 100 ? 2 : 4,
    );
    return formatter.format(value).trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Döviz Kurları'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchRates,
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Döviz Kurları'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchRates,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchRates, child: Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    final lastUpdated = _rates.isNotEmpty ? _rates.first.lastUpdated : DateTime.now();
    final updatedText = DateFormat('d MMMM y, HH:mm', 'tr_TR').format(lastUpdated);

    final featured = _rates
        .where((r) => _featuredCodes.contains(r.code))
        .toList()
      ..sort((a, b) => _featuredCodes.indexOf(a.code).compareTo(_featuredCodes.indexOf(b.code)));

    final filteredRates = _rates
        .where((r) => r.code != 'TRY')
        .where((r) => _searchQuery.isEmpty ||
            r.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchRates,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchRates,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
                title: const Text(
                  'Döviz Kurları',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.7),
                            ]
                          : [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.85),
                              theme.colorScheme.tertiary.withValues(alpha: 0.6),
                            ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Türk Lirası Karşılığı',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('🇹🇷', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 6),
                              Text(
                                '1 ₺ = 1,00 ₺',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Son güncelleme: $updatedText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _buildConverterCard(theme),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Öne Çıkan Kurlar',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: featured.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _buildFeaturedCard(featured[i], theme, isDark),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Tüm Kurlar',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredRates.length} para birimi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Para birimi ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            if (filteredRates.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 40, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList.separated(
                  itemCount: filteredRates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _buildRateRow(filteredRates[i], theme, isDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.swap_horiz, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Çevirici',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                TurkishCurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Tutar',
                filled: true,
                fillColor: theme.colorScheme.surface.withValues(alpha: 0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.monetization_on),
              ),
              onChanged: (_) => _convert(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCurrencyDropdown(
                    value: _fromCurrency,
                    label: 'Kaynak',
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _fromCurrency = v);
                        _convert();
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward, color: theme.colorScheme.onSecondaryContainer),
                ),
                Expanded(
                  child: _buildCurrencyDropdown(
                    value: _toCurrency,
                    label: 'Hedef',
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _toCurrency = v);
                        _convert();
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_conversionError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_conversionError!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            if (_conversionResult != null && _parsedAmount != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2).format(_parsedAmount)} $_fromCurrency = ${NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2).format(_conversionResult!)} $_toCurrency',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: _currencyList
          .map((c) => DropdownMenuItem(
                value: c,
                child: Row(
                  children: [
                    Text(_flags[c] ?? '', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFeaturedCard(ExchangeRate rate, ThemeData theme, bool isDark) {
    final tryValue = _tryPerUnit(rate);
    final flag = _flags[rate.code] ?? '';

    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '1 ${rate.code}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(flag, style: const TextStyle(fontSize: 28)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₺ ${_formatTry(tryValue)}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rate.name,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(ExchangeRate rate, ThemeData theme, bool isDark) {
    final tryValue = _tryPerUnit(rate);
    final flag = _flags[rate.code] ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(flag, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1 ${rate.code}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rate.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺ ${_formatTry(tryValue)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Türk Lirası',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TurkishCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String text = newValue.text;

    int decimalSepIndexInNew = -1;
    if (text.contains(',')) {
      decimalSepIndexInNew = text.indexOf(',');
    } else if (text.contains('.')) {
      final lastDot = text.lastIndexOf('.');
      final afterDot = text.substring(lastDot + 1);
      if (afterDot.isEmpty || (afterDot.length <= 2 && RegExp(r'^\d+$').hasMatch(afterDot))) {
        decimalSepIndexInNew = lastDot;
      }
    }

    String cleanInteger = '';
    String cleanDecimal = '';
    bool hasDecimal = decimalSepIndexInNew != -1;

    if (hasDecimal) {
      String rawInteger = text.substring(0, decimalSepIndexInNew);
      String rawDecimal = text.substring(decimalSepIndexInNew + 1);

      cleanInteger = rawInteger.replaceAll(RegExp(r'\D'), '');
      cleanDecimal = rawDecimal.replaceAll(RegExp(r'\D'), '');
      if (cleanDecimal.length > 2) {
        cleanDecimal = cleanDecimal.substring(0, 2);
      }
    } else {
      cleanInteger = text.replaceAll(RegExp(r'\D'), '');
    }

    String formattedInteger = '';
    if (cleanInteger.isNotEmpty) {
      final number = int.tryParse(cleanInteger);
      if (number != null) {
        formattedInteger = NumberFormat('#,##0', 'tr_TR').format(number);
      } else {
        formattedInteger = cleanInteger;
      }
    } else if (hasDecimal) {
      formattedInteger = '0';
    }

    String formattedText = formattedInteger;
    if (hasDecimal) {
      formattedText += ',$cleanDecimal';
    }

    int selectionEnd = newValue.selection.end;
    if (selectionEnd < 0) {
      selectionEnd = text.length;
    }

    int cleanCharsBeforeCursor = 0;
    for (int i = 0; i < selectionEnd; i++) {
      if (i < text.length) {
        final char = text[i];
        if (char == '.') {
          if (hasDecimal && i == decimalSepIndexInNew) {
            cleanCharsBeforeCursor++;
          }
        } else {
          cleanCharsBeforeCursor++;
        }
      }
    }

    int formattedOffset = 0;
    int cleanCharsSeen = 0;
    while (formattedOffset < formattedText.length && cleanCharsSeen < cleanCharsBeforeCursor) {
      final char = formattedText[formattedOffset];
      if (char != '.') {
        cleanCharsSeen++;
      }
      formattedOffset++;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedOffset),
    );
  }
}
