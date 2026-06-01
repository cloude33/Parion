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

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final FamilyService _familyService = FamilyService();

  FamilyGroup? _group;
  bool _isLoading = true;

  static const _palette = [
    0xFF2C6BED,
    0xFFFF6B6B,
    0xFF34C759,
    0xFFFF9500,
    0xFFAF52DE,
    0xFF5856D6,
    0xFFFF2D55,
    0xFF00BFA5,
    0xFFFFC107,
    0xFF8D6E63,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final group = await _familyService.getGroupById(widget.groupId);
    if (!mounted) return;
    setState(() {
      _group = group;
      _isLoading = false;
    });
  }

  Future<void> _addMember() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberFormSheet(
        group: _group!,
        palette: _palette,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _editMember(FamilyMember member) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberFormSheet(
        group: _group!,
        existing: member,
        palette: _palette,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _removeMember(FamilyMember member) async {
    if (member.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grup sahibi silinemez'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${member.name} üyeyi sil'),
        content: const Text(
            'Bu üye gruptan çıkarılacak. Paylaşımlı harcamalardaki payı kalacak.'),
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
      try {
        await _familyService.removeMember(
          groupId: widget.groupId,
          memberId: member.id,
        );
        _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppPageScaffold(
      title: 'Üyeler',
      body: _group!.members.isEmpty
          ? const AppEmptyState(
              icon: Icons.people_outline,
              title: 'Üye yok',
              description: 'Gruba ilk üyeyi ekleyin.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemBuilder: (context, index) {
                final m = _group!.members[index];
                return Card(
                  child: ListTile(
                    leading: MemberAvatar(member: m, size: 48),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.name,
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        _buildRoleBadge(m),
                      ],
                    ),
                    subtitle: m.email != null && m.email!.isNotEmpty
                        ? Text(m.email!)
                        : m.monthlyBudget > 0
                            ? Text(
                                'Aylık bütçe: ${NumberFormat('#,##0.00', 'tr_TR').format(m.monthlyBudget)} ${_group!.currencySymbol}',
                              )
                            : null,
                    trailing: m.isOwner
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _editMember(m);
                              if (v == 'remove') _removeMember(m);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Düzenle'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('Sil',
                                        style:
                                            TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemCount: _group!.members.length,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        icon: const Icon(Icons.person_add),
        label: const Text('Üye Ekle'),
      ),
    );
  }

  Widget _buildRoleBadge(FamilyMember m) {
    if (m.isOwner) {
      return _badge('Sahip', AppColors.primary);
    }
    if (m.role == FamilyGroupRole.admin) {
      return _badge('Yönetici', AppColors.warning);
    }
    return const SizedBox.shrink();
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MemberFormSheet extends StatefulWidget {
  const _MemberFormSheet({
    required this.group,
    this.existing,
    required this.palette,
  });

  final FamilyGroup group;
  final FamilyMember? existing;
  final List<int> palette;

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _budgetController;
  late int _color;
  late FamilyGroupRole _role;
  final _familyService = FamilyService();

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _nameController = TextEditingController(text: m?.name ?? '');
    _emailController = TextEditingController(text: m?.email ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _budgetController = TextEditingController(
      text: m?.monthlyBudget != null && m!.monthlyBudget > 0
          ? m.monthlyBudget.toStringAsFixed(2)
          : '',
    );
    _color = m?.colorValue ?? widget.palette.first;
    _role = m?.role ?? FamilyGroupRole.member;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final budget = double.tryParse(
          _budgetController.text.replaceAll(',', '.'),
        ) ??
        0.0;

    try {
      if (widget.existing == null) {
        await _familyService.addMember(
          groupId: widget.group.id,
          name: _nameController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          colorValue: _color,
          monthlyBudget: budget,
          role: _role,
        );
      } else {
        await _familyService.updateMember(
          groupId: widget.group.id,
          member: widget.existing!.copyWith(
            name: _nameController.text,
            email:
                _emailController.text.isEmpty ? null : _emailController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
            colorValue: _color,
            monthlyBudget: budget,
            role: _role,
          ),
        );
      }
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
              Text(
                widget.existing == null ? 'Yeni Üye' : 'Üyeyi Düzenle',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Ad Soyad',
                controller: _nameController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ad gerekli' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'E-posta (isteğe bağlı)',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Telefon (isteğe bağlı)',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Aylık Bütçe (${widget.group.currencySymbol})',
                hint: '0.00',
                controller: _budgetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.existing != null && !widget.existing!.isOwner) ...[
                Text('Rol', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                SegmentedButton<FamilyGroupRole>(
                  segments: const [
                    ButtonSegment(
                      value: FamilyGroupRole.member,
                      label: Text('Üye'),
                    ),
                    ButtonSegment(
                      value: FamilyGroupRole.admin,
                      label: Text('Yönetici'),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) =>
                      setState(() => _role = s.first),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                'Avatar rengi',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: widget.palette.map((c) {
                  final isSelected = c == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
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
