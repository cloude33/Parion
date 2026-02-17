import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/services_export.dart';
import 'package:parion/models/models_export.dart';

void main() {
  test('Verify imports work', () {
    // This test just verifies that the imports are resolvable
    expect(BackupService, isNotNull);
    expect(FirebaseAuthService, isNotNull);
    expect(DataService, isNotNull);
    expect(AutoBackupService, isNotNull);
    expect(Transaction, isNotNull);
    expect(Wallet, isNotNull);
  });
}