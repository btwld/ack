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
        _buildPrivateConstructor(modelInfo),
        _buildDefaultFactoryConstructor(modelInfo),
        _buildPrivateSchemaConstructor(modelInfo),
      ])
      ..fields.addAll([
        _buildSchemaField(modelInfo),
      ])
      ..methods.addAll([
        _buildCreateFromMapMethod(modelInfo),
        ..._buildFluentMethods(modelInfo),
      ]));
  }

  /// Builds the private constructor
  Constructor _buildPrivateConstructor(ModelInfo modelInfo) {
    // Determine the specific schema type based on whether this is a discriminated base class
    final schemaType = modelInfo.isDiscriminatedBase
        ? 'DiscriminatedObjectSchema'
        : 'ObjectSchema';

    return Constructor((b) => b
      ..name = '_internal'
      ..requiredParameters.add(Parameter((p) => p
        ..name = 'schema'
        ..type = refer(schemaType)
        ..toThis = true)));
  }

  /// Builds the default factory constructor
  Constructor _buildDefaultFactoryConstructor(ModelInfo modelInfo) {
    final schemaVarName = _toCamelCase(modelInfo.schemaClassName);

    return Constructor((b) => b
      ..factory = true
      ..body = Code(
          'return ${modelInfo.className}SchemaModel._internal($schemaVarName);'));
  }

  /// Builds the private schema constructor for fluent methods
  Constructor _buildPrivateSchemaConstructor(ModelInfo modelInfo) {
    // Determine the specific schema type based on whether this is a discriminated base class
    final schemaType = modelInfo.isDiscriminatedBase
        ? 'DiscriminatedObjectSchema'
        : 'ObjectSchema';

    return Constructor((b) => b
      ..name = '_withSchema'
      ..requiredParameters.add(Parameter((p) => p
        ..name = 'customSchema'
        ..type = refer(schemaType)))
      ..initializers.add(Code('schema = customSchema')));
  }

  /// Builds the schema field
  Field _buildSchemaField(ModelInfo modelInfo) {
    // Determine the specific schema type based on whether this is a discriminated base class
    final schemaType = modelInfo.isDiscriminatedBase
        ? 'DiscriminatedObjectSchema'
        : 'ObjectSchema';

    return Field((b) => b
      ..name = 'schema'
      ..modifier = FieldModifier.final$
      ..type = refer(schemaType)
      ..annotations.add(refer('override')));
  }

  // Schema property is now a field - no method needed

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
    // Check if this is a discriminated base class
    if (modelInfo.isDiscriminatedBase && modelInfo.subtypes != null) {
      return _generateDiscriminatedCreateFromMapBody(modelInfo);
    }

    // Regular model or discriminated subtype
    return _generateRegularCreateFromMapBody(modelInfo);
  }

  /// Generates createFromMap body for discriminated base classes with switch logic
  String _generateDiscriminatedCreateFromMapBody(ModelInfo modelInfo) {
    final discriminatorKey = modelInfo.discriminatorKey!;
    final subtypes = modelInfo.subtypes!;

    final buffer = StringBuffer();
    buffer.writeln(
        'final $discriminatorKey = map[\'$discriminatorKey\'] as String;');
    buffer.writeln('return switch ($discriminatorKey) {');

    // Generate case for each subtype
    for (final entry in subtypes.entries) {
      final discriminatorValue = entry.key;
      final subtypeElement = entry.value;
      final subtypeSchemaModelName = '${subtypeElement.name}SchemaModel';

      buffer.writeln(
          '  \'$discriminatorValue\' => $subtypeSchemaModelName().createFromMap(map),');
    }

    // Default case with error
    final validValues = subtypes.keys.map((v) => '\\\'$v\\\'').join(', ');
    buffer.writeln(
        '  _ => throw ArgumentError(\'Unknown $discriminatorKey: \$$discriminatorKey. Valid values: $validValues\'),');
    buffer.writeln('};');

    return buffer.toString();
  }

  /// Generates createFromMap body for regular models and discriminated subtypes
  String _generateRegularCreateFromMapBody(ModelInfo modelInfo) {
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

    // Handle empty parameter case
    if (params.isEmpty) {
      return 'return ${modelInfo.className}();';
    } else {
      final buffer = StringBuffer('return ${modelInfo.className}(\n');
      buffer.writeln(params.join(',\n'));
      buffer.write('    );');
      return buffer.toString();
    }
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

    // Check if this is a field that uses AnyOfSchema (sealed class types)
    // For now, we'll detect common AnyOf patterns and handle them differently
    if (typeName == 'ResponseData' || typeName == 'SettingValue') {
      // These fields use AnyOfSchema which doesn't have SchemaModel classes
      // For now, we'll cast directly to the expected type
      // TODO: Implement proper AnyOfSchema handling
      if (field.isNullable) {
        return '${field.name}: map[$mapKey] as $typeName?';
      } else {
        return '${field.name}: map[$mapKey] as $typeName';
      }
    }

    if (field.isNullable) {
      return '${field.name}: map[$mapKey] != null ? ${typeName}SchemaModel().createFromMap(map[$mapKey] as Map<String, dynamic>) : null';
    } else {
      return '${field.name}: ${typeName}SchemaModel().createFromMap(map[$mapKey] as Map<String, dynamic>)';
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
          return '${field.name}: (map[$mapKey] as List?)?.map((item) => ${itemTypeName}SchemaModel().createFromMap(item as Map<String, dynamic>)).toList()';
        } else {
          return '${field.name}: (map[$mapKey] as List).map((item) => ${itemTypeName}SchemaModel().createFromMap(item as Map<String, dynamic>)).toList()';
        }
      }
    }

    // Simple list - use safe navigation pattern for nullable lists
    if (field.isNullable) {
      final paramType = listType as ParameterizedType;
      final itemTypeString = paramType.typeArguments.first.getDisplayString();
      return '${field.name}: (map[$mapKey] as List?)?.cast<$itemTypeString>()';
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

  /// Builds fluent methods that delegate to the underlying schema
  List<Method> _buildFluentMethods(ModelInfo modelInfo) {
    final className = '${modelInfo.className}SchemaModel';

    return [
      // Fluent methods for schema modification - now properly implemented
      Method((b) => b
        ..name = 'describe'
        ..returns = refer(className)
        ..requiredParameters.add(Parameter((p) => p
          ..name = 'description'
          ..type = refer('String')))
        ..docs.add('/// Returns a new schema with the specified description.')
        ..body = Code('''
final newSchema = schema.copyWith(description: description);
return $className._withSchema(newSchema);
''')),

      Method((b) => b
        ..name = 'withDefault'
        ..returns = refer(className)
        ..requiredParameters.add(Parameter((p) => p
          ..name = 'defaultValue'
          ..type = refer('Map<String, dynamic>')))
        ..docs.add('/// Returns a new schema with the specified default value.')
        ..body = Code('''
final newSchema = schema.copyWith(defaultValue: defaultValue);
return $className._withSchema(newSchema);
''')),

      Method((b) => b
        ..name = 'nullable'
        ..returns = refer(className)
        ..optionalParameters.add(Parameter((p) => p
          ..name = 'value'
          ..type = refer('bool')
          ..defaultTo = const Code('true')))
        ..docs.add(
            '/// Returns a new schema with nullable flag set to the specified value.')
        ..body = Code('''
final newSchema = schema.copyWith(isNullable: value);
return $className._withSchema(newSchema);
''')),
    ];
  }

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toLowerCase() + text.substring(1);
  }
}
