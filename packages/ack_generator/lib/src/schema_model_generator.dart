import 'package:analyzer/dart/element/element.dart';
import 'package:dart_style/dart_style.dart';

// Import new analyzer classes
import 'analyzers/class_analyzer.dart';
import 'analyzers/property_analyzer.dart';
import 'analyzers/constraint_analyzer.dart';
import 'analyzers/type_analyzer.dart';

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

    // Analyze the class using the new ClassAnalyzer
    ClassInfo classInfo = ClassAnalyzer.analyzeClass(
      element,
      modelData.additionalPropertiesField,
    );

    // Calculate dependencies
    final dependencies = ClassAnalyzer.findClassDependencies(classInfo.properties);
    classInfo = classInfo.withDependencies(dependencies);

    // Generate the schema code
    final code = _generateSchemaClass(
      modelClassName: className,
      schemaClassName: schemaClassName,
      modelData: modelData,
      classInfo: classInfo,
      isAbstract: element.isAbstract,
    );

    try {
      return formatter.format(code);
    } catch (e) {
      // Return unformatted code if formatting fails
      return code;
    }
  }


  /// Generate the schema class
  String _generateSchemaClass({
    required String modelClassName,
    required String schemaClassName,
    required SchemaData modelData,
    required ClassInfo classInfo,
    required bool isAbstract,
  }) {
    // Get properties excluding additional properties field
    final properties = classInfo.getPropertiesExcluding(
      modelData.additionalPropertiesField,
    );

    // Generate property schemas
    final propertySchemas = properties.values
        .map(
          (property) =>
              "        '${property.name}': ${_generatePropertySchema(property)},",
        )
        .join('\n');

    // Required properties
    final requiredProps = classInfo
        .getRequiredProperties(excludeField: modelData.additionalPropertiesField)
        .map((p) => '\'${p.name}\'')
        .join(', ');

    // Dependencies code
    final dependenciesCode = classInfo.dependencies.isNotEmpty
        ? '''
    // Register schema dependencies
    ${classInfo.dependencies.map((dependency) => '${dependency}Schema.ensureInitialize();').join('\n    ')}'''
        : '';

    // Type-safe getters
    final getters = properties.values.map((property) {
      final typeStr = TypeAnalyzer.getTypeString(property.typeName);
      final nullSuffix = property.isNullable ? '' : '!';
      final returnType = property.isNullable ? '$typeStr?' : typeStr;

      // For custom model types, we need special handling
      if (!TypeAnalyzer.isPrimitiveType(property.typeName)) {
        // Generate a getter that properly handles nested schema objects
        final schemaType = '${property.typeName.name}Schema';
        final schemaReturnType =
            property.isNullable ? '$schemaType?' : schemaType;

        if (property.isNullable) {
          return '''  $schemaReturnType get ${property.name} {
    final map = getValue<Map<String, dynamic>>('${property.name}');
    return map == null ? null : $schemaType(map);
  }''';
        }
        return '''  $schemaReturnType get ${property.name} {
    return $schemaType(getValue<Map<String, dynamic>>('${property.name}')!);
  }''';
      }

      // For list types with model items, we also need special handling
      if (typeStr.startsWith('List<') &&
          !TypeAnalyzer.isPrimitiveListType(property.typeName)) {
        final itemType = property.typeName.typeArguments[0].name;
        final schemaType = '${itemType}Schema';
        final listType = 'List<$schemaType>';
        final schemaReturnType = property.isNullable ? '$listType?' : listType;

        if (property.isNullable) {
          return '''  $schemaReturnType get ${property.name} {
    final list = getValue<List<dynamic>>('${property.name}');
    return list?.map((item) => $schemaType(item as Map<String, dynamic>)).toList();
  }''';
        }
        return '''  $schemaReturnType get ${property.name} {
    return getValue<List<dynamic>>('${property.name}')!.map((item) => $schemaType(item as Map<String, dynamic>)).toList();
  }''';
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
    final knownFields = [${properties.values.map((p) => '\'${p.name}\'').join(', ')}];

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
    final allProperties = classInfo.properties.values;
    final modelConversionProps = allProperties.map((property) {
      if (property.name == modelData.additionalPropertiesField) {
        return '      ${property.name}: ${modelData.additionalPropertiesField},';
      }
      final conversion = _generateModelConversion(property);
      return '      ${property.name}: $conversion,';
    }).join('\n');

    // ToMap properties
    final toMapProps = properties.values.map((property) {
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

    return '''$classDoc
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
      (data) => $schemaClassName(data),
    );
$dependenciesCode
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  $schemaClassName([Object? value]) : super(value);

  // Type-safe getters
$getters

$metadataGetter
  // Model conversion methods
  @override
  $modelClassName toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    ${isAbstract 
      ? 'throw UnimplementedError(\'Cannot instantiate abstract class $modelClassName. Use a concrete subclass instead.\');'
      : '''return $modelClassName(
$modelConversionProps
    );'''}
  }

  /// Parses the input and returns a $modelClassName instance.
  /// Throws an [AckException] if validation fails.
  static $modelClassName parse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    if (result.isOk) {
      return $schemaClassName(result.getOrNull()).toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a $modelClassName instance.
  /// Returns null if validation fails.
  static $modelClassName? tryParse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    return result.isOk ? $schemaClassName(result.getOrNull()).toModel() : null;
  }

  /// Create a schema from a model instance
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

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}''';
  }

  /// Generate schema code for a property
  String _generatePropertySchema(PropertyInfo property) {
    // Get the base schema type using TypeAnalyzer
    String baseSchema = TypeAnalyzer.getBaseSchemaType(property.typeName);

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
    // Use PropertyAnalyzer to check if custom conversion is needed
    if (PropertyAnalyzer.needsCustomConversion(property)) {
      final typeStr = TypeAnalyzer.getTypeString(property.typeName);
      
      // For nested model types, convert properly
      if (!TypeAnalyzer.isPrimitiveType(property.typeName)) {
        // Handle nullable properties with null-safe operator
        return property.isNullable 
            ? '${property.name}?.toModel()' 
            : '${property.name}.toModel()';
      }

      // For list types with models
      if (typeStr.startsWith('List<') &&
          !TypeAnalyzer.isPrimitiveListType(property.typeName)) {
        // Handle nullable lists
        return property.isNullable
            ? '${property.name}?.map((item) => item.toModel()).toList()'
            : '${property.name}.map((item) => item.toModel()).toList()';
      }
    }

    // Simple values don't need conversion
    return property.name;
  }

  /// Generate conversion code for a property in toMap
  String _generateToMapConversion(PropertyInfo property, String varName) {
    // Use PropertyAnalyzer to check if custom conversion is needed
    if (PropertyAnalyzer.needsCustomConversion(property)) {
      final typeStr = TypeAnalyzer.getTypeString(property.typeName);
      
      // For nested model types
      if (!TypeAnalyzer.isPrimitiveType(property.typeName)) {
        // Handle nullable properties properly with non-null assertion
        return property.isNullable
            ? '$varName != null ? ${property.typeName.name}Schema.toMapFromModel($varName!) : null'
            : '${property.typeName.name}Schema.toMapFromModel($varName)';
      }

      // For list types with models
      if (typeStr.startsWith('List<') &&
          !TypeAnalyzer.isPrimitiveListType(property.typeName)) {
        final itemTypeName = property.typeName.typeArguments[0].name;
        // Handle nullable lists
        return property.isNullable
            ? '$varName?.map((item) => ${itemTypeName}Schema.toMapFromModel(item)).toList()'
            : '$varName.map((item) => ${itemTypeName}Schema.toMapFromModel(item)).toList()';
      }
    }

    // Simple values don't need conversion
    return varName;
  }

}

/// Data class for Schema annotation properties
class SchemaData {
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final String? schemaClassName;
  final String? discriminatedKey;
  final String? discriminatedValue;

  const SchemaData({
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.schemaClassName,
    this.discriminatedKey,
    this.discriminatedValue,
  });
}

