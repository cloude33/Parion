import 'package:flutter/material.dart';

/// Central color token definitions for the Parion design system.
/// Use these tokens instead of hardcoded hex values throughout the app.
class AppColors {
  AppColors._();

  // Light theme tokens
  static const Color primary = Color(0xFF2C6BED);
  static const Color primaryVariant = Color(0xFF1A56D6);
  static const Color secondary = Color(0xFFFFD60A);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF1C1C1E);
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color incomeColor = Color(0xFF34C759);
  static const Color expenseColor = Color(0xFFFF3B30);

  // Dark theme tokens
  static const Color primaryDark = Color(0xFF0A84FF);
  static const Color primaryVariantDark = Color(0xFF0066CC);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color onSurfaceDark = Colors.white;
  static const Color errorDark = Color(0xFFFF453A);
  static const Color successDark = Color(0xFF30D158);
  static const Color warningDark = Color(0xFFFF9F0A);
}
