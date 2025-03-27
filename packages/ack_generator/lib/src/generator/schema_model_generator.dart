import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

// Add imports for SchemaContext and SchemaUnknownError
const schemaContextImport = "import 'package:ack/src/context.dart';";
const schemaErrorImport =
    "import 'package:ack/src/validation/schema_error.dart';";
const stackTraceImport = "import 'dart:core';";

/// Generator for SchemaModel-based schemas
class SchemaModelGenerator {
  final formatter = DartFormatter();

  /// Generate a schema model class for an annotated class element
  String generateForAnnotatedElement(
    ClassElement element,
    SchemaData modelData,
  ) {
    final className = element.name;
    final schemaClassName = modelData.schemaClassName ?? '${className}Schema';

    // Find constructor parameters (either default or annotated)
    final constructorParams = _findConstructorParameters(element);

    // Process all properties
    final properties = _mapProperties(
      element,
      constructorParams,
      modelData.additionalPropertiesField,
    );

    // Generate the schema code
    final code = _generateSchemaClass(
      modelClassName: className,
      schemaClassName: schemaClassName,
      modelData: modelData,
      properties: properties.values.toList(),
    );

    try {
      return formatter.format(code);
    } catch (e) {
      print('ERROR FORMATTING CODE: $e');
      return code; // Return unformatted code for debugging
    }
  }

  /// Find constructor parameters from the default or annotated constructor
  Map<String, PropertyInfo> _findConstructorParameters(
    ClassElement classElement,
  ) {
    final constructorParams = <String, PropertyInfo>{};

    // Find the primary constructor
    ConstructorElement? primaryConstructor;

    // First look for a constructor annotated with @SchemaConstructor
    for (final constructor in classElement.constructors) {
      if (constructor.metadata
          .any((m) => m.element?.displayName == 'SchemaConstructor')) {
        primaryConstructor = constructor;
        break;
      }
    }

    // If no annotated constructor, use the default constructor
    if (primaryConstructor == null && classElement.unnamedConstructor != null) {
      primaryConstructor = classElement.unnamedConstructor;
    }

    // If still no constructor, try to use any constructor
    if (primaryConstructor == null && classElement.constructors.isNotEmpty) {
      primaryConstructor = classElement.constructors.first;
    }

    // Analyze the parameters
    if (primaryConstructor != null) {
      for (final param in primaryConstructor.parameters) {
        final paramName = param.name;
        final isRequired = param.isRequired;
        final isNullable =
            param.type.nullabilitySuffix == NullabilitySuffix.question;
        final TypeName typeName = _getTypeName(param.type);

        constructorParams[paramName] = PropertyInfo(
          name: paramName,
          typeName: typeName,
          isRequired: isRequired,
          isNullable: isNullable,
          constraints: [],
        );
      }
    }

    return constructorParams;
  }

  /// Map all properties with their types and constraints
  Map<String, PropertyInfo> _mapProperties(
    ClassElement classElement,
    Map<String, PropertyInfo> constructorParams,
    String? additionalPropertiesField,
  ) {
    final properties = <String, PropertyInfo>{};

    // Copy constructor params as a starting point
    properties.addAll(constructorParams);

    // Process all instance fields
    for (final field in classElement.fields) {
      // Skip static fields, private fields, and the additionalProperties field
      if (field.isStatic ||
          field.name.startsWith('_') ||
          field.name == additionalPropertiesField) {
        continue;
      }

      // Determine type and nullability from field declaration
      final fieldType = field.type;
      final isNullableField =
          fieldType.nullabilitySuffix == NullabilitySuffix.question;
      final typeName = _getTypeName(fieldType);

      // Create property info or update existing from constructor
      PropertyInfo property;
      if (properties.containsKey(field.name)) {
        property = properties[field.name]!;
        // If field is not nullable but constructor param is, prefer the field
        if (!isNullableField && property.isNullable) {
          property.isNullable = false;
        }
      } else {
        property = PropertyInfo(
          name: field.name,
          typeName: typeName,
          isNullable: isNullableField,
          isRequired: false,
          constraints: [],
        );
        properties[field.name] = property;
      }

      // Get constraint annotations
      for (final metadata in field.metadata) {
        final constraint = _extractPropertyConstraint(metadata);
        if (constraint != null) {
          property.constraints.add(constraint);

          // Handle special constraints that affect required or nullable
          if (constraint is RequiredConstraint) {
            property.isRequired = true;
          } else if (constraint is NullableConstraint) {
            property.isNullable = true;
          }
        }
      }
    }

    return properties;
  }

