import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';

/// Builds SchemaModel classes using code_builder
class SchemaModelBuilder {
  /// Builds a complete SchemaModel class for the given model
  Class buildSchemaModelClass(ModelInfo modelInfo) {
    return Class((b) => b
      ..name = '${modelInfo.className}SchemaModel'
      ..extend = refer('SchemaModel<${modelInfo.className}>')
      ..docs.addAll([
        '/// Generated SchemaModel for [${modelInfo.className}].',
        if (modelInfo.description != null) '/// ${modelInfo.description}',
      ])
      ..constructors.addAll([
        _buildPrivateConstructor(),
        _buildFactoryConstructor(),
      ])
      ..fields.add(_buildStaticInstance(modelInfo))
      ..methods.addAll([
        _buildSchemaMethod(modelInfo),
        _buildCreateFromMapMethod(modelInfo),
      ]));
  }

  /// Builds the private constructor
  Constructor _buildPrivateConstructor() {
    return Constructor((b) => b..name = '_');
  }

  /// Builds the factory constructor that returns the singleton instance
  Constructor _buildFactoryConstructor() {
    return Constructor((b) => b
      ..factory = true
      ..body = const Code('return _instance;'));
  }

  /// Builds the static singleton instance field
  Field _buildStaticInstance(ModelInfo modelInfo) {
    return Field((b) => b
      ..name = '_instance'
      ..static = true
      ..modifier = FieldModifier.final$
      ..assignment = Code('${modelInfo.className}SchemaModel._()'));
  }

  /// Builds the buildSchema method
  Method _buildSchemaMethod(ModelInfo modelInfo) {
    // Use the schema variable name
    final schemaVarName = _toCamelCase(modelInfo.schemaClassName);

    return Method((b) => b
      ..name = 'buildSchema'
      ..annotations.add(refer('override'))
      ..returns = refer('ObjectSchema')
      ..body = Code('return $schemaVarName;'));
  }

  /// Builds the createFromMap method
  Method _buildCreateFromMapMethod(ModelInfo modelInfo) {
    return Method((b) => b
      ..name = 'createFromMap'
      ..annotations.add(refer('override'))
      ..returns = refer(modelInfo.className)
      ..requiredParameters.add(Parameter((p) => p
        ..name = 'map'
        ..type = refer('Map<String, dynamic>')))
      ..body = Code(_generateCreateFromMapBody(modelInfo)));
  }

  /// Generates the createFromMap method body
  String _generateCreateFromMapBody(ModelInfo modelInfo) {
    final buffer = StringBuffer('return ${modelInfo.className}(\n');

    final params = <String>[];

    // Process all regular fields
    for (final field in modelInfo.fields) {
      final param = _generateFieldMapping(field);
      params.add('      $param');
    }

    // Add additional properties field if configured
    if (modelInfo.additionalProperties &&
        modelInfo.additionalPropertiesField != null) {
      params.add(
          '      ${modelInfo.additionalPropertiesField}: extractAdditionalProperties(map, {${_getKnownFields(modelInfo)}})');
    }

    buffer.writeln(params.join(',\n'));
    buffer.write('    );');

    return buffer.toString();
  }

  /// Get list of known field names for filtering additional properties
  String _getKnownFields(ModelInfo modelInfo) {
    final knownFields = modelInfo.fields
        .where((f) => f.name != modelInfo.additionalPropertiesField)
        .map((f) => "'${f.jsonKey}'")
        .join(', ');
    return knownFields;
  }

  /// Generates the field mapping for createFromMap
  String _generateFieldMapping(FieldInfo field) {
    final mapKey = "'${field.jsonKey}'";

    // Handle different field types
    if (field.isEnum) {
      return _generateEnumMapping(field, mapKey);
    } else if (field.isNestedSchema) {
      return _generateNestedSchemaMapping(field, mapKey);
    } else if (field.isList) {
      return _generateListMapping(field, mapKey);
    } else if (field.isMap) {
      return _generateMapMapping(field, mapKey);
    } else if (field.isSet) {
      return _generateSetMapping(field, mapKey);
    } else {
      // Simple field
      return _generateSimpleMapping(field, mapKey);
    }
  }

