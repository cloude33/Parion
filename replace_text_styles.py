#!/usr/bin/env python3
"""
Script to help automate replacement of inline TextStyle definitions with AppTextStyles tokens.
This script analyzes Dart files in the statistics widgets directory and suggests replacements.
"""

import os
import re
from pathlib import Path

# AppTextStyles mapping based on font size and weight
APP_TEXT_STYLES = {
    # (font_size, font_weight) -> AppTextStyles token
    (32, 'bold'): 'AppTextStyles.displayLarge',
    (28, 'bold'): 'AppTextStyles.displayMedium',
    (24, 'bold'): 'AppTextStyles.headlineLarge',
    (20, 'bold'): 'AppTextStyles.headlineMedium',
    (18, 'w600'): 'AppTextStyles.titleLarge',
    (18, 'bold'): 'AppTextStyles.titleLarge',  # bold is often w600 equivalent
    (16, 'w600'): 'AppTextStyles.titleMedium',
    (16, 'bold'): 'AppTextStyles.titleMedium',  # bold is often w600 equivalent
    (16, 'normal'): 'AppTextStyles.bodyLarge',
    (14, 'w600'): 'AppTextStyles.labelLarge',
    (14, 'bold'): 'AppTextStyles.labelLarge',  # bold is often w600 equivalent
    (14, 'normal'): 'AppTextStyles.bodyMedium',
    (12, 'normal'): 'AppTextStyles.bodySmall',
    (12, 'w600'): 'AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)',
    (12, 'bold'): 'AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)',
    (11, 'w500'): 'AppTextStyles.labelSmall',
    (11, 'normal'): 'AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.normal)',
    (10, 'normal'): 'AppTextStyles.labelSmall.copyWith(fontSize: 10)',
    (10, 'bold'): 'AppTextStyles.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold)',
}

def parse_text_style(text_style_str):
    """Parse a TextStyle constructor string to extract font size and weight."""
    # Extract fontSize
    font_size_match = re.search(r'fontSize:\s*(\d+)', text_style_str)
    font_size = int(font_size_match.group(1)) if font_size_match else None
    
    # Extract fontWeight
    font_weight_match = re.search(r'fontWeight:\s*FontWeight\.(\w+)', text_style_str)
    font_weight = font_weight_match.group(1).lower() if font_weight_match else 'normal'
    
    # Normalize fontWeight values
    if font_weight in ['w600', 'semibold']:
        font_weight = 'w600'
    elif font_weight in ['w500', 'medium']:
        font_weight = 'w500'
    elif font_weight in ['bold', 'w700', 'w800', 'w900']:
        font_weight = 'bold'
    else:
        font_weight = 'normal'
    
    return font_size, font_weight

def find_app_text_style(font_size, font_weight):
    """Find the appropriate AppTextStyles token for given font size and weight."""
    key = (font_size, font_weight)
    if key in APP_TEXT_STYLES:
        return APP_TEXT_STYLES[key]
    
    # Try to find closest match
    if font_size:
        # Try with different weights
        for weight in [font_weight, 'normal', 'bold', 'w600']:
            key = (font_size, weight)
            if key in APP_TEXT_STYLES:
                return APP_TEXT_STYLES[key]
    
    # Default fallback
    return f'AppTextStyles.bodyMedium.copyWith(fontSize: {font_size})' if font_size else 'AppTextStyles.bodyMedium'

def analyze_file(file_path):
    """Analyze a Dart file for inline TextStyle definitions."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to find TextStyle constructors
    # Matches: style: TextStyle(...)
    pattern = r'style:\s*(TextStyle\s*\([^)]+\))'
    matches = re.findall(pattern, content, re.DOTALL)
    
    if not matches:
        return []
    
    results = []
    for match in matches:
        # Clean up the match
        text_style_str = match.strip()
        
        # Parse the TextStyle
        font_size, font_weight = parse_text_style(text_style_str)
        
        # Find appropriate AppTextStyles token
        app_text_style = find_app_text_style(font_size, font_weight)
        
        results.append({
            'original': text_style_str,
            'font_size': font_size,
            'font_weight': font_weight,
            'replacement': app_text_style,
            'line': content.count('\n', 0, content.find(text_style_str)) + 1
        })
    
    return results

def generate_replacement_suggestions(file_path, results):
    """Generate replacement suggestions for a file."""
    suggestions = []
    
    for result in results:
        suggestion = f"""
Line {result['line']}:
  Original: style: {result['original']}
  Replacement: style: {result['replacement']}
  Reason: Font size {result['font_size']} with weight {result['font_weight']} matches {result['replacement'].split('.')[1]}
"""
        suggestions.append(suggestion)
    
    return suggestions

def main():
    # Statistics widgets directory
    stats_dir = Path("lib/widgets/statistics")
    
    if not stats_dir.exists():
        print(f"Directory not found: {stats_dir}")
        return
    
    # Find all Dart files
    dart_files = list(stats_dir.glob("*.dart"))
    
    print(f"Found {len(dart_files)} Dart files in {stats_dir}")
    print("=" * 80)
    
    all_suggestions = []
    
    for dart_file in dart_files:
        print(f"\nAnalyzing: {dart_file.name}")
        
        results = analyze_file(dart_file)
        
        if results:
            print(f"  Found {len(results)} inline TextStyle definitions")
            
            suggestions = generate_replacement_suggestions(dart_file, results)
            all_suggestions.extend([(dart_file.name, s) for s in suggestions])
            
            # Show first few suggestions
            for i, suggestion in enumerate(suggestions[:3]):
                print(suggestion)
            if len(suggestions) > 3:
                print(f"  ... and {len(suggestions) - 3} more")
        else:
            print("  No inline TextStyle definitions found")
    
    # Write summary to file
    if all_suggestions:
        with open('text_style_replacements_summary.txt', 'w', encoding='utf-8') as f:
            f.write("Inline TextStyle to AppTextStyles Replacement Suggestions\n")
            f.write("=" * 80 + "\n\n")
            
            current_file = None
            for file_name, suggestion in all_suggestions:
                if file_name != current_file:
                    f.write(f"\n{'=' * 60}\n")
                    f.write(f"File: {file_name}\n")
                    f.write(f"{'=' * 60}\n\n")
                    current_file = file_name
                f.write(suggestion + "\n")
        
        print(f"\n{'=' * 80}")
        print(f"Summary written to: text_style_replacements_summary.txt")
        print(f"Total suggestions: {len(all_suggestions)}")
        
        # Generate batch replacement commands
        print("\nBatch replacement commands:")
        print("1. First, ensure AppTextStyles is imported:")
        print("   import '../../core/design/app_text_styles.dart';")
        print("\n2. For manual replacement, use the suggestions in the summary file.")
        print("\n3. Common patterns to search for:")
        print("   - style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)")
        print("   - style: TextStyle(fontSize: 14)")
        print("   - style: TextStyle(fontSize: 12, color: Colors.grey)")
        print("\n4. Remember to preserve color and other properties:")
        print("   style: TextStyle(fontSize: 14, color: Colors.red)")
        print("   → style: AppTextStyles.bodyMedium.copyWith(color: Colors.red)")
    else:
        print("\nNo inline TextStyle definitions found in statistics widgets.")

if __name__ == "__main__":
    main()