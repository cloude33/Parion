import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_payment.dart';
import '../models/transaction.dart';
import 'bill_template_service.dart';
import 'credit_card_service.dart';
import '../models/credit_card_transaction.dart';
import 'data_service.dart';
class BillPaymentService {
  static const String _storageKey = 'bill_payments';
  final Uuid _uuid = const Uuid();
  final BillTemplateService _templateService = BillTemplateService();
  Future<List<BillPayment>> getPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => BillPayment.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  Future<List<BillPayment>> getPendingPayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isPending).toList();
  }
  Future<List<BillPayment>> getOverduePayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isOverdue).toList();
  }
  Future<List<BillPayment>> getPaidPayments() async {
    final payments = await getPayments();
    return payments.where((p) => p.isPaid).toList();
  }
  Future<List<BillPayment>> getPaymentsByTemplate(String templateId) async {
    final payments = await getPayments();
    return payments.where((p) => p.templateId == templateId).toList();
  }
  Future<List<BillPayment>> getPaymentsByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final payments = await getPayments();
    return payments.where((p) {
      return p.periodStart.isAfter(start.subtract(const Duration(days: 1))) &&
          p.periodEnd.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> checkAndProcessDuePayments() async {
    final payments = await getPendingPayments();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final payment in payments) {
      final due = DateTime(payment.dueDate.year, payment.dueDate.month, payment.dueDate.day);
      
      // Vadesi gelmiş veya geçmiş ödemeler
      if (due.isBefore(today) || due.isAtSameMomentAs(today)) {
        // Öncelik: Ödeme kaydındaki targetWalletId
        // Yedek: Şablondaki walletId
        final template = await _templateService.getTemplate(payment.templateId);
        String? walletIdToUse = payment.targetWalletId;
        
        if (walletIdToUse == null && template != null) {
          walletIdToUse = template.walletId;
        }
        
        if (walletIdToUse != null) {
          try {
            await markAsPaid(
              paymentId: payment.id, 
              walletId: walletIdToUse
            );
          } catch (e) {
            // Hata durumunda sessizce devam et
            debugPrint('Error processing payment ${payment.id}: $e');
          }
        }
      }
    }
  }

  Future<BillPayment> addPayment({
    required String templateId,
    required double amount,
    required DateTime dueDate,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? targetWalletId,
    String? notes,
  }) async {
    final template = await _templateService.getTemplate(templateId);
    if (template == null) {
      throw Exception('Fatura şablonu bulunamadı');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final isOverdue = dueDateOnly.isBefore(today) || dueDateOnly.isAtSameMomentAs(today);
    
    // Use selected target wallet or fallback to template default
    final walletIdToUse = targetWalletId ?? template.walletId;
    
    final payment = BillPayment(
      id: _uuid.v4(),
      templateId: templateId,
      amount: amount,
      dueDate: dueDate,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: isOverdue ? BillPaymentStatus.paid : BillPaymentStatus.pending,
      paidDate: isOverdue ? now : null,
      paidWithWalletId: isOverdue ? walletIdToUse : null,
      targetWalletId: targetWalletId,
      notes: notes?.trim(),
      createdDate: now,
      updatedDate: now,
    );

    final payments = await getPayments();
    payments.add(payment);
    await savePayments(payments);
    
    // If it's overdue (or paid immediately), process the transaction
    if (isOverdue && walletIdToUse != null) {
      String? transactionId;
      
      // Check if it is a credit card
      bool isCreditCard = walletIdToUse.startsWith('cc_');
      String processedWalletId = isCreditCard ? walletIdToUse.replaceFirst('cc_', '') : walletIdToUse;
      
      // Double check if it's a credit card ID even without prefix
      final creditCardService = CreditCardService();
      if (!isCreditCard) {
         final card = await creditCardService.getCard(walletIdToUse);
         if (card != null) {
           isCreditCard = true;
           processedWalletId = walletIdToUse;
         }
      }

      if (isCreditCard) {
          // Verify the card actually exists
          final card = await creditCardService.getCard(processedWalletId);
          if (card != null) {
            final ccTransaction = CreditCardTransaction(
              id: _uuid.v4(),
              cardId: processedWalletId, // Use the CLEAN ID logic
              amount: amount,
              description: '${template.name} Fatura Ödemesi',
              transactionDate: dueDate, 
              category: template.categoryDisplayName,
              installmentCount: 1,
              installmentsPaid: 0,
              createdAt: now,
            );
            await creditCardService.addTransaction(ccTransaction);
            transactionId = ccTransaction.id;
          } else {
             // Fallback to regular transaction if card not found? No, that would be wrong.
             // Just log error
             debugPrint('Error: Credit card not found for ID: $processedWalletId');
          }
      } else {
          final dataService = DataService();
          final transaction = Transaction(
            id: _uuid.v4(),
            description: '${template.name} Fatura Ödemesi',
            amount: amount,
            type: 'expense',
            category: template.categoryDisplayName,
            date: dueDate,
            walletId: walletIdToUse,
          );
          
          await dataService.addTransaction(transaction);
          transactionId = transaction.id;
      }

      final updatedPayment = payment.copyWith(transactionId: transactionId);
      final index = payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        payments[index] = updatedPayment;
        await savePayments(payments);
      }
    }

    return payment;
  }
  Future<void> updatePayment(BillPayment payment) async {
    final payments = await getPayments();
    final index = payments.indexWhere((p) => p.id == payment.id);

    if (index == -1) {
      throw Exception('Ödeme bulunamadı');
    }

    payments[index] = payment.copyWith(updatedDate: DateTime.now());
    await savePayments(payments);
  }
  Future<void> deletePayment(String id) async {
    final payments = await getPayments();
    payments.removeWhere((p) => p.id == id);
    await savePayments(payments);
  }
  Future<void> markAsPaid({
    required String paymentId,
    required String walletId,
    String? transactionId,
  }) async {
    final payments = await getPayments();
    final index = payments.indexWhere((p) => p.id == paymentId);

    if (index == -1) {
      throw Exception('Ödeme bulunamadı');
    }

    final payment = payments[index];
    String? newTransactionId = transactionId;
    if (newTransactionId == null) {
      final template = await _templateService.getTemplate(payment.templateId);
      
      if (template != null) {
        // Kredi kartı kontrolü
        bool isCreditCard = walletId.startsWith('cc_');
        String processedCardId = isCreditCard ? walletId.replaceFirst('cc_', '') : walletId;

        // Eğer prefix yoksa bile ID ile kredi kartı var mı diye kontrol et
        if (!isCreditCard) {
           final creditCardService = CreditCardService();
           final card = await creditCardService.getCard(walletId);
           if (card != null) {
             isCreditCard = true;
             processedCardId = walletId;
           }
        }
        
        if (isCreditCard) {
          // Kredi kartı işlemi oluştur
          final creditCardService = CreditCardService();
          
          final ccTransaction = CreditCardTransaction(
            id: _uuid.v4(),
            cardId: processedCardId,
            amount: payment.amount,
            description: '${template.name} Fatura Ödemesi',
            transactionDate: payment.dueDate,
            category: template.categoryDisplayName,
            installmentCount: 1,
            installmentsPaid: 0,
            createdAt: DateTime.now(),
          );
          
          await creditCardService.addTransaction(ccTransaction);
          newTransactionId = ccTransaction.id;
        } else {
          // Normal cüzdan işlemi oluştur
          final dataService = DataService();
          final transaction = Transaction(
            id: _uuid.v4(),
            description: '${template.name} Fatura Ödemesi',
            amount: payment.amount,
            type: 'expense',
            category: template.categoryDisplayName,
            date: payment.dueDate,
            walletId: walletId,
          );
          
          await dataService.addTransaction(transaction);
          newTransactionId = transaction.id;
        }
      }
    }

    payments[index] = payment.copyWith(
      status: BillPaymentStatus.paid,
      paidDate: DateTime.now(),
      paidWithWalletId: walletId,
      transactionId: newTransactionId,
      updatedDate: DateTime.now(),
    );
    await savePayments(payments);
  }
  Future<void> savePayments(List<BillPayment> payments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = payments.map((p) => p.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
  Future<bool> hasPaymentForCurrentMonth(String templateId) async {
    final now = DateTime.now();
    final payments = await getPaymentsByTemplate(templateId);
    return payments.any(
      (p) => p.periodStart.year == now.year && p.periodStart.month == now.month,
    );
  }
  Future<double> getTotalPaidAmount(DateTime start, DateTime end) async {
    final payments = await getPaymentsByPeriod(start, end);
    final paidPayments = payments.where((p) => p.isPaid).toList();
    return paidPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }
  Future<double> getTotalPendingAmount() async {
    final payments = await getPendingPayments();
    return payments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }
  Future<void> clearAllPayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
  Future<void> addPaymentDirect(BillPayment payment) async {
    final payments = await getPayments();
    payments.add(payment);
    await savePayments(payments);
  }
}