  /// Extract property constraint from annotation
  PropertyConstraintInfo? _extractPropertyConstraint(
    ElementAnnotation metadata,
  ) {
    final name = metadata.element?.displayName;

    if (name == 'Required') {
      return RequiredConstraint();
    } else if (name == 'Nullable') {
      return NullableConstraint();
    }

    // Check for other constraints
    final reader = ConstantReader(metadata.computeConstantValue());

    // Try to read constraints based on the constraint class
    if (name == 'IsEmail') {
      return PropertyConstraintInfo(constraintKey: 'isEmail', parameters: {});
    } else if (name == 'MinLength') {
      final length = reader.peek('length')?.intValue ?? 0;
      return PropertyConstraintInfo(
        constraintKey: 'minLength',
        parameters: {'length': length},
      );
    } else if (name == 'MaxLength') {
      final length = reader.peek('length')?.intValue ?? 0;
      return PropertyConstraintInfo(
        constraintKey: 'maxLength',
        parameters: {'length': length},
      );
    } else if (name == 'Pattern') {
      final pattern = reader.peek('pattern')?.stringValue ?? '';
      return PropertyConstraintInfo(
        constraintKey: 'pattern',
        parameters: {'pattern': pattern},
      );
    } else if (name == 'IsNotEmpty') {
      return PropertyConstraintInfo(
        constraintKey: 'isNotEmpty',
        parameters: {},
      );
    } else if (name == 'EnumValues') {
      final listReader = reader.peek('values');
      final values = <String>[];
      if (listReader != null && listReader.isList) {
        for (final value in listReader.listValue) {
          final stringValue = ConstantReader(value).stringValue;
          values.add(stringValue);
        }
      }
      return PropertyConstraintInfo(
        constraintKey: 'enumValues',
        parameters: {'values': values},
      );
    } else if (name == 'Min') {
      final valueReader = reader.peek('value');
      final value = valueReader?.isInt == true
          ? valueReader!.intValue.toDouble()
          : valueReader?.doubleValue ?? 0;

      return PropertyConstraintInfo(
        constraintKey: 'min',
        parameters: {'value': value},
      );
    } else if (name == 'Max') {
      final valueReader = reader.peek('value');
      final value = valueReader?.isInt == true
          ? valueReader!.intValue.toDouble()
          : valueReader?.doubleValue ?? 0;

      return PropertyConstraintInfo(
        constraintKey: 'max',
        parameters: {'value': value},
      );
    } else if (name == 'MultipleOf') {
      final value = reader.peek('value')?.doubleValue ?? 0;
      return PropertyConstraintInfo(
        constraintKey: 'multipleOf',
        parameters: {'value': value},
      );
    } else if (name == 'MinItems') {
      final count = reader.peek('count')?.intValue ?? 0;
      return PropertyConstraintInfo(
        constraintKey: 'minItems',
        parameters: {'count': count},
      );
    } else if (name == 'MaxItems') {
      final count = reader.peek('count')?.intValue ?? 0;
      return PropertyConstraintInfo(
        constraintKey: 'maxItems',
        parameters: {'count': count},
      );
    } else if (name == 'UniqueItems') {
      return PropertyConstraintInfo(
        constraintKey: 'uniqueItems',
        parameters: {},
      );
    } else if (name == 'Description') {
      final text = reader.peek('text')?.stringValue ?? '';
      return PropertyConstraintInfo(
        constraintKey: 'description',
        parameters: {'text': text},
      );
    } else if (name == 'FieldType') {
      final typeStr = reader.peek('type')?.typeValue.toString() ?? '';
      return PropertyConstraintInfo(
        constraintKey: 'fieldType',
        parameters: {'type': typeStr},
      );
    }

    return null;
  }

