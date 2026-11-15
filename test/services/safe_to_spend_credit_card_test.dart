import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parion/models/credit_card.dart';
import 'package:parion/models/credit_card_payment.dart';
import 'package:parion/models/credit_card_statement.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/services/credit_card_box_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/safe_to_spend_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Wallet _wallet(double balance) => Wallet(
  id: 'cash',
  name: 'Nakit',
  balance: balance,
  type: 'cash',
  color: '0xFF000000',
  icon: 'cash',
);

CreditCard _card({
  String id = 'card-1',
  int statementDay = 10,
  int dueDateOffset = 20,
  bool isActive = true,
  double initialDebt = 0,
}) => CreditCard(
  id: id,
  bankName: 'Test Bank',
  cardName: 'Test Card',
  last4Digits: '1234',
  creditLimit: 10000,
  statementDay: statementDay,
  dueDateOffset: dueDateOffset,
  monthlyInterestRate: 1,
  lateInterestRate: 2,
  cardColor: 0xFF2196F3,
  createdAt: DateTime(2026, 1, 1),
  isActive: isActive,
  initialDebt: initialDebt,
);

CreditCardStatement _statement({
  String id = 'statement-1',
  String cardId = 'card-1',
  required DateTime dueDate,
  required double remainingDebt,
  String status = 'pending',
  DateTime? periodEnd,
}) => CreditCardStatement(
  id: id,
  cardId: cardId,
  periodStart: DateTime(2026, 3, 11),
  periodEnd: periodEnd ?? DateTime(2026, 3, 10),
  dueDate: dueDate,
  totalDebt: remainingDebt,
  minimumPayment: remainingDebt * 0.33,
  remainingDebt: remainingDebt,
  status: status,
  createdAt: DateTime(2026, 3, 10),
);

CreditCardTransaction _creditCardTransaction({
  String id = 'credit-tx-1',
  String cardId = 'card-1',
  double amount = 100,
  int installmentCount = 1,
  int installmentsPaid = 0,
  DateTime? transactionDate,
}) => CreditCardTransaction(
  id: id,
  cardId: cardId,
  amount: amount,
  description: 'Test credit purchase',
  transactionDate: transactionDate ?? DateTime(2026, 4, 8),
  category: 'Test',
  installmentCount: installmentCount,
  installmentsPaid: installmentsPaid,
  createdAt: DateTime(2026, 4, 8),
);

Future<DataService> _createDataService(double balance) async {
  SharedPreferences.setMockInitialValues({});
  final service = DataService.forTesting();
  await service.init();
  await service.addWallet(_wallet(balance));
  return service;
}

