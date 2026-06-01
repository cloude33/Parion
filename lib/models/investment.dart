enum InvestmentType { stock, crypto, gold, fund, etf }

enum InvestmentCurrency { try_, usd, eur, gold }

class Investment {
  final String id;
  InvestmentType type;
  String symbol;
  String name;
  double quantity;
  double buyPrice;
  InvestmentCurrency currency;
  double? currentPrice;
  DateTime buyDate;
  String? notes;
  String? portfolioId;

  Investment({
    required this.id,
    required this.type,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.buyPrice,
    this.currency = InvestmentCurrency.try_,
    this.currentPrice,
    DateTime? buyDate,
    this.notes,
    this.portfolioId,
  }) : buyDate = buyDate ?? DateTime.now();

  double get costBasis => quantity * buyPrice;
  double? get currentValue => currentPrice != null ? quantity * currentPrice! : null;
  double? get profitLoss => currentValue != null ? currentValue! - costBasis : null;
  double? get profitLossPercent => costBasis > 0 ? ((profitLoss! / costBasis) * 100) : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'symbol': symbol,
    'name': name,
    'quantity': quantity,
    'buyPrice': buyPrice,
    'currency': currency.name,
    'currentPrice': currentPrice,
    'buyDate': buyDate.toIso8601String(),
    'notes': notes,
    'portfolioId': portfolioId,
  };

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      type: InvestmentType.values.firstWhere((e) => e.name == json['type']),
      symbol: json['symbol'],
      name: json['name'],
      quantity: (json['quantity'] as num).toDouble(),
      buyPrice: (json['buyPrice'] as num).toDouble(),
      currency: InvestmentCurrency.values.firstWhere(
        (e) => e.name == json['currency'],
        orElse: () => InvestmentCurrency.try_,
      ),
      currentPrice: (json['currentPrice'] as num?)?.toDouble(),
      buyDate: DateTime.parse(json['buyDate']),
      notes: json['notes'],
      portfolioId: json['portfolioId'],
    );
  }

  Investment copyWith({
    InvestmentType? type,
    String? symbol,
    String? name,
    double? quantity,
    double? buyPrice,
    InvestmentCurrency? currency,
    double? currentPrice,
    DateTime? buyDate,
    String? notes,
    String? portfolioId,
  }) {
    return Investment(
      id: id,
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      currency: currency ?? this.currency,
      currentPrice: currentPrice ?? this.currentPrice,
      buyDate: buyDate ?? this.buyDate,
      notes: notes ?? this.notes,
      portfolioId: portfolioId ?? this.portfolioId,
    );
  }
}
