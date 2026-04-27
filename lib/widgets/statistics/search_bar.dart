import 'package:flutter/material.dart';
import '../../utils/debounce_throttle.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_text_styles.dart';
import 'package:parion/core/design/app_spacing.dart';
class StatisticsSearchBar extends StatefulWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback? onClear;
  final String hintText;
  final int debounceMilliseconds;

  const StatisticsSearchBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onClear,
    this.hintText = 'İşlem veya kategori ara...',
    this.debounceMilliseconds = 300,
  });

  @override
  State<StatisticsSearchBar> createState() => _StatisticsSearchBarState();
}

class _StatisticsSearchBarState extends State<StatisticsSearchBar> {
  late TextEditingController _controller;
  late Debouncer _debouncer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _debouncer = Debouncer(
      delay: Duration(milliseconds: widget.debounceMilliseconds),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StatisticsSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _controller.text) {
      _controller.text = widget.searchQuery;
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _isSearching = true;
    });
    _debouncer.call(() {
      widget.onSearchChanged(value);
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    _debouncer.cancel();
    widget.onSearchChanged('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.5) : AppColors.onSurface.withValues(alpha: 0.4),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
            size: 22,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark ? AppColors.onSurfaceDark.withValues(alpha: 0.6) : AppColors.onSurface.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                      tooltip: 'Aramayı Temizle',
                    ),
                  ],
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}


