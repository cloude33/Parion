import 'dart:convert';
import 'package:http/http.dart' as http;

class TruncgilRate {
  final String code;
  final String name;
  final double buying;
  final double selling;
  final double changePercent;
  final String type;

  const TruncgilRate({
    required this.code,
    required this.name,
    required this.buying,
    required this.selling,
    required this.changePercent,
    required this.type,
  });

  factory TruncgilRate.fromJson(String code, Map<String, dynamic> json) {
    return TruncgilRate(
      code: code,
      name: code,
      buying: TruncgilService.parseTurkishNumber(
        (json['Buying'] ?? '0').toString(),
      ),
      selling: TruncgilService.parseTurkishNumber(
        (json['Selling'] ?? '0').toString(),
      ),
      changePercent: TruncgilService.parseChangePercent(
        (json['Change'] ?? '%0,00').toString(),
      ),
      type: (json['Type'] ?? 'Currency').toString(),
    );
  }
}

class TruncgilData {
  final DateTime updatedAt;
  final Map<String, TruncgilRate> rates;

  const TruncgilData({
    required this.updatedAt,
    required this.rates,
  });

  TruncgilRate? operator [](String code) => rates[code];

  double? usdBuy() => rates['USD']?.buying;
  double? usdSell() => rates['USD']?.selling;
  double? eurBuy() => rates['EUR']?.buying;
  double? eurSell() => rates['EUR']?.selling;
  double? gbpSell() => rates['GBP']?.selling;
  double? onsUsdSell() => rates['ons']?.selling;
  double? onsUsdBuy() => rates['ons']?.buying;
  double? gramAltinSell() => rates['gram-altin']?.selling;
  double? gramAltinBuy() => rates['gram-altin']?.buying;
  double? ceyrekAltinSell() => rates['ceyrek-altin']?.selling;
  double? gumusSell() => rates['gumus']?.selling;
}

class TruncgilService {
  static const String _apiUrl =
      'https://finans.truncgil.com/v3/today.json';

  static const Duration _cacheTimeout = Duration(minutes: 5);

  static const Map<String, String> _currencyNames = {
    'USD': 'ABD Doları',
    'EUR': 'Euro',
    'GBP': 'İngiliz Sterlini',
    'CHF': 'İsviçre Frangı',
    'JPY': 'Japon Yeni',
    'AUD': 'Avustralya Doları',
    'CAD': 'Kanada Doları',
    'CNY': 'Çin Yuanı',
    'SEK': 'İsveç Kronu',
    'NOK': 'Norveç Kronu',
    'DKK': 'Danimarka Kronu',
    'RUB': 'Rus Rublesi',
    'AED': 'BAE Dirhemi',
    'SAR': 'Suudi Riyali',
    'KWD': 'Kuveyt Dinarı',
    'BGN': 'Bulgar Levası',
    'RON': 'Romen Leyi',
    'INR': 'Hindistan Rupisi',
    'BRL': 'Brezilya Reali',
    'ZAR': 'Güney Afrika Randı',
    'MXN': 'Meksika Pezosu',
    'PLN': 'Polonya Zlotisi',
    'CZK': 'Çek Kronu',
    'HUF': 'Macar Forinti',
    'ILS': 'İsrail Şekeli',
    'KRW': 'Güney Kore Wonu',
    'SGD': 'Singapur Doları',
    'HKD': 'Hong Kong Doları',
    'MYR': 'Malezya Ringiti',
    'THB': 'Tayland Bahtı',
    'PHP': 'Filipin Pezosu',
    'IDR': 'Endonezya Rupiahı',
    'NZD': 'Yeni Zelanda Doları',
    'KZT': 'Kazakistan Tengesi',
    'UAH': 'Ukrayna Grivnası',
    'TRY': 'Türk Lirası',
  };

  TruncgilData? _cached;
  DateTime? _lastFetch;

  Future<TruncgilData?> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
        return _cached;
      }
    }

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return _cached;

      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body) as Map<String, dynamic>;

      final rates = <String, TruncgilRate>{};
      for (final entry in data.entries) {
        final key = entry.key;
        if (key == 'Update_Date') continue;
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        rates[key] = TruncgilRate.fromJson(key, value);
      }

      final updatedAt = _parseUpdateDate(
        (data['Update_Date'] ?? '').toString(),
      );

      _cached = TruncgilData(updatedAt: updatedAt, rates: rates);
      _lastFetch = DateTime.now();
      return _cached;
    } catch (_) {
      return _cached;
    }
  }

  static double parseTurkishNumber(String s) {
    var cleaned = s.trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double parseChangePercent(String s) {
    final cleaned = s.replaceAll('%', '').replaceAll(',', '.').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  static DateTime _parseUpdateDate(String s) {
    try {
      final parts = s.split(' ');
      if (parts.length < 2) return DateTime.now();
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  static String nameFor(String code) => _currencyNames[code] ?? code;

  static bool isFreeMarketClosed(DateTime now) {
    final trHour = now.hour;
    final weekday = now.weekday;

    if (weekday == DateTime.saturday) return true;
    if (weekday == DateTime.sunday) return true;
    if (weekday == DateTime.friday && trHour >= 18) return true;
    if (weekday == DateTime.monday && trHour < 8) return true;
    return false;
  }

  static String freeMarketStatusMessage(DateTime now) {
    if (isFreeMarketClosed(now)) {
      return 'Piyasalar kapalı • Son kapanış fiyatları gösteriliyor';
    }
    return 'Serbest piyasa • Anlık';
  }
}
