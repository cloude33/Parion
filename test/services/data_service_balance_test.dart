import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/utils/money.dart';
import 'package:shared_preferences/shared_preferences.dart';

Wallet _wallet(String id, double balance) => Wallet(
  id: id,
  name: 'Cüzdan $id',
  balance: balance,
  type: 'cash',
  color: '0xFF000000',
  icon: 'cash',
);

Transaction _transaction(
  String id,
  double amount, {
  String type = 'expense',
  String walletId = 'w1',
}) => Transaction(
  id: id,
  type: type,
  amount: amount,
  description: 'Test $id',
  category: 'Test',
  walletId: walletId,
  date: DateTime.now(),
);

Future<DataService> _createService({double balance = 100.0}) async {
  SharedPreferences.setMockInitialValues({});
  final service = DataService.forTesting();
  await service.init();
  await service.addWallet(_wallet('w1', balance));
  return service;
}

Future<double> _balanceOf(DataService service, String walletId) async {
  final wallets = await service.getWallets();
  return wallets.firstWhere((wallet) => wallet.id == walletId).balance;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataService balance effects', () {
    test('expense decreases the wallet and delete restores it exactly', () async {
      final service = await _createService(balance: 100.0);

      await service.addTransaction(_transaction('t1', 10.0));
      expect(await _balanceOf(service, 'w1'), 90.0);

      await service.deleteTransaction('t1');
      expect(await _balanceOf(service, 'w1'), 100.0);
    });

    test('income increases the wallet balance', () async {
      final service = await _createService(balance: 100.0);

      await service.addTransaction(_transaction('t1', 250.50, type: 'income'));

      expect(await _balanceOf(service, 'w1'), 350.50);
    });

    test('updating a transaction reverts the old amount before applying the new one',
        () async {
      final service = await _createService(balance: 100.0);
      final original = _transaction('t1', 10.0);
      await service.addTransaction(original);
      expect(await _balanceOf(service, 'w1'), 90.0);

      await service.updateTransaction(original, _transaction('t1', 25.0));
      expect(await _balanceOf(service, 'w1'), 75.0);

      await service.deleteTransaction('t1');
      expect(await _balanceOf(service, 'w1'), 100.0);
    });

    test('every write is rounded to a whole kuruş', () async {
      final service = await _createService(balance: 100.0);

      for (var i = 0; i < 10; i++) {
        await service.addTransaction(_transaction('t$i', 0.006));
      }

      // 0.006 rounds to 0.01 per write, so ten writes cost exactly 0.10.
      expect(await _balanceOf(service, 'w1'), closeTo(99.90, 1e-9));
      expect(roundMoney(0.1 + 0.2), 0.3);
      expect(sumMoney(const [0.1, 0.2]), 0.3);
    });

    test('transfer moves money without changing the total', () async {
      final service = await _createService(balance: 100.0);
      await service.addWallet(_wallet('w2', 0.0));

      await service.addTransferTransaction(
        fromWalletId: 'w1',
        toWalletId: 'w2',
        amount: 40.0,
        description: 'Test transfer',
      );

      expect(await _balanceOf(service, 'w1'), 60.0);
      expect(await _balanceOf(service, 'w2'), 40.0);

      final total = sumMoney([await _balanceOf(service, 'w1'), await _balanceOf(service, 'w2')]);
      expect(total, 100.0);
    });

    test('installment delete reverts every linked transaction', () async {
      final service = await _createService(balance: 100.0);
      final parent = _transaction('p1', 30.0);
      final child = Transaction(
        id: 'c1',
        type: 'expense',
        amount: 30.0,
        description: 'Taksit',
        category: 'Test',
        walletId: 'w1',
        date: DateTime.now(),
        parentTransactionId: 'p1',
        installments: 2,
        currentInstallment: 2,
      );

      await service.addTransaction(parent);
      await service.addTransaction(child);
      expect(await _balanceOf(service, 'w1'), 40.0);

      await service.deleteTransaction('p1');
      expect(await _balanceOf(service, 'w1'), 100.0);
    });
  });
}
