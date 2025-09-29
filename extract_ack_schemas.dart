import 'dart:io';

void main() async {
  // Output file
  final outputFile = File('context.local.md');
  final buffer = StringBuffer();

  buffer.writeln('# Ack Schema Library - Complete Source Code\n');
  buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}\n');
  buffer.writeln('---\n');

  // Get all Dart files from packages/ack/lib directory
  final libDir = Directory('packages/ack/lib');
  if (!libDir.existsSync()) {
    print('❌ Directory not found: packages/ack/lib');
    exit(1);
  }

  // Recursively find all .dart files
  final dartFiles = <File>[];
  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      dartFiles.add(entity);
    }
  }

  // Sort files by path for consistent output
  dartFiles.sort((a, b) => a.path.compareTo(b.path));

  // Process each file
  int processedCount = 0;
  for (final file in dartFiles) {
    // Get relative path from packages/ack/lib
    final relativePath = file.path;

    buffer.writeln('## File: `$relativePath`\n');
    buffer.writeln('```dart');

    try {
      final content = await file.readAsString();
      buffer.write(content);
      processedCount++;
    } catch (e) {
      buffer.writeln('// Error reading file: $e');
    }

    buffer.writeln('```\n');
  }

  buffer.writeln('---\n');
  buffer.writeln('## Summary\n');
  buffer.writeln('Total files extracted: $processedCount\n');
  buffer.writeln('This extraction includes the complete Ack schema validation library with:');
  buffer.writeln('- Core schema implementations');
  buffer.writeln('- Schema extensions for fluent API');
  buffer.writeln('- Validation and error handling');
  buffer.writeln('- Constraint system');
  buffer.writeln('- Context management');
  buffer.writeln('- Helper utilities\n');

  // Write to file
  await outputFile.writeAsString(buffer.toString());
  print('✅ Context extracted to context.local.md ($processedCount files)');
}