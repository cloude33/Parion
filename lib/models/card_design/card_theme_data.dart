import 'package:flutter/material.dart';

/// Kart yüzeyi için görsel tanım.
///
/// Her banka/kart markası bu modelin bir örneği ile temsil edilir.
/// [colors] gradyan için, [accentColor] dekoratif öğeler için,
/// [backgroundPattern] painter'da hangi desenin çizileceğini belirler.
@immutable
class CardThemeData {
  const CardThemeData({
    required this.colors,
    required this.accentColor,
    required this.backgroundPattern,
    this.textColor = Colors.white,
    this.labelColor,
  });

  /// Ana gradyan renkleri (en az iki renk önerilir).
  final List<Color> colors;

  /// Vurgu rengi (desen, badge border, simge).
  final Color accentColor;

  /// Desen tanımlayıcısı (`circle`, `spiral`, `b`, `m`, vb.).
  final String backgroundPattern;

  /// Kart üzerindeki birincil metin rengi.
  final Color textColor;

  /// İkincil etiket rengi (örn. "VALID THRU"). Varsayılan: [textColor] %70 opaklık.
  final Color? labelColor;

  /// Etiket rengini opaklık ile döndürür.
  Color get effectiveLabelColor =>
      labelColor ?? textColor.withValues(alpha: 0.7);

  /// Doğrusal gradyan olarak kenar-köşeden kenar-köşeye.
  LinearGradient get gradient => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Üst ışık + alt gölge overlay'i ile birlikte tam arkaplan.
  LinearGradient get overlayGradient => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardThemeData &&
          runtimeType == other.runtimeType &&
          colors == other.colors &&
          accentColor == other.accentColor &&
          backgroundPattern == other.backgroundPattern;

  @override
  int get hashCode =>
      Object.hash(colors, accentColor, backgroundPattern);
}
