import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../models/model_info.dart';
import 'field_builder.dart' as fb;

/// Builds schema functions using code_builder
class SchemaBuilder {
  final _fieldBuilder = fb.FieldBuilder();
  final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  String build(ModelInfo model, [String? sourceFileName]) {
    final schemaField = buildSchemaField(model);

    final library = Library((b) => b
      ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..directives.addAll([
        Directive.import('package:ack/ack.dart'),
      ])
      ..body.add(schemaField));

    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    return _formatter.format('${library.accept(emitter)}');
  }

  Field buildSchemaField(ModelInfo model) {
    // Convert schema class name to camelCase variable name
    // e.g., "UserSchema" -> "userSchema", "CustomUserSchema" -> "customUserSchema"
    final variableName = _toCamelCase(model.schemaClassName);

    return Field((b) => b
      ..name = variableName
      ..modifier = FieldModifier.final$
      ..assignment = Code(_buildSchemaDefinition(model))
      ..docs.addAll([
        '/// Generated schema for ${model.className}',
        if (model.description != null) '/// ${model.description}',
      ]));
  }

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toLowerCase() + text.substring(1);
  }

  String _buildSchemaDefinition(ModelInfo model) {
    // Check if this is a discriminated base class
    if (model.isDiscriminatedBase && model.subtypes != null) {
      return _buildDiscriminatedSchema(model);
    }

    // Check if this is a discriminated subtype
    if (model.isDiscriminatedSubtype) {
      return _buildSubtypeSchema(model);
    }

    // Regular object schema
    return _buildRegularObjectSchema(model);
  }

  /// Builds a discriminated schema for base classes
  String _buildDiscriminatedSchema(ModelInfo model) {
    final buffer = StringBuffer();
    final discriminatorKey = model.discriminatorKey!;
    final subtypes = model.subtypes!;

    buffer.write('Ack.discriminated(\n');
    buffer.write('  discriminatorKey: \'$discriminatorKey\',\n');
    buffer.write('  schemas: {\n');

    // Generate schema references for each subtype
    final schemaRefs = <String>[];
    for (final entry in subtypes.entries) {
      final discriminatorValue = entry.key;
      final subtypeElement = entry.value;
      final subtypeSchemaName = _toCamelCase('${subtypeElement.name}Schema');

      schemaRefs.add('    \'$discriminatorValue\': $subtypeSchemaName');
    }

    buffer.write(schemaRefs.join(',\n'));
    buffer.write('\n  },\n');
    buffer.write(')');

    return buffer.toString();
  }

  /// Builds a regular object schema for subtypes (with literal discriminator field)
  String _buildSubtypeSchema(ModelInfo model) {
    final buffer = StringBuffer();

    // Build field definitions with descriptions
    final fieldDefs = <String>[];
    for (final field in model.fields) {
      final fieldSchema = _fieldBuilder.buildFieldSchema(field, model);

      // Add description comment if available
      if (field.description != null && field.description!.isNotEmpty) {
        fieldDefs.add(
            '// ${field.description}\n  \'${field.jsonKey}\': $fieldSchema');
      } else {
        fieldDefs.add("'${field.jsonKey}': $fieldSchema");
      }
    }

    buffer.write('Ack.object({');
    if (fieldDefs.isNotEmpty) {
      buffer.write('\n  ');
      buffer.write(fieldDefs.join(',\n  '));
      buffer.write(',\n');
    }
    buffer.write('}');

    // Add additionalProperties if enabled
    if (model.additionalProperties) {
      buffer.write(', additionalProperties: true');
    }

    buffer.write(')');

    return buffer.toString();
  }

  /// Builds a regular object schema for non-discriminated models
  String _buildRegularObjectSchema(ModelInfo model) {
    final buffer = StringBuffer();

    // Build field definitions with descriptions
    final fieldDefs = <String>[];
    for (final field in model.fields) {
      final fieldSchema = _fieldBuilder.buildFieldSchema(field);

      // Add description comment if available
      if (field.description != null && field.description!.isNotEmpty) {
        fieldDefs.add(
            '// ${field.description}\n  \'${field.jsonKey}\': $fieldSchema');
      } else {
        fieldDefs.add("'${field.jsonKey}': $fieldSchema");
      }
    }

    buffer.write('Ack.object({');
    if (fieldDefs.isNotEmpty) {
      buffer.write('\n  ');
      buffer.write(fieldDefs.join(',\n  '));
      buffer.write(',\n');
    }
    buffer.write('}');

    // Add additionalProperties if enabled
    if (model.additionalProperties) {
      buffer.write(', additionalProperties: true');
    }

    buffer.write(')');

    return buffer.toString();
  }
}
