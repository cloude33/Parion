import 'package:flutter/material.dart';
import '../widgets/statistics/debt_statistics_tab.dart';

class DebtStatisticsScreen extends StatelessWidget {
  const DebtStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: SafeArea(
        child: DebtStatisticsTab(
          startDate: DateTime(now.year, now.month, 1),
          endDate: now,
        ),
      ),
    );
  }
}
