import 'package:ack/ack.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

// Reuse existing analyzers
import 'analyzers/class_analyzer.dart';
import 'analyzers/constraint_analyzer.dart';
import 'analyzers/property_analyzer.dart';
import 'analyzers/type_analyzer.dart';
import 'models/class_info.dart';
import 'models/property_info.dart';
import 'models/schema_data.dart';
import 'models/sealed_class_info.dart';
import 'models/type_name.dart';
import 'utils/ack_types.dart';

/// Single generator class - no separate builders (KISS)
class AckSchemaGenerator extends GeneratorForAnnotation<Schema> {
  final _formatter = DartFormatter();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `${element.displayName}`.',
        element: element,
      );
    }

    // Extract schema data
    final schemaData = _extractSchemaData(annotation);

    // Skip subclasses that are part of a sealed discriminated union
    // They will be generated as part of the sealed class processing
    if (_isSubclassOfSealedDiscriminatedUnion(element)) {
      return ''; // Return empty string to skip generation
    }

    // Analyze class (reuse existing analyzer)
    ClassInfo classInfo = ClassAnalyzer.analyzeClass(
      element,
      schemaData.additionalPropertiesField,
    );

    // Add dependencies
    final dependencies =
        ClassAnalyzer.findClassDependencies(classInfo.properties);
    classInfo = classInfo.withDependencies(dependencies);

    // Special handling for sealed classes with discriminated unions
    if (element.isSealed && schemaData.discriminatedKey != null) {
      final sealedInfo = ClassAnalyzer.analyzeSealedClass(element, schemaData);
      if (sealedInfo != null) {
        return _generateDiscriminatedUnionSchema(
          element,
          schemaData,
          sealedInfo,
        );
      }
    }

    // Build schema class with code_builder
    final schemaClass = _buildSchemaClass(
      element,
      element.name,
      schemaData,
      classInfo,
      element.isAbstract,
    );

    // Generate and format
    final library = Library((b) => b.body.add(schemaClass));
    final code =
        library.accept(DartEmitter(useNullSafetySyntax: true)).toString();

    try {
      return _formatter.format(code);
    } catch (_) {
      return code; // Return unformatted if formatting fails
    }
  }

  SchemaData _extractSchemaData(ConstantReader annotation) {
    return SchemaData(
      description: annotation.peek('description')?.stringValue,
      additionalProperties:
          annotation.peek('additionalProperties')?.boolValue ?? false,
      additionalPropertiesField:
          annotation.peek('additionalPropertiesField')?.stringValue,
      schemaClassName: annotation.peek('schemaClassName')?.stringValue,
      discriminatedKey: annotation.peek('discriminatedKey')?.stringValue,
      discriminatedValue: annotation.peek('discriminatedValue')?.stringValue,
    );
  }

  Class _buildSchemaClass(
    ClassElement element,
    String modelClassName,
    SchemaData schemaData,
    ClassInfo classInfo,
    bool isAbstract,
  ) {
    final schemaClassName =
        schemaData.schemaClassName ?? '${modelClassName}Schema';

    return Class(
      (b) => b
        ..name = schemaClassName
        ..extend = refer('SchemaModel<$modelClassName>')
        ..docs.add('/// Generated schema for $modelClassName')
        ..docs.addAll(
          schemaData.description != null
              ? ['/// ${schemaData.description}']
              : [],
        )
        ..fields.add(_buildSchemaField())
        ..constructors.add(_buildConstructor())
        ..methods.addAll([
          _buildCreateSchemaMethod(classInfo, schemaData),
          _buildEnsureInitializeMethod(
            schemaClassName,
            modelClassName,
            classInfo,
          ),
          _buildGetSchemaMethod(),
          ..._buildPropertyGetters(classInfo, schemaData),
          if (schemaData.additionalPropertiesField != null)
            _buildAdditionalPropertiesGetter(classInfo, schemaData),
          _buildToModelMethod(
            modelClassName,
            classInfo,
            schemaData,
            isAbstract,
            element,
          ),
          _buildToJsonSchemaMethod(),
        ]),
    );
  }

  Field _buildSchemaField() {
    return Field(
      (b) => b
        ..name = 'schema'
        ..static = true
        ..modifier = FieldModifier.final$
        ..type = refer(AckTypes.objectSchema)
        ..assignment = const Code('_createSchema()'),
    );
  }

  Constructor _buildConstructor() {
    return Constructor(
      (b) => b
        ..optionalParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer(AckTypes.objectType)
              ..defaultTo = const Code('null'),
          ),
        )
        ..initializers.add(const Code('super(value)')),
    );
  }

  Method _buildCreateSchemaMethod(ClassInfo classInfo, SchemaData schemaData) {
    final properties = classInfo
        .getPropertiesExcluding(schemaData.additionalPropertiesField)
        .values;

    final propertyCode = _buildPropertySchemaCode(properties);
    final requiredProps = _buildRequiredPropsString(classInfo, schemaData);

    final body = '''
    return Ack.object(
      {
$propertyCode
      },
      required: [$requiredProps],
      additionalProperties: ${schemaData.additionalProperties},
    );''';

    return Method(
      (b) => b
        ..name = '_createSchema'
        ..static = true
        ..returns = refer(AckTypes.objectSchema)
        ..body = Code(body),
    );
  }

  String _buildPropertySchemaExpression(PropertyInfo property) {
    // Direct string building (matches current implementation)
    var expr = TypeAnalyzer.getBaseSchemaType(property.typeName);

    // Apply constraints
    for (final constraint in property.constraints) {
      expr = ConstraintAnalyzer.applyConstraint(expr, constraint);
    }

    // Apply nullable
    if (property.isNullable) {
      expr += '.nullable()';
    }

    return expr;
  }

  Method _buildEnsureInitializeMethod(
    String schemaClassName,
    String modelClassName,
    ClassInfo classInfo,
  ) {
    final bodyParts = <String>[
      '    SchemaRegistry.register<$modelClassName, $schemaClassName>(',
      '      (data) => $schemaClassName(data),',
      '    );',
    ];

    if (classInfo.dependencies.isNotEmpty) {
      bodyParts.add('    // Register schema dependencies');
      for (final dep in classInfo.dependencies) {
        bodyParts.add('    ${dep}Schema.ensureInitialize();');
      }
    }

    return Method(
      (b) => b
        ..name = 'ensureInitialize'
        ..static = true
        ..returns = refer('void')
        ..docs
            .add('/// Ensures this schema and its dependencies are registered')
        ..body = Code(bodyParts.join('\n')),
    );
  }

  Method _buildGetSchemaMethod() {
    return Method(
      (b) => b
        ..name = 'getSchema'
        ..returns = refer(AckTypes.ackSchema)
        ..annotations.add(refer('override'))
        ..body = const Code('return schema;'),
    );
  }

  List<Method> _buildPropertyGetters(
    ClassInfo classInfo,
    SchemaData schemaData,
  ) {
    final properties = classInfo
        .getPropertiesExcluding(schemaData.additionalPropertiesField)
        .values;

    return properties.map((prop) => _buildPropertyGetter(prop)).toList();
  }

  Method _buildPropertyGetter(PropertyInfo property) {
    final typeStr = TypeAnalyzer.getTypeString(property.typeName);
    final isNullable = property.isNullable;
    final body = _generateGetterBody(property, typeStr);

    // Determine the correct return type
    String returnType;
    if (!TypeAnalyzer.isPrimitiveType(property.typeName)) {
      // For custom model types, return the schema type
      final schemaType = '${property.typeName.name}Schema';
      returnType = isNullable ? '$schemaType?' : schemaType;
    } else if (typeStr.startsWith('List<') &&
        !TypeAnalyzer.isPrimitiveListType(property.typeName)) {
      // For lists of custom models, return List<SchemaType>
      final itemType =
          property.typeName.typeArguments.firstOrNull?.name ?? 'dynamic';
      final schemaType = '${itemType}Schema';
      returnType = isNullable ? 'List<$schemaType>?' : 'List<$schemaType>';
    } else {
      // For primitive types, use the original type
      returnType = isNullable ? '$typeStr?' : typeStr;
    }

    return Method(
      (b) => b
        ..name = property.name
        ..type = MethodType.getter
        ..returns = refer(returnType)
        ..body = Code(body),
    );
  }

  String _generateGetterBody(PropertyInfo property, String typeStr) {
    final propName = property.name;
    final nullSuffix = property.isNullable ? '' : '!';

    // Custom model types
    if (!TypeAnalyzer.isPrimitiveType(property.typeName)) {
      final schemaType = '${property.typeName.name}Schema';
      if (property.isNullable) {
        return '''final map = getValue<Map<String, dynamic>>('$propName');
    return map == null ? null : $schemaType(map);''';
      }
      return 'return $schemaType(getValue<Map<String, dynamic>>(\'$propName\')!);';
    }

    // List types with models
    if (typeStr.startsWith('List<') &&
        !TypeAnalyzer.isPrimitiveListType(property.typeName)) {
      final itemType =
          property.typeName.typeArguments.firstOrNull?.name ?? 'dynamic';
      final schemaType = '${itemType}Schema';
      if (property.isNullable) {
        return '''final list = getValue<List<dynamic>>('$propName');
    return list?.map((item) => $schemaType(item as Map<String, dynamic>)).toList();''';
      }
      return '''return getValue<List<dynamic>>('$propName')!
        .map((item) => $schemaType(item as Map<String, dynamic>))
        .toList();''';
    }

    // Simple types
    return "return getValue<$typeStr>('$propName')$nullSuffix;";
  }

  Method _buildAdditionalPropertiesGetter(
    ClassInfo classInfo,
    SchemaData schemaData,
  ) {
    final fieldName = schemaData.additionalPropertiesField!;
    final knownFields = classInfo
        .getPropertiesExcluding(schemaData.additionalPropertiesField)
        .values
        .map((p) => "'${p.name}'")
        .toSet();

    final body = '''
    final map = toMap();
    final knownFields = {${knownFields.join(', ')}};
    return Map.fromEntries(
      map.entries.where((e) => !knownFields.contains(e.key))
    );''';

    return Method(
      (b) => b
        ..name = fieldName
        ..type = MethodType.getter
        ..returns = refer(AckTypes.mapStringObject)
        ..body = Code(body),
    );
  }

  Method _buildToModelMethod(
    String modelClassName,
    ClassInfo classInfo,
    SchemaData schemaData,
    bool isAbstract,
    ClassElement element, // Add element parameter
  ) {
    final validationCheck = '''
    if (!isValid) {
      throw AckException(getErrors()!);
    }''';

    String modelCreation;
    if (isAbstract) {
      modelCreation = '''
    throw UnimplementedError(
        'Cannot instantiate abstract class $modelClassName. Use a concrete subclass instead.');''';
    } else {
      modelCreation = _buildModelConstructorCall(
        modelClassName,
        classInfo,
        schemaData,
        element,
      );
    }

    return Method(
      (b) => b
        ..name = 'toModel'
        ..returns = refer(modelClassName)
        ..annotations.add(refer('override'))
        ..body = Code('$validationCheck\n$modelCreation'),
    );
  }

  String _buildModelConstructorCall(
    String modelClassName,
    ClassInfo classInfo,
    SchemaData schemaData,
    ClassElement element,
  ) {
    final constructor = ClassAnalyzer.findPrimaryConstructor(element);
    if (constructor == null) {
      return 'return $modelClassName();';
    }

    final args = constructor.parameters
        .map((param) {
          final property = classInfo.properties[param.name];
          if (property == null) return null;

          final conversion = _getPropertyConversion(property, schemaData);
          return param.isNamed ? '${param.name}: $conversion' : conversion;
        })
        .whereType<String>()
        .toList();

    final argsString = args.map((arg) => '      $arg,').join('\n');
    return '''
    return $modelClassName(
$argsString
    );''';
  }

  String _getPropertyConversion(PropertyInfo property, SchemaData schemaData) {
    // Handle additional properties field
    if (property.name == schemaData.additionalPropertiesField) {
      return schemaData.additionalPropertiesField ?? 'metadata';
    }

    // Handle custom model conversion
    if (PropertyAnalyzer.needsCustomConversion(property)) {
      if (!TypeAnalyzer.isPrimitiveType(property.typeName)) {
        // Convert nested models
        return property.isNullable
            ? '${property.name}?.toModel()'
            : '${property.name}.toModel()';
      }

      // Convert lists of models
      final typeStr = TypeAnalyzer.getTypeString(property.typeName);
      if (typeStr.startsWith('List<') &&
          !TypeAnalyzer.isPrimitiveListType(property.typeName)) {
        return property.isNullable
            ? '${property.name}?.map((item) => item.toModel()).toList()'
            : '${property.name}.map((item) => item.toModel()).toList()';
      }
    }

    // Simple property reference
    return property.name;
  }

  Method _buildToJsonSchemaMethod() {
    final body = '''
    final converter = JsonSchemaConverter(schema: schema);
    return converter.toSchema();''';

    return Method(
      (b) => b
        ..name = 'toJsonSchema'
        ..static = true
        ..returns = refer(AckTypes.mapStringObject)
        ..docs.add('/// Convert the schema to a JSON Schema')
        ..body = Code(body),
    );
  }

  String _generateDiscriminatedUnionSchema(
    ClassElement element,
    SchemaData schemaData,
    SealedClassInfo sealedInfo,
  ) {
    final schemaClassName =
        schemaData.schemaClassName ?? '${element.name}Schema';

    // Generate base schema with inheritance support
    final baseSchemaCode = _generateBaseSchema(element, schemaData, sealedInfo);

    // Generate base getters (reuse existing logic)
    final baseGetters = _generateBaseGetters(element, sealedInfo);

    // Generate pattern matching (reuse existing logic)
    final patternMatching = _generatePatternMatching(sealedInfo);

    // Generate discriminated schema method
    final discriminatedSchemaCode =
        _generateDiscriminatedSchemaMethod(sealedInfo);

    // Generate dependencies
    final dependencies = sealedInfo.subclasses
        .map((subclass) => '${subclass.name}Schema.ensureInitialize();')
        .join('\n    ');

    // Generate subclass schemas
    final subclassSchemas = <String>[];
    for (final subclass in sealedInfo.subclasses) {
      final subclassSchema = _generateSubclassSchema(
        subclass,
        element,
        sealedInfo,
      );
      subclassSchemas.add(subclassSchema);
    }

    // Generate the inheritance-based discriminated schema class
    final baseSchemaClass = '''
/// Generated base schema for ${element.name} with inheritance support
${schemaData.description != null ? '/// ${schemaData.description}' : ''}
class $schemaClassName<T extends ${element.name}> extends SchemaModel<T> {
  // Constructor that validates input
  $schemaClassName([Object? value = null]) : super(value);

  // Main discriminated schema (default entry point for ${element.name})
  static final DiscriminatedObjectSchema schema = _createDiscriminatedSchema();

$baseSchemaCode

$discriminatedSchemaCode

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<${element.name}, $schemaClassName>(
      (data) => $schemaClassName(data),
    );
    // Register schema dependencies
    $dependencies
  }

  // Override to return the discriminated schema for validation
  @override
  AckSchema getSchema() {
    return schema;
  }

$baseGetters

$patternMatching

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = JsonSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}''';

    // Combine all schemas
    return [baseSchemaClass, ...subclassSchemas].join('\n\n');
  }

  String _buildPropertyGetterString(PropertyInfo property) {
    final method = _buildPropertyGetter(property);
    final emitter = DartEmitter(useNullSafetySyntax: true);
    final code = method.accept(emitter).toString();

    // Add proper indentation for string context
    // Skip comment lines that start with '//'
    return code
        .split('\n')
        .where((line) => !line.trim().startsWith('//'))
        .map((line) => '  $line')
        .join('\n');
  }

  String _toCamelCase(String input) {
    if (!input.contains(RegExp(r'[_-]'))) return input;

    final parts = input.split(RegExp(r'[_-]'));
    return parts.first +
        parts
            .skip(1)
            .map(
              (p) => p.isEmpty
                  ? ''
                  : p[0].toUpperCase() + p.substring(1).toLowerCase(),
            )
            .join();
  }

  /// Check if a class is a subclass of a sealed discriminated union
  /// This prevents duplicate generation of subclass schemas
  bool _isSubclassOfSealedDiscriminatedUnion(ClassElement element) {
    // Simple check: if this class has a discriminatedValue annotation,
    // it's part of a discriminated union and should not be generated separately
    for (final annotation in element.metadata) {
      if (annotation.element?.displayName == 'Schema') {
        final reader = ConstantReader(annotation.computeConstantValue());
        final discriminatedValue =
            reader.peek('discriminatedValue')?.stringValue;
        if (discriminatedValue != null) {
          // This class has a discriminatedValue, so it's part of a discriminated union
          // Check if the superclass is sealed to confirm
          final supertype = element.supertype;
          if (supertype != null) {
            final superElement = supertype.element;
            if (superElement is ClassElement && superElement.isSealed) {
              return true; // This is a subclass of a sealed discriminated union
            }
          }
        }
      }
    }

    return false;
  }

  /// Generate base schema with common fields + discriminator
  /// Reuses existing property generation patterns for DRY compliance
  String _generateBaseSchema(
    ClassElement element,
    SchemaData schemaData,
    SealedClassInfo sealedInfo,
  ) {
    // Create enhanced ClassInfo with discriminator field
    final enhancedClassInfo = _addDiscriminatorToClassInfo(
      ClassAnalyzer.analyzeClass(element, schemaData.additionalPropertiesField),
      sealedInfo.discriminatorKey,
    );

    // Reuse existing schema generation pattern
    return _buildBaseSchemaMethodString(enhancedClassInfo, schemaData);
  }

  /// Add discriminator field to ClassInfo as PropertyInfo for consistent handling
  ClassInfo _addDiscriminatorToClassInfo(
    ClassInfo classInfo,
    String discriminatorKey,
  ) {
    // Create discriminator as PropertyInfo to reuse existing patterns
    final discriminatorProperty = PropertyInfo(
      name: discriminatorKey,
      typeName: const TypeName('String', []),
      isRequired: true,
      isNullable: false,
      constraints: [],
    );

    // Add discriminator to properties map
    final enhancedProperties =
        Map<String, PropertyInfo>.from(classInfo.properties);
    enhancedProperties[discriminatorKey] = discriminatorProperty;

    return ClassInfo(
      name: classInfo.name,
      constructorParams: classInfo.constructorParams,
      properties: enhancedProperties,
      dependencies: classInfo.dependencies,
    );
  }

  /// Build base schema method string reusing existing property generation logic
  String _buildBaseSchemaMethodString(
    ClassInfo classInfo,
    SchemaData schemaData,
  ) {
    // Reuse existing property generation logic from _buildCreateSchemaMethod
    final properties = classInfo
        .getPropertiesExcluding(schemaData.additionalPropertiesField)
        .values;

    final propertyCode = _buildPropertySchemaCode(properties);
    final requiredProps = _buildRequiredPropsString(classInfo, schemaData);

    return '''
  static final ObjectSchema baseSchema = _createBaseSchema();

  static ObjectSchema _createBaseSchema() {
    return Ack.object(
      {
$propertyCode
      },
      required: [$requiredProps],
      additionalProperties: ${schemaData.additionalProperties},
    );
  }''';
  }

  /// Shared helper: Build property schema code from properties
  String _buildPropertySchemaCode(Iterable<PropertyInfo> properties) {
    return properties.map((prop) {
      final schemaExpr = _buildPropertySchemaExpression(prop);
      return "        '${prop.name}': $schemaExpr,";
    }).join('\n');
  }

  /// Shared helper: Build required properties string for schema generation
  String _buildRequiredPropsString(ClassInfo classInfo, SchemaData schemaData) {
    return classInfo
        .getRequiredProperties(
          excludeField: schemaData.additionalPropertiesField,
        )
        .map((p) => "'${p.name}'")
        .join(', ');
  }

  /// Shared helper: Build subclass property schema code with different format
  String _buildSubclassPropertySchemaCode(List<PropertyInfo> properties) {
    return properties
        .map(
          (prop) => "'${prop.name}': ${_buildPropertySchemaExpression(prop)}",
        )
        .join(',\n        ');
  }

  /// Shared helper: Build required fields string from property list
  String _buildRequiredFieldsString(List<PropertyInfo> properties) {
    return properties
        .where((prop) => prop.isRequired)
        .map((prop) => "'${prop.name}'")
        .join(', ');
  }

  /// Generate base getters for inheritance
  /// Reuses existing _buildPropertyGetterString for all getters including discriminator
  String _generateBaseGetters(
    ClassElement element,
    SealedClassInfo sealedInfo,
  ) {
    // Create enhanced ClassInfo with discriminator field for consistent handling
    final enhancedClassInfo = _addDiscriminatorToClassInfo(
      ClassAnalyzer.analyzeClass(element, null),
      sealedInfo.discriminatorKey,
    );

    final getters = <String>[];

    // Generate all getters using existing pattern (including discriminator)
    for (final prop in enhancedClassInfo.properties.values) {
      getters.add(_buildPropertyGetterString(prop));
    }

    return getters.join('\n\n');
  }

  /// Generate pattern matching methods
  /// Reuses existing _toCamelCase for consistency
  String _generatePatternMatching(SealedClassInfo sealedInfo) {
    final whenParameters = sealedInfo.discriminatorMapping.entries
        .map(
          (entry) =>
              'required R Function(${entry.value.name}Schema) ${_toCamelCase(entry.key)}',
        )
        .join(',\n    ');

    final whenCases = sealedInfo.discriminatorMapping.entries
        .map(
          (entry) =>
              "      case '${entry.key}':\n        return ${_toCamelCase(entry.key)}(${entry.value.name}Schema(data));",
        )
        .join('\n');

    final maybeWhenParameters = sealedInfo.discriminatorMapping.entries
        .map(
          (entry) =>
              'R Function(${entry.value.name}Schema)? ${_toCamelCase(entry.key)}',
        )
        .join(',\n    ');

    final maybeWhenCases = sealedInfo.discriminatorMapping.entries
        .map(
          (entry) =>
              "      case '${entry.key}':\n        return ${_toCamelCase(entry.key)}?.call(${entry.value.name}Schema(data)) ?? orElse();",
        )
        .join('\n');

    return '''  R when<R>({
    $whenParameters,
  }) {
    switch (${sealedInfo.discriminatorKey}) {
$whenCases
      default:
        throw StateError('Unknown ${sealedInfo.sealedClass.name.toLowerCase()} type: \$${sealedInfo.discriminatorKey}');
    }
  }

  R maybeWhen<R>({
    $maybeWhenParameters,
    required R Function() orElse,
  }) {
    switch (${sealedInfo.discriminatorKey}) {
$maybeWhenCases
      default:
        return orElse();
    }
  }''';
  }

  /// Generate discriminated schema method
  String _generateDiscriminatedSchemaMethod(SealedClassInfo sealedInfo) {
    final discriminatorMappingEntries = sealedInfo.discriminatorMapping.entries
        .map((entry) => "'${entry.key}': ${entry.value.name}Schema.schema")
        .join(',\n        ');

    return '''  static DiscriminatedObjectSchema _createDiscriminatedSchema() {
    return Ack.discriminated(
      discriminatorKey: '${sealedInfo.discriminatorKey}',
      schemas: {
        $discriminatorMappingEntries,
      },
    );
  }''';
  }

  /// Generate subclass schema that extends the base schema
  /// Reuses existing analysis and generation methods for consistency
  String _generateSubclassSchema(
    ClassElement subclassElement,
    ClassElement baseElement,
    SealedClassInfo sealedInfo,
  ) {
    final subclassName = subclassElement.name;
    final baseName = baseElement.name;
    final schemaClassName = '${subclassName}Schema';

    // Analyze subclass properties
    final subclassInfo = ClassAnalyzer.analyzeClass(subclassElement, null);

    // Get base property names to exclude from subclass
    final baseClassInfo = ClassAnalyzer.analyzeClass(baseElement, null);
    final basePropertyNames = baseClassInfo.properties.keys.toSet();

    // Get subclass-specific properties (excluding base properties)
    final subclassProperties = subclassInfo.properties.values
        .where((prop) => !basePropertyNames.contains(prop.name))
        .toList();

    // Build subclass property schema strings using shared helper
    final propertySchemas =
        _buildSubclassPropertySchemaCode(subclassProperties);

    // Build required fields for subclass using shared helper
    final requiredFields = _buildRequiredFieldsString(subclassProperties);

    // Generate subclass-specific getters
    final subclassGetters = subclassProperties
        .map((prop) => _buildPropertyGetterString(prop))
        .join('\n\n');

    // Get description from subclass annotation
    final description = _getClassDescription(subclassElement);

    return '''
/// Generated schema for $subclassName extending ${baseName}Schema
${description != null ? '/// $description' : ''}
class $schemaClassName extends ${baseName}Schema<$subclassName> {
  // Constructor that validates input
  $schemaClassName([Object? value = null]) : super(value);

  // Extended schema that inherits from base schema
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema by extending base schema
  static ObjectSchema _createSchema() {
    return ${baseName}Schema.baseSchema.extend(
      {
        ${propertySchemas.isNotEmpty ? propertySchemas : '// No additional properties'}
      },
      ${requiredFields.isNotEmpty ? 'required: [$requiredFields],' : ''}
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<$subclassName, $schemaClassName>(
      (data) => $schemaClassName(data),
    );
  }

  // Override to return the extended schema for validation
  @override
  AckSchema getSchema() {
    return schema;
  }

${subclassGetters.isNotEmpty ? '  // Subclass-specific type-safe getters (base getters inherited)\n$subclassGetters\n' : ''}
  // Model conversion methods
  @override
  $subclassName toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }
    return $subclassName(
      ${_generateToModelParameters(subclassInfo, baseElement)}
    );
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = JsonSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}''';
  }

  /// Get class description from annotation
  String? _getClassDescription(ClassElement element) {
    for (final annotation in element.metadata) {
      if (annotation.element?.displayName == 'Schema') {
        final reader = ConstantReader(annotation.computeConstantValue());
        return reader.peek('description')?.stringValue;
      }
    }
    return null;
  }

  /// Generate constructor parameters for toModel() method
  String _generateToModelParameters(
    ClassInfo classInfo,
    ClassElement baseElement,
  ) {
    // Get base properties
    final baseClassInfo = ClassAnalyzer.analyzeClass(baseElement, null);
    final allProperties = <PropertyInfo>[];

    // Add base properties first
    allProperties.addAll(baseClassInfo.properties.values);

    // Add subclass-specific properties
    final basePropertyNames = baseClassInfo.properties.keys.toSet();
    allProperties.addAll(
      classInfo.properties.values
          .where((prop) => !basePropertyNames.contains(prop.name)),
    );

    return allProperties
        .map((prop) => '${prop.name}: ${prop.name}')
        .join(',\n      ');
  }
}
