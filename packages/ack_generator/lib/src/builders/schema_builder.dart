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
    _fieldBuilder.setAllModels(models);
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
    if (model.isDiscriminatedBaseDefinition) {
      return _buildDiscriminatedSchema(model);
    }

    if (model.isDiscriminatedSubtype) {
      return _buildObjectSchema(model);
    }

    return _buildObjectSchema(model);
  }

  /// Builds a discriminated schema for base classes
  String _buildDiscriminatedSchema(ModelInfo model) {
    final buffer = StringBuffer();
    final discriminatorKey = _resolvedBaseDiscriminatorKey(model);
    final subtypeNames = model.subtypeNames!;

    buffer.write('Ack.discriminated(\n');
    buffer.write('  discriminatorKey: \'$discriminatorKey\',\n');
    buffer.write('  schemas: {\n');

    // Generate schema references for each subtype
    final schemaRefs = <String>[];
    for (final entry in subtypeNames.entries) {
      final discriminatorValue = entry.key;
      final subtypeClassName = entry.value;

      // Look up the subtype's ModelInfo to get its custom schemaClassName
      // This handles cases where the subtype has a custom schemaName annotation
      final subtypeModelInfo = _allModels.cast<ModelInfo?>().firstWhere(
        (m) => m?.className == subtypeClassName,
        orElse: () => null,
      );

      // Use the subtype's schemaClassName if found, otherwise fall back to default
      final subtypeSchemaName = subtypeModelInfo != null
          ? _toCamelCase(subtypeModelInfo.schemaClassName)
          : _toCamelCase('${subtypeClassName}Schema');

      schemaRefs.add('    \'$discriminatorValue\': $subtypeSchemaName');
    }

    buffer.write(schemaRefs.join(',\n'));
    buffer.write('\n  },\n');
    buffer.write(')');

    return buffer.toString();
  }

  String _resolvedBaseDiscriminatorKey(ModelInfo model) {
    final declaredKey = model.discriminatorKey!;
    final subtypeNames = model.subtypeNames;
    if (subtypeNames == null || subtypeNames.isEmpty) {
      return declaredKey;
    }

    final subtypeKeys = <String>{};
    for (final subtypeName in subtypeNames.values) {
      final subtypeModel = _allModels.cast<ModelInfo?>().firstWhere(
        (candidate) =>
            candidate?.className == subtypeName ||
            candidate?.schemaClassName == subtypeName,
        orElse: () => null,
      );
      if (subtypeModel == null ||
          !subtypeModel.isDiscriminatedSubtype ||
          subtypeModel.discriminatorKey != declaredKey) {
        continue;
      }
      subtypeKeys.add(_resolvedSubtypeDiscriminatorKey(subtypeModel));
    }

    if (subtypeKeys.length == 1) {
      return subtypeKeys.single;
    }

    return declaredKey;
  }

  String _resolvedSubtypeDiscriminatorKey(ModelInfo model) {
    final declaredKey = model.discriminatorKey;
    if (declaredKey == null) {
      return '';
    }

    final byJsonKey = model.fields.any((field) => field.jsonKey == declaredKey);
    if (byJsonKey) {
      return declaredKey;
    }

    for (final field in model.fields) {
      if (field.name == declaredKey) {
        return field.jsonKey;
      }
    }

    return declaredKey;
  }

  /// Common logic for building object schemas
  ///
  /// Extracted from _buildSubtypeSchema and _buildRegularObjectSchema to eliminate duplication.
  /// The only difference is whether the model is passed to the field builder (for subtypes).
  String _buildObjectSchema(ModelInfo model) {
    final buffer = StringBuffer();

    // Build field definitions with descriptions
    final fieldDefs = <String>[];

    // For discriminated subtypes, add the discriminator field first
    final discriminatorJsonKey = model.isDiscriminatedSubtype
        ? _resolvedSubtypeDiscriminatorKey(model)
        : null;
    if (model.isDiscriminatedSubtype &&
        discriminatorJsonKey != null &&
        discriminatorJsonKey.isNotEmpty &&
        model.discriminatorValue != null) {
      fieldDefs.add(
        "'$discriminatorJsonKey': Ack.literal('${model.discriminatorValue}')",
      );
    }

    for (final field in model.fields) {
      // Skip the discriminator field for subtypes - it was already added above
      // This prevents duplicate keys in the generated schema
      if (model.isDiscriminatedSubtype &&
          discriminatorJsonKey != null &&
          field.jsonKey == discriminatorJsonKey) {
        continue;
      }

      final fieldSchema = _fieldBuilder.buildFieldSchema(field, model);

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
