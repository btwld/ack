import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../models/model_info.dart';
import '../utils/annotation_utils.dart';
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
    final schemaVariableName = schemaVariableNameForSchemaClassName(
      model.schemaClassName,
    );

    return Field(
      (b) => b
        ..name = schemaVariableName
        ..modifier = FieldModifier.final$
        ..assignment = Code(_buildSchemaDefinition(model))
        ..docs.addAll([
          '/// Generated schema for ${model.className}',
          if (model.description != null) '/// ${model.description}',
        ]),
    );
  }

  String _buildSchemaDefinition(ModelInfo model) {
    return model.isDiscriminatedBaseDefinition
        ? _buildDiscriminatedSchema(model)
        : _buildObjectSchema(model);
  }

  /// Builds a discriminated schema for base classes
  String _buildDiscriminatedSchema(ModelInfo model) {
    final buffer = StringBuffer();
    final discriminatorKey = model.discriminatorKey!;
    final subtypeNames = model.subtypeNames!;

    buffer.write('Ack.discriminated(\n');
    buffer.write('  discriminatorKey: \'$discriminatorKey\',\n');
    buffer.write('  schemas: {\n');

    final schemaRefs = <String>[];
    for (final entry in subtypeNames.entries) {
      final discriminatorValue = entry.key;
      final subtypeClassName = entry.value;

      final subtypeModelInfo = _allModels.cast<ModelInfo?>().firstWhere(
        (m) => m?.className == subtypeClassName,
        orElse: () => null,
      );

      final subtypeSchemaName = subtypeModelInfo != null
          ? schemaVariableNameForSchemaClassName(
              subtypeModelInfo.schemaClassName,
            )
          : schemaVariableNameForSchemaClassName('${subtypeClassName}Schema');

      schemaRefs.add('    \'$discriminatorValue\': $subtypeSchemaName');
    }

    buffer.write(schemaRefs.join(',\n'));
    buffer.write('\n  },\n');
    buffer.write(')');

    return buffer.toString();
  }

  /// Builds an object schema for both regular models and discriminated leaves.
  String _buildObjectSchema(ModelInfo model) {
    final buffer = StringBuffer();
    final fieldEntries = <String>[];

    if (model.isDiscriminatedSubtype &&
        model.discriminatorKey != null &&
        model.discriminatorValue != null) {
      fieldEntries.add(
        "'${model.discriminatorKey}': Ack.literal('${model.discriminatorValue}')",
      );
    }

    for (final field in model.fields) {
      if (model.isDiscriminatedSubtype &&
          model.discriminatorKey != null &&
          field.jsonKey == model.discriminatorKey) {
        continue;
      }

      final fieldSchema = _fieldBuilder.buildFieldSchema(field, model);

      fieldEntries.add("'${field.jsonKey}': $fieldSchema");
    }

    buffer.write('Ack.object({');
    if (fieldEntries.isNotEmpty) {
      buffer.write('\n  ');
      buffer.write(fieldEntries.join(',\n  '));
      buffer.write(',\n');
    }
    buffer.write('}');

    if (model.additionalProperties) {
      buffer.write(', additionalProperties: true');
    }

    buffer.write(')');

    return buffer.toString();
  }
}
