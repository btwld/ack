#!/usr/bin/env dart

import 'dart:io';

import 'package:path/path.dart' as p;

/// Update golden test files by extracting actual generator output.
///
/// **When to use this tool:**
/// - After changing generator code (new features, bug fixes)
/// - When golden tests are failing due to outdated reference files
/// - To see what the current generator produces
///
/// **When NOT to use:**
/// - When tests are already passing (golden files are correct)
/// - When you haven't changed the generator
void main(List<String> args) async {
  final updateAll = args.contains('--all');
  final testNames = args.where((arg) => !arg.startsWith('--')).toList();

  if (!updateAll && testNames.isEmpty) {
    print('🔧 Golden File Updater for ACK Generator');
    print('');
    print(
      'Updates golden test files by extracting actual generator output from test failures.',
    );
    print('');
    print('📋 When to use:');
    print('  ✅ After changing generator code');
    print('  ✅ When golden tests are failing');
    print('  ✅ To see current generator output');
    print('');
    print('❌ When NOT to use:');
    print('  - Tests are already passing');
    print('  - You haven\'t changed anything');
    print('');
    print('Usage:');
    print(
      '  dart tool/update_goldens.dart --all              # Update all golden files',
    );
    print(
      '  dart tool/update_goldens.dart user_schema        # Update specific test',
    );
    print('');
    print('Available tests:');
    print('  - user_schema    (simple schema with basic types)');
    return;
  }

  // Ensure golden directory exists
  final goldenDir = Directory('test/golden');
  if (!await goldenDir.exists()) {
    await goldenDir.create(recursive: true);
    print('📁 Created test/golden directory');
  }

  print('🚀 Auto-updating golden files from test output...');
  print('');

  try {
    if (updateAll || testNames.contains('user_schema')) {
      await _autoUpdateUserSchemaGolden();
    }

    print('');
    print('✅ Golden files auto-updated successfully!');
    print('');
    print('Next steps:');
    print('  1. Run tests: dart test test/golden_test.dart');
    print('  2. Commit the updated golden files if tests pass');
  } catch (e, stackTrace) {
    print('❌ Error auto-updating golden files: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<void> _autoUpdateUserSchemaGolden() async {
  print('🔄 Auto-updating user_schema.dart.golden...');

  try {
    // Run the test and capture the detailed output
    final result = await Process.run('dart', [
      'test',
      'test/golden_test.dart',
      '--plain-name',
      'user schema golden test',
      '--reporter=expanded',
    ], workingDirectory: Directory.current.path);

    final output = result.stdout.toString();

    // Extract the generated content from the test output
    final content = _extractContentFromTestOutput(output);

    if (content != null && content.isNotEmpty) {
      final goldenFile = File(
        p.join('test', 'golden', 'user_schema.dart.golden'),
      );
      await goldenFile.writeAsString(content);
      print('  ✅ Updated ${goldenFile.path}');
      print('  📝 Content length: ${content.length} characters');
    } else {
      print('  ❌ FAILED to extract generator output from test');
      print('  💡 Possible causes:');
      print('     - Test is already passing (golden file is correct)');
      print('     - Test output format has changed');
      print('     - Generator is not producing expected output');
      print(
        '  🔧 Try running: dart test test/golden_test.dart --plain-name "user schema golden test"',
      );
      throw Exception(
        'Failed to extract generator output for user_schema.dart.golden',
      );
    }
  } catch (e) {
    print('  ❌ Error running test: $e');
    rethrow; // Re-throw to fail the script
  }
}

String? _extractContentFromTestOutput(String output) {
  // Look for the actual generated content in the test output
  // The test failure shows the actual content in a specific format

  // Method 1: Look for the content between specific markers
  final lines = output.split('\n');
  final contentLines = <String>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Look for the line that shows the actual content
    if (line.contains('Which: has `utf-8 decoded bytes` with value')) {
      // The content is in the following lines, quoted
      for (int j = i + 1; j < lines.length; j++) {
        final contentLine = lines[j].trim();

        if (contentLine.startsWith("'") && contentLine.endsWith("'")) {
          // Extract content between quotes
          var content = contentLine.substring(1, contentLine.length - 1);
          // Convert escape sequences
          content = content.replaceAll(r'\n', '\n');
          content = content.replaceAll(r"\'", "'");
          content = content.replaceAll(r'\"', '"');
          contentLines.add(content);
        } else if (contentLine.isEmpty ||
            contentLine.contains('Unexpected content') ||
            contentLine.contains('package:')) {
          break;
        }
      }
      break;
    }
  }

  if (contentLines.isNotEmpty) {
    var result = contentLines.join('');
    // Clean up leading newlines but preserve structure
    result = result.replaceAll(RegExp(r'^\n+'), '');
    return result;
  }

  // Method 2: Try regex extraction as fallback
  final regexMatch = RegExp(
    r"'([^']*class UserSchema[^']*)'",
    multiLine: true,
    dotAll: true,
  ).firstMatch(output);

  if (regexMatch != null) {
    var content = regexMatch.group(1) ?? '';
    content = content.replaceAll(r'\n', '\n');
    content = content.replaceAll(r"\'", "'");
    return content.trim();
  }

  return null;
}
