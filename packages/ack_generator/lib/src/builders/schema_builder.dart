import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../models/model_info.dart';
import '../models/field_info.dart';
import 'method_builder.dart' as mb;

/// Builds schema classes using code_builder
class SchemaBuilder {
  final _methodBuilder = mb.MethodBuilder();
  final _formatter = DartFormatter();

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
      allocator: Allocator.simplePrefixing(),
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
      ..type = refer('ObjectSchema', 'package:ack/ack.dart')
      ..modifier = FieldModifier.final$
      ..late = true
      ..annotations.add(const CodeExpression(Code('override')))
      ..assignment = Code(schemaCode)
    );
  }

  String _buildSchemaDefinition(ModelInfo model) {
    final buffer = StringBuffer('Ack.object({\n');
    
    // Build field definitions
    for (final field in model.fields) {
      // TODO: Use FieldBuilder when implemented
      final fieldSchema = _buildSimpleFieldSchema(field);
      buffer.writeln("  '${field.jsonKey}': $fieldSchema,");
    }
    
    buffer.write('}');
    
    // Add required fields if any
    if (model.requiredFields.isNotEmpty) {
      buffer.write(', required: [');
      buffer.write(model.requiredFields.map((f) => "'$f'").join(', '));
      buffer.write(']');
    }
    
    buffer.write(')');
    
    return buffer.toString();
  }
  // Temporary simple field schema builder
  String _buildSimpleFieldSchema(FieldInfo field) {
    final typeName = field.type.getDisplayString();
    String schema;
    
    if (field.type.isDartCoreString) {
      schema = 'Ack.string';
    } else if (field.type.isDartCoreInt) {
      schema = 'Ack.integer';
    } else if (field.type.isDartCoreDouble) {
      schema = 'Ack.double';
    } else if (field.type.isDartCoreBool) {
      schema = 'Ack.boolean';
    } else if (field.type.isDartCoreNum) {
      schema = 'Ack.number';
    } else if (field.type.isDartCoreList) {
      schema = 'Ack.list(Ack.any)'; // TODO: Extract item type
    } else if (field.type.isDartCoreMap) {
      schema = 'Ack.object({}, additionalProperties: true)';
    } else {
      // Assume it's a nested schema
      final baseType = typeName.replaceAll('?', '');
      schema = '${baseType}Schema().definition';
    }
    
    // Apply nullable if needed
    if (field.isNullable && !field.isRequired) {
      schema = '$schema.nullable()';
    }
    
    return schema;
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
    final typeName = field.type.getDisplayString();
    
    return Method((b) => b
      ..name = field.name
      ..type = MethodType.getter
      ..returns = refer(typeName)
      ..lambda = true
      ..body = Code(field.isNullable
          ? "getValueOrNull<${typeName.replaceAll('?', '')}>('${field.jsonKey}')"
          : "getValue<${typeName}>('${field.jsonKey}')")
    );
  }
  Method _buildListGetter(FieldInfo field) {
    // For now, simple implementation - will improve with FieldBuilder
    final typeName = field.type.getDisplayString();
    final code = field.isNullable
        ? "getValueOrNull<List>('${field.jsonKey}')?.cast<dynamic>()"
        : "getValue<List>('${field.jsonKey}').cast<dynamic>()";
    
    return Method((b) => b
      ..name = field.name
      ..type = MethodType.getter
      ..returns = refer(typeName)
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