SafeToSpendService _service(DataService dataService) =>
    SafeToSpendService(dataService: dataService);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive.init('./test_hive_safe_to_spend_cc');
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CreditCardStatementAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(CreditCardPaymentAdapter());
    }
    await CreditCardBoxService.init();
  });

  tearDownAll(() async {
    await CreditCardBoxService.close();
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    await CreditCardBoxService.creditCardsBox.clear();
    await CreditCardBoxService.transactionsBox.clear();
    await CreditCardBoxService.statementsBox.clear();
    await CreditCardBoxService.paymentsBox.clear();
  });

  test('unpaid statements due this month are added once', () async {
    final dataService = await _createDataService(1000);
    await CreditCardBoxService.creditCardsBox.put('card-1', _card());
    await CreditCardBoxService.creditCardsBox.put(
      'inactive-card',
      _card(id: 'inactive-card', isActive: false),
    );
    await CreditCardBoxService.statementsBox.put(
      'statement-1',
      _statement(dueDate: DateTime(2026, 4, 15), remainingDebt: 300),
    );
    await CreditCardBoxService.statementsBox.put(
      'statement-paid',
      _statement(
        id: 'statement-paid',
        dueDate: DateTime(2026, 4, 20),
        remainingDebt: 0,
        status: 'paid',
      ),
    );
    await CreditCardBoxService.statementsBox.put(
      'statement-future',
      _statement(
        id: 'statement-future',
        dueDate: DateTime(2026, 5, 2),
        remainingDebt: 500,
      ),
    );
    await CreditCardBoxService.statementsBox.put(
      'statement-inactive',
      _statement(
        id: 'statement-inactive',
        cardId: 'inactive-card',
        dueDate: DateTime(2026, 4, 18),
        remainingDebt: 777,
      ),
    );

    final result = await _service(
      dataService,
    ).calculate(referenceDate: DateTime(2026, 4, 8));

    expect(result.upcomingFixed, 300.0);
    expect(result.available, 700.0);
  });

  test('current-period credit purchases due this month are added', () async {
    final dataService = await _createDataService(1000);
    await CreditCardBoxService.creditCardsBox.put('card-1', _card());
    await CreditCardBoxService.statementsBox.put(
      'statement-paid',
      _statement(
        id: 'statement-paid',
        dueDate: DateTime(2026, 4, 30),
        remainingDebt: 0,
        status: 'paid',
      ),
    );
    await CreditCardBoxService.transactionsBox.put(
      'single',
      _creditCardTransaction(id: 'single', amount: 200.25),
    );

    final result = await _service(
      dataService,
    ).calculate(referenceDate: DateTime(2026, 4, 8));

    expect(result.upcomingFixed, 200.25);
    expect(result.upcomingItems.single.label, contains('yeni ekstre'));
  });

  test('projected statement excludes purchases due after this month', () async {
    final dataService = await _createDataService(1000);
    await CreditCardBoxService.creditCardsBox.put(
      'card-1',
      _card(dueDateOffset: 25),
    );
    await CreditCardBoxService.statementsBox.put(
      'statement-paid',
      _statement(
        id: 'statement-paid',
        dueDate: DateTime(2026, 4, 30),
        remainingDebt: 0,
        status: 'paid',
      ),
    );
    await CreditCardBoxService.transactionsBox.put(
      'single',
      _creditCardTransaction(id: 'single', amount: 300),
    );

    final result = await _service(
      dataService,
    ).calculate(referenceDate: DateTime(2026, 4, 8));

    expect(result.upcomingFixed, 0.0);
  });

  test('installment purchases add only one current installment', () async {
    final dataService = await _createDataService(1000);
    await CreditCardBoxService.creditCardsBox.put('card-1', _card());
    await CreditCardBoxService.statementsBox.put(
      'statement-paid',
      _statement(
        id: 'statement-paid',
        dueDate: DateTime(2026, 4, 30),
        remainingDebt: 0,
        status: 'paid',
      ),
    );
    await CreditCardBoxService.transactionsBox.put(
      'installment',
      _creditCardTransaction(
        id: 'installment',
        amount: 400,
        installmentCount: 4,
        installmentsPaid: 0,
      ),
    );
    await CreditCardBoxService.transactionsBox.put(
      'single',
      _creditCardTransaction(id: 'single', amount: 50),
    );

    final result = await _service(
      dataService,
    ).calculate(referenceDate: DateTime(2026, 4, 8));

    expect(result.upcomingFixed, 150.0);
  });

  test(
    'initial credit-card debt is counted before the first statement',
    () async {
      final dataService = await _createDataService(1000);
      await CreditCardBoxService.creditCardsBox.put(
        'card-1',
        _card(initialDebt: 250),
      );

      final result = await _service(
        dataService,
      ).calculate(referenceDate: DateTime(2026, 4, 8));

      expect(result.upcomingFixed, 250.0);
      expect(result.upcomingItems.single.label, contains('başlangıç borcu'));
    },
  );

  test(
    'synthetic credit-card wallet does not double-count statement debt',
    () async {
      final dataService = await _createDataService(1000);
      await CreditCardBoxService.creditCardsBox.put('card-1', _card());
      await CreditCardBoxService.statementsBox.put(
        'statement-1',
        _statement(dueDate: DateTime(2026, 4, 15), remainingDebt: 300),
      );

      final wallets = await dataService.getWallets();
      expect(
        wallets.any(
          (wallet) => wallet.id == 'cc_card-1' && wallet.balance == -300,
        ),
        isTrue,
      );

      final result = await _service(
        dataService,
      ).calculate(referenceDate: DateTime(2026, 4, 8));

      expect(result.available, 700.0);
    },
  );
}
