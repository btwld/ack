import 'dart:io';

/// Golden file update tool for ACK Generator
///
/// Usage:
///   dart tool/update_goldens.dart --all              # Update all golden files
///   dart tool/update_goldens.dart user_model         # Update specific test
///   dart tool/update_goldens.dart --help             # Show help
void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _showHelp();
    return;
  }

  final updateAll = args.contains('--all');
  final specificTests = args.where((arg) => !arg.startsWith('--')).toList();

  if (!updateAll && specificTests.isEmpty) {
    print('❌ Error: Please specify --all or provide specific test names');
    print('Run with --help for usage information');
    exit(1);
  }

  print('🔄 Updating golden files...');

  try {
    if (updateAll) {
      await _updateAllGoldenFiles();
    } else {
      await _updateSpecificGoldenFiles(specificTests);
    }

    await _showChanges();
    print('✅ Golden files updated successfully');
  } catch (e) {
    print('❌ Failed to update golden files: $e');
    exit(1);
  }
}

/// Update all golden files
Future<void> _updateAllGoldenFiles() async {
  print('📝 Updating all golden files...');

  final result = await Process.run(
    'dart',
    ['test'],
    environment: {...Platform.environment, 'UPDATE_GOLDEN': 'true'},
    workingDirectory: Directory.current.path,
  );

  if (result.exitCode != 0) {
    print('❌ Failed to update golden files');
    print('STDOUT: ${result.stdout}');
    print('STDERR: ${result.stderr}');
    throw Exception('Test execution failed with exit code ${result.exitCode}');
  }

  print('📄 All golden files updated');
}

/// Update specific golden files
Future<void> _updateSpecificGoldenFiles(List<String> testNames) async {
  print('📝 Updating golden files for: ${testNames.join(', ')}');

  for (final testName in testNames) {
    // Verify the fixture exists
    final fixtureFile = File('test/fixtures/$testName.dart');
    if (!fixtureFile.existsSync()) {
      print('⚠️  Warning: Fixture not found: test/fixtures/$testName.dart');
      continue;
    }

    print('🔄 Updating $testName...');

    // Try different test name patterns to find the right test
    final testPatterns = [
      testName.replaceAll('_', ' '), // Convert underscores to spaces
      'generates correct output for ${testName.replaceAll('_', ' ')}',
      'handles ${testName.replaceAll('_', ' ')}',
      testName,
    ];

    bool success = false;
    for (final pattern in testPatterns) {
      final result = await Process.run(
        'dart',
        ['test', '--name', pattern],
        environment: {...Platform.environment, 'UPDATE_GOLDEN': 'true'},
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode == 0) {
        success = true;
        break;
      }
    }

    if (!success) {
      print('⚠️  Warning: Failed to update $testName - no matching test found');
      continue;
    }

    print('✅ Updated $testName');
  }
}

/// Show git diff of changes
Future<void> _showChanges() async {
  print('\n📊 Checking for changes...');

  // Check if there are any changes in the golden directory
  final statusResult = await Process.run(
    'git',
    ['status', '--porcelain', 'test/golden/'],
    workingDirectory: Directory.current.path,
  );

  if (statusResult.stdout.toString().trim().isEmpty) {
    print('✨ No changes to golden files');
    return;
  }

  // Show detailed diff
  final diffResult = await Process.run(
    'git',
    ['diff', '--stat', 'test/golden/'],
    workingDirectory: Directory.current.path,
  );

  if (diffResult.stdout.toString().trim().isNotEmpty) {
    print('\n📝 Changed files:');
    print(diffResult.stdout);
  }

  // Show which files were modified
  final modifiedFiles = statusResult.stdout
      .toString()
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .map((line) => line.substring(3)) // Remove git status prefix
      .where((file) => file.startsWith('test/golden/'))
      .toList();

  if (modifiedFiles.isNotEmpty) {
    print('\n🔄 Modified golden files:');
    for (final file in modifiedFiles) {
      print('  • $file');
    }
  }
}

/// Show help information
void _showHelp() {
  print('''
🛠️  ACK Generator Golden File Update Tool

USAGE:
  dart tool/update_goldens.dart [OPTIONS] [TEST_NAMES...]

OPTIONS:
  --all, -a     Update all golden files
  --help, -h    Show this help message

EXAMPLES:
  dart tool/update_goldens.dart --all
    Update all golden files

  dart tool/update_goldens.dart user_model
    Update golden file for user_model test

  dart tool/update_goldens.dart user_model product_model
    Update golden files for multiple specific tests

  dart tool/update_goldens.dart deeply_nested_model large_model
    Update golden files for complex scenario tests

NOTES:
  • Test names should match the fixture file names (without .dart extension)
  • The tool will show git diff of changes after updating
  • Use git to review and commit the changes
  • Run 'dart test' after updating to verify all tests pass
''');
}
