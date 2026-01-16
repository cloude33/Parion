import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parion/models/credit_card.dart';
import 'package:parion/models/credit_card_statement.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/models/credit_card_payment.dart';
import 'package:parion/services/statement_generator_service.dart';
import 'package:parion/services/credit_card_box_service.dart';
import 'package:parion/repositories/credit_card_repository.dart';
import 'package:parion/repositories/credit_card_statement_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive.init('./test_hive_statement_gen');
    Hive.registerAdapter(CreditCardAdapter());
    Hive.registerAdapter(CreditCardStatementAdapter());
    Hive.registerAdapter(CreditCardTransactionAdapter());
    Hive.registerAdapter(CreditCardPaymentAdapter());

    await CreditCardBoxService.init();
  });

  tearDownAll(() async {
    await CreditCardBoxService.close();
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    await CreditCardBoxService.creditCardsBox.clear();
    await CreditCardBoxService.statementsBox.clear();
    await CreditCardBoxService.transactionsBox.clear();
  });

  test('checkAndGenerateStatements generates statement when due', () async {
    final cardRepo = CreditCardRepository();
    final statementRepo = CreditCardStatementRepository();
    final generator = StatementGeneratorService();

    final now = DateTime.now();
    // Use today as statement day. Logic: now.year, now.month, statementDay.
    // If statementDay == now.day, then statementDate == now (start of day).
    // now (probably with time) > statementDate. So SHOULD generate.
    final statementDay = now.day;

    final card = CreditCard(
      id: const Uuid().v4(),
      cardName: 'Test Card',
      bankName: 'Test Bank',
      last4Digits: '1234',
      creditLimit: 10000,
      statementDay: statementDay,
      dueDateOffset: 10,
      monthlyInterestRate: 2.0,
      lateInterestRate: 2.5,
      cardColor: 0xFF000000,
      initialDebt: 0,
      createdAt: now.subtract(const Duration(days: 60)),
    );
    await cardRepo.save(card);

    // Act
    await generator.checkAndGenerateStatements();

    // Assert
    final statements = await statementRepo.findByCardId(card.id);
    expect(
      statements,
      isNotEmpty,
      reason: 'Statement should be generated for today',
    );
    expect(statements.first.periodEnd.year, now.year);
    expect(statements.first.periodEnd.month, now.month);
    expect(statements.first.periodEnd.day, statementDay);
  });

  test(
    'checkAndGenerateStatements does NOT generate statement when NOT due',
    () async {
      final cardRepo = CreditCardRepository();
      final statementRepo = CreditCardStatementRepository();
      final generator = StatementGeneratorService();

      final now = DateTime.now();

      // Pick a day in the future of current month
      int futureDay = now.day + 5;
      if (futureDay > 28) {
        // Cannot test "not due" easily if we are at end of month,
        // unless we pick a day that doesn't exist or logic handles rollover.
        // Current logic limits to lastDayOfMonth.
        // If today is 25th, and we pick 30th.
        // StatementDate = 30th. Now (25th) < 30th. Returns null. Correct.

        // If today is 28th. futureDay = 33.
        // Logic: Check if futureDay > 28... if futureDay > lastDayOfMonth (e.g. 31)...
        // If we are really at end of month, let's skip to avoid flaky test on specific days.
        print('Skipping "not due" test due to end of month proximity');
        return;
      }

      final card = CreditCard(
        id: const Uuid().v4(),
        cardName: 'Test Card Future',
        bankName: 'Test Bank',
        last4Digits: '5678',
        creditLimit: 10000,
        statementDay: futureDay,
        dueDateOffset: 10,
        monthlyInterestRate: 2.0,
        lateInterestRate: 2.5,
        cardColor: 0xFF000000,
        initialDebt: 0,
        createdAt: now.subtract(const Duration(days: 60)),
      );
      await cardRepo.save(card);

      // Act
      await generator.checkAndGenerateStatements();

      // Assert
      final statements = await statementRepo.findByCardId(card.id);
      expect(
        statements,
        isEmpty,
        reason: 'Statement should NOT be generated for future date',
      );
    },
  );
}
