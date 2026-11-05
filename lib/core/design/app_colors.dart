import 'package:flutter/material.dart';

/// Central color token definitions for the Parion design system.
/// Use these tokens instead of hardcoded hex values throughout the app.
class AppColors {
  AppColors._();

  // Light theme tokens
  static const Color primary = Color(0xFF2C6BED);
  static const Color primaryVariant = Color(0xFF1A56D6);
  static const Color secondary = Color(0xFFFFD60A);
  static const Color background = Color(0xFFF8F7F3);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color priceBarAccent = Color(0xFFC9A227);
  static const Color goldAccent = Color(0xFFD4A017);
  static const Color goldAccentSoft = Color(0xFFFFF1C9);
  static const Color currencyAccent = Color(0xFF0EA5E9);
  static const Color currencyAccentSoft = Color(0xFFE0F2FE);
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
  static const Color goldAccentDark = Color(0xFFFFC857);
  static const Color currencyAccentDark = Color(0xFF38BDF8);

  // Reusable Premium Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2C6BED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient primaryDarkGradient = LinearGradient(
    colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient incomeGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGlassGradientLight = LinearGradient(
    colors: [Color(0x1F2C6BED), Color(0x0A6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGlassGradientDark = LinearGradient(
    colors: [Color(0x24FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

