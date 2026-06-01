enum MemberDebtStatus {
  pending,
  settled,
  cancelled,
}

class MemberDebt {
  final String id;
  final String groupId;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final String description;
  final String? relatedExpenseId;
  final DateTime date;
  final MemberDebtStatus status;
  final DateTime? settledAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberDebt({
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.description,
    this.relatedExpenseId,
    required this.date,
    this.status = MemberDebtStatus.pending,
    this.settledAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == MemberDebtStatus.pending;
  bool get isSettled => status == MemberDebtStatus.settled;

  MemberDebt copyWith({
    String? id,
    String? groupId,
    String? fromMemberId,
    String? toMemberId,
    double? amount,
    String? description,
    String? relatedExpenseId,
    DateTime? date,
    MemberDebtStatus? status,
    DateTime? settledAt,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberDebt(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      relatedExpenseId: relatedExpenseId ?? this.relatedExpenseId,
      date: date ?? this.date,
      status: status ?? this.status,
      settledAt: settledAt ?? this.settledAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'fromMemberId': fromMemberId,
        'toMemberId': toMemberId,
        'amount': amount,
        'description': description,
        'relatedExpenseId': relatedExpenseId,
        'date': date.toIso8601String(),
        'status': status.name,
        'settledAt': settledAt?.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MemberDebt.fromJson(Map<String, dynamic> json) {
    return MemberDebt(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      fromMemberId: json['fromMemberId'] as String,
      toMemberId: json['toMemberId'] as String,
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
      description: (json['description'] as String?) ?? '',
      relatedExpenseId: json['relatedExpenseId'] as String?,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      status: MemberDebtStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MemberDebtStatus.pending,
      ),
      settledAt: json['settledAt'] != null
          ? DateTime.tryParse(json['settledAt'].toString())
          : null,
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String? validate() {
    if (fromMemberId == toMemberId) {
      return 'Borçlu ve alacaklı aynı kişi olamaz';
    }
    if (amount <= 0) {
      return 'Tutar sıfırdan büyük olmalı';
    }
    return null;
  }
}

class MemberSettlement {
  final String fromMemberId;
  final String toMemberId;
  final double amount;

  const MemberSettlement({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });
}
