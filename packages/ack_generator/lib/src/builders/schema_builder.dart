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

  /// All models in the current compilation unit, used to look up
  /// custom schemaClassNames for discriminated subtypes
  List<ModelInfo> _allModels = [];

  /// Sets the list of all models for cross-referencing subtype schemas
  void setAllModels(List<ModelInfo> models) {
    _allModels = models;
  }

  String build(ModelInfo model, [String? sourceFileName]) {
    final schemaField = buildSchemaField(model);

    final library = Library(
      (b) => b
        ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
        ..directives.addAll([Directive.import('package:ack/ack.dart')])
        ..body.add(schemaField),
    );

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

    return Field(
      (b) => b
        ..name = variableName
        ..modifier = FieldModifier.final$
        ..assignment = Code(_buildSchemaDefinition(model))
        ..docs.addAll([
          '/// Generated schema for ${model.className}',
          if (model.description != null) '/// ${model.description}',
        ]),
    );
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

    // Subtypes need the model passed to the field builder to generate discriminator literals
    if (model.isDiscriminatedSubtype) {
      return _buildObjectSchema(model, passModelToFieldBuilder: true);
    }

    // Regular objects don't need model context
    return _buildObjectSchema(model);
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

      // Look up the subtype's ModelInfo to get its custom schemaClassName
      // This handles cases where the subtype has a custom schemaName annotation
      final subtypeModelInfo = _allModels.cast<ModelInfo?>().firstWhere(
            (m) => m?.className == subtypeElement.name3,
            orElse: () => null,
          );

      // Use the subtype's schemaClassName if found, otherwise fall back to default
      final subtypeSchemaName = subtypeModelInfo != null
          ? _toCamelCase(subtypeModelInfo.schemaClassName)
          : _toCamelCase('${subtypeElement.name3}Schema');

      schemaRefs.add('    \'$discriminatorValue\': $subtypeSchemaName');
    }

    buffer.write(schemaRefs.join(',\n'));
    buffer.write('\n  },\n');
    buffer.write(')');

    return buffer.toString();
  }

  /// Common logic for building object schemas
  ///
  /// Extracted from _buildSubtypeSchema and _buildRegularObjectSchema to eliminate duplication.
  /// The only difference is whether the model is passed to the field builder (for subtypes).
  String _buildObjectSchema(
    ModelInfo model, {
    bool passModelToFieldBuilder = false,
  }) {
    final buffer = StringBuffer();

    // Build field definitions with descriptions
    final fieldDefs = <String>[];

    // For discriminated subtypes, add the discriminator field first
    if (model.isDiscriminatedSubtype &&
        model.discriminatorKey != null &&
        model.discriminatorValue != null) {
      fieldDefs.add(
        "'${model.discriminatorKey}': Ack.literal('${model.discriminatorValue}')",
      );
    }

    for (final field in model.fields) {
      // Skip the discriminator field for subtypes - it was already added above
      // This prevents duplicate keys in the generated schema
      if (model.isDiscriminatedSubtype &&
          model.discriminatorKey != null &&
          field.jsonKey == model.discriminatorKey) {
        continue;
      }

      final fieldSchema = passModelToFieldBuilder
          ? _fieldBuilder.buildFieldSchema(field, model)
          : _fieldBuilder.buildFieldSchema(field);

      fieldDefs.add("'${field.jsonKey}': $fieldSchema");
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
