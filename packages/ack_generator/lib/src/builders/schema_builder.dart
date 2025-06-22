import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';
import 'field_builder.dart' as fb;
import 'method_builder.dart' as mb;

/// Builds schema classes using code_builder
class SchemaBuilder {
  final _methodBuilder = mb.MethodBuilder();
  final _fieldBuilder = fb.FieldBuilder();
  final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  String build(ModelInfo model, [String? sourceFileName]) {
    final schemaClass = buildClass(model);

    final library = Library((b) => b
      ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..directives.addAll([
        Directive.import('package:ack/ack.dart'),
        Directive.import('package:meta/meta.dart'),
      ])
      ..body.add(schemaClass));

    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    return _formatter.format('${library.accept(emitter)}');
  }

  Class buildClass(ModelInfo model) {
    return Class((b) => b
      ..name = model.schemaClassName
      ..extend = refer('SchemaModel', 'package:ack/ack.dart')
      ..docs.addAll([
        '/// Generated schema for ${model.className}',
        if (model.description != null) '/// ${model.description}',
      ])
      ..constructors.addAll(_buildConstructors(model))
      ..methods.addAll(_buildMethods(model))
      ..fields.add(_buildDefinitionField(model))
      ..methods.addAll(_buildPropertyGetters(model)));
  }

  List<Constructor> _buildConstructors(ModelInfo model) {
    return [
      // Default constructor (can't be const due to late final fields)
      Constructor((b) => b),
      // Private validated constructor (can't be const due to late final fields in parent)
      Constructor((b) => b
        ..name = '_valid'
        ..requiredParameters.add(Parameter((p) => p
          ..name = 'data'
          ..type = refer('Map<String, Object?>')))
        ..initializers.add(Code('super.validated(data)'))),
    ];
  }

  List<Method> _buildMethods(ModelInfo model) {
    return [
      _methodBuilder.buildParseMethod(model),
      _methodBuilder.buildTryParseMethod(model),
      _methodBuilder.buildCreateValidatedMethod(model),
    ];
  }

  Field _buildDefinitionField(ModelInfo model) {
    final schemaCode = _buildSchemaDefinition(model);

    return Field((b) => b
      ..name = 'definition'
      ..modifier = FieldModifier.final$
      ..late = true
      ..annotations.add(const CodeExpression(Code('override')))
      ..assignment = Code(schemaCode));
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

    // Add additionalProperties if enabled
    if (model.additionalProperties) {
      buffer.write(', additionalProperties: true');
    }

    buffer.write(')');

    return buffer.toString();
  }

  List<Method> _buildPropertyGetters(ModelInfo model) {
    final getters = <Method>[];

    for (final field in model.fields) {
      if (field.isPrimitive) {
        getters.add(_buildPrimitiveGetter(field));
      } else if (field.isList) {
        getters.add(_buildListGetter(field));
      } else if (field.isNestedSchema) {
        getters.add(_buildNestedSchemaGetter(field));
      }
    }

    // Add metadata getter if additionalPropertiesField is specified
    if (model.additionalPropertiesField != null) {
      getters.add(_buildMetadataGetter(model));
    }

    return getters;
  }

  Method _buildPrimitiveGetter(FieldInfo field) {
    final baseTypeName = field.type.getDisplayString().replaceAll('?', '');
    final returnTypeName = field.isNullable ? '$baseTypeName?' : baseTypeName;

    return Method((b) => b
      ..name = field.name
      ..type = MethodType.getter
      ..returns = refer(returnTypeName)
      ..lambda = true
      ..body = Code(field.isNullable
          ? "getValueOrNull<$baseTypeName>('${field.jsonKey}')"
          : "getValue<$baseTypeName>('${field.jsonKey}')"));
  }

  Method _buildListGetter(FieldInfo field) {
    final baseTypeName = field.type.getDisplayString().replaceAll('?', '');
    final returnTypeName = field.isNullable ? '$baseTypeName?' : baseTypeName;

    // Extract the item type from List<ItemType>
    String itemType = 'dynamic';

    // Try to get from ParameterizedType first
    if (field.type is ParameterizedType) {
      final paramType = field.type as ParameterizedType;
      if (paramType.typeArguments.isNotEmpty) {
        itemType = paramType.typeArguments.first
            .getDisplayString()
            .replaceAll('?', '');
      }
    } else {
      // Fallback: parse from type name string like "List<String>"
      final typeStr = baseTypeName;
      final match = RegExp(r'List<(.+)>').firstMatch(typeStr);
      if (match != null) {
        itemType = match.group(1) ?? 'dynamic';
      }
    }

    final code = field.isNullable
        ? "getValueOrNull<List>('${field.jsonKey}')?.cast<$itemType>()"
        : "getValue<List>('${field.jsonKey}').cast<$itemType>()";

    return Method((b) => b
      ..name = field.name
      ..type = MethodType.getter
      ..returns = refer(returnTypeName)
      ..lambda = true
      ..body = Code(code));
  }

  Method _buildNestedSchemaGetter(FieldInfo field) {
    final typeName = field.type.getDisplayString();
    final baseType = typeName.replaceAll('?', '');
    final schemaClassName = '${baseType}Schema';

    if (field.isNullable) {
      return Method((b) => b
        ..name = field.name
        ..type = MethodType.getter
        ..returns = refer('$schemaClassName?')
        ..body = Code('''
          final data = getValueOrNull<Map<String, Object?>>('${field.jsonKey}');
          return data != null ? $schemaClassName().parse(data) : null;
        '''));
    } else {
      return Method((b) => b
        ..name = field.name
        ..type = MethodType.getter
        ..returns = refer(schemaClassName)
        ..body = Code('''
          final data = getValue<Map<String, Object?>>('${field.jsonKey}');
          return $schemaClassName().parse(data);
        '''));
    }
  }

  Method _buildMetadataGetter(ModelInfo model) {
    final fieldName = model.additionalPropertiesField!;

    // Build the set of known field names to exclude
    final knownFields = model.fields.map((f) => "'${f.jsonKey}'").join(', ');

    return Method((b) => b
      ..name = fieldName
      ..type = MethodType.getter
      ..returns = refer('Map<String, Object?>')
      ..body = Code('''
        final map = toMap();
        final knownFields = {$knownFields};
        return Map.fromEntries(
            map.entries.where((e) => !knownFields.contains(e.key)));
      '''));
  }

  String _camelToSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }
}