  /// Generate the schema class
  String _generateSchemaClass({
    required String modelClassName,
    required String schemaClassName,
    required SchemaData modelData,
    required List<PropertyInfo> properties,
  }) {
    // Check if we need context and error imports
    bool needsContextAndErrorImports = properties.any(
      (property) =>
          (!_isPrimitiveType(property.typeName) ||
              (property.typeName.name == 'List' &&
                  !_isPrimitiveListType(property.typeName))) &&
          !property.isNullable,
    );

    // Generate import statements
    String imports =
        "import 'package:ack/ack.dart';\n\nimport '$modelClassName.dart';\n";

    // Add additional imports if needed
    if (needsContextAndErrorImports) {
      imports += '\n$schemaContextImport\n$schemaErrorImport\n';
    }

    // Generate property schemas
    final propertySchemas = properties
        .where(
          (property) => property.name != modelData.additionalPropertiesField,
        )
        .map(
          (property) =>
              "        '${property.name}': ${_generatePropertySchema(property)},",
        )
        .join('\n');

    // Required properties
    final requiredProps = properties
        .where(
          (p) => p.isRequired && p.name != modelData.additionalPropertiesField,
        )
        .map((p) => '\'${p.name}\'')
        .join(', ');

    // Find dependencies and register them
    final dependencies = _findDependencies(properties);
    final dependenciesCode = dependencies.isNotEmpty
        ? '''
    // Register schema dependencies
    ${dependencies.map((dependency) => '${dependency}Schema.ensureInitialize();').join('\n    ')}'''
        : '';

    // Type-safe getters
    final getters = properties
        .where(
      (property) => property.name != modelData.additionalPropertiesField,
    )
        .map((property) {
      final typeStr = _getTypeString(property.typeName);
      final nullSuffix = property.isNullable ? '' : '!';
      final returnType = property.isNullable ? '$typeStr?' : typeStr;

      // For custom model types, we need special handling
      if (!_isPrimitiveType(property.typeName)) {
        // Generate a getter that properly handles nested schema objects
        final schemaType = '${property.typeName.name}Schema';
        if (property.isNullable) {
          return '''  $returnType get ${property.name} {
    final map = getValue<Map<String, dynamic>>('${property.name}');
    if (map == null) return null;
    return $schemaType.parse(map);
  }''';
        } else {
          return '''  $returnType get ${property.name} {
    final map = getValue<Map<String, dynamic>>('${property.name}');
    if (map == null) {
      final context = SchemaContext(name: '${property.name}', schema: schema, value: null);
      final error = SchemaUnknownError(
        error: '${property.name} is required but was null', 
        stackTrace: StackTrace.current,
        context: context,
      );
      throw AckException(error);
    }
    return $schemaType.parse(map);
  }''';
        }
      }

      // For list types with model items, we also need special handling
      if (typeStr.startsWith('List<') &&
          !_isPrimitiveListType(property.typeName)) {
        final itemType = property.typeName.typeArguments[0].name;
        final schemaType = '${itemType}Schema';
        if (property.isNullable) {
          return '''  $returnType get ${property.name} {
    final list = getValue<List<dynamic>>('${property.name}');
    if (list == null) return null;
    return list.map((item) => $schemaType.parse(item as Map<String, dynamic>)).toList();
  }''';
        } else {
          return '''  $returnType get ${property.name} {
    final list = getValue<List<dynamic>>('${property.name}');
    if (list == null) {
      final context = SchemaContext(name: '${property.name}', schema: schema, value: null);
      final error = SchemaUnknownError(
        error: '${property.name} is required but was null', 
        stackTrace: StackTrace.current,
        context: context,
      );
      throw AckException(error);
    }
    return list.map((item) => $schemaType.parse(item as Map<String, dynamic>)).toList();
  }''';
        }
      }

      // For primitive types, use the original approach
      return '  $returnType get ${property.name} => getValue<$typeStr>(\'${property.name}\')$nullSuffix;';
    }).join('\n');

    // Metadata getter
    final metadataGetter = modelData.additionalPropertiesField != null
        ? '''
  // Get metadata with fallback
  Map<String, Object?> get ${modelData.additionalPropertiesField} {
    final result = <String, Object?>{};
    final knownFields = [${properties.where((p) => p.name != modelData.additionalPropertiesField).map((p) => '\'${p.name}\'').join(', ')}];

    for (final key in toMap().keys) {
      if (!knownFields.contains(key)) {
        result[key] = toMap()[key];
      }
    }
    return result;
  }
'''
        : '';

    // Model conversion properties
    final modelConversionProps = properties.map((property) {
      if (property.name == modelData.additionalPropertiesField) {
        return '      ${property.name}: ${modelData.additionalPropertiesField},';
      } else {
        final conversion = _generateModelConversion(property);
        return '      ${property.name}: $conversion,';
      }
    }).join('\n');

    // ToMap properties
    final toMapProps = properties
        .where(
      (property) => property.name != modelData.additionalPropertiesField,
    )
        .map((property) {
      final conversion =
          _generateToMapConversion(property, 'instance.${property.name}');
      return "      '${property.name}': $conversion,";
    }).join('\n');

    // Additional properties handling
    final additionalPropsCode = modelData.additionalPropertiesField != null
        ? '''
    // Include additional properties
    if (instance.${modelData.additionalPropertiesField}.isNotEmpty) {
      result.addAll(instance.${modelData.additionalPropertiesField});
    }
'''
        : '';
    // Class documentation
    final baseDoc = '/// Generated schema for $modelClassName';
    final classDoc = modelData.description != null
        ? '$baseDoc\n/// ${modelData.description}'
        : baseDoc;

    return '''$imports
$classDoc
class $schemaClassName extends SchemaModel<$modelClassName> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
$propertySchemas
      },
      required: [$requiredProps],
      additionalProperties: ${modelData.additionalProperties},
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<$modelClassName, $schemaClassName>(
      $schemaClassName.parse,
    );
$dependenciesCode
  }

  // Constructors
  $schemaClassName([Map<String, Object?>? data]) : super(data ?? {});

  // Internal constructor for validated data
  factory $schemaClassName.fromValidated(Map<String, Object?> data) {
    final schema = $schemaClassName(data);
    // Mark as pre-validated (implementation detail)
    return schema;
  }

  /// Factory methods for parsing data
  static $schemaClassName parse(Map<String, Object?> data) {
    final result = schema.validate(data);

    if (result.isFail) {
      throw AckException(result.getError());
    }

    return $schemaClassName(result.getOrThrow());
  }

  static $schemaClassName? tryParse(Map<String, Object?> data) {
    try {
      return parse(data);
    } catch (_) {
      return null;
    }
  }

  /// Static helper to validate a map
  static SchemaResult validateMap(Map<String, Object?> map) {
    return schema.validate(map);
  }

  /// Validate the current data
  @override
  SchemaResult validate() {
    return schema.validate(toMap());
  }

  // Type-safe getters
$getters

$metadataGetter
  // Model conversion methods
  @override
  $modelClassName toModel() {
    return $modelClassName(
$modelConversionProps
    );
  }

  /// Convert from a model instance to a schema
  static $schemaClassName fromModel($modelClassName model) {
    return $schemaClassName(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel($modelClassName instance) {
    final Map<String, Object?> result = {
$toMapProps
    };

$additionalPropsCode
    return result;
  }

  /// Convert the schema to OpenAPI specification format
  static Map<String, Object?> toOpenApiSpec() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }

  /// Convert the schema to OpenAPI specification JSON string
  static String toOpenApiSpecString() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchemaString();
  }

  /// Validate and convert to an instance - maintaining compatibility
  static SchemaResult<$modelClassName> createFromMap(Map<String, Object?> map) {
    final result = schema.validate(map);
    if (result.isFail) {
      return SchemaResult.fail(result.getError());
    }

    return SchemaResult.ok($schemaClassName(result.getOrThrow()).toModel());
  }
}''';
  }

