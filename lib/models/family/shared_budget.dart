enum SharedBudgetPeriod {
  weekly,
  monthly,
  yearly,
}

class SharedBudgetAllocation {
  final String memberId;
  final double amount;
  final double percentage;

  const SharedBudgetAllocation({
    required this.memberId,
    required this.amount,
    this.percentage = 0.0,
  });

  SharedBudgetAllocation copyWith({
    String? memberId,
    double? amount,
    double? percentage,
  }) {
    return SharedBudgetAllocation(
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'amount': amount,
        'percentage': percentage,
      };

  factory SharedBudgetAllocation.fromJson(Map<String, dynamic> json) {
    return SharedBudgetAllocation(
      memberId: json['memberId'] as String,
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
      percentage: ((json['percentage'] as num?) ?? 0).toDouble(),
    );
  }
}

class SharedBudget {
  final String id;
  final String groupId;
  final String name;
  final String category;
  final double totalAmount;
  final SharedBudgetPeriod period;
  final DateTime startDate;
  final List<SharedBudgetAllocation> allocations;
  final String? colorHex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedBudget({
    required this.id,
    required this.groupId,
    required this.name,
    this.category = 'Genel',
    required this.totalAmount,
    this.period = SharedBudgetPeriod.monthly,
    required this.startDate,
    this.allocations = const [],
    this.colorHex,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  double getAmountFor(String memberId) {
    try {
      return allocations
          .firstWhere((a) => a.memberId == memberId)
          .amount;
    } catch (_) {
      return 0.0;
    }
  }

  SharedBudget copyWith({
    String? id,
    String? groupId,
    String? name,
    String? category,
    double? totalAmount,
    SharedBudgetPeriod? period,
    DateTime? startDate,
    List<SharedBudgetAllocation>? allocations,
    String? colorHex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedBudget(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      category: category ?? this.category,
      totalAmount: totalAmount ?? this.totalAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      allocations: allocations ?? this.allocations,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'name': name,
        'category': category,
        'totalAmount': totalAmount,
        'period': period.name,
        'startDate': startDate.toIso8601String(),
        'allocations': allocations.map((a) => a.toJson()).toList(),
        'colorHex': colorHex,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SharedBudget.fromJson(Map<String, dynamic> json) {
    return SharedBudget(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      name: (json['name'] as String?) ?? 'Ortak Bütçe',
      category: (json['category'] as String?) ?? 'Genel',
      totalAmount: ((json['totalAmount'] as num?) ?? 0).toDouble(),
      period: SharedBudgetPeriod.values.firstWhere(
        (p) => p.name == json['period'],
        orElse: () => SharedBudgetPeriod.monthly,
      ),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      allocations: (json['allocations'] as List<dynamic>?)
              ?.map((e) =>
                  SharedBudgetAllocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      colorHex: json['colorHex'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
