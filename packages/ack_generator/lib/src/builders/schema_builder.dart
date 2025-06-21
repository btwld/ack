import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:analyzer/dart/element/type.dart';

import '../models/model_info.dart';
import '../models/field_info.dart';
import 'method_builder.dart' as mb;
import 'field_builder.dart' as fb;

/// Builds schema classes using code_builder
class SchemaBuilder {
  final _methodBuilder = mb.MethodBuilder();
  final _fieldBuilder = fb.FieldBuilder();
  final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  String build(ModelInfo model) {
    final schemaClass = Class((b) => b
      ..name = model.schemaClassName
      ..extend = refer('SchemaModel', 'package:ack/ack.dart')
      ..docs.addAll([
        '/// Generated schema for ${model.className}',
        if (model.description != null) '/// ${model.description}',
      ])
      ..constructors.addAll(_buildConstructors(model))
      ..methods.addAll(_buildMethods(model))
      ..fields.add(_buildDefinitionField(model))
      ..methods.addAll(_buildPropertyGetters(model))
    );

    final library = Library((b) => b
      ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..body.add(schemaClass)
    );

    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    return _formatter.format('${library.accept(emitter)}');
  }

  List<Constructor> _buildConstructors(ModelInfo model) {
    return [
      // Default constructor
      Constructor((b) => b
        ..constant = true
      ),
      // Private validated constructor
      Constructor((b) => b
        ..name = '_valid'
        ..constant = true
        ..requiredParameters.add(Parameter((p) => p
          ..name = 'data'
          ..type = refer('Map<String, Object?>')
        ))
        ..initializers.add(Code('super.validated(data)'))
      ),
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
      ..assignment = Code(schemaCode)
    );
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
          : "getValue<$baseTypeName>('${field.jsonKey}')")
    );
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
        itemType = paramType.typeArguments.first.getDisplayString().replaceAll('?', '');
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
      ..body = Code(code)
    );
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
        ''')
      );
    } else {
      return Method((b) => b
        ..name = field.name
        ..type = MethodType.getter
        ..returns = refer(schemaClassName)
        ..body = Code('''
          final data = getValue<Map<String, Object?>>('${field.jsonKey}');
          return $schemaClassName().parse(data);
        ''')
      );
    }
  }
}