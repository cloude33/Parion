import 'package:flutter/foundation.dart';
import 'truncgil_service.dart';

class ExchangeRate {
  final String code;
  final String name;
  final double rate;
  final DateTime lastUpdated;

  ExchangeRate({
    required this.code,
    required this.name,
    required this.rate,
    required this.lastUpdated,
  });
}

class ExchangeRateService {
  final TruncgilService _truncgil = TruncgilService();

  TruncgilData? _cachedData;
  DateTime? _lastFetch;

  Future<List<ExchangeRate>> fetchRates() async {
    try {
      final data = await _truncgil.fetchAll();
      if (data == null) {
        debugPrint('ExchangeRateService: Truncgil returned null');
        return [];
      }
      _cachedData = data;
      _lastFetch = DateTime.now();

      final result = <ExchangeRate>[];
      result.add(ExchangeRate(
        code: 'TRY',
        name: 'Türk Lirası',
        rate: 1.0,
        lastUpdated: data.updatedAt,
      ));

      final List<String> prioritized = [
        'USD', 'EUR', 'GBP', 'CHF', 'JPY',
        'AUD', 'CAD', 'CNY', 'SAR', 'AED',
      ];
      final seen = <String>{};
      for (final code in prioritized) {
        final r = data[code];
        if (r == null) continue;
        seen.add(code);
        result.add(ExchangeRate(
          code: code,
          name: TruncgilService.nameFor(code),
          rate: r.selling == 0 ? 0.0 : 1.0 / r.selling,
          lastUpdated: data.updatedAt,
        ));
      }
      for (final entry in data.rates.entries) {
        if (seen.contains(entry.key)) continue;
        if (entry.value.type != 'Currency') continue;
        if (entry.key.length != 3) continue;
        result.add(ExchangeRate(
          code: entry.key,
          name: TruncgilService.nameFor(entry.key),
          rate: entry.value.selling == 0 ? 0.0 : 1.0 / entry.value.selling,
          lastUpdated: data.updatedAt,
        ));
      }
      return result;
    } catch (e) {
      debugPrint('ExchangeRateService: Error fetching rates: $e');
      return [];
    }
  }

  Future<double?> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;

    try {
      if (_cachedData == null) {
        await fetchRates();
      }

      final data = _cachedData;
      if (data == null) return null;

      double? fromSell = from == 'TRY' ? 1.0 : data[from]?.selling;
      double? toSell = to == 'TRY' ? 1.0 : data[to]?.selling;

      if (fromSell == null || toSell == null || fromSell == 0) return null;

      final amountInTry = from == 'TRY' ? amount : amount * fromSell;
      if (to == 'TRY') return amountInTry;
      return amountInTry / toSell;
    } catch (e) {
      debugPrint('ExchangeRateService: Error converting: $e');
      return null;
    }
  }
}
