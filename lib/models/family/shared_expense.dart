import 'family_member.dart';

enum SplitType {
  equal,
  exact,
  percentage,
  shares,
}

class ExpenseShare {
  final String memberId;
  final double amount;
  final double percentage;

  const ExpenseShare({
    required this.memberId,
    required this.amount,
    this.percentage = 0.0,
  });

  ExpenseShare copyWith({
    String? memberId,
    double? amount,
    double? percentage,
  }) {
    return ExpenseShare(
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

  factory ExpenseShare.fromJson(Map<String, dynamic> json) {
    return ExpenseShare(
      memberId: json['memberId'] as String,
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
      percentage: ((json['percentage'] as num?) ?? 0).toDouble(),
    );
  }
}

class SharedExpense {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final double totalAmount;
  final String paidByMemberId;
  final String category;
  final DateTime date;
  final SplitType splitType;
  final List<ExpenseShare> shares;
  final String? receiptImagePath;
  final bool isSettled;
  final DateTime? settledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedExpense({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.paidByMemberId,
    this.category = 'Genel',
    required this.date,
    this.splitType = SplitType.equal,
    this.shares = const [],
    this.receiptImagePath,
    this.isSettled = false,
    this.settledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  double getAmountFor(String memberId) {
    try {
      return shares
          .firstWhere((s) => s.memberId == memberId)
          .amount;
    } catch (_) {
      return 0.0;
    }
  }

  double getPaidBy(String memberId) {
    return paidByMemberId == memberId ? totalAmount : 0.0;
  }

  double getNetFor(String memberId) {
    return getPaidBy(memberId) - getAmountFor(memberId);
  }

  bool involves(String memberId) {
    if (paidByMemberId == memberId) return true;
    return shares.any((s) => s.memberId == memberId);
  }

  SharedExpense copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    double? totalAmount,
    String? paidByMemberId,
    String? category,
    DateTime? date,
    SplitType? splitType,
    List<ExpenseShare>? shares,
    String? receiptImagePath,
    bool? isSettled,
    DateTime? settledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedExpense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      category: category ?? this.category,
      date: date ?? this.date,
      splitType: splitType ?? this.splitType,
      shares: shares ?? this.shares,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'title': title,
        'description': description,
        'totalAmount': totalAmount,
        'paidByMemberId': paidByMemberId,
        'category': category,
        'date': date.toIso8601String(),
        'splitType': splitType.name,
        'shares': shares.map((s) => s.toJson()).toList(),
        'receiptImagePath': receiptImagePath,
        'isSettled': isSettled,
        'settledAt': settledAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SharedExpense.fromJson(Map<String, dynamic> json) {
    return SharedExpense(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      title: (json['title'] as String?) ?? 'Harcama',
      description: json['description'] as String?,
      totalAmount: ((json['totalAmount'] as num?) ?? 0).toDouble(),
      paidByMemberId: json['paidByMemberId'] as String,
      category: (json['category'] as String?) ?? 'Genel',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      splitType: SplitType.values.firstWhere(
        (s) => s.name == json['splitType'],
        orElse: () => SplitType.equal,
      ),
      shares: (json['shares'] as List<dynamic>?)
              ?.map((e) => ExpenseShare.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      receiptImagePath: json['receiptImagePath'] as String?,
      isSettled: (json['isSettled'] as bool?) ?? false,
      settledAt: json['settledAt'] != null
          ? DateTime.tryParse(json['settledAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String? validate(List<FamilyMember> members) {
    if (title.trim().isEmpty) {
      return 'Harcama başlığı boş olamaz';
    }
    if (totalAmount <= 0) {
      return 'Tutar sıfırdan büyük olmalı';
    }
    final memberIds = members.map((m) => m.id).toSet();
    if (!memberIds.contains(paidByMemberId)) {
      return 'Ödeyen üye grupta bulunmalı';
    }
    if (shares.isEmpty) {
      return 'En az bir paylaşım girilmeli';
    }
    final sumShares = shares.fold<double>(0, (s, e) => s + e.amount);
    if ((sumShares - totalAmount).abs() > 0.01) {
      return 'Paylaşım toplamı, harcama tutarına eşit olmalı';
    }
    if (splitType == SplitType.percentage) {
      final sumPct = shares.fold<double>(0, (s, e) => s + e.percentage);
      if ((sumPct - 100).abs() > 0.01) {
        return 'Yüzde toplamı %100 olmalı';
      }
    }
    for (final s in shares) {
      if (!memberIds.contains(s.memberId)) {
        return 'Paylaşım listesinde geçersiz üye var';
      }
    }
    return null;
  }
}

class BalanceEntry {
  final String memberId;
  final String memberName;
  final double paid;
  final double share;
  final double net;

  const BalanceEntry({
    required this.memberId,
    required this.memberName,
    required this.paid,
    required this.share,
    required this.net,
  });

  bool get isDebtor => net < -0.01;
  bool get isCreditor => net > 0.01;
}
