#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

const ackPackages = ['ack', 'ack_generator'];

Future<void> main(List<String> args) async {
  // Parse arguments
  String? packageName;
  String? version;

  if (args.isNotEmpty) {
    // Check if first argument is a version (starts with v or is a number)
    final firstArg = args[0];
    if (firstArg.startsWith('v') || RegExp(r'^\d+\.\d+').hasMatch(firstArg)) {
      // First argument is a version, check all packages
      version = firstArg;
    } else if (ackPackages.contains(firstArg)) {
      // First argument is a package name
      packageName = firstArg;
      if (args.length > 1) {
        version = args[1];
      }
    } else {
      print(
        '❌ Invalid package name. Available packages: ${ackPackages.join(', ')}',
      );
      printUsage();
      exit(1);
    }
  }

  // If no version provided, get latest from pub.dev
  if (version == null) {
    if (packageName != null) {
      version = await getLatestVersion(packageName);
    } else {
      print('❌ Please specify a version when checking all packages');
      printUsage();
      exit(1);
    }
  }

  // Remove 'v' prefix if present
  final cleanVersion = version.startsWith('v') ? version.substring(1) : version;

  print('🚀 API Compatibility Check vs $version');

  // Activate dart_apitool
  await runCommand('dart', ['pub', 'global', 'activate', 'dart_apitool']);

  // Check packages
  final packagesToCheck = packageName != null ? [packageName] : ackPackages;
  final reports = <String>[];

  for (final pkg in packagesToCheck) {
    await checkPackage(pkg, cleanVersion, version, reports);
  }

  // Print summary
  print('');
  print('🎯 API compatibility check completed!');
  print('📂 Reports saved in project root:');
  for (final report in reports) {
    print('   • $report');
  }
}

Future<String> getLatestVersion(String packageName) async {
  try {
    final result = await Process.run('curl', [
      '-s',
      'https://pub.dev/api/packages/$packageName',
    ]);

    if (result.exitCode == 0) {
      final json = jsonDecode(result.stdout);
      return json['latest']['version'];
    }
  } catch (e) {
    print(
      '⚠️  Could not fetch latest version for $packageName, please specify version manually',
    );
  }

  exit(1);
}

Future<void> checkPackage(
  String packageName,
  String cleanVersion,
  String displayVersion,
  List<String> reports,
) async {
  print('📦 Checking $packageName package...');

  final reportFile = 'api-compat-$packageName-vs-$displayVersion.md';
  reports.add(reportFile);

  final result = await Process.run('dart-apitool', [
    'diff',
    '--old',
    'pub://$packageName/$cleanVersion',
    '--new',
    './packages/$packageName',
    '--report-format',
    'markdown',
    '--report-file-path',
    reportFile,
    '--ignore-prerelease',
  ]);

  if (result.exitCode == 0) {
    print('✅ $packageName: API check completed');
  } else {
    print('⚠️  $packageName: API changes detected');
  }

  print('📄 Report saved: $reportFile');
}

Future<void> runCommand(String command, List<String> args) async {
  final result = await Process.run(command, args);
  if (result.exitCode != 0) {
    print('Error running $command ${args.join(' ')}');
    print(result.stderr);
  }
}

void printUsage() {
  print('');
  print('Usage: dart scripts/api_check.dart [PACKAGE] [VERSION]');
  print('');
  print('Arguments:');
  print('  PACKAGE  Package to check (${ackPackages.join('|')})');
  print('           If not provided, checks all packages');
  print('  VERSION  Version to compare against (e.g., v0.2.0 or 0.2.0)');
  print(
    '           If not provided with single package, uses latest from pub.dev',
  );
  print('');
  print('Examples:');
  print(
    '  dart scripts/api_check.dart ack                    # Check ack against latest',
  );
  print(
    '  dart scripts/api_check.dart ack v0.2.0            # Check ack against v0.2.0',
  );
  print(
    '  dart scripts/api_check.dart v0.2.0                # Check all packages against v0.2.0',
  );
  print('');
  print('Melos usage:');
  print('  melos api-check ack v0.2.0');
  print('  melos api-check v0.2.0');
}
