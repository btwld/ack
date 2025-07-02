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
    final buffer = StringBuffer();

    // Build field definitions
    final fieldDefs = <String>[];
    for (final field in model.fields) {
      final fieldSchema = _fieldBuilder.buildFieldSchema(field);
      fieldDefs.add("'${field.jsonKey}': $fieldSchema");
    }

    buffer.write('Ack.object({');
    buffer.write(fieldDefs.join(', '));
    buffer.write('}');

    // Add required fields if any
    if (model.requiredFields.isNotEmpty) {
      final requiredList = model.requiredFields.map((f) => "'$f'").join(', ');
      buffer.write(', required: [$requiredList]');
    }
    
    // Debug: Always add required to see what's happening
    // print('DEBUG: model.requiredFields = ${model.requiredFields}');

    // Add additionalProperties if enabled
    if (model.additionalProperties) {
      buffer.write(', additionalProperties: true');
    }

    buffer.write(')');

    return buffer.toString();
  }
}
