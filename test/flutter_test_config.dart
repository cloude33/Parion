import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'test_setup.dart';

/// Global test configuration that runs before all tests and after all tests complete.
/// This file is automatically detected by Flutter test framework.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Initialize test environment before any test runs
  await TestSetup.initializeTestEnvironment();
  
  // Run all tests
  await testMain();
  
  // Cleanup after all tests complete
  await TestSetup.cleanupTestEnvironment();
}
