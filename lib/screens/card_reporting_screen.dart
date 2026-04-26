import 'package:flutter/material.dart';
import '../widgets/statistics/card_reporting_tab.dart';

class CardReportingScreen extends StatelessWidget {
  const CardReportingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kart Raporları'),
      ),
      body: SafeArea(
        child: CardReportingTab(
          startDate: DateTime(now.year, now.month, 1),
          endDate: now,
        ),
      ),
    );
  }
}
