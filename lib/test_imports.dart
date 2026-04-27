import 'package:parion/services/services_export.dart';
import 'package:parion/models/models_export.dart';

void main() {
  // Just verify that the imports work
  final backupService = BackupService();
  final authService = FirebaseAuthService();
  final dataService = DataService();
  final autoBackupService = AutoBackupService();

  final transaction = Transaction(
    id: 'test',
    type: 'expense',
    amount: 100.0,
    description: 'Test',
    category: 'test',
    walletId: 'test',
    date: DateTime.now(),
  );

  final wallet = Wallet(
    id: 'test',
    name: 'Test Wallet',
    balance: 1000.0,
    type: 'bank',
    color: 'blue',
    icon: 'wallet',
  );

  // Use all variables to avoid "unused variable" warnings
  print('backupService: $backupService');
  print('authService: $authService');
  print('dataService: $dataService');
  print('autoBackupService: $autoBackupService');
  print('transaction: ${transaction.id}');
  print('wallet: ${wallet.name}');
  print('All imports work correctly');
}
