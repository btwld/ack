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
    final schemaFunction = buildSchemaFunction(model);

    final library = Library((b) => b
      ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..directives.addAll([
        Directive.import('package:ack/ack.dart'),
      ])
      ..body.add(schemaFunction));

    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    return _formatter.format('${library.accept(emitter)}');
  }

  Method buildSchemaFunction(ModelInfo model) {
    // Convert schema class name to camelCase function name
    // e.g., "UserSchema" -> "userSchema", "CustomUserSchema" -> "customUserSchema"
    final functionName = _toCamelCase(model.schemaClassName);
    
    return Method((b) => b
      ..name = functionName
      ..returns = refer('ObjectSchema')
      ..docs.addAll([
        '/// Generated schema for ${model.className}',
        if (model.description != null) '/// ${model.description}',
      ])
      ..body = Code(_buildSchemaBody(model)));
  }
  
  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toLowerCase() + text.substring(1);
  }

  String _buildSchemaBody(ModelInfo model) {
    return 'return ${_buildSchemaDefinition(model)};';
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