  /// Generates mapping for simple fields
  String _generateSimpleMapping(FieldInfo field, String mapKey) {
    final cast = field.type.getDisplayString();

    if (field.isNullable) {
      return '${field.name}: map[$mapKey] as $cast';
    } else {
      return '${field.name}: map[$mapKey] as $cast';
    }
  }

  /// Generates mapping for enum fields
  String _generateEnumMapping(FieldInfo field, String mapKey) {
    final enumTypeName = field.type.getDisplayString().replaceAll('?', '');

    if (field.isNullable) {
      return '${field.name}: map[$mapKey] != null ? $enumTypeName.values.byName(map[$mapKey] as String) : null';
    } else {
      return '${field.name}: $enumTypeName.values.byName(map[$mapKey] as String)';
    }
  }

  /// Generates mapping for nested schema fields
  String _generateNestedSchemaMapping(FieldInfo field, String mapKey) {
    final typeName = field.type.getDisplayString().replaceAll('?', '');

    if (field.isNullable) {
      return '${field.name}: map[$mapKey] != null ? ${typeName}SchemaModel._instance.createFromMap(map[$mapKey] as Map<String, dynamic>) : null';
    } else {
      return '${field.name}: ${typeName}SchemaModel._instance.createFromMap(map[$mapKey] as Map<String, dynamic>)';
    }
  }

  /// Generates mapping for List fields
  String _generateListMapping(FieldInfo field, String mapKey) {
    final listType = field.type;

    // Extract the item type from List<T>
    if (listType is ParameterizedType && listType.typeArguments.isNotEmpty) {
      final itemType = listType.typeArguments.first;
      final itemTypeName = itemType.getDisplayString().replaceAll('?', '');

      // Check if item is a nested schema
      if (!itemType.isDartCoreString &&
          !itemType.isDartCoreInt &&
          !itemType.isDartCoreBool &&
          !itemType.isDartCoreDouble &&
          !itemType.isDartCoreNum) {
        // Nested model in list
        if (field.isNullable) {
          return '${field.name}: (map[$mapKey] as List?)?.map((item) => ${itemTypeName}SchemaModel._instance.createFromMap(item as Map<String, dynamic>)).toList()';
        } else {
          return '${field.name}: (map[$mapKey] as List).map((item) => ${itemTypeName}SchemaModel._instance.createFromMap(item as Map<String, dynamic>)).toList()';
        }
      }
    }

    // Simple list
    final listTypeString = field.type.getDisplayString();
    if (field.isNullable) {
      return '${field.name}: map[$mapKey] as $listTypeString';
    } else {
      final paramType = listType as ParameterizedType;
      return '${field.name}: (map[$mapKey] as List).cast<${paramType.typeArguments.first.getDisplayString()}>()';
    }
  }

  /// Generates mapping for Map fields
  String _generateMapMapping(FieldInfo field, String mapKey) {
    final mapTypeString = field.type.getDisplayString();
    return '${field.name}: map[$mapKey] as $mapTypeString';
  }

  /// Generates mapping for Set fields
  String _generateSetMapping(FieldInfo field, String mapKey) {
    final setType = field.type;

    if (setType is ParameterizedType && setType.typeArguments.isNotEmpty) {
      final itemType = setType.typeArguments.first;

      if (field.isNullable) {
        return '${field.name}: (map[$mapKey] as List?)?.cast<${itemType.getDisplayString()}>().toSet()';
      } else {
        return '${field.name}: (map[$mapKey] as List).cast<${itemType.getDisplayString()}>().toSet()';
      }
    }

    // Fallback
    return '${field.name}: (map[$mapKey] as List).toSet()';
  }

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toLowerCase() + text.substring(1);
  }
}
