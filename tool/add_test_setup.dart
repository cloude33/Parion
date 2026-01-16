// ignore_for_file: unused_import
/// This script adds TestSetup to all test files that don't have it
import 'dart:io';

void main() async {
  final testDir = Directory('test');
  var updatedCount = 0;
  var skippedCount = 0;

  await for (final entity in testDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('_test.dart')) {
      final content = await entity.readAsString();

      // Skip if already has test_setup import
      if (content.contains("import '../test_setup.dart'") ||
          content.contains("import 'test_setup.dart'") ||
          content.contains('test_setup.dart')) {
        skippedCount++;
        continue;
      }

      // Skip flutter_test_config.dart and test_setup.dart itself
      if (entity.path.contains('flutter_test_config.dart') ||
          entity.path.contains('test_setup.dart') ||
          entity.path.contains('test_config.dart') ||
          entity.path.contains('test_helpers.dart')) {
        skippedCount++;
        continue;
      }

      // Calculate relative path to test_setup.dart
      final pathFromTest = entity.path
          .replaceFirst('test\\', '')
          .replaceFirst('test/', '');
      final depth = pathFromTest.split(RegExp(r'[/\\]')).length - 1;
      final relativePath = depth == 0
          ? 'test_setup.dart'
          : '${'../' * depth}test_setup.dart';

      // Find the last import statement
      final importPattern = RegExp(r"import\s+'[^']+';", multiLine: true);
      final matches = importPattern.allMatches(content).toList();

      if (matches.isEmpty) {
        print('No imports found in: ${entity.path}');
        skippedCount++;
        continue;
      }

      final lastImport = matches.last;
      final lastImportEnd = lastImport.end;

      // Check if main() exists
      if (!content.contains('void main()')) {
        print('No main() found in: ${entity.path}');
        skippedCount++;
        continue;
      }

      // Add import after last import
      var newContent =
          '${content.substring(0, lastImportEnd)}\nimport \'$relativePath\';${content.substring(lastImportEnd)}';

      // Check if setUpAll already exists
      if (!newContent.contains('setUpAll(')) {
        // Find 'void main() {' and add setUpAll after it
        final mainPattern = RegExp(r'void main\(\)\s*\{');
        final mainMatch = mainPattern.firstMatch(newContent);

        if (mainMatch != null) {
          final insertPosition = mainMatch.end;
          final setupCode = '''

  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });
''';
          newContent =
              newContent.substring(0, insertPosition) +
              setupCode +
              newContent.substring(insertPosition);
        }
      }

      await entity.writeAsString(newContent);
      updatedCount++;
      print('Updated: ${entity.path}');
    }
  }

  print('\n===== Summary =====');
  print('Updated: $updatedCount files');
  print('Skipped: $skippedCount files');
}
