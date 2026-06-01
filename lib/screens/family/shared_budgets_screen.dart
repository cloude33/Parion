import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import '../../models/family/family_export.dart';
import '../../services/family_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/family/member_avatar.dart';

class SharedBudgetsScreen extends StatefulWidget {
  const SharedBudgetsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<SharedBudgetsScreen> createState() => _SharedBudgetsScreenState();
}

class _SharedBudgetsScreenState extends State<SharedBudgetsScreen> {
  final FamilyService _familyService = FamilyService();

  FamilyGroup? _group;
  List<SharedBudget> _budgets = [];
  Map<String, double> _spentForBudget = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final group = await _familyService.getGroupById(widget.groupId);
    final budgets = await _familyService.getBudgets(groupId: widget.groupId);
    final expenses = await _familyService.getExpenses(groupId: widget.groupId);

    final spent = <String, double>{};
    for (final b in budgets) {
      final monthStart = DateTime(b.startDate.year, b.startDate.month, 1);
      final monthEnd =
          DateTime(b.startDate.year, b.startDate.month + 1, 0, 23, 59, 59);
      double total = 0;
      for (final e in expenses) {
        if (e.category == b.category &&
            !e.date.isBefore(monthStart) &&
            !e.date.isAfter(monthEnd)) {
          total += e.totalAmount;
        }
      }
      spent[b.id] = total;
    }

    if (!mounted) return;
    setState(() {
      _group = group;
      _budgets = budgets;
      _spentForBudget = spent;
      _isLoading = false;
    });
  }

  Future<void> _addBudget() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BudgetFormSheet(group: _group!),
    );
    if (result == true) _load();
  }

  Future<void> _deleteBudget(SharedBudget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bütçeyi Sil'),
        content: Text('"${budget.name}" bütçesi silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _familyService.deleteBudget(budget.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalBudget =
        _budgets.fold<double>(0, (s, b) => s + b.totalAmount);
    final totalSpent = _spentForBudget.values.fold<double>(0, (s, v) => s + v);
    final totalRemaining = totalBudget - totalSpent;
    final usage =
        totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

    return AppPageScaffold(
      title: 'Ortak Bütçeler',
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        'Toplam Bütçe',
                        '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalBudget)}',
                      ),
                    ),
                    Expanded(
                      child: _stat(
                        'Harcanan',
                        '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalSpent)}',
                      ),
                    ),
                    Expanded(
                      child: _stat(
                        totalRemaining >= 0 ? 'Kalan' : 'Aşım',
                        '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalRemaining.abs())}',
                        color: totalRemaining >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (usage / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        AppColors.onSurface.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usage > 100 ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '%${usage.toStringAsFixed(1)} kullanıldı',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _budgets.isEmpty
                ? AppEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Henüz bütçe yok',
                    description: 'Grup için ortak bir bütçe oluşturun.',
                    actionLabel: 'Bütçe Oluştur',
                    onAction: _addBudget,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final b = _budgets[index];
                      final spent = _spentForBudget[b.id] ?? 0;
                      final pct = b.totalAmount > 0
                          ? (spent / b.totalAmount) * 100
                          : 0;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(b.name,
                                            style: AppTextStyles.titleMedium),
                                        Text(
                                          '${b.category} • ${_periodLabel(b.period)}',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: AppColors.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteBudget(b),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(spent)}',
                                    style: AppTextStyles.titleMedium
                                        .copyWith(
                                      color: pct > 100
                                          ? AppColors.error
                                          : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ' / ${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(b.totalAmount)}',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (pct / 100).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: AppColors.onSurface
                                      .withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    pct > 100
                                        ? AppColors.error
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (b.allocations.isNotEmpty) ...[
                                Text(
                                  'Üye Katkıları',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: 4,
                                  children: b.allocations.map((a) {
                                    final m = _group!.getMember(a.memberId);
                                    if (m == null) return const SizedBox();
                                    return Chip(
                                      avatar: MemberAvatar(
                                        member: m,
                                        size: 20,
                                      ),
                                      label: Text(
                                        '${m.name}: ${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(a.amount)}',
                                        style:
                                            AppTextStyles.bodySmall,
                                      ),
                                      visualDensity:
                                          VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemCount: _budgets.length,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBudget,
        icon: const Icon(Icons.add),
        label: const Text('Bütçe'),
      ),
    );
  }

  String _periodLabel(SharedBudgetPeriod p) {
    switch (p) {
      case SharedBudgetPeriod.weekly:
        return 'Haftalık';
      case SharedBudgetPeriod.monthly:
        return 'Aylık';
      case SharedBudgetPeriod.yearly:
        return 'Yıllık';
    }
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: color ?? AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({required this.group});
  final FamilyGroup group;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _familyService = FamilyService();

  String _category = 'Genel';
  SharedBudgetPeriod _period = SharedBudgetPeriod.monthly;
  final DateTime _startDate = DateTime.now();
  final Map<String, double> _allocations = {};

  static const _categories = [
    'Genel',
    'Yiyecek',
    'Faturalar',
    'Ulaşım',
    'Eğlence',
    'Sağlık',
    'Eğitim',
    'Alışveriş',
    'Kira',
  ];

  @override
  void initState() {
    super.initState();
    for (final m in widget.group.activeMembers) {
      _allocations[m.id] = 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final total = double.tryParse(
          _amountController.text.replaceAll(',', '.'),
        ) ??
        0.0;
    if (total <= 0) return;

    final allocations = _allocations.entries
        .map((e) => SharedBudgetAllocation(
              memberId: e.key,
              amount: e.value,
            ))
        .toList();

    try {
      await _familyService.addBudget(
        groupId: widget.group.id,
        name: _nameController.text,
        category: _category,
        totalAmount: total,
        period: _period,
        startDate: _startDate,
        allocations: allocations,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _distributeEqual() {
    final total =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (total <= 0) return;
    final each = total / _allocations.length;
    setState(() {
      for (final k in _allocations.keys.toList()) {
        _allocations[k] = each;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Yeni Ortak Bütçe', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Bütçe adı',
                hint: 'Örn: Market bütçesi, Faturalar',
                controller: _nameController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Toplam tutar (${widget.group.currencySymbol})',
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  if (_allocations.values.every((v) => v == 0)) {
                    _distributeEqual();
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Tutar gerekli';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Geçerli tutar girin';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'Genel'),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<SharedBudgetPeriod>(
                segments: const [
                  ButtonSegment(
                    value: SharedBudgetPeriod.weekly,
                    label: Text('Haftalık'),
                  ),
                  ButtonSegment(
                    value: SharedBudgetPeriod.monthly,
                    label: Text('Aylık'),
                  ),
                  ButtonSegment(
                    value: SharedBudgetPeriod.yearly,
                    label: Text('Yıllık'),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (s) =>
                    setState(() => _period = s.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text('Üye Katkıları', style: AppTextStyles.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _distributeEqual,
                    icon: const Icon(Icons.balance, size: 16),
                    label: const Text('Eşit Böl'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...widget.group.activeMembers.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      MemberAvatar(member: m, size: 32),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.name)),
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          initialValue: '0.00',
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (v) {
                            final n = double.tryParse(
                                  v.replaceAll(',', '.'),
                                ) ??
                                0.0;
                            setState(() => _allocations[m.id] = n);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Bütçeyi Kaydet',
                icon: Icons.check,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
