import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/utils/date_range_validator.dart';
import '../../screens/statistics_screen.dart';

/// Modern, evrensel zaman filtresi ve ay seçici çubuğu.
///
/// Günlük, Haftalık, Aylık, Yıllık ve Özel seçeneklerini sunar.
/// Aylık modda hızlı ay değiştirme (< Kasım 2026 >) ve görsel ay seçici sunar.
class TimeFilterBar extends StatelessWidget {
  final TimeFilter selectedFilter;
  final ValueChanged<TimeFilter> onFilterChanged;
  final DateTime? referenceDate;
  final ValueChanged<DateTime>? onDateChanged;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final ValueChanged<DateTime>? onStartDateChanged;
  final ValueChanged<DateTime>? onEndDateChanged;

  const TimeFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.referenceDate,
    this.onDateChanged,
    this.customStartDate,
    this.customEndDate,
    this.onStartDateChanged,
    this.onEndDateChanged,
  });

  static const List<String> _turkishMonths = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static const Map<TimeFilter, String> _labels = {
    TimeFilter.daily: 'Günlük',
    TimeFilter.weekly: 'Haftalık',
    TimeFilter.monthly: 'Aylık',
    TimeFilter.yearly: 'Yıllık',
    TimeFilter.custom: 'Özel',
  };

  static const Map<TimeFilter, IconData> _icons = {
    TimeFilter.daily: Icons.today_rounded,
    TimeFilter.weekly: Icons.date_range_rounded,
    TimeFilter.monthly: Icons.calendar_month_rounded,
    TimeFilter.yearly: Icons.insert_chart_outlined_rounded,
    TimeFilter.custom: Icons.tune_rounded,
  };

  DateTime get _activeRef => referenceDate ?? DateTime.now();

  bool get _isCurrentPeriod {
    final now = DateTime.now();
    final ref = _activeRef;
    switch (selectedFilter) {
      case TimeFilter.daily:
        return now.year == ref.year &&
            now.month == ref.month &&
            now.day == ref.day;
      case TimeFilter.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final refStart = ref.subtract(Duration(days: ref.weekday - 1));
        return start.year == refStart.year &&
            start.month == refStart.month &&
            start.day == refStart.day;
      case TimeFilter.monthly:
        return now.year == ref.year && now.month == ref.month;
      case TimeFilter.yearly:
        return now.year == ref.year;
      case TimeFilter.custom:
        return false;
    }
  }

  void _stepPeriod(int step) {
    final ref = _activeRef;
    DateTime next;
    switch (selectedFilter) {
      case TimeFilter.daily:
        next = ref.add(Duration(days: step));
        break;
      case TimeFilter.weekly:
        next = ref.add(Duration(days: step * 7));
        break;
      case TimeFilter.monthly:
        next = DateTime(ref.year, ref.month + step, 1);
        break;
      case TimeFilter.yearly:
        next = DateTime(ref.year + step, 1, 1);
        break;
      case TimeFilter.custom:
        return;
    }
    onDateChanged?.call(next);
  }

  String _formatPeriodLabel() {
    final ref = _activeRef;
    switch (selectedFilter) {
      case TimeFilter.daily:
        return '${ref.day} ${_turkishMonths[ref.month - 1]} ${ref.year}';
      case TimeFilter.weekly:
        final start = ref.subtract(Duration(days: ref.weekday - 1));
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${start.day}-${end.day} ${_turkishMonths[start.month - 1]}';
        }
        return '${start.day} ${_turkishMonths[start.month - 1]} - ${end.day} ${_turkishMonths[end.month - 1]}';
      case TimeFilter.monthly:
        return '${_turkishMonths[ref.month - 1]} ${ref.year}';
      case TimeFilter.yearly:
        return '${ref.year}';
      case TimeFilter.custom:
        if (customStartDate != null && customEndDate != null) {
          return '${_formatDate(customStartDate!)} – ${_formatDate(customEndDate!)}';
        }
        return 'Tarih Seçin';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

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

  void _showFilterSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2230) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_view_day_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Zaman Filtresi',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...TimeFilter.values.map((filter) {
                  final isSelected = selectedFilter == filter;
                  final descriptions = {
                    TimeFilter.daily: 'Günün verilerini görüntüle',
                    TimeFilter.weekly: 'Haftalık toplam ve değişimler',
                    TimeFilter.monthly: 'Ay bazlı detaylı harcama ve gelirler',
                    TimeFilter.yearly: 'Yıllık genel finansal performans',
                    TimeFilter.custom: 'İstediğiniz iki tarih arası özel aralık',
                  };

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (filter == TimeFilter.custom) {
                          _pickCustomRange(context);
                        } else {
                          onFilterChanged(filter);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.02)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _icons[filter],
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? Colors.white70 : Colors.black54),
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _labels[filter]!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    descriptions[filter]!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthPickerSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int viewingYear = _activeRef.year;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final now = DateTime.now();

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2230) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Yıl Başlığı & Değiştirme
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setSheetState(() => viewingYear--);
                          },
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                            size: 26,
                          ),
                        ),
                        Text(
                          '$viewingYear',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setSheetState(() => viewingYear++);
                          },
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 12 Ay Grid Seçici
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected = _activeRef.year == viewingYear &&
                            _activeRef.month == monthNum;
                        final isCurrent =
                            now.year == viewingYear && now.month == monthNum;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            onDateChanged?.call(
                              DateTime(viewingYear, monthNum, 1),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF1F5F9))),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isCurrent
                                        ? AppColors.primary.withValues(alpha: 0.5)
                                        : Colors.transparent),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _turkishMonths[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected || isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                                if (isCurrent && !isSelected) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // "Bu Ay" Hızlı Butonu
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDateChanged?.call(
                            DateTime(now.year, now.month, 1),
                          );
                        },
                        icon: const Icon(
                          Icons.restart_alt_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Bu Aya Dön',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol: Zaman Filtresi Seçim Butonu
          InkWell(
            onTap: () => _showFilterSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icons[selectedFilter],
                    size: 16,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _labels[selectedFilter]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Sağ: Dönem / Ay Gezgini (< Kasım 2026 >)
          if (selectedFilter == TimeFilter.custom)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => _pickCustomRange(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _formatPeriodLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.edit_calendar_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Önceki Butonu
                  _buildNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _stepPeriod(-1),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 2),

                  // Dönem / Ay Etiketi Butonu
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        if (selectedFilter == TimeFilter.monthly) {
                          _showMonthPickerSheet(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isCurrentPeriod) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                _formatPeriodLabel(),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selectedFilter == TimeFilter.monthly) ...[
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 16,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 2),
                  // Sonraki Butonu
                  _buildNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _stepPeriod(1),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
