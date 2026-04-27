import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/kmh_repository.dart';
import '../models/kmh_transaction_type.dart';
import '../services/credit_card_service.dart';
import '../services/data_service.dart';
import 'notification_scheduler_service.dart';

/// Service for generating and showing daily financial summaries
class DailySummaryService {
  static final DailySummaryService _instance = DailySummaryService._internal();
  
  factory DailySummaryService() => _instance;
  
  DailySummaryService._internal();
  
  final DataService _dataService = DataService();
  final CreditCardService _creditCardService = CreditCardService();
  final CreditCardTransactionRepository _transactionRepo = CreditCardTransactionRepository();
  final KmhRepository _kmhRepo = KmhRepository();
  final NotificationSchedulerService _notificationService = NotificationSchedulerService();
  
  /// Calculate today's financial summary
  Future<DailySummary> calculateTodaySummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    double totalExpense = 0;
    double totalIncome = 0;
    int transactionCount = 0;
    String? topCategory;
    double topCategoryAmount = 0;
    final categoryBreakdown = <String, double>{};
    
    try {
      // Get credit card transactions
      final creditCards = await _creditCardService.getActiveCards();
      for (var card in creditCards) {
        final transactions = await _transactionRepo.findByDateRange(
          card.id,
          todayStart,
          todayEnd,
        );
        
        for (var transaction in transactions) {
          totalExpense += transaction.amount;
          transactionCount++;
          
          final category = transaction.category.isNotEmpty ? transaction.category : 'Diğer';
          categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + transaction.amount;
        }
      }
      
      // Get wallet/KMH transactions
      final wallets = await _dataService.getWallets();
      for (var wallet in wallets) {
        if (wallet.isKmhAccount) {
          final kmhTransactions = await _kmhRepo.getTransactionsByDateRange(
            wallet.id,
            todayStart,
            todayEnd,
          );
          
          for (var transaction in kmhTransactions) {
            transactionCount++;
            if (transaction.type == KmhTransactionType.withdrawal) {
              totalExpense += transaction.amount;
            } else if (transaction.type == KmhTransactionType.deposit || 
                       transaction.type == KmhTransactionType.interest) {
              totalIncome += transaction.amount;
            }
          }
        }
      }
      
      // Find top category
      categoryBreakdown.forEach((category, amount) {
        if (amount > topCategoryAmount) {
          topCategoryAmount = amount;
          topCategory = category;
        }
      });
      
    } catch (e) {
      debugPrint('DailySummaryService: Error calculating summary: $e');
    }
    
