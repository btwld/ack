import 'dart:io';

void main() async {
  print('# Ack Schema Library - Complete Source Code\n');
  print('Generated on: ${DateTime.now().toIso8601String()}\n');
  print('---\n');

  // Define the schema library structure
  final schemaFiles = [
    // Core schema file
    'packages/ack/lib/src/schemas/schema.dart',

    // Individual schema implementations (part files)
    'packages/ack/lib/src/schemas/any_of_schema.dart',
    'packages/ack/lib/src/schemas/any_schema.dart',
    'packages/ack/lib/src/schemas/boolean_schema.dart',
    'packages/ack/lib/src/schemas/discriminated_object_schema.dart',
    'packages/ack/lib/src/schemas/enum_schema.dart',
    'packages/ack/lib/src/schemas/fluent_schema.dart',
    'packages/ack/lib/src/schemas/list_schema.dart',
    'packages/ack/lib/src/schemas/num_schema.dart',
    'packages/ack/lib/src/schemas/object_schema.dart',
    'packages/ack/lib/src/schemas/optional_schema.dart',
    'packages/ack/lib/src/schemas/string_schema.dart',
    'packages/ack/lib/src/schemas/transformed_schema.dart',

    // Schema extensions
    'packages/ack/lib/src/schemas/extensions/ack_schema_extensions.dart',
    'packages/ack/lib/src/schemas/extensions/boolean_schema_extensions.dart',
    'packages/ack/lib/src/schemas/extensions/list_schema_extensions.dart',
    'packages/ack/lib/src/schemas/extensions/num_schema_extensions.dart',
    'packages/ack/lib/src/schemas/extensions/object_schema_extensions.dart',
    'packages/ack/lib/src/schemas/extensions/string_schema_extensions.dart',

    // Validation components
    'packages/ack/lib/src/validation/schema_result.dart',
    'packages/ack/lib/src/validation/schema_error.dart',
    'packages/ack/lib/src/validation/ack_exception.dart',

    // Context
    'packages/ack/lib/src/context.dart',

    // Schema model
    'packages/ack/lib/src/schema_model.dart',

    // Constraints
    'packages/ack/lib/src/constraints/constraint.dart',
    'packages/ack/lib/src/constraints/validators.dart',

    // Core constraints
    'packages/ack/lib/src/constraints/core/comparison_constraint.dart',
    'packages/ack/lib/src/constraints/core/enum_constraint.dart',
    'packages/ack/lib/src/constraints/core/is_finite_constraint.dart',
    'packages/ack/lib/src/constraints/core/is_negative_constraint.dart',
    'packages/ack/lib/src/constraints/core/is_positive_constraint.dart',
    'packages/ack/lib/src/constraints/core/literal_constraint.dart',
    'packages/ack/lib/src/constraints/core/pattern_constraint.dart',
    'packages/ack/lib/src/constraints/core/range_constraint.dart',
    'packages/ack/lib/src/constraints/core/unique_items_constraint.dart',

    // String constraints
    'packages/ack/lib/src/constraints/string/format_constraint.dart',
    'packages/ack/lib/src/constraints/string/string_enum_constraint.dart',

    // Helpers
    'packages/ack/lib/src/helpers.dart',

    // Main Ack factory
    'packages/ack/lib/src/ack.dart',

    // Main export file
    'packages/ack/lib/ack.dart',
  ];

  for (final filePath in schemaFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('## ⚠️ File not found: $filePath\n');
      continue;
    }

    print('## File: `$filePath`\n');
    print('```dart');

    try {
      final content = await file.readAsString();
      print(content);
    } catch (e) {
      print('// Error reading file: $e');
    }

    print('```\n');
  }

  print('---\n');
  print('## Summary\n');
  print('Total files extracted: ${schemaFiles.length}\n');
  print('This extraction includes the complete Ack schema validation library with:');
  print('- Core schema implementations');
  print('- Schema extensions for fluent API');
  print('- Validation and error handling');
  print('- Constraint system');
  print('- Context management');
  print('- Helper utilities\n');
}