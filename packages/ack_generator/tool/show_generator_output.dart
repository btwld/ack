#!/usr/bin/env dart

import 'dart:io';

/// Simple tool to show the actual generator output by running tests
void main(List<String> args) async {
  final testName = args.isNotEmpty ? args[0] : 'user_schema';

  print('🔍 Showing generator output for: $testName');
  print('=' * 60);

  if (testName == 'user_schema' || testName == 'user') {
    await _showGeneratorOutput('user schema golden test');
  } else if (testName == 'order_schema' || testName == 'order') {
    print(
        'ℹ️  Order schema test uses pattern matching, not golden file comparison');
    print(
        '   Run: dart test test/golden_test.dart --plain-name "complex nested schema golden test"');
  } else {
    print('❌ Unknown test: $testName');
    print('Available tests: user_schema, order_schema');
    exit(1);
  }
}

Future<void> _showGeneratorOutput(String testName) async {
  print('📝 Running test to extract generator output...');
  print('-' * 40);

  try {
    // Run the specific golden test and capture its output
    final result = await Process.run(
      'dart',
      [
        'test',
        'test/golden_test.dart',
        '--plain-name',
        testName,
        '--reporter=expanded'
      ],
      workingDirectory: Directory.current.path,
    );

    final output = result.stdout.toString();

    // Look for the actual generated content in the test output
    // The test output shows the actual bytes, we need to extract the readable content
    final lines = output.split('\n');
    bool foundActualContent = false;
    final contentLines = <String>[];

    for (final line in lines) {
      if (line.contains('Which: has `utf-8 decoded bytes` with value')) {
        foundActualContent = true;
        continue;
      }

      if (foundActualContent) {
        if (line.trim().startsWith("'") && line.trim().endsWith("'")) {
          // Extract content between quotes and convert escape sequences
          var content = line.trim();
          content = content.substring(1, content.length - 1); // Remove quotes
          content = content.replaceAll(r'\n', '\n');
          content = content.replaceAll(r"\'", "'");
          contentLines.add(content);
        } else if (line.trim().isEmpty || line.contains('Unexpected content')) {
          break;
        }
      }
    }

    if (contentLines.isNotEmpty) {
      print('✅ Generated Code:');
      print('=' * 60);
      final generatedCode = contentLines.join('');
      print(generatedCode);
      print('=' * 60);
    } else {
      print('❌ Could not extract generator output from test failure');
      print('Raw test output:');
      print(output);
    }
  } catch (e) {
    print('❌ Error running test: $e');
  }
}