    return DailySummary(
      date: now,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      transactionCount: transactionCount,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      categoryBreakdown: categoryBreakdown,
    );
  }
  
  /// Calculate this month's summary (for context in daily notification)
  Future<MonthlySummaryContext> calculateMonthContext() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    double totalExpense = 0;
    double totalIncome = 0;
    
    try {
      final creditCards = await _creditCardService.getActiveCards();
      for (var card in creditCards) {
        final transactions = await _transactionRepo.findByDateRange(
          card.id,
          monthStart,
          monthEnd,
        );
        
        for (var transaction in transactions) {
          totalExpense += transaction.amount;
        }
      }
      
      final wallets = await _dataService.getWallets();
      for (var wallet in wallets) {
        if (wallet.isKmhAccount) {
          final kmhTransactions = await _kmhRepo.getTransactionsByDateRange(
            wallet.id,
            monthStart,
            monthEnd,
          );
          
          for (var transaction in kmhTransactions) {
            if (transaction.type == KmhTransactionType.withdrawal) {
              totalExpense += transaction.amount;
            } else if (transaction.type == KmhTransactionType.deposit || 
                       transaction.type == KmhTransactionType.interest) {
              totalIncome += transaction.amount;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DailySummaryService: Error calculating month context: $e');
    }
    
    final daysElapsed = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyAverage = daysElapsed > 0 ? totalExpense / daysElapsed : 0.0;
    final projectedMonthlyExpense = dailyAverage * daysInMonth;
    
    return MonthlySummaryContext(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      dailyAverage: dailyAverage,
      projectedMonthlyExpense: projectedMonthlyExpense,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
    );
  }
  
  /// Generate and show the daily summary notification with real data
  Future<void> showDailySummaryNotification() async {
    await _notificationService.initialize();
    
    final summary = await calculateTodaySummary();
    final monthContext = await calculateMonthContext();
    
    final title = 'Günlük Finansal Özet';
    final body = _buildNotificationBody(summary, monthContext);
    
    await _notificationService.showNotification(
      id: 1001, // Unique ID for daily summary
      title: title,
      body: body,
      payload: 'daily_summary',
      priority: NotificationPriority.normal,
    );
  }
  
  String _buildNotificationBody(DailySummary summary, MonthlySummaryContext monthContext) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    
    final parts = <String>[];
    
    // Today's summary
    if (summary.totalExpense > 0) {
      parts.add('Bugün: ${currencyFormat.format(summary.totalExpense)} harcama');
      
      if (summary.topCategory != null) {
        parts.add('(${summary.topCategory})');
      }
    } else if (summary.transactionCount == 0) {
      parts.add('Bugün harcama yok');
    }
    
    // Monthly context
    if (monthContext.totalExpense > 0) {
      parts.add('• Bu ay: ${currencyFormat.format(monthContext.totalExpense)}');
      parts.add('• Günlük ort: ${currencyFormat.format(monthContext.dailyAverage)}');
    }
    
    if (parts.isEmpty) {
      return 'Bugün için finansal aktivite bulunmuyor.';
    }
    
    return parts.join(' ');
  }
  
  /// Get formatted summary text for display in app
  Future<String> getFormattedDailySummary() async {
    final summary = await calculateTodaySummary();
    final monthContext = await calculateMonthContext();
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    
    final buffer = StringBuffer();
    
    buffer.writeln('📊 Günlük Özet - ${DateFormat('d MMMM yyyy', 'tr_TR').format(summary.date)}');
    buffer.writeln();
    
    if (summary.transactionCount > 0) {
      buffer.writeln('💸 Bugünkü Harcama: ${currencyFormat.format(summary.totalExpense)}');
      if (summary.totalIncome > 0) {
        buffer.writeln('💰 Bugünkü Gelir: ${currencyFormat.format(summary.totalIncome)}');
      }
      buffer.writeln('📝 İşlem Sayısı: ${summary.transactionCount}');
      
      if (summary.topCategory != null) {
        buffer.writeln('🏷️ En Çok Harcama: ${summary.topCategory} (${currencyFormat.format(summary.topCategoryAmount)})');
      }
    } else {
      buffer.writeln('Bugün henüz işlem yapılmadı.');
    }
    
    buffer.writeln();
    buffer.writeln('📅 Bu Ay (${monthContext.daysElapsed}/${monthContext.daysInMonth} gün)');
    buffer.writeln('💸 Toplam Harcama: ${currencyFormat.format(monthContext.totalExpense)}');
    buffer.writeln('📈 Günlük Ortalama: ${currencyFormat.format(monthContext.dailyAverage)}');
    buffer.writeln('🔮 Tahmini Aylık: ${currencyFormat.format(monthContext.projectedMonthlyExpense)}');
    
    return buffer.toString();
  }
}

/// Daily summary data model
class DailySummary {
  final DateTime date;
  final double totalExpense;
  final double totalIncome;
  final int transactionCount;
  final String? topCategory;
  final double topCategoryAmount;
  final Map<String, double> categoryBreakdown;
  
  DailySummary({
    required this.date,
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
    this.topCategory,
    required this.topCategoryAmount,
    required this.categoryBreakdown,
  });
  
  double get netFlow => totalIncome - totalExpense;
}

/// Monthly context for daily summary
class MonthlySummaryContext {
  final double totalExpense;
  final double totalIncome;
  final double dailyAverage;
  final double projectedMonthlyExpense;
  final int daysElapsed;
  final int daysInMonth;
  
  MonthlySummaryContext({
    required this.totalExpense,
    required this.totalIncome,
    required this.dailyAverage,
    required this.projectedMonthlyExpense,
    required this.daysElapsed,
    required this.daysInMonth,
  });
}
