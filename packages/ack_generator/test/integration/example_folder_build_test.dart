import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Integration test that verifies the example folder builds correctly
/// and has no analyze errors. This acts as a golden test to ensure
/// the generated code remains valid and analyzer-clean.
void main() {
  group('Example Folder Build Integration', () {
    late Directory projectRoot;
    late Directory exampleDir;

    setUpAll(() {
      // Find project root (go up from test directory)
      var current = Directory.current;

      while (current.path.contains('packages')) {
        current = current.parent;
      }
      projectRoot = current;
      exampleDir = Directory(p.join(projectRoot.path, 'example'));
    });

    test(
      'example folder should build successfully with build_runner',
      () async {
        // Clean previous builds
        final cleanResult = await Process.run('dart', [
          'run',
          'build_runner',
          'clean',
        ], workingDirectory: exampleDir.path);

        expect(
          cleanResult.exitCode,
          0,
          reason:
              'build_runner clean should succeed\n'
              'STDOUT: ${cleanResult.stdout}\n'
              'STDERR: ${cleanResult.stderr}',
        );

        // Run build_runner
        final buildResult = await Process.run('dart', [
          'run',
          'build_runner',
          'build',
          '--delete-conflicting-outputs',
        ], workingDirectory: exampleDir.path);

        expect(
          buildResult.exitCode,
          0,
          reason:
              'build_runner should complete successfully\n'
              'STDOUT: ${buildResult.stdout}\n'
              'STDERR: ${buildResult.stderr}',
        );

        // Verify that generated files were created
        final generatedFiles = exampleDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.g.dart'))
            .toList();

        expect(
          generatedFiles,
          isNotEmpty,
          reason: 'At least one .g.dart file should be generated',
        );

        print('✅ Generated ${generatedFiles.length} files:');
        for (final file in generatedFiles) {
          print('   - ${p.relative(file.path, from: exampleDir.path)}');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('example folder should have no dart analyze errors', () async {
      final analyzeResult = await Process.run('dart', [
        'analyze',
        '--fatal-infos',
      ], workingDirectory: exampleDir.path);

      expect(
        analyzeResult.exitCode,
        0,
        reason:
            'dart analyze should find no issues\n'
            'STDOUT: ${analyzeResult.stdout}\n'
            'STDERR: ${analyzeResult.stderr}',
      );

      print('✅ Example folder passed dart analyze with no issues');
    });

    test('generated files should match expected schema patterns', () async {
      final generatedFiles = exampleDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.g.dart'))
          .toList();

      for (final file in generatedFiles) {
        final content = await file.readAsString();
        final fileName = p.basename(file.path);

        // Verify basic structure
        expect(
          content,
          contains('// GENERATED CODE - DO NOT MODIFY BY HAND'),
          reason: '$fileName should have generation warning',
        );

        // Verify it contains either Ack schema definitions (@AckModel) OR extension types (@AckType)
        final hasSchema = RegExp(r'final \w+Schema = Ack\.').hasMatch(content);
        final hasExtensionType = RegExp(
          r'extension type \w+Type',
        ).hasMatch(content);

        expect(
          hasSchema || hasExtensionType,
          isTrue,
          reason:
              '$fileName should contain either Ack schema definitions or extension types',
        );

        // Verify it's a part file (generated files are parts of the main file)
        expect(
          content,
          matches(RegExp(r"part of '.*\.dart';")),
          reason: '$fileName should be a part file',
        );

        // Verify the corresponding main file exists and imports ack
        final mainFileName = fileName.replaceAll('.g.dart', '.dart');
        final mainFile = File(p.join(p.dirname(file.path), mainFileName));

        expect(
          mainFile.existsSync(),
          isTrue,
          reason: 'Main file $mainFileName should exist for $fileName',
        );

        final mainContent = await mainFile.readAsString();
        expect(
          mainContent,
          contains("import 'package:ack/ack.dart'"),
          reason: 'Main file $mainFileName should import ack package',
        );

        expect(
          mainContent,
          contains("part '$fileName'"),
          reason: 'Main file $mainFileName should include part directive',
        );

        print('✅ $fileName matches expected patterns');
      }
    });

    test('example folder pub get should succeed', () async {
      final pubGetResult = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: exampleDir.path);

      expect(
        pubGetResult.exitCode,
        0,
        reason:
            'dart pub get should succeed\n'
            'STDOUT: ${pubGetResult.stdout}\n'
            'STDERR: ${pubGetResult.stderr}',
      );

      print('✅ Example folder dependencies resolved successfully');
    });
  });
}
