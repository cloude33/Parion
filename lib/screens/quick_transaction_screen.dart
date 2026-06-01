import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'add_transaction_screen.dart';

class QuickTransactionScreen extends StatefulWidget {
  const QuickTransactionScreen({super.key});

  @override
  State<QuickTransactionScreen> createState() => _QuickTransactionScreenState();
}

class _QuickTransactionScreenState extends State<QuickTransactionScreen> {
  final DataService _dataService = DataService();
  final bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    try {
      final wallets = await _dataService.getWallets();
      final categories = await _dataService.getCategories();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddTransactionScreen(
              wallets: wallets,
              categories: categories,
              defaultType: 'expense',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
