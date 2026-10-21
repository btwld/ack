#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import 'src/workspace_packages.dart';

final ackPackages = publishableAckPackages;
const dartApiToolVersion = '0.23.0';

Future<void> main(List<String> args) async {
  final inputs = [...args];
  final allowAdditive = inputs.remove('--allow-additive');
  if (inputs.length > 2 || inputs.any((arg) => arg.startsWith('--'))) {
    stderr.writeln('❌ Unexpected API check argument.');
    printUsage();
    exitCode = 64;
    return;
  }

  // Parse arguments
  String? packageName;
  String? version;

  if (inputs.isNotEmpty) {
    // Check if first argument is a version (starts with v or is a number)
    final firstArg = inputs[0];
    if (firstArg.startsWith('v') || RegExp(r'^\d+\.\d+').hasMatch(firstArg)) {
      // First argument is a version, check all packages
      version = firstArg;
    } else if (ackPackages.contains(firstArg)) {
      // First argument is a package name
      packageName = firstArg;
      if (inputs.length > 1) {
        version = inputs[1];
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

  final requestedPackages = packageName != null ? [packageName] : ackPackages;
  final baseline = Version.parse(cleanVersion);
  final packagesToCheck = requestedPackages.where((package) {
    final firstRelease = ackPackageFirstReleases[package];
    if (firstRelease != null && baseline < Version.parse(firstRelease)) {
      print(
        'Skipping $package: $package first releases in $firstRelease; '
        'no API exists at baseline $cleanVersion.',
      );
      return false;
    }
    return true;
  }).toList();
  if (packagesToCheck.isEmpty) return;

  // Activate dart_apitool
  final activated = await runCommand('dart', [
    'pub',
    'global',
    'activate',
    'dart_apitool',
    dartApiToolVersion,
  ]);
  if (!activated) {
    stderr.writeln('❌ Unable to activate dart_apitool.');
    exitCode = 1;
    return;
  }

  // Check packages
  final reports = <String>[];
  var hasFailures = false;

  for (final pkg in packagesToCheck) {
    if (!await checkPackage(
      pkg,
      cleanVersion,
      version,
      reports,
      allowAdditive: allowAdditive,
    )) {
      hasFailures = true;
    }
  }

  // Print summary
  print('');
  print(
    hasFailures
        ? '❌ API compatibility check found changes or errors.'
        : '🎯 API compatibility check completed!',
  );
  print('📂 Reports saved in project root:');
  for (final report in reports) {
    print('   • $report');
  }
  if (hasFailures) exitCode = 1;
}

Future<String> getLatestVersion(String packageName) async {
  try {
    final result = await Process.run('curl', [
      '-s',
      'https://pub.dev/api/packages/$packageName',
    ]);

    if (result.exitCode == 0) {
      final decoded = jsonDecode(result.stdout);
      if (decoded is Map) {
        final latest = decoded['latest'];
        if (latest is Map) {
          final latestVersion = latest['version'];
          if (latestVersion is String) return latestVersion;
        }
      }
    }
  } catch (e) {
    stderr.writeln('Could not fetch the latest $packageName version: $e');
  }

  stderr.writeln(
    'Could not fetch the latest version for $packageName; specify one explicitly.',
  );
  exit(1);
}

Future<bool> checkPackage(
  String packageName,
  String cleanVersion,
  String displayVersion,
  List<String> reports, {
  required bool allowAdditive,
}) async {
  print('📦 Checking $packageName package...');

  final reportFile = 'api-compat-$packageName-vs-$displayVersion.md';
  final report = File(reportFile);
  try {
    if (report.existsSync()) report.deleteSync();
  } on FileSystemException catch (error) {
    stderr.writeln('❌ $packageName: Could not replace $reportFile: $error');
    return false;
  }

  final ProcessResult result;
  try {
    result = await Process.run('dart', [
      'pub',
      'global',
      'run',
      'dart_apitool:main',
      'diff',
      '--old',
      'pub://$packageName/$cleanVersion',
      '--new',
      './packages/$packageName',
      if (allowAdditive) ...['--version-check-mode', 'onlyBreakingChanges'],
      '--report-format',
      'markdown',
      '--report-file-path',
      reportFile,
      '--ignore-prerelease',
    ]);
  } on ProcessException catch (error) {
    stderr.writeln('❌ $packageName: Could not run dart_apitool: $error');
    return false;
  }

  if (result.exitCode == 0) {
    print('✅ $packageName: API check completed');
  } else {
    stderr.writeln('❌ $packageName: API changes detected or check failed');
    _writeProcessStderr(result);
  }

  final reportExists = report.existsSync();
  if (reportExists) {
    reports.add(reportFile);
    print('📄 Report saved: $reportFile');
  } else if (result.exitCode == 0) {
    stderr.writeln('❌ $packageName: dart_apitool did not create $reportFile');
  }
  return result.exitCode == 0 && reportExists;
}

Future<bool> runCommand(String command, List<String> args) async {
  try {
    final result = await Process.run(command, args);
    if (result.exitCode == 0) return true;

    stderr.writeln('Error running $command ${args.join(' ')}');
    _writeProcessStderr(result);
  } on ProcessException catch (error) {
    stderr.writeln('Error running $command ${args.join(' ')}: $error');
  }
  return false;
}

void _writeProcessStderr(ProcessResult result) {
  if ((result.stderr as String).isNotEmpty) {
    stderr.writeln(result.stderr);
  }
}

void printUsage() {
  print('');
  print('Usage: dart scripts/api_check.dart [PACKAGE] [VERSION]');
  print('       dart scripts/api_check.dart [VERSION] --allow-additive');
  print('');
  print('Arguments:');
  print('  PACKAGE  Package to check (${ackPackages.join('|')})');
  print('           If not provided, checks all packages');
  print('  VERSION  Version to compare against (e.g., v1.1.0 or 1.1.0)');
  print(
    '           If not provided with single package, uses latest from pub.dev',
  );
  print('  --allow-additive  Accept additions before a release version bump.');
  print('');
  print('Examples:');
  print(
    '  dart scripts/api_check.dart ack                    # Check ack against latest',
  );
  print(
    '  dart scripts/api_check.dart ack v1.1.0            # Check ack against v1.1.0',
  );
  print(
    '  dart scripts/api_check.dart v1.1.0                # Check all packages against v1.1.0',
  );
  print('');
  print('Melos usage:');
  print('  dart run melos run api-check -- ack v1.1.0');
  print('  dart run melos run api-check -- v1.1.0');
}