  /// Generate schema code for a property
  String _generatePropertySchema(PropertyInfo property) {
    // Get the base schema type
    String baseSchema = _getBaseSchemaType(property.typeName);

    // Apply constraints
    final constraintBuffer = StringBuffer(baseSchema);

    for (final constraint in property.constraints) {
      _applyConstraint(constraintBuffer, constraint);
    }

    // Apply nullable if needed
    if (property.isNullable) {
      constraintBuffer.write('.nullable()');
    }

    return constraintBuffer.toString();
  }

  /// Get the base schema type for a property type
  String _getBaseSchemaType(TypeName typeName) {
    final typeStr = typeName.name;

    if (typeStr == 'String') {
      return 'Ack.string';
    } else if (typeStr == 'int') {
      return 'Ack.int';
    } else if (typeStr == 'double') {
      return 'Ack.double';
    } else if (typeStr == 'bool' || typeStr == 'boolean') {
      return 'Ack.boolean';
    } else if (typeStr == 'List') {
      // For lists, extract item type if possible
      final itemType = typeName.typeArguments.isNotEmpty
          ? _getBaseSchemaType(typeName.typeArguments[0])
          : 'Ack.string';
      return 'Ack.list($itemType)';
    } else if (typeStr == 'Map') {
      // Default handling for Map
      return 'Ack.object({}, additionalProperties: true)';
    } else {
      // For custom types, reference their schema
      return '${typeStr}Schema.schema';
    }
  }

