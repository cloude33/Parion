import 'package:flutter/material.dart';
import 'package:parion/core/design/app_colors.dart';
import 'package:parion/core/design/app_text_styles.dart';

/// Displays a monetary amount with income/expense color coding.
/// [isIncome] == true → [AppColors.incomeColor] (green)
/// [isIncome] == false → [AppColors.expenseColor] (red)
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amount,
    required this.isIncome,
    this.style,
    this.showSign = false,
  });

  final double amount;
  final bool isIncome;
  final TextStyle? style;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.incomeColor : AppColors.expenseColor;
    final effectiveStyle = (style ?? AppTextStyles.titleMedium).copyWith(
      color: color,
    );

    final String sign;
    if (showSign) {
      sign = isIncome ? '+' : '-';
    } else {
      sign = '';
    }

    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(2);

    return Text(
      '$sign$formatted',
      style: effectiveStyle,
    );
  }
}
