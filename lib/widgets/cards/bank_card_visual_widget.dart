import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BankCardVisualWidget extends StatelessWidget {
  final String bankName;
  final String cardName;
  final String last4Digits;
  final double currentDebt;
  final double limit;
  final String colorHex;
  final int? cutOffDay;
  final int? paymentDay; // If only day of month is known
  final DateTime? fullPaymentDate; // If full date is known (preferred for List Screen)
  final Widget? action;
  final VoidCallback? onTap;

  const BankCardVisualWidget({
    super.key,
    required this.bankName,
    required this.cardName,
    required this.last4Digits,
    required this.currentDebt,
    required this.limit,
    required this.colorHex,
    this.cutOffDay,
    this.paymentDay,
    this.fullPaymentDate,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    try {
      cardColor = Color(int.parse(colorHex));
    } catch (_) {
      cardColor = const Color(0xFF212121);
    }
    
    // Fix for "Banka" issue: Use cardName if bankName is empty/generic
    String displayBankName = bankName;
    if (displayBankName == 'Banka' || displayBankName.isEmpty || displayBankName.trim() == '') {
        displayBankName = cardName; 
    }
    if (displayBankName.isEmpty) {
        displayBankName = 'Banka';
    }

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cardColor.withValues(alpha: 0.8),
        cardColor,
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayBankName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                action ?? const Icon(Icons.contactless, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   '**** **** **** ${last4Digits.length >= 4 ? last4Digits : "1234"}',
                   style: const TextStyle(
                     color: Colors.white70,
                     fontSize: 15,
                     letterSpacing: 2,
                     fontFamily: 'Courier',
                   ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GÜNCEL BORÇ', style: TextStyle(color: Colors.white60, fontSize: 9)),
                        const SizedBox(height: 2),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(currentDebt)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('LİMİT', style: TextStyle(color: Colors.white60, fontSize: 9)),
                        const SizedBox(height: 2),
                        Text(
                          '₺${NumberFormat('#,##0', 'tr_TR').format(limit)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (cutOffDay != null || paymentDay != null || fullPaymentDate != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (cutOffDay != null && cutOffDay! > 0)
                      Text(
                        'Kesim: $cutOffDay',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    
                    if (fullPaymentDate != null)
                      Text(
                        'Son Ödeme: ${DateFormat('dd MMM', 'tr_TR').format(fullPaymentDate!)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      )
                    else if (paymentDay != null && paymentDay! > 0)
                      Text(
                        'Son Ödeme: $paymentDay',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
