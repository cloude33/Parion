import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/family/family_export.dart';

class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;
  FamilyService._internal();

  static const String _groupsKey = 'family_groups_v1';
  static const String _expensesKey = 'family_expenses_v1';
  static const String _budgetsKey = 'family_budgets_v1';
  static const String _debtsKey = 'family_member_debts_v1';

  final Uuid _uuid = const Uuid();

  List<FamilyGroup>? _cachedGroups;
  List<SharedExpense>? _cachedExpenses;
  List<SharedBudget>? _cachedBudgets;
  List<MemberDebt>? _cachedDebts;
  DateTime? _lastGroupUpdate;
  DateTime? _lastExpenseUpdate;
  DateTime? _lastBudgetUpdate;
  DateTime? _lastDebtUpdate;

  static const Duration _cacheTimeout = Duration(minutes: 5);

  void clearCache() {
    _cachedGroups = null;
    _cachedExpenses = null;
    _cachedBudgets = null;
    _cachedDebts = null;
    _lastGroupUpdate = null;
    _lastExpenseUpdate = null;
    _lastBudgetUpdate = null;
    _lastDebtUpdate = null;
  }

  bool _isCacheValid(DateTime? lastUpdate) {
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < _cacheTimeout;
  }

  // ===== GROUPS =====

  Future<List<FamilyGroup>> getGroups({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isCacheValid(_lastGroupUpdate) &&
        _cachedGroups != null) {
      return _cachedGroups!;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_groupsKey);
    final groups = raw == null
        ? <FamilyGroup>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => FamilyGroup.fromJson(e as Map<String, dynamic>))
            .toList();
    _cachedGroups = groups;
    _lastGroupUpdate = DateTime.now();
    return groups;
  }

  Future<FamilyGroup?> getGroupById(String id,
      {bool forceRefresh = false}) async {
    final groups = await getGroups(forceRefresh: forceRefresh);
    try {
      return groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<FamilyGroup>> getActiveGroups() async {
    final groups = await getGroups();
    return groups.where((g) => !g.isArchived).toList();
  }

  Future<FamilyGroup> createGroup({
    required String name,
    String? description,
    required String ownerId,
    String currencyCode = 'TRY',
    String currencySymbol = '₺',
    String? colorHex,
    String? iconName,
    String ownerName = 'Siz',
    String? ownerEmail,
    int ownerColor = 0xFF2C6BED,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Grup adı boş olamaz');
    }

    final now = DateTime.now();
    final owner = FamilyMember(
      id: ownerId,
      name: ownerName,
      email: ownerEmail,
      role: FamilyGroupRole.owner,
      colorValue: ownerColor,
      createdAt: now,
    );

    final group = FamilyGroup(
      id: _uuid.v4(),
      name: name.trim(),
      description: description?.trim(),
      ownerId: ownerId,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      members: [owner],
      colorHex: colorHex,
      iconName: iconName,
      createdAt: now,
      updatedAt: now,
    );

    final error = group.validate();
    if (error != null) {
      throw ArgumentError(error);
    }

    final groups = await getGroups();
    groups.add(group);
    await _saveGroups(groups);
    return group;
  }

  Future<FamilyGroup> updateGroup(FamilyGroup group) async {
    final error = group.validate();
    if (error != null) {
      throw ArgumentError(error);
    }
    final groups = await getGroups();
    final idx = groups.indexWhere((g) => g.id == group.id);
    if (idx == -1) {
      throw ArgumentError('Grup bulunamadı');
    }
    final updated = group.copyWith(updatedAt: DateTime.now());
    groups[idx] = updated;
    await _saveGroups(groups);
    return updated;
  }

  Future<void> deleteGroup(String id) async {
    final groups = await getGroups();
    groups.removeWhere((g) => g.id == id);
    await _saveGroups(groups);

    final prefs = await SharedPreferences.getInstance();
    final expensesRaw = prefs.getString(_expensesKey);
    if (expensesRaw != null) {
      final expenses = (jsonDecode(expensesRaw) as List<dynamic>)
          .map((e) => SharedExpense.fromJson(e as Map<String, dynamic>))
          .where((e) => e.groupId != id)
          .toList();
      await prefs.setString(
        _expensesKey,
        jsonEncode(expenses.map((e) => e.toJson()).toList()),
      );
      _cachedExpenses = expenses;
    }
    final budgetsRaw = prefs.getString(_budgetsKey);
    if (budgetsRaw != null) {
      final budgets = (jsonDecode(budgetsRaw) as List<dynamic>)
          .map((e) => SharedBudget.fromJson(e as Map<String, dynamic>))
          .where((b) => b.groupId != id)
          .toList();
      await prefs.setString(
        _budgetsKey,
        jsonEncode(budgets.map((b) => b.toJson()).toList()),
      );
      _cachedBudgets = budgets;
    }
    final debtsRaw = prefs.getString(_debtsKey);
    if (debtsRaw != null) {
      final debts = (jsonDecode(debtsRaw) as List<dynamic>)
          .map((e) => MemberDebt.fromJson(e as Map<String, dynamic>))
          .where((d) => d.groupId != id)
          .toList();
      await prefs.setString(
        _debtsKey,
        jsonEncode(debts.map((d) => d.toJson()).toList()),
      );
      _cachedDebts = debts;
    }
  }

  // ===== MEMBERS =====

  Future<FamilyMember> addMember({
    required String groupId,
    required String name,
    String? email,
    String? phone,
    FamilyGroupRole role = FamilyGroupRole.member,
    int colorValue = 0xFF2C6BED,
    double monthlyBudget = 0.0,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Üye adı boş olamaz');
    }
    final group = await getGroupById(groupId);
    if (group == null) {
      throw ArgumentError('Grup bulunamadı');
    }

    final now = DateTime.now();
    final member = FamilyMember(
      id: _uuid.v4(),
      name: name.trim(),
      email: email?.trim(),
      phone: phone?.trim(),
      role: role,
      colorValue: colorValue,
      monthlyBudget: monthlyBudget,
      createdAt: now,
    );
    final error = member.validate();
    if (error != null) {
      throw ArgumentError(error);
    }

    final updatedMembers = [...group.members, member];
    final updated = group.copyWith(
      members: updatedMembers,
      updatedAt: now,
    );
    await updateGroup(updated);
    return member;
  }

  Future<FamilyMember> updateMember({
    required String groupId,
    required FamilyMember member,
  }) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw ArgumentError('Grup bulunamadı');
    }
    final error = member.validate();
    if (error != null) {
      throw ArgumentError(error);
    }
    final idx = group.members.indexWhere((m) => m.id == member.id);
    if (idx == -1) {
      throw ArgumentError('Üye bulunamadı');
    }
    final newMembers = List<FamilyMember>.from(group.members);
    newMembers[idx] = member;
    await updateGroup(group.copyWith(members: newMembers));
    return member;
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw ArgumentError('Grup bulunamadı');
    }
    if (memberId == group.ownerId) {
      throw ArgumentError('Grup sahibi silinemez');
    }
    final newMembers =
        group.members.where((m) => m.id != memberId).toList();
    await updateGroup(group.copyWith(members: newMembers));
  }

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw ArgumentError('Grup bulunamadı');
    }
    final exists = group.members.any((m) => m.id == newOwnerId);
    if (!exists) {
      throw ArgumentError('Yeni sahip grupta bulunmalı');
    }
    final newMembers = group.members.map((m) {
      if (m.id == newOwnerId) {
        return m.copyWith(role: FamilyGroupRole.owner);
      } else if (m.role == FamilyGroupRole.owner) {
        return m.copyWith(role: FamilyGroupRole.admin);
      }
      return m;
    }).toList();
    await updateGroup(
      group.copyWith(
        members: newMembers,
        ownerId: newOwnerId,
      ),
    );
  }

  // ===== EXPENSES =====

  Future<List<SharedExpense>> getExpenses({
    String? groupId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _isCacheValid(_lastExpenseUpdate) &&
        _cachedExpenses != null) {
      final all = _cachedExpenses!;
      if (groupId == null) return all;
      return all.where((e) => e.groupId == groupId).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_expensesKey);
    final expenses = raw == null
        ? <SharedExpense>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => SharedExpense.fromJson(e as Map<String, dynamic>))
            .toList();
    _cachedExpenses = expenses;
    _lastExpenseUpdate = DateTime.now();
    if (groupId == null) return expenses;
    return expenses.where((e) => e.groupId == groupId).toList();
  }

  Future<List<SharedExpense>> getExpensesForMember(String memberId) async {
    final all = await getExpenses();
    return all.where((e) => e.involves(memberId)).toList();
  }

  Future<SharedExpense> addExpense({
    required String groupId,
    required String title,
    String? description,
    required double totalAmount,
    required String paidByMemberId,
    String category = 'Genel',
    required DateTime date,
    SplitType splitType = SplitType.equal,
    required List<ExpenseShare> shares,
    String? receiptImagePath,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Başlık boş olamaz');
    }
    if (totalAmount <= 0) {
      throw ArgumentError('Tutar sıfırdan büyük olmalı');
    }
    final group = await getGroupById(groupId);
    if (group == null) {
      throw ArgumentError('Grup bulunamadı');
    }
    final now = DateTime.now();
    final expense = SharedExpense(
      id: _uuid.v4(),
      groupId: groupId,
      title: title.trim(),
      description: description?.trim(),
      totalAmount: totalAmount,
      paidByMemberId: paidByMemberId,
      category: category,
      date: date,
      splitType: splitType,
      shares: shares,
      receiptImagePath: receiptImagePath,
      createdAt: now,
      updatedAt: now,
    );
    final error = expense.validate(group.activeMembers);
    if (error != null) {
      throw ArgumentError(error);
    }
    final all = await getExpenses();
    all.add(expense);
    await _saveExpenses(all);
    return expense;
  }

  Future<SharedExpense> updateExpense(SharedExpense expense) async {
    final group = await getGroupById(expense.groupId);
    if (group == null) {
      throw ArgumentError('Grup bulunamadı');
    }
    final error = expense.validate(group.activeMembers);
    if (error != null) {
      throw ArgumentError(error);
    }
    final all = await getExpenses();
    final idx = all.indexWhere((e) => e.id == expense.id);
    if (idx == -1) {
      throw ArgumentError('Harcama bulunamadı');
    }
    final updated = expense.copyWith(updatedAt: DateTime.now());
    all[idx] = updated;
    await _saveExpenses(all);
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    final all = await getExpenses();
    all.removeWhere((e) => e.id == id);
    await _saveExpenses(all);
  }

  // ===== BUDGETS =====

  Future<List<SharedBudget>> getBudgets({
    String? groupId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _isCacheValid(_lastBudgetUpdate) &&
        _cachedBudgets != null) {
      final all = _cachedBudgets!;
      if (groupId == null) return all;
      return all.where((b) => b.groupId == groupId).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_budgetsKey);
    final budgets = raw == null
        ? <SharedBudget>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => SharedBudget.fromJson(e as Map<String, dynamic>))
            .toList();
    _cachedBudgets = budgets;
    _lastBudgetUpdate = DateTime.now();
    if (groupId == null) return budgets;
    return budgets.where((b) => b.groupId == groupId).toList();
  }

  Future<SharedBudget> addBudget({
    required String groupId,
    required String name,
    String category = 'Genel',
    required double totalAmount,
    SharedBudgetPeriod period = SharedBudgetPeriod.monthly,
    required DateTime startDate,
    required List<SharedBudgetAllocation> allocations,
    String? colorHex,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Bütçe adı boş olamaz');
    }
    if (totalAmount <= 0) {
      throw ArgumentError('Tutar sıfırdan büyük olmalı');
    }
    final group = await getGroupById(groupId);
    if (group == null) {
      throw ArgumentError('Grup bulunamadı');
    }
    final now = DateTime.now();
    final budget = SharedBudget(
      id: _uuid.v4(),
      groupId: groupId,
      name: name.trim(),
      category: category,
      totalAmount: totalAmount,
      period: period,
      startDate: startDate,
      allocations: allocations,
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );
    final all = await getBudgets();
    all.add(budget);
    await _saveBudgets(all);
    return budget;
  }

  Future<SharedBudget> updateBudget(SharedBudget budget) async {
    final all = await getBudgets();
    final idx = all.indexWhere((b) => b.id == budget.id);
    if (idx == -1) {
      throw ArgumentError('Bütçe bulunamadı');
    }
    final updated = budget.copyWith(updatedAt: DateTime.now());
    all[idx] = updated;
    await _saveBudgets(all);
    return updated;
  }

  Future<void> deleteBudget(String id) async {
    final all = await getBudgets();
    all.removeWhere((b) => b.id == id);
    await _saveBudgets(all);
  }

  // ===== DEBTS =====

  Future<List<MemberDebt>> getMemberDebts({
    String? groupId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _isCacheValid(_lastDebtUpdate) &&
        _cachedDebts != null) {
      final all = _cachedDebts!;
      if (groupId == null) return all;
      return all.where((d) => d.groupId == groupId).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_debtsKey);
    final debts = raw == null
        ? <MemberDebt>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => MemberDebt.fromJson(e as Map<String, dynamic>))
            .toList();
    _cachedDebts = debts;
    _lastDebtUpdate = DateTime.now();
    if (groupId == null) return debts;
    return debts.where((d) => d.groupId == groupId).toList();
  }

  Future<List<MemberDebt>> getDebtsForMember(String memberId) async {
    final all = await getMemberDebts();
    return all
        .where((d) => d.fromMemberId == memberId || d.toMemberId == memberId)
        .toList();
  }

  Future<MemberDebt> addMemberDebt({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required String description,
    String? relatedExpenseId,
    required DateTime date,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Tutar sıfırdan büyük olmalı');
    }
    final now = DateTime.now();
    final debt = MemberDebt(
      id: _uuid.v4(),
      groupId: groupId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: amount,
      description: description.trim(),
      relatedExpenseId: relatedExpenseId,
      date: date,
      note: note?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    final error = debt.validate();
    if (error != null) {
      throw ArgumentError(error);
    }
    final all = await getMemberDebts();
    all.add(debt);
    await _saveDebts(all);
    return debt;
  }

  Future<MemberDebt> settleMemberDebt(String id) async {
    final all = await getMemberDebts();
    final idx = all.indexWhere((d) => d.id == id);
    if (idx == -1) {
      throw ArgumentError('Borç bulunamadı');
    }
    final updated = all[idx].copyWith(
      status: MemberDebtStatus.settled,
      settledAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    all[idx] = updated;
    await _saveDebts(all);
    return updated;
  }

  Future<void> deleteMemberDebt(String id) async {
    final all = await getMemberDebts();
    all.removeWhere((d) => d.id == id);
    await _saveDebts(all);
  }

  // ===== BALANCES / SETTLEMENTS =====

  Future<List<BalanceEntry>> calculateBalances(String groupId) async {
    final group = await getGroupById(groupId);
    if (group == null) return [];

    final expenses = await getExpenses(groupId: groupId);
    final settledDebts = await getMemberDebts(groupId: groupId);
    final paidMap = <String, double>{};
    final shareMap = <String, double>{};

    for (final m in group.activeMembers) {
      paidMap[m.id] = 0;
      shareMap[m.id] = 0;
    }

    for (final expense in expenses) {
      if (expense.isSettled) continue;
      paidMap.update(
        expense.paidByMemberId,
        (v) => v + expense.totalAmount,
        ifAbsent: () => expense.totalAmount,
      );
      for (final share in expense.shares) {
        shareMap.update(
          share.memberId,
          (v) => v + share.amount,
          ifAbsent: () => share.amount,
        );
      }
    }

    return group.activeMembers.map((m) {
      final paid = paidMap[m.id] ?? 0;
      final share = shareMap[m.id] ?? 0;
      return BalanceEntry(
        memberId: m.id,
        memberName: m.name,
        paid: paid,
        share: share,
        net: paid - share,
      );
    }).toList()
      ..sort((a, b) => b.net.compareTo(a.net))
      ..addAll(const <BalanceEntry>[])
      ..removeWhere(
        (e) => settledDebts
            .where((d) => d.status == MemberDebtStatus.settled)
            .any((d) => false),
      );
  }

  Future<List<MemberSettlement>> getOptimalSettlements(
    String groupId,
  ) async {
    final balances = await calculateBalances(groupId);
    final positives = <BalanceEntry>[];
    final negatives = <BalanceEntry>[];
    for (final b in balances) {
      if (b.net > 0.01) {
        positives.add(b);
      } else if (b.net < -0.01) {
        negatives.add(b);
      }
    }

    final settlements = <MemberSettlement>[];
    var i = 0;
    var j = 0;
    final pos = List<BalanceEntry>.from(positives);
    final neg = List<BalanceEntry>.from(negatives);

    while (i < pos.length && j < neg.length) {
      final pay = pos[i].net;
      final owe = -neg[j].net;
      final amount = pay < owe ? pay : owe;
      if (amount > 0.01) {
        settlements.add(
          MemberSettlement(
            fromMemberId: neg[j].memberId,
            toMemberId: pos[i].memberId,
            amount: amount,
          ),
        );
      }
      pos[i] = pos[i].copyWithCustomNet(pos[i].net - amount);
      neg[j] = neg[j].copyWithCustomNet(neg[j].net + amount);
      if (pos[i].net.abs() < 0.01) i++;
      if (neg[j].net.abs() < 0.01) j++;
    }
    return settlements;
  }

  // ===== PERSISTENCE =====

  Future<void> _saveGroups(List<FamilyGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(groups.map((g) => g.toJson()).toList());
    await prefs.setString(_groupsKey, raw);
    _cachedGroups = groups;
    _lastGroupUpdate = DateTime.now();
  }

  Future<void> _saveExpenses(List<SharedExpense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_expensesKey, raw);
    _cachedExpenses = expenses;
    _lastExpenseUpdate = DateTime.now();
  }

  Future<void> _saveBudgets(List<SharedBudget> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(budgets.map((b) => b.toJson()).toList());
    await prefs.setString(_budgetsKey, raw);
    _cachedBudgets = budgets;
    _lastBudgetUpdate = DateTime.now();
  }

  Future<void> _saveDebts(List<MemberDebt> debts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(debts.map((d) => d.toJson()).toList());
    await prefs.setString(_debtsKey, raw);
    _cachedDebts = debts;
    _lastDebtUpdate = DateTime.now();
  }
}

extension on BalanceEntry {
  BalanceEntry copyWithCustomNet(double net) {
    return BalanceEntry(
      memberId: memberId,
      memberName: memberName,
      paid: paid,
      share: share,
      net: net,
    );
  }
}
