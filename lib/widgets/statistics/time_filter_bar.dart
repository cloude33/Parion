import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/utils/date_range_validator.dart';
import '../../screens/statistics_screen.dart';
import 'statistics_filter_chip.dart';

/// Evrensel zaman filtresi çubuğu.
///
/// Günlük, Haftalık, Aylık, Yıllık ve Özel seçeneklerini sunar.
/// Özel seçildiğinde tarih aralığı seçici gösterir.
/// Geçersiz aralıkta SnackBar ile hata mesajı gösterir.
class TimeFilterBar extends StatelessWidget {
  final TimeFilter selectedFilter;
  final ValueChanged<TimeFilter> onFilterChanged;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final ValueChanged<DateTime>? onStartDateChanged;
  final ValueChanged<DateTime>? onEndDateChanged;

  const TimeFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.customStartDate,
    this.customEndDate,
    this.onStartDateChanged,
    this.onEndDateChanged,
  });

  static const Map<TimeFilter, String> _labels = {
    TimeFilter.daily: 'Günlük',
    TimeFilter.weekly: 'Haftalık',
    TimeFilter.monthly: 'Aylık',
    TimeFilter.yearly: 'Yıllık',
    TimeFilter.custom: 'Özel',
  };

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = customStartDate ?? DateTime(now.year, now.month, 1);
    final initialEnd = customEndDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final validation = validateDateRange(picked.start, picked.end);
    if (!validation.isValid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validation.errorMessage ?? 'Geçersiz tarih aralığı',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    onStartDateChanged?.call(picked.start);
    onEndDateChanged?.call(picked.end);
    onFilterChanged(TimeFilter.custom);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              DropdownButtonHideUnderline(
                child: DropdownButton<TimeFilter>(
                  value: selectedFilter,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                  items: TimeFilter.values.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(_labels[filter]!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    if (val == TimeFilter.custom) {
                      _pickCustomRange(context);
                    } else {
                      onFilterChanged(val);
                    }
                  },
                ),
              ),
            ],
          ),
          if (selectedFilter == TimeFilter.custom &&
              customStartDate != null &&
              customEndDate != null)
            Text(
              '${_formatDate(customStartDate!)} – ${_formatDate(customEndDate!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
