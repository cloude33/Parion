import 'family_member.dart';

enum FamilyGroupRole {
  owner,
  admin,
  member,
}

class FamilyGroup {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String currencyCode;
  final String currencySymbol;
  final List<FamilyMember> members;
  final String? colorHex;
  final String? iconName;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyGroup({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.currencyCode = 'TRY',
    this.currencySymbol = '₺',
    this.members = const [],
    this.colorHex,
    this.iconName,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  int get memberCount => members.length;

  List<FamilyMember> get activeMembers =>
      members.where((m) => m.isActive).toList();

  int get activeMemberCount => activeMembers.length;

  FamilyMember? getMember(String id) {
    try {
      return members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  FamilyGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? currencyCode,
    String? currencySymbol,
    List<FamilyMember>? members,
    String? colorHex,
    String? iconName,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      members: members ?? this.members,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'members': members.map((m) => m.toJson()).toList(),
        'colorHex': colorHex,
        'iconName': iconName,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Aile Grubu',
      description: json['description'] as String?,
      ownerId: (json['ownerId'] as String?) ?? '',
      currencyCode: (json['currencyCode'] as String?) ?? 'TRY',
      currencySymbol: (json['currencySymbol'] as String?) ?? '₺',
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      colorHex: json['colorHex'] as String?,
      iconName: json['iconName'] as String?,
      isArchived: (json['isArchived'] as bool?) ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String? validate() {
    if (name.trim().isEmpty) {
      return 'Grup adı boş olamaz';
    }
    if (members.isEmpty) {
      return 'En az bir üye olmalı';
    }
    if (ownerId.isEmpty) {
      return 'Sahip belirtilmeli';
    }
    final hasOwner = members.any((m) => m.id == ownerId);
    if (!hasOwner) {
      return 'Sahip, grup üyeleri arasında olmalı';
    }
    return null;
  }
}
