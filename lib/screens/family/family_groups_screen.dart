import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import '../../models/family/family_export.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';
import '../../services/family_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/family/family_group_card.dart';
import 'family_group_detail_screen.dart';

class FamilyGroupsScreen extends StatefulWidget {
  const FamilyGroupsScreen({super.key});

  @override
  State<FamilyGroupsScreen> createState() => _FamilyGroupsScreenState();
}

class _FamilyGroupsScreenState extends State<FamilyGroupsScreen> {
  final FamilyService _familyService = FamilyService();
  final DataService _dataService = DataService();
  final Uuid _uuid = const Uuid();

  List<FamilyGroup> _groups = [];
  Map<String, double> _groupTotals = {};
  Map<String, int> _groupPendingDebts = {};
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = await _dataService.getCurrentUser();
      final groups = await _familyService.getActiveGroups();
      final totals = <String, double>{};
      final pending = <String, int>{};
      for (final g in groups) {
        final expenses = await _familyService.getExpenses(groupId: g.id);
        final now = DateTime.now();
        totals[g.id] = expenses
            .where((e) =>
                e.date.year == now.year && e.date.month == now.month)
            .fold<double>(0, (s, e) => s + e.totalAmount);
        final debts = await _familyService.getMemberDebts(groupId: g.id);
        pending[g.id] = debts.where((d) => d.isPending).length;
      }
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _groupTotals = totals;
        _groupPendingDebts = pending;
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _openCreateGroup() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devam etmek için lütfen giriş yapın'),
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateGroupSheet(currentUser: _currentUser!),
    );
    if (result == true) _load();
  }

  Future<void> _openGroup(FamilyGroup group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyGroupDetailScreen(groupId: group.id),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Aile Paketi',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Yeni Grup',
          onPressed: _openCreateGroup,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _groups.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemBuilder: (context, index) {
                        final g = _groups[index];
                        return FamilyGroupCard(
                          group: g,
                          totalExpenses: _groupTotals[g.id] ?? 0,
                          pendingDebts: _groupPendingDebts[g.id] ?? 0,
                          onTap: () => _openGroup(g),
                        );
                      },
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemCount: _groups.length,
                    ),
            ),
      floatingActionButton: _groups.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateGroup,
              icon: const Icon(Icons.group_add),
              label: const Text('Yeni Grup'),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.groups_2_outlined,
          size: 80,
          color: AppColors.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Henüz bir aile/grup yok',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Aile üyeleri veya arkadaşlarınızla ortak bütçe, paylaşımlı harcamalar ve borç takibi için yeni bir grup oluşturun.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: 'İlk Grubunu Oluştur',
          icon: Icons.group_add,
          onPressed: _openCreateGroup,
        ),
      ],
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet({required this.currentUser});
  final User currentUser;

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _familyService = FamilyService();

  static const _palette = [
    '2C6BED',
    'FF6B6B',
    '34C759',
    'FF9500',
    'AF52DE',
    '5856D6',
    'FF2D55',
    '00BFA5',
  ];
  String _selectedColor = _palette.first;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _familyService.createGroup(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        ownerId: widget.currentUser.id,
        currencyCode: widget.currentUser.currencyCode,
        currencySymbol: widget.currentUser.currencySymbol,
        ownerName: widget.currentUser.name,
        ownerEmail: widget.currentUser.email,
        ownerColor: _colorFromHex(_selectedColor).toARGB32(),
        colorHex: _selectedColor,
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

  Color _colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
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
              Text(
                'Yeni Aile/Grup',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Grup adı',
                hint: 'Örn: Aile, Ev Arkadaşları, Tatil 2026',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Grup adı gerekli';
                  }
                  if (v.trim().length < 2) {
                    return 'En az 2 karakter girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Açıklama (isteğe bağlı)',
                hint: 'Bu grup ne için?',
                controller: _descriptionController,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Grup rengi',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: _palette.map((hex) {
                  final isSelected = hex == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _colorFromHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Oluştur',
                icon: Icons.check,
                onPressed: _create,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'İptal',
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
