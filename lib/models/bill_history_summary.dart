import 'package:parion/models/bill_template.dart';

class BillHistorySummary {
  final String templateId;
  final String templateName;
  final BillTemplateCategory category;
  final int totalPayments;
  final int paidPayments;
  final double paymentRate;
  final DateTime? lastPaidDate;
  final DateTime? nextDueDate;

  BillHistorySummary({
    required this.templateId,
    required this.templateName,
    required this.category,
    required this.totalPayments,
    required this.paidPayments,
    required this.paymentRate,
    this.lastPaidDate,
    this.nextDueDate,
  });

  /// Ödeme oranını hesaplar.
  /// totalPayments > 0 ise: paidPayments / totalPayments × 100
  /// totalPayments ≤ 0 ise: 0.0 döner
  static double calculatePaymentRate(int paid, int total) {
    if (total <= 0) return 0.0;
    return (paid / total) * 100;
  }
}
