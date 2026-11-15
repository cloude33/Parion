import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/user.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

User _user(String id) => User(id: id, name: 'Kullanıcı $id');

Wallet _wallet(String id, double balance) => Wallet(
  id: id,
  name: 'Cüzdan $id',
  balance: balance,
  type: 'cash',
  color: '0xFF000000',
  icon: 'cash',
);

Transaction _transaction(String id, String walletId) => Transaction(
  id: id,
  type: 'expense',
  amount: 10.0,
  description: 'Test $id',
  category: 'Test',
  walletId: walletId,
  date: DateTime.now(),
);

Future<DataService> _serviceFor(String userId) async {
  final service = DataService.forTesting();
  await service.init();
  await service.saveUser(_user(userId));
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataService per-user isolation', () {
    test('transactions and wallets never leak between profiles', () async {
      SharedPreferences.setMockInitialValues({});

      final userA = await _serviceFor('user_a');
      await userA.addWallet(_wallet('w_a', 100.0));
      await userA.addTransaction(_transaction('t_a', 'w_a'));

      expect(await userA.getTransactions(), hasLength(1));

      final userB = await _serviceFor('user_b');
      expect(await userB.getTransactions(), isEmpty);
      expect(await userB.getWallets(), isEmpty);

      // Switching back must return the original data, not a cached copy from
      // the other profile.
      await userB.saveUser(_user('user_a'));
      expect(await userB.getTransactions(), hasLength(1));
      expect(await userB.getWallets(), hasLength(1));
    });

    test('legacy unscoped data is migrated once to the active user', () async {
      final legacyTransaction = _transaction('legacy_t', 'legacy_w');
      SharedPreferences.setMockInitialValues({
        'current_user': jsonEncode(_user('user_a').toJson()),
        'transactions': jsonEncode([legacyTransaction.toJson()]),
        'wallets': jsonEncode([_wallet('legacy_w', 50.0).toJson()]),
      });

      final service = DataService.forTesting();
      await service.init();

      final transactions = await service.getTransactions();
      expect(transactions, hasLength(1));
      expect(transactions.first.id, 'legacy_t');
      expect(await service.getWallets(), hasLength(1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('u_user_a_transactions'), isNotNull);
      expect(prefs.getString('u_user_a_wallets'), isNotNull);

      // A different profile must not inherit the migrated data.
      await service.saveUser(_user('user_b'));
      expect(await service.getTransactions(), isEmpty);
    });

    test('guest mode keeps its own bucket instead of the first profile bucket',
        () async {
      SharedPreferences.setMockInitialValues({});

      final guest = DataService.forTesting();
      await guest.init();
      await guest.addWallet(_wallet('guest_w', 10.0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('guest_wallets'), isNotNull);

      final user = await _serviceFor('user_a');
      expect(await user.getWallets(), isEmpty);
    });
  });
}
