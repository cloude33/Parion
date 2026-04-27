import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/recurring_transaction_service.dart';
import '../widgets/recurring_transaction_card.dart';
import 'add_recurring_transaction_screen.dart';
import 'recurring_transaction_detail_screen.dart';
import 'recurring_statistics_screen.dart';

class RecurringTransactionListScreen extends StatefulWidget {
  final RecurringTransactionService service;

  const RecurringTransactionListScreen({super.key, required this.service});

  @override
  State<RecurringTransactionListScreen> createState() =>
      _RecurringTransactionListScreenState();
}

class _RecurringTransactionListScreenState
    extends State<RecurringTransactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recurringTransactions),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.active),
            Tab(text: AppLocalizations.of(context)!.inactive),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RecurringStatisticsScreen(service: widget.service),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveList(), _buildInactiveList()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddRecurringTransactionScreen(service: widget.service),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActiveList() {
    final transactions = widget.service.getActive();

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.repeat, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noRecurringTransactions,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return RecurringTransactionCard(
          transaction: transaction,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecurringTransactionDetailScreen(
                  transaction: transaction,
                  service: widget.service,
                ),
              ),
            );
            if (result == true) {
              setState(() {});
            }
          },
        );
      },
    );
  }

  Widget _buildInactiveList() {
    final transactions = widget.service.getInactive();

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.inactive,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return RecurringTransactionCard(
          transaction: transaction,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecurringTransactionDetailScreen(
                  transaction: transaction,
                  service: widget.service,
                ),
              ),
            );
            if (result == true) {
              setState(() {});
            }
          },
        );
      },
    );
  }
}
