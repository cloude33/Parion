import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/investment.dart';

class InvestmentService {
  static const String _boxName = 'investments';

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  Future<List<Investment>> getAll() async {
    final box = await _getBox();
    final values = box.values.cast<Map>().toList();
    return values.map((e) => Investment.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> add(Investment investment) async {
    final box = await _getBox();
    await box.put(investment.id, investment.toJson());
  }

  Future<void> update(Investment investment) async {
    final box = await _getBox();
    await box.put(investment.id, investment.toJson());
  }

  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<double> fetchPrice(Investment investment) async {
    switch (investment.type) {
      case InvestmentType.crypto:
        return await _fetchCryptoPrice(investment.symbol);
      case InvestmentType.stock:
      case InvestmentType.fund:
      case InvestmentType.etf:
        return await _fetchStockPrice(investment.symbol);
      case InvestmentType.gold:
        return await _fetchGoldPrice();
    }
  }

  Future<double> _fetchCryptoPrice(String symbol) async {
    final id = _cryptoId(symbol);
    if (id == null) return 0;
    try {
      final response = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$id&vs_currencies=try'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final price = (data[id]?['try'] as num?)?.toDouble();
        return price ?? 0;
      }
    } catch (e) {
      debugPrint('InvestmentService: Crypto price error: $e');
    }
    return 0;
  }

  String? _cryptoId(String symbol) {
    const map = {
      'BTC': 'bitcoin',
      'ETH': 'ethereum',
      'BNB': 'binancecoin',
      'XRP': 'ripple',
      'ADA': 'cardano',
      'SOL': 'solana',
      'DOT': 'polkadot',
      'DOGE': 'dogecoin',
      'AVAX': 'avalanche-2',
      'MATIC': 'matic-network',
      'LINK': 'chainlink',
      'UNI': 'uniswap',
      'ATOM': 'cosmos',
      'LTC': 'litecoin',
      'BCH': 'bitcoin-cash',
      'TRX': 'tron',
      'NEAR': 'near',
      'APT': 'aptos',
      'ARB': 'arbitrum',
      'OP': 'optimism',
    };
    return map[symbol.toUpperCase()];
  }

  Future<double> _fetchStockPrice(String symbol) async {
    try {
      final response = await http
          .get(Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/${symbol.toUpperCase()}.IS'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['chart']?['result'] as List?;
        if (result != null && result.isNotEmpty) {
          final meta = result[0] as Map<String, dynamic>;
          final price = (meta['meta']?['regularMarketPrice'] as num?)?.toDouble();
          return price ?? 0;
        }
      }
    } catch (e) {
      debugPrint('InvestmentService: Stock price error: $e');
    }
    return 0;
  }

  Future<double> _fetchGoldPrice() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.collectapi.com/economy/goldPrice'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['result'] as List?;
        if (result != null && result.isNotEmpty) {
          for (final item in result) {
            if (item['name']?.toString().contains('Gram Altın') == true) {
              return double.tryParse(item['selling']?.toString() ?? '0') ?? 0;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('InvestmentService: Gold price error: $e');
    }
    return 0;
  }

  Future<void> updateAllPrices() async {
    final investments = await getAll();
    for (final inv in investments) {
      final price = await fetchPrice(inv);
      if (price > 0) {
        inv.currentPrice = price;
        await update(inv);
      }
    }
  }

  List<Map<String, String>> _cachedCryptoList = [];
  DateTime? _cryptoListFetched;

  Future<List<Map<String, String>>> fetchTopCryptos() async {
    if (_cachedCryptoList.isNotEmpty && _cryptoListFetched != null &&
        DateTime.now().difference(_cryptoListFetched!).inMinutes < 30) {
      return _cachedCryptoList;
    }

    try {
      final response = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=try&order=market_cap_desc&per_page=100&page=1'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        _cachedCryptoList = list.map((item) {
          final coin = item as Map<String, dynamic>;
          return {
            'symbol': (coin['symbol']?.toString() ?? '').toUpperCase(),
            'name': coin['name']?.toString() ?? '',
            'id': coin['id']?.toString() ?? '',
            'current_price': (coin['current_price'] as num?)?.toStringAsFixed(2) ?? '',
          };
        }).toList();
        _cryptoListFetched = DateTime.now();
        return _cachedCryptoList;
      }
    } catch (e) {
      debugPrint('InvestmentService: Crypto list error: $e');
    }
    return [];
  }
}
