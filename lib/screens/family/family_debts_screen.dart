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

class FamilyDebtsScreen extends StatefulWidget {
  const FamilyDebtsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<FamilyDebtsScreen> createState() => _FamilyDebtsScreenState();
}

class _FamilyDebtsScreenState extends State<FamilyDebtsScreen>
    with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();

  late TabController _tabController;
  FamilyGroup? _group;
  List<MemberDebt> _allDebts = [];
  List<MemberSettlement> _settlements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final debts = await _familyService.getMemberDebts(
        groupId: widget.groupId,
      );
      final settlements =
          await _familyService.getOptimalSettlements(widget.groupId);
      if (!mounted) return;
      setState(() {
        _group = group;
        _allDebts = debts;
        _settlements = settlements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDebt() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DebtFormSheet(group: _group!),
    );
    if (result == true) _load();
  }

  Future<void> _settleDebt(MemberDebt debt) async {
    try {
      await _familyService.settleMemberDebt(debt.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _createSettlementRecord(MemberSettlement s) async {
    final from = _group!.getMember(s.fromMemberId);
    final to = _group!.getMember(s.toMemberId);
    if (from == null || to == null) return;
    try {
      await _familyService.addMemberDebt(
        groupId: widget.groupId,
        fromMemberId: from.id,
        toMemberId: to.id,
        amount: s.amount,
        description:
            'Ödeme: ${from.name} → ${to.name}',
        date: DateTime.now(),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _deleteDebt(MemberDebt debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borç Kaydını Sil'),
        content: const Text('Bu borç kaydı kalıcı olarak silinecek.'),
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
      await _familyService.deleteMemberDebt(debt.id);
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

    final pendingDebts =
        _allDebts.where((d) => d.isPending).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final settledDebts = _allDebts.where((d) => d.isSettled).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalPending = pendingDebts.fold<double>(0, (s, d) => s + d.amount);

    return AppPageScaffold(
      title: 'Borç Takibi',
      bottomNavigationBar: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurface.withValues(alpha: 0.6),
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(text: 'Bekleyen (${pendingDebts.length})'),
          Tab(text: 'Ödenen (${settledDebts.length})'),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.warning.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toplam Bekleyen Borç',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalPending)}',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_settlements.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Önerilen ödemeler:',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  ..._settlements.take(3).map((s) {
                    final from = _group!.getMember(s.fromMemberId);
                    final to = _group!.getMember(s.toMemberId);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${from?.name ?? '?'} → ${to?.name ?? '?'}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Text(
                            '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(s.amount)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 18),
                            tooltip: 'Borç olarak kaydet',
                            onPressed: () => _createSettlementRecord(s),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDebtList(pendingDebts, true),
                _buildDebtList(settledDebts, false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDebt,
        icon: const Icon(Icons.add),
        label: const Text('Borç Ekle'),
      ),
    );
  }

  Widget _buildDebtList(List<MemberDebt> debts, bool isPending) {
    if (debts.isEmpty) {
      return AppEmptyState(
        icon: isPending ? Icons.handshake_outlined : Icons.task_alt,
        title: isPending ? 'Bekleyen borç yok' : 'Ödenen borç yok',
        description: isPending
            ? 'Üyeler arası yeni bir borç kaydı ekleyin.'
            : 'Henüz ödenmiş borç bulunmuyor.',
        actionLabel: isPending ? 'Borç Ekle' : null,
        onAction: isPending ? _addDebt : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemBuilder: (context, index) {
        final debt = debts[index];
        final from = _group!.getMember(debt.fromMemberId);
        final to = _group!.getMember(debt.toMemberId);
        return Card(
          child: ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                if (from != null)
                  MemberAvatar(member: from, size: 40)
                else
                  const CircleAvatar(child: Icon(Icons.person)),
                Positioned(
                  left: 28,
                  top: 0,
                  child: to != null
                      ? MemberAvatar(member: to, size: 28)
                      : const CircleAvatar(
                          radius: 14,
                          child: Icon(Icons.person, size: 14),
                        ),
                ),
              ],
            ),
            title: Text(
              '${from?.name ?? '?'} → ${to?.name ?? '?'}',
              style: AppTextStyles.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd.MM.yyyy', 'tr_TR').format(debt.date),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(debt.amount)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isPending ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPending)
                  TextButton(
                    onPressed: () => _settleDebt(debt),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Ödendi',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            onLongPress: () => _deleteDebt(debt),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemCount: debts.length,
    );
  }
}

class _DebtFormSheet extends StatefulWidget {
  const _DebtFormSheet({required this.group});
  final FamilyGroup group;

  @override
  State<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<_DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _familyService = FamilyService();

  String? _fromMemberId;
  String? _toMemberId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fromMemberId = widget.group.ownerId;
    if (widget.group.activeMembers.length > 1) {
      _toMemberId = widget.group.activeMembers
          .firstWhere(
            (m) => m.id != widget.group.ownerId,
            orElse: () => widget.group.activeMembers.first,
          )
          .id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromMemberId == null || _toMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borçlu ve alacaklı seçilmeli')),
      );
      return;
    }
    if (_fromMemberId == _toMemberId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Borçlu ve alacaklı aynı kişi olamaz'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final amount = double.tryParse(
          _amountController.text.replaceAll(',', '.'),
        ) ??
        0.0;

    try {
      await _familyService.addMemberDebt(
        groupId: widget.group.id,
        fromMemberId: _fromMemberId!,
        toMemberId: _toMemberId!,
        amount: amount,
        description: _descriptionController.text,
        date: _date,
        note: _noteController.text.isEmpty ? null : _noteController.text,
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

  @override
  Widget build(BuildContext context) {
    final members = widget.group.activeMembers;
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
              Text('Yeni Borç Kaydı', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _fromMemberId,
                decoration: const InputDecoration(
                  labelText: 'Borçlu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _fromMemberId = v),
                validator: (v) => v == null ? 'Borçlu seçin' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Icon(
                  Icons.arrow_downward,
                  color: AppColors.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _toMemberId,
                decoration: const InputDecoration(
                  labelText: 'Alacaklı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _toMemberId = v),
                validator: (v) => v == null ? 'Alacaklı seçin' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Tutar (${widget.group.currencySymbol})',
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Tutar gerekli';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Geçerli tutar girin';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Açıklama',
                hint: 'Örn: Akşam yemeği, Benzin',
                controller: _descriptionController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Açıklama gerekli' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Not (isteğe bağlı)',
                controller: _noteController,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tarih'),
                subtitle: Text(
                  DateFormat('dd.MM.yyyy', 'tr_TR').format(_date),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
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
