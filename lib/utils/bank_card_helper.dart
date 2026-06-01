import 'package:flutter/material.dart';

class BankCardHelper {
  static String? getCardImage(String? bankName, String? cardName) {
    return null;
  }

  static List<String> get availableBankImages => const [];

  static Color getBankColor(String? bankName) {
    if (bankName == null) return Colors.blue;
    
    final name = bankName.toLowerCase();
    if (name.contains('garanti')) return const Color(0xFF009639);
    if (name.contains('akbank')) return const Color(0xFFE30613);
    if (name.contains('iş bank')) return const Color(0xFF003399);
    if (name.contains('yapı kredi')) return const Color(0xFF6C2A8C);
    if (name.contains('ziraat')) return const Color(0xFFED1C24);
    if (name.contains('halkbank')) return const Color(0xFF0054A6);
    if (name.contains('vakıf')) return const Color(0xFFFDB913);
    if (name.contains('finans')) return const Color(0xFF003399);
    if (name.contains('teb')) return const Color(0xFF009639);
    
    return Colors.blue;
  }
}
