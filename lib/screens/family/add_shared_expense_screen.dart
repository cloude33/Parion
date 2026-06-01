import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import '../../models/family/family_export.dart';
import '../../services/family_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/family/member_avatar.dart';

class AddSharedExpenseScreen extends StatefulWidget {
  const AddSharedExpenseScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<AddSharedExpenseScreen> createState() =>
      _AddSharedExpenseScreenState();
}

class _AddSharedExpenseScreenState extends State<AddSharedExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _familyService = FamilyService();

  FamilyGroup? _group;
  String? _paidByMemberId;
  String _category = 'Genel';
  DateTime _date = DateTime.now();
  SplitType _splitType = SplitType.equal;
  final Map<String, double> _amounts = {};
  final Map<String, double> _percentages = {};
  final Map<String, double> _shares = {};
  bool _isLoading = true;
  bool _isSaving = false;

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
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final group = await _familyService.getGroupById(widget.groupId);
    if (group == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _paidByMemberId = group.ownerId;
    for (final m in group.activeMembers) {
      _amounts[m.id] = 0;
      _percentages[m.id] = 0;
      _shares[m.id] = 1;
    }
    if (!mounted) return;
    setState(() {
      _group = group;
      _isLoading = false;
    });
  }

  double get _totalAmount {
    return double.tryParse(
            _amountController.text.replaceAll(',', '.')) ??
        0.0;
  }

  double get _totalPercentage =>
      _percentages.values.fold<double>(0, (s, v) => s + v);

  double get _totalShares => _shares.values.fold<double>(0, (s, v) => s + v);

  double get _totalAmounts =>
      _amounts.values.fold<double>(0, (s, v) => s + v);

  void _onAmountChanged() {
    final total = _totalAmount;
    if (total <= 0 || _group == null) return;
    setState(() {
      if (_splitType == SplitType.equal) {
        // Otomatik eşit bölüş
        for (final m in _group!.activeMembers) {
          _amounts[m.id] = total / _group!.activeMembers.length;
        }
      } else if (_splitType == SplitType.percentage) {
        for (final entry in _percentages.entries) {
          _amounts[entry.key] = total * (entry.value / 100.0);
        }
      } else if (_splitType == SplitType.shares) {
        final sum = _totalShares;
        if (sum > 0) {
          for (final entry in _shares.entries) {
            _amounts[entry.key] = total * (entry.value / sum);
          }
        }
      }
    });
  }

  void _onSplitChanged(SplitType type) {
    setState(() {
      _splitType = type;
      if (type == SplitType.equal) {
        final total = _totalAmount;
        if (total > 0 && _group != null) {
          for (final m in _group!.activeMembers) {
            _amounts[m.id] = total / _group!.activeMembers.length;
          }
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  List<ExpenseShare> _buildShares() {
    if (_group == null) return [];
    switch (_splitType) {
      case SplitType.equal:
      case SplitType.exact:
        return _group!.activeMembers
            .map((m) => ExpenseShare(
                  memberId: m.id,
                  amount: _amounts[m.id] ?? 0,
                ))
            .toList();
      case SplitType.percentage:
        return _group!.activeMembers
            .map((m) => ExpenseShare(
                  memberId: m.id,
                  amount: _amounts[m.id] ?? 0,
                  percentage: _percentages[m.id] ?? 0,
                ))
            .toList();
      case SplitType.shares:
        return _group!.activeMembers
            .map((m) => ExpenseShare(
                  memberId: m.id,
                  amount: _amounts[m.id] ?? 0,
                  percentage: _totalShares > 0
                      ? ((_shares[m.id] ?? 0) / _totalShares) * 100.0
                      : 0,
                ))
            .toList();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_group == null || _paidByMemberId == null) return;

    if (_splitType == SplitType.exact &&
        (_totalAmounts - _totalAmount).abs() > 0.01) {
      _showError(
          'Payların toplamı (${_totalAmounts.toStringAsFixed(2)}) harcama tutarına (${_totalAmount.toStringAsFixed(2)}) eşit olmalı');
      return;
    }
    if (_splitType == SplitType.percentage &&
        (_totalPercentage - 100).abs() > 0.01) {
      _showError(
          'Yüzdelerin toplamı %100 olmalı (Şu an: ${_totalPercentage.toStringAsFixed(1)}%)');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _familyService.addExpense(
        groupId: widget.groupId,
        title: _titleController.text,
        description: _descriptionController.text,
        totalAmount: _totalAmount,
        paidByMemberId: _paidByMemberId!,
        category: _category,
        date: _date,
        splitType: _splitType,
        shares: _buildShares(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppPageScaffold(
      title: 'Paylaşımlı Harcama',
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: Text(
            _isSaving ? '...' : 'Kaydet',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              label: 'Başlık',
              hint: 'Örn: Market alışverişi',
              controller: _titleController,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Başlık gerekli' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Toplam Tutar',
              hint: '0.00',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+[.,]?\d{0,2}'),
                ),
              ],
              onChanged: (_) => _onAmountChanged(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Tutar gerekli';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Geçerli bir tutar girin';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Açıklama (isteğe bağlı)',
              controller: _descriptionController,
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tarih'),
              subtitle: Text(DateFormat('dd.MM.yyyy', 'tr_TR').format(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text('Kim ödedi?', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _group!.activeMembers.map((m) {
                final isSelected = _paidByMemberId == m.id;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MemberAvatar(member: m, size: 24),
                      const SizedBox(width: 6),
                      Text(m.name),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _paidByMemberId = m.id),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Bölüşme şekli', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<SplitType>(
              segments: const [
                ButtonSegment(
                  value: SplitType.equal,
                  label: Text('Eşit'),
                  icon: Icon(Icons.balance),
                ),
                ButtonSegment(
                  value: SplitType.exact,
                  label: Text('Tutar'),
                  icon: Icon(Icons.calculate_outlined),
                ),
                ButtonSegment(
                  value: SplitType.percentage,
                  label: Text('%'),
                  icon: Icon(Icons.percent),
                ),
                ButtonSegment(
                  value: SplitType.shares,
                  label: Text('Pay'),
                  icon: Icon(Icons.scatter_plot),
                ),
              ],
              selected: {_splitType},
              onSelectionChanged: (s) => _onSplitChanged(s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._buildSplitEditors(),
            const SizedBox(height: AppSpacing.xl),
            _buildSummary(),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Harcamayı Kaydet',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSplitEditors() {
    if (_group == null) return [];
    final total = _totalAmount;
    return _group!.activeMembers.map((m) {
      final amount = _amounts[m.id] ?? 0;
      return Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              MemberAvatar(member: m, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: AppTextStyles.titleMedium),
                    if (_splitType != SplitType.equal)
                      _buildFieldForSplitType(m, total),
                    if (_splitType == SplitType.equal)
                      Text(
                        '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(amount)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(amount)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFieldForSplitType(FamilyMember m, double total) {
    switch (_splitType) {
      case SplitType.exact:
        return TextFormField(
          initialValue: (_amounts[m.id] ?? 0).toStringAsFixed(2),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Tutar',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: (v) {
            final n = double.tryParse(v.replaceAll(',', '.')) ?? 0;
            setState(() => _amounts[m.id] = n);
          },
        );
      case SplitType.percentage:
        return TextFormField(
          initialValue: (_percentages[m.id] ?? 0).toStringAsFixed(1),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Yüzde (%)',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: (v) {
            final p = double.tryParse(v.replaceAll(',', '.')) ?? 0;
            setState(() {
              _percentages[m.id] = p;
              _amounts[m.id] = total * (p / 100.0);
            });
          },
        );
      case SplitType.shares:
        return TextFormField(
          initialValue: (_shares[m.id] ?? 0).toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Pay birimi',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: (v) {
            final s = double.tryParse(v) ?? 0;
            setState(() {
              _shares[m.id] = s;
              final sum = _totalShares;
              if (sum > 0) {
                _amounts[m.id] = total * (s / sum);
              }
            });
          },
        );
      case SplitType.equal:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSummary() {
    final total = _totalAmount;
    final valid = _splitType != SplitType.exact ||
        (_totalAmounts - total).abs() < 0.01;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: valid
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.error_outline,
            color: valid ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay toplamı: ${_group!.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(_totalAmounts)}',
                  style: AppTextStyles.bodyMedium,
                ),
                if (_splitType == SplitType.percentage)
                  Text(
                    'Yüzde toplamı: ${_totalPercentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodySmall,
                  ),
                if (_splitType == SplitType.shares)
                  Text(
                    'Pay toplamı: ${_totalShares.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
