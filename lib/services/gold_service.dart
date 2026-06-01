import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GoldService {
  static const String _apiUrl = 'https://api.gold-api.com/price/XAU';

  static const double _ounceToGram = 31.1034768;

  Map<String, double>? _cached;
  DateTime? _lastFetch;

  Future<GoldPrice?> fetchPrices({String currency = 'USD'}) async {
    try {
      stderr.writeln('GoldService: GET $_apiUrl');
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 8));

      stderr.writeln('GoldService: HTTP ${response.statusCode} len=${response.body.length}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final price = (data['price'] as num).toDouble();
        _cached = {'ounce_usd': price};
        _lastFetch = DateTime.now();
        stderr.writeln('GoldService: ounce_usd=$price');
        return GoldPrice(
          ounceUsd: price,
          fetchedAt: _lastFetch!,
        );
      } else {
        stderr.writeln('GoldService: non-200 body=${response.body.substring(0, response.body.length.clamp(0, 120))}');
        return _cached != null
            ? GoldPrice(ounceUsd: _cached!['ounce_usd']!, fetchedAt: _lastFetch ?? DateTime.now())
            : null;
      }
    } catch (e, st) {
      stderr.writeln('GoldService: ERROR $e');
      stderr.writeln('GoldService: STACK $st');
      return _cached != null
          ? GoldPrice(ounceUsd: _cached!['ounce_usd']!, fetchedAt: _lastFetch ?? DateTime.now())
          : null;
    }
  }

  static double gramPriceInCurrency({
    required double ouncePrice,
    required double currencyPerUsd,
  }) {
    return ouncePrice * currencyPerUsd / _ounceToGram;
  }
}

class GoldPrice {
  final double ounceUsd;
  final DateTime fetchedAt;

  GoldPrice({required this.ounceUsd, required this.fetchedAt});
}
