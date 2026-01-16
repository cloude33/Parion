import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:parion/models/cash_flow_data.dart';

class StatisticsAccessibility {
  static const double minTouchTargetSize = 48.0;

  static String summaryCardLabel({required String title, required String value, String? subtitle}) {
    return '$title: $value${subtitle != null ? ', $subtitle' : ''}';
  }

  static Future<void> announce(BuildContext context, String message) async {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  static bool hasGoodContrast(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 4.5;
  }

  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color getAccessibleColor(Color foreground, Color background) {
    if (hasGoodContrast(foreground, background)) return foreground;
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  static Color getAccessibleColorOld(Color color) {
    return color;
  }

  static String metricCardLabel({required String label, required String value, String? change, TrendDirection? trend}) {
    String result = '$label: $value';
    if (change != null) {
      result += ', değişim: $change';
    }
    if (trend != null) {
      result += ', ${trendLabel(trend)}';
    }
    return result;
  }

  static String chartLabel({required String title, required int dataPointCount, String? description}) {
    String result = '$title grafik, $dataPointCount veri noktası';
    if (description != null) {
      result += ', $description';
    }
    return result;
  }
  
  static String currencyLabel(double value, {String currency = 'TL'}) {
    if (value == 0) {
      return 'Sıfır $currency';
    }
    final absValue = value.abs().toStringAsFixed(2);
    final suffix = value > 0 ? 'artı' : 'eksi';
    return '$absValue $currency $suffix';
  }

  static String percentageLabel(double value) {
    return 'Yüzde ${value.toStringAsFixed(1)}';
  }

  static String dateLabel(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String trendLabel(TrendDirection trend) {
    return _getTrendDescription(trend);
  }

  static String _getTrendDescription(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return 'Artış trendi';
      case TrendDirection.down:
        return 'Azalış trendi';
      case TrendDirection.stable:
        return 'Sabit trend';
    }
  }
}

class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: true,
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
        ),
      ),
    );
  }
}

class AccessibleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String semanticLabel;
  final String? semanticHint;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
      child: Semantics(
        label: semanticLabel,
        hint: semanticHint,
        button: true,
        enabled: true,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}

class AccessibleFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const AccessibleFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48.0),
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        enabled: true,
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          avatar: icon != null ? Icon(icon, size: 18) : null,
        ),
      ),
    );
  }
}

class AccessibleProgress extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const AccessibleProgress({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: '${(value * 100).toInt()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
    
    if (onTap != null) {
      cardContent = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48.0),
        child: cardContent,
      );
    }
    
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: cardContent,
    );
  }
}

class AccessibleListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final String semanticLabel;

  const AccessibleListTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48.0),
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}