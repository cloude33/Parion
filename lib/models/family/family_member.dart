import 'family_group.dart';

class FamilyMember {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final FamilyGroupRole role;
  final int colorValue;
  final bool isActive;
  final double monthlyBudget;
  final DateTime createdAt;

  const FamilyMember({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.role = FamilyGroupRole.member,
    this.colorValue = 0xFF2C6BED,
    this.isActive = true,
    this.monthlyBudget = 0.0,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get isOwner => role == FamilyGroupRole.owner;
  bool get isAdmin => role == FamilyGroupRole.admin || isOwner;

  FamilyMember copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    FamilyGroupRole? role,
    int? colorValue,
    bool? isActive,
    double? monthlyBudget,
    DateTime? createdAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'role': role.name,
        'colorValue': colorValue,
        'isActive': isActive,
        'monthlyBudget': monthlyBudget,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Üye',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      role: FamilyGroupRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => FamilyGroupRole.member,
      ),
      colorValue: (json['colorValue'] as int?) ?? 0xFF2C6BED,
      isActive: (json['isActive'] as bool?) ?? true,
      monthlyBudget:
          ((json['monthlyBudget'] as num?) ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String? validate() {
    if (name.trim().isEmpty) {
      return 'Üye adı boş olamaz';
    }
    if (monthlyBudget < 0) {
      return 'Aylık bütçe negatif olamaz';
    }
    return null;
  }
}