  /// Apply a constraint to the schema buffer
  void _applyConstraint(
    StringBuffer buffer,
    PropertyConstraintInfo constraint,
  ) {
    switch (constraint.constraintKey) {
      case 'isEmail':
        buffer.write('.isEmail()');
        break;
      case 'minLength':
        final length = constraint.parameters['length'] as int;
        buffer.write('.minLength($length)');
        break;
      case 'maxLength':
        final length = constraint.parameters['length'] as int;
        buffer.write('.maxLength($length)');
        break;
      case 'pattern':
        final pattern = constraint.parameters['pattern'] as String;
        buffer.write('.pattern(\'$pattern\')');
        break;
      case 'isNotEmpty':
        buffer.write('.isNotEmpty()');
        break;
      case 'enumValues':
        final values = constraint.parameters['values'] as List<String>;
        buffer.write('.isEnum([${values.map((v) => "'$v'").join(', ')}])');
        break;
      case 'min':
        final value = constraint.parameters['value'] as num;
        // Handle integer formatting
        if (value is double && value.truncateToDouble() == value) {
          buffer.write('.min(${value.toInt()})');
        } else {
          buffer.write('.min($value)');
        }
        break;
      case 'max':
        final value = constraint.parameters['value'] as num;
        // Handle integer formatting
        if (value is double && value.truncateToDouble() == value) {
          buffer.write('.max(${value.toInt()})');
        } else {
          buffer.write('.max($value)');
        }
        break;
      case 'multipleOf':
        final value = constraint.parameters['value'] as num;
        buffer.write('.multipleOf($value)');
        break;
      case 'minItems':
        final count = constraint.parameters['count'] as int;
        buffer.write('.minItems($count)');
        break;
      case 'maxItems':
        final count = constraint.parameters['count'] as int;
        buffer.write('.maxItems($count)');
        break;
      case 'uniqueItems':
        buffer.write('.uniqueItems()');
        break;
      // Ignore constraints that only affect schema generation
      case 'required':
      case 'nullable':
      case 'fieldType':
      case 'description':
        break;
    }
  }

  /// Generate model conversion code for a property
  String _generateModelConversion(PropertyInfo property) {
    final typeStr = _getTypeString(property.typeName);

    // For nested model types, convert properly
    if (!typeStr.startsWith('String') &&
        !typeStr.startsWith('int') &&
        !typeStr.startsWith('double') &&
        !typeStr.startsWith('bool') &&
        !typeStr.startsWith('List<') &&
        !typeStr.startsWith('Map<')) {
      return '${property.name}.toModel()';
    }

    // For list types with models
    if (typeStr.startsWith('List<') &&
        !_isPrimitiveListType(property.typeName)) {
      return '${property.name}.map((item) => item.toModel()).toList()';
    }

    // Simple values don't need conversion
    return property.name;
  }

  /// Generate conversion code for a property in toMap
  String _generateToMapConversion(PropertyInfo property, String varName) {
    final typeStr = _getTypeString(property.typeName);

    // For nested model types
    if (!typeStr.startsWith('String') &&
        !typeStr.startsWith('int') &&
        !typeStr.startsWith('double') &&
        !typeStr.startsWith('bool') &&
        !typeStr.startsWith('List<') &&
        !typeStr.startsWith('Map<')) {
      return '${property.typeName.name}Schema.toMapFromModel($varName)';
    }

    // For list types with models
    if (typeStr.startsWith('List<') &&
        !_isPrimitiveListType(property.typeName)) {
      final itemTypeName = property.typeName.typeArguments[0].name;
      return '$varName.map((item) => ${itemTypeName}Schema.toMapFromModel(item)).toList()';
    }

    // Simple values don't need conversion
    return varName;
  }

  /// Check if a list type contains primitive types
  bool _isPrimitiveListType(TypeName typeName) {
    if (typeName.name != 'List' || typeName.typeArguments.isEmpty) {
      return true;
    }

    final itemType = typeName.typeArguments[0].name;
    return itemType == 'String' ||
        itemType == 'int' ||
        itemType == 'double' ||
        itemType == 'bool' ||
        itemType == 'num';
  }

