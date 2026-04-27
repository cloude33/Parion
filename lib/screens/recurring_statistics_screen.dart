import 'package:flutter/material.dart';
import '../services/recurring_transaction_service.dart';
import '../widgets/statistics/recurring_statistics_tab.dart';

class RecurringStatisticsScreen extends StatelessWidget {
  final RecurringTransactionService service;

  const RecurringStatisticsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Tekrarlayan İşlem İstatistikleri')),
      body: SafeArea(
        child: RecurringStatisticsTab(
          startDate: DateTime(now.year, now.month, 1),
          endDate: now,
        ),
      ),
    );
  }
}
