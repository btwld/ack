#!/usr/bin/env dart

import 'dart:io';

Future<void> main() async {
  final ackPackageDir = Directory('packages/ack/lib');
  final outputFile = File('ack_package_consolidated.md');
  
  if (!await ackPackageDir.exists()) {
    print('Error: packages/ack/lib directory not found');
    exit(1);
  }
  
  final buffer = StringBuffer();
  buffer.writeln('# Ack Package - All Dart Files\n');
  buffer.writeln('This document contains all Dart source files from the ack package.\n');
  
  await _processDirectory(ackPackageDir, buffer, 'packages/ack/lib');
  
  await outputFile.writeAsString(buffer.toString());
  print('✅ Created ack_package_consolidated.md with all Dart files from the ack package');
}

Future<void> _processDirectory(Directory dir, StringBuffer buffer, String basePath) async {
  final entities = await dir.list().toList();
  entities.sort((a, b) => a.path.compareTo(b.path));
  
  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final relativePath = entity.path.substring(entity.path.indexOf(basePath));
      final fileName = entity.path.split('/').last;
      
      buffer.writeln('## $fileName');
      buffer.writeln('**Path:** `$relativePath`\n');
      buffer.writeln('```dart');
      
      try {
        final content = await entity.readAsString();
        buffer.writeln(content);
      } catch (e) {
        buffer.writeln('// Error reading file: $e');
      }
      
      buffer.writeln('```\n');
    } else if (entity is Directory) {
      await _processDirectory(entity, buffer, basePath);
    }
  }
}