  /// Get a TypeName from a DartType
  TypeName _getTypeName(DartType type) {
    final name = _getSimpleTypeName(type);
    final typeArguments = <TypeName>[];

    if (type is InterfaceType) {
      for (final argType in type.typeArguments) {
        typeArguments.add(_getTypeName(argType));
      }
    }

    return TypeName(name, typeArguments);
  }

  /// Get a simple type name from a DartType
  String _getSimpleTypeName(DartType type) {
    if (type is InterfaceType) {
      return type.element.name;
    }
    return type.getDisplayString();
  }

  /// Get a string representation of a type
  String _getTypeString(TypeName typeName) {
    final name = typeName.name;

    if (typeName.typeArguments.isEmpty) {
      return name;
    }

    final typeArgs =
        typeName.typeArguments.map((t) => _getTypeString(t)).join(', ');

    return '$name<$typeArgs>';
  }

  /// Format a constraint value based on the property type
  String _formatConstraintValue(
    TypeName typeName,
    String constraintKey,
    dynamic value,
  ) {
    // Handle numeric values - show integers without decimal points
    if ((constraintKey == 'min' ||
            constraintKey == 'max' ||
            constraintKey == 'multipleOf') &&
        value is double &&
        value.truncateToDouble() == value &&
        typeName.name == 'int') {
      return value.toInt().toString();
    }

    // Handle string values
    if (value is String) {
      return "'$value'";
    }

    // Handle list values
    if (value is List) {
      final items = value.map((item) {
        if (item is String) {
          return "'$item'";
        }
        return item.toString();
      }).join(', ');
      return '[$items]';
    }

    return value.toString();
  }

  /// Find model dependencies for a list of properties
  Set<String> _findDependencies(List<PropertyInfo> properties) {
    final dependencies = <String>{};

    for (final property in properties) {
      final typeStr = property.typeName.name;

      // Skip primitive types and collections
      if (typeStr == 'String' ||
          typeStr == 'int' ||
          typeStr == 'double' ||
          typeStr == 'bool' ||
          typeStr == 'boolean' ||
          typeStr == 'List' ||
          typeStr == 'Map') {
        continue;
      }

      // Add the dependency
      dependencies.add(typeStr);

      // For list types with model items
      if (typeStr == 'List' && property.typeName.typeArguments.isNotEmpty) {
        final itemType = property.typeName.typeArguments[0].name;
        if (itemType != 'String' &&
            itemType != 'int' &&
            itemType != 'double' &&
            itemType != 'bool' &&
            itemType != 'boolean') {
          dependencies.add(itemType);
        }
      }
    }

    return dependencies;
  }

  /// Check if a type is a primitive (not a custom model)
  bool _isPrimitiveType(TypeName typeName) {
    final typeStr = typeName.name;
    return typeStr == 'String' ||
        typeStr == 'int' ||
        typeStr == 'double' ||
        typeStr == 'bool' ||
        typeStr == 'boolean' ||
        typeStr == 'List' ||
        typeStr == 'Map';
  }
}

/// Data class for Schema annotation properties
class SchemaData {
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final String? schemaClassName;

  SchemaData({
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.schemaClassName,
  });
}

/// Information about a property including its constraints
class PropertyInfo {
  final String name;
  final TypeName typeName;
  bool isRequired;
  bool isNullable;
  final List<PropertyConstraintInfo> constraints;

  PropertyInfo({
    required this.name,
    required this.typeName,
    this.isRequired = false,
    this.isNullable = false,
    required this.constraints,
  });
}

/// Type name with type arguments
class TypeName {
  final String name;
  final List<TypeName> typeArguments;

  TypeName(this.name, this.typeArguments);
}

/// Information about a property constraint
class PropertyConstraintInfo {
  final String constraintKey;
  final Map<String, Object?> parameters;

  PropertyConstraintInfo({
    required this.constraintKey,
    required this.parameters,
  });
}

/// Required constraint implementation
class RequiredConstraint extends PropertyConstraintInfo {
  RequiredConstraint() : super(constraintKey: 'required', parameters: {});
}

/// Nullable constraint implementation
class NullableConstraint extends PropertyConstraintInfo {
  NullableConstraint() : super(constraintKey: 'nullable', parameters: {});
}
