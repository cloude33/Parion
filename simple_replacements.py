#!/usr/bin/env python3
"""
Simple script to show common TextStyle to AppTextStyles replacements.
"""

import os

# Common replacements
REPLACEMENTS = [
    # Pattern: (search_pattern, replacement, description)
    (
        "style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)",
        "style: AppTextStyles.titleMedium",
        "16px bold → titleMedium"
    ),
    (
        "style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)",
        "style: AppTextStyles.titleMedium",
        "16px w600 → titleMedium"
    ),
    (
        "style: TextStyle(fontSize: 16)",
        "style: AppTextStyles.bodyLarge",
        "16px normal → bodyLarge"
    ),
    (
        "style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)",
        "style: AppTextStyles.labelLarge",
        "14px bold → labelLarge"
    ),
    (
        "style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)",
        "style: AppTextStyles.labelLarge",
        "14px w600 → labelLarge"
    ),
    (
        "style: TextStyle(fontSize: 14)",
        "style: AppTextStyles.bodyMedium",
        "14px normal → bodyMedium"
    ),
    (
        "style: TextStyle(fontSize: 12)",
        "style: AppTextStyles.bodySmall",
        "12px normal → bodySmall"
    ),
    (
        "style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)",
        "style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)",
        "12px bold → bodySmall with bold"
    ),
    (
        "style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)",
        "style: AppTextStyles.labelSmall",
        "11px w500 → labelSmall"
    ),
    (
        "style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)",
        "style: AppTextStyles.titleLarge",
        "18px bold → titleLarge"
    ),
    (
        "style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)",
        "style: AppTextStyles.titleLarge",
        "18px w600 → titleLarge"
    ),
    (
        "style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)",
        "style: AppTextStyles.headlineMedium",
        "20px bold → headlineMedium"
    ),
    (
        "style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)",
        "style: AppTextStyles.headlineLarge",
        "24px bold → headlineLarge"
    ),
]

def main():
    print("Common TextStyle to AppTextStyles Replacements")
    print("=" * 80)
    print("\nBefore running replacements, ensure AppTextStyles is imported:")
    print("import '../../core/design/app_text_styles.dart';")
    print("\n" + "=" * 80)
    
    for i, (search, replace, desc) in enumerate(REPLACEMENTS, 1):
        print(f"\n{i}. {desc}")
        print(f"   Search:  {search}")
        print(f"   Replace: {replace}")
    
    print("\n" + "=" * 80)
    print("\nImportant Notes:")
    print("1. When TextStyle has additional properties (color, etc.), use .copyWith():")
    print("   style: TextStyle(fontSize: 14, color: Colors.red)")
    print("   → style: AppTextStyles.bodyMedium.copyWith(color: Colors.red)")
    print("\n2. For dynamic fontSize values, use .copyWith(fontSize: value):")
    print("   style: TextStyle(fontSize: fontSize)")
    print("   → style: AppTextStyles.bodyMedium.copyWith(fontSize: fontSize)")
    print("\n3. Check if file already imports AppTextStyles before adding import.")
    print("\n4. Run the other script (replace_text_styles.py) for detailed analysis.")

if __name__ == "__main__":
    main()