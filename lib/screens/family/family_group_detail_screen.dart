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
import 'add_shared_expense_screen.dart';
import 'family_debts_screen.dart';
import 'family_members_screen.dart';
import 'shared_budgets_screen.dart';

class FamilyGroupDetailScreen extends StatefulWidget {
  const FamilyGroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<FamilyGroupDetailScreen> createState() =>
      _FamilyGroupDetailScreenState();
}

class _FamilyGroupDetailScreenState extends State<FamilyGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();

  late TabController _tabController;
  FamilyGroup? _group;
  List<SharedExpense> _expenses = [];
  List<BalanceEntry> _balances = [];
  Map<String, double> _memberSpendings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final group = await _familyService.getGroupById(widget.groupId);
      final expenses = await _familyService.getExpenses(
        groupId: widget.groupId,
      );
      final balances = await _familyService.calculateBalances(
        widget.groupId,
      );
      final spendings = <String, double>{};
      if (group != null) {
        final now = DateTime.now();
        for (final m in group.activeMembers) {
          double sum = 0;
          for (final e in expenses) {
            if (e.paidByMemberId == m.id &&
                e.date.year == now.year &&
                e.date.month == now.month) {
              sum += e.totalAmount;
            }
          }
          spendings[m.id] = sum;
        }
      }
      if (!mounted) return;
      setState(() {
        _group = group;
        _expenses = expenses;
        _balances = balances;
        _memberSpendings = spendings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddSharedExpenseScreen(groupId: widget.groupId),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _openMembers() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyMembersScreen(groupId: widget.groupId),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _openDebts() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyDebtsScreen(groupId: widget.groupId),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _openBudgets() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedBudgetsScreen(groupId: widget.groupId),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _editGroup() async {
    if (_group == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditGroupSheet(group: _group!),
    );
    if (result == true) _load();
  }

  Future<void> _confirmDelete() async {
    if (_group == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Grubu Sil'),
        content: Text(
          '"${_group!.name}" grubu ve tüm paylaşımlı harcamalar, bütçeler ve borçlar silinecek. Devam etmek istiyor musunuz?',
        ),
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
    if (confirmed == true) {
      await _familyService.deleteGroup(_group!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final group = _group!;
    final totalSpent = _expenses.fold<double>(0, (s, e) => s + e.totalAmount);
    final totalDebts = _balances
        .where((b) => b.net.abs() > 0.01)
        .fold<double>(0, (s, b) => s + b.net.abs()) /
        2;

    return AppPageScaffold(
      title: group.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: _editGroup,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _confirmDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Grubu Sil',
                      style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          _buildHeader(group, totalSpent, totalDebts),
          _buildQuickActions(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                AppColors.onSurface.withValues(alpha: 0.6),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Harcamalar'),
              Tab(text: 'Bakiyeler'),
              Tab(text: 'Üyeler'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesTab(),
                _buildBalancesTab(),
                _buildMembersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Harcama'),
      ),
    );
  }

  Widget _buildHeader(
    FamilyGroup group,
    double totalSpent,
    double totalDebts,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          if (group.description != null && group.description!.isNotEmpty) ...[
            Text(
              group.description!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: _headerStat(
                  'Toplam Harcama',
                  '${group.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalSpent)}',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.onSurface.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _headerStat(
                  'Açık Bakiye',
                  '${group.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalDebts)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _quickAction(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Bütçeler',
              onTap: _openBudgets,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _quickAction(
              icon: Icons.handshake_outlined,
              label: 'Borçlar',
              onTap: _openDebts,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _quickAction(
              icon: Icons.people_outline,
              label: 'Üyeler',
              onTap: _openMembers,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: AppColors.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Henüz harcama yok',
        description: 'Paylaşımlı ilk harcamanızı eklemek için + butonunu kullanın.',
        actionLabel: 'Harcama Ekle',
        onAction: _openAddExpense,
      );
    }
    final sorted = List<SharedExpense>.from(_expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemBuilder: (context, index) {
        final e = sorted[index];
        final payer = _group!.getMember(e.paidByMemberId);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Color(payer?.colorValue ?? 0xFF2C6BED).withValues(alpha: 0.2),
              child: Icon(
                _iconForCategory(e.category),
                color: Color(payer?.colorValue ?? 0xFF2C6BED),
                size: 20,
              ),
            ),
            title: Text(e.title, style: AppTextStyles.titleMedium),
            subtitle: Text(
              '${payer?.name ?? '?'} ödedi • ${DateFormat('dd.MM.yyyy', 'tr_TR').format(e.date)}',
            ),
            trailing: Text(
              '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(e.totalAmount)}',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemCount: sorted.length,
    );
  }

  Widget _buildBalancesTab() {
    if (_balances.isEmpty) {
      return const AppEmptyState(
        icon: Icons.balance_outlined,
        title: 'Bakiye bilgisi yok',
        description: 'Henüz hesaplanacak harcama bulunmuyor.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ..._balances.map((b) {
          final member = _group!.getMember(b.memberId);
          final isPositive = b.net > 0.01;
          final isNegative = b.net < -0.01;
          final color = isPositive
              ? AppColors.success
              : isNegative
                  ? AppColors.error
                  : AppColors.onSurface.withValues(alpha: 0.6);
          return Card(
            child: ListTile(
              leading: member != null
                  ? MemberAvatar(member: member, size: 44)
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                member?.name ?? b.memberId,
                style: AppTextStyles.titleMedium,
              ),
              subtitle: Text(
                'Ödedi: ${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(b.paid)}\n'
                'Payı: ${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(b.share)}',
                style: AppTextStyles.bodySmall,
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isPositive
                        ? '+${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(b.net)}'
                        : '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(b.net)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isPositive
                        ? 'Alacaklı'
                        : isNegative
                            ? 'Borçlu'
                            : 'Eşit',
                    style: AppTextStyles.bodySmall.copyWith(color: color),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMembersTab() {
    final members = _group!.activeMembers;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemBuilder: (context, index) {
        final m = members[index];
        final spending = _memberSpendings[m.id] ?? 0;
        return Card(
          child: ListTile(
            leading: MemberAvatar(member: m, size: 44),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    m.name,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                if (m.isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sahip',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (m.role == FamilyGroupRole.admin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Yönetici',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              'Bu ay ${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(spending)} ödedi',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Üye yönet',
              onPressed: _openMembers,
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemCount: members.length,
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'yiyecek':
      case 'market':
        return Icons.shopping_basket_outlined;
      case 'faturalar':
        return Icons.receipt_long_outlined;
      case 'ulaşım':
        return Icons.directions_car_outlined;
      case 'eğlence':
        return Icons.movie_outlined;
      case 'sağlık':
        return Icons.local_hospital_outlined;
      case 'eğitim':
        return Icons.school_outlined;
      case 'alışveriş':
        return Icons.shopping_cart_outlined;
      case 'kira':
        return Icons.home_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}

class _EditGroupSheet extends StatefulWidget {
  const _EditGroupSheet({required this.group});
  final FamilyGroup group;

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _familyService = FamilyService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.group.name;
    _descriptionController.text = widget.group.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _familyService.updateGroup(widget.group.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
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
              Text('Grubu Düzenle', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Grup adı',
                controller: _nameController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Açıklama',
                controller: _descriptionController,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Kaydet',
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
