import 'package:ack/ack.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzers/class_analyzer.dart';
import 'analyzers/constraint_analyzer.dart';
import 'analyzers/type_analyzer.dart';
import 'models/class_info.dart';
import 'models/discriminated_class_info.dart';
import 'models/property_info.dart';
import 'models/schema_data.dart';
import 'models/type_name.dart';
import 'utils/ack_types.dart';

/// Generator for Ack schema classes
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
    if (_isSubclassOfDiscriminatedUnion(element)) {
      return ''; // Return empty string to skip generation
    }

    // Analyze class
    ClassInfo classInfo = ClassAnalyzer.analyzeClass(
      element,
      schemaData.additionalPropertiesField,
    );

    // Add dependencies
    final dependencies = ClassAnalyzer.findClassDependencies(
      classInfo.properties,
    );
    classInfo = classInfo.withDependencies(dependencies);

    // Special handling for discriminated unions (sealed or abstract classes)
    if ((element.isSealed || element.isAbstract) &&
        schemaData.discriminatedKey != null) {
      final discriminatedInfo = ClassAnalyzer.analyzeDiscriminatedClass(
        element,
        schemaData,
      );
      if (discriminatedInfo != null) {
        return _generateDiscriminatedUnionSchema(
          element,
          schemaData,
          discriminatedInfo,
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
    } catch (e) {
      throw Exception(
        'Failed to format generated code for ${element.name}. '
        'This usually indicates a syntax error in the generated code.\n'
        'Error: $e\n'
        'Generated code:\n$code',
      );
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
        ..extend = refer('SchemaModel<$schemaClassName>')
        ..docs.add('/// Generated schema for $modelClassName')
        ..docs.addAll(
          schemaData.description != null
              ? ['/// ${schemaData.description}']
              : [],
        )
        ..fields.add(_buildSchemaField(classInfo, schemaData))
        ..constructors.addAll([
          _buildDefaultConstructor(),
          _buildValidConstructor(),
        ])
        ..methods.addAll([
          _buildParseMethod(schemaClassName),
          _buildEnsureInitializeMethod(
            schemaClassName,
            modelClassName,
            classInfo,
          ),
          _buildDefinitionMethod(),
          ..._buildPropertyGetters(classInfo, schemaData),
          if (schemaData.additionalPropertiesField != null)
            _buildAdditionalPropertiesGetter(classInfo, schemaData),
          _buildToJsonSchemaMethod(),
        ]),
    );
  }

  Field _buildSchemaField(ClassInfo classInfo, SchemaData schemaData) {
    return Field(
      (b) => b
        ..name = 'schema'
        ..static = true
        ..modifier = FieldModifier.final$
        ..type = refer(AckTypes.objectSchema)
        ..assignment = Code(_buildSchemaExpression(classInfo, schemaData)),
    );
  }

  String _buildSchemaExpression(ClassInfo classInfo, SchemaData schemaData) {
    final properties = classInfo
        .getPropertiesExcluding(schemaData.additionalPropertiesField)
        .values;

    final propertyCode = _buildPropertySchemaCode(properties);
    final requiredProps = _buildRequiredPropsString(classInfo, schemaData);

    return '''Ack.object(
      {
$propertyCode
      },
      required: [$requiredProps],
      additionalProperties: ${schemaData.additionalProperties},
    )''';
  }

  Constructor _buildDefaultConstructor() {
    return Constructor(
      (b) => b
        ..constant = true
        ..docs.add('/// Default constructor for parser instances'),
    );
  }

  Constructor _buildValidConstructor() {
    return Constructor(
      (b) => b
        ..name = '_valid'
        ..constant = true
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'data'
              ..type = refer('Map<String, Object?>'),
          ),
        )
        ..initializers.add(const Code('super.valid(data)'))
        ..docs.add('/// Private constructor for validated instances'),
    );
  }

  Method _buildParseMethod(String schemaClassName) {
    return Method(
      (b) => b
        ..name = 'parse'
        ..returns = refer(schemaClassName)
        ..annotations.add(refer('override'))
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'data'
              ..type = refer('Object?'),
          ),
        )
        ..docs.add('/// Parse with validation - core implementation')
        ..body = Code('''
    final result = definition.validate(data);
    if (result.isOk) {
      final validatedData = Map<String, Object?>.from(
        result.getOrThrow(),
      );
      return $schemaClassName._valid(validatedData);
    }
    throw AckException(result.getError());
  '''),
    );
  }

  Method _buildDefinitionMethod() {
    return Method(
      (b) => b
        ..name = 'definition'
        ..type = MethodType.getter
        ..returns = refer('ObjectSchema')
        ..annotations.add(refer('override'))
        ..body = const Code('schema')
        ..lambda = true,
    );
  }

  String _buildPropertySchemaExpression(PropertyInfo property) {
    var expr = TypeAnalyzer.getSchemaModelType(property.typeName);

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
      '    SchemaRegistry.register<$schemaClassName>(',
      '      (data) => const $schemaClassName().parse(data),',
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
        ..docs.add(
          '/// Ensures this schema and its dependencies are registered',
        )
        ..body = Code(bodyParts.join('\n')),
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
      final itemType = property.typeName.typeArguments.isNotEmpty
          ? property.typeName.typeArguments.first.name
          : 'dynamic';
      final schemaType = '${itemType}Schema';
      returnType = isNullable ? 'List<$schemaType>?' : 'List<$schemaType>';
    } else {
      // For primitive types, use the original type
      returnType = isNullable ? '$typeStr?' : typeStr;
    }

    // Use arrow function only for simple primitive getters (not lists or custom types)
    final isSimpleGetter = TypeAnalyzer.isPrimitiveType(property.typeName) &&
        !property.typeName.name.startsWith('List');

    return Method(
      (b) => b
        ..name = property.name
        ..type = MethodType.getter
        ..returns = refer(returnType)
        ..body = Code(body)
        ..lambda = isSimpleGetter,
    );
  }

  String _generateGetterBody(PropertyInfo property, String typeStr) {
    final propName = property.jsonKey ?? property.name;
    final isNullable = property.isNullable;

    // Primitives - use getValue
    if (TypeAnalyzer.isPrimitiveType(property.typeName)) {
      // Skip List types - they're handled separately below
      if (property.typeName.name != 'List') {
        // Special handling for Map types to use Object? instead of dynamic
        if (property.typeName.name == 'Map') {
          return "getValue<Map<String, Object?>>('$propName')${isNullable ? '' : '!'}";
        }
        return "getValue<$typeStr>('$propName')${isNullable ? '' : '!'}";
      }
    }

    // Custom model types
    if (!property.typeName.name.startsWith('List')) {
      final schemaType = '${property.typeName.name}Schema';
      if (isNullable) {
        return '''final data = getValue<Map<String, Object?>>('$propName');
    return data != null ? const $schemaType().parse(data) : null;''';
      }
      return "return const $schemaType().parse(getValue<Map<String, Object?>>('$propName')!);";
    }

    // List types
    if (property.typeName.name == 'List' || typeStr.startsWith('List<')) {
      final itemType = property.typeName.typeArguments.isNotEmpty
          ? property.typeName.typeArguments.first
          : null;

      if (itemType != null) {
        // List of primitives
        if (TypeAnalyzer.isPrimitiveType(itemType)) {
          if (isNullable) {
            return '''final data = getValue<List?>('$propName');
    return data?.cast<${itemType.name}>();''';
          }
          return "return getValue<List>('$propName')!.cast<${itemType.name}>();";
        }

        // List of custom models
        final schemaType = '${itemType.name}Schema';
        if (isNullable) {
          return '''final data = getValue<List?>('$propName');
    if (data != null) {
      return data.whereType<Map<String, Object?>>()
          .map((item) => const $schemaType().parse(item))
          .toList();
    }
    return null;''';
        }
        return '''return getValue<List>('$propName')!
        .whereType<Map<String, Object?>>()
        .map((item) => const $schemaType().parse(item))
        .toList();''';
      }

      // If we can't determine the item type, assume it's a list of maps for schema types
      if (typeStr.contains('Schema>')) {
        final schemaTypeName =
            typeStr.substring(5, typeStr.length - 1); // Extract from List<...>
        return '''return getValue<List>('$propName')!
        .whereType<Map<String, Object?>>()
        .map((item) => $schemaTypeName(item))
        .toList();''';
      }
    }

    // Fallback - should not normally reach here for well-formed types
    // For lists, we need to get the list and handle the elements
    if (typeStr.startsWith('List<') && typeStr.endsWith('>')) {
      // Extract the inner type
      final innerType = typeStr.substring(5, typeStr.length - 1);

      // If it's a Schema type, handle it properly
      if (innerType.endsWith('Schema')) {
        return '''return getValue<List>('$propName')!
        .whereType<Map<String, dynamic>>()
        .map((item) => const $innerType().parse(item))
        .toList();''';
      }

      // Otherwise, fallback to simple cast
      return "return getValue<List>('$propName')!.cast<$innerType>();";
    }

    // Non-list fallback
    return "return getValue<$typeStr>('$propName')${isNullable ? '' : '!'};";
  }

  Method _buildAdditionalPropertiesGetter(
    ClassInfo classInfo,
    SchemaData schemaData,
  ) {
    final fieldName = schemaData.additionalPropertiesField!;
    final knownFields = classInfo
        .getPropertiesExcluding(schemaData.additionalPropertiesField)
        .values
        .map((p) => "'${p.jsonKey ?? p.name}'")
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

  Method _buildToJsonSchemaMethod() {
    return Method(
      (b) => b
        ..name = 'toJsonSchema'
        ..static = true
        ..returns = refer(AckTypes.mapStringObject)
        ..docs.add('/// Convert the schema to a JSON Schema')
        ..body = const Code(
          'JsonSchemaConverter(schema: schema).toSchema()',
        )
        ..lambda = true,
    );
  }

  String _generateDiscriminatedUnionSchema(
    ClassElement element,
    SchemaData schemaData,
    DiscriminatedClassInfo discriminatedInfo,
  ) {
    final schemaClassName =
        schemaData.schemaClassName ?? '${element.name}Schema';

    // Build base schema class using code_builder
    final baseClass = _buildDiscriminatedBaseClass(
      element,
      schemaData,
      discriminatedInfo,
      schemaClassName,
    );

    // Generate subclass schemas
    final subclassSchemas = <String>[];
    for (final subclass in discriminatedInfo.subclasses) {
      final subclassSchema = _generateSubclassSchema(
        subclass,
        element,
        discriminatedInfo,
      );
      subclassSchemas.add(subclassSchema);
    }

    // Generate and format base class
    final library = Library((b) => b.body.add(baseClass));
    final baseCode =
        library.accept(DartEmitter(useNullSafetySyntax: true)).toString();

    final String formattedBase;
    try {
      formattedBase = _formatter.format(baseCode);
    } catch (e) {
      throw Exception(
        'Failed to format generated code for discriminated base ${element.name}. '
        'This usually indicates a syntax error in the generated code.\n'
        'Error: $e\n'
        'Generated code:\n$baseCode',
      );
    }

    // Combine all schemas
    return [formattedBase, ...subclassSchemas].join('\n\n');
  }

  Class _buildDiscriminatedBaseClass(
    ClassElement element,
    SchemaData schemaData,
    DiscriminatedClassInfo discriminatedInfo,
    String schemaClassName,
  ) {
    return Class(
      (b) => b
        ..name = schemaClassName
        ..extend = refer('SchemaModel<$schemaClassName>')
        ..docs.addAll([
          '/// Generated base schema for ${element.name} with inheritance support',
          if (schemaData.description != null) '/// ${schemaData.description}',
        ])
        ..constructors.addAll([
          _buildDefaultConstructor(),
          _buildValidConstructor(),
        ])
        ..fields.addAll([
          _buildDiscriminatedSchemaField(discriminatedInfo),
          _buildSchemaModelField(element, schemaData, discriminatedInfo),
        ])
        ..methods.addAll([
          _buildParseMethod(schemaClassName),
          _buildDiscriminatedEnsureInitializeMethod(
            schemaClassName,
            discriminatedInfo,
          ),
          _buildDefinitionMethod(),
          ..._buildDiscriminatedGetters(element, discriminatedInfo),
          ..._buildPatternMatchingMethods(discriminatedInfo),
          _buildToJsonSchemaMethod(),
        ]),
    );
  }

  Field _buildDiscriminatedSchemaField(
    DiscriminatedClassInfo discriminatedInfo,
  ) {
    final discriminatorMappingCode = discriminatedInfo
        .discriminatorMapping.entries
        .map((entry) => "'${entry.key}': ${entry.value.name}Schema.schema")
        .join(',\n        ');

    return Field(
      (b) => b
        ..name = 'schema'
        ..static = true
        ..modifier = FieldModifier.final$
        ..type = refer('DiscriminatedObjectSchema')
        ..assignment = Code('''Ack.discriminated(
    discriminatorKey: '${discriminatedInfo.discriminatorKey}',
    schemas: {
      $discriminatorMappingCode,
    },
  )'''),
    );
  }

  Field _buildSchemaModelField(
    ClassElement element,
    SchemaData schemaData,
    DiscriminatedClassInfo discriminatedInfo,
  ) {
    // Create enhanced ClassInfo with discriminator field
    final enhancedClassInfo = _addDiscriminatorToClassInfo(
      ClassAnalyzer.analyzeClass(element, schemaData.additionalPropertiesField),
      discriminatedInfo.discriminatorKey,
    );

    final properties = enhancedClassInfo
        .getPropertiesExcluding(schemaData.additionalPropertiesField)
        .values;

    final propertyCode = _buildPropertySchemaCode(properties);
    final requiredProps =
        _buildRequiredPropsString(enhancedClassInfo, schemaData);

    return Field(
      (b) => b
        ..name = 'baseSchema'
        ..static = true
        ..modifier = FieldModifier.final$
        ..type = refer('ObjectSchema')
        ..assignment = Code('''Ack.object(
    {
$propertyCode
    },
    required: [$requiredProps],
    additionalProperties: ${schemaData.additionalProperties},
  )'''),
    );
  }

  Method _buildDiscriminatedEnsureInitializeMethod(
    String schemaClassName,
    DiscriminatedClassInfo discriminatedInfo,
  ) {
    final dependencies = discriminatedInfo.subclasses
        .map((subclass) => '${subclass.name}Schema.ensureInitialize();')
        .join('\n    ');

    return Method(
      (b) => b
        ..name = 'ensureInitialize'
        ..static = true
        ..returns = refer('void')
        ..docs
            .add('/// Ensures this schema and its dependencies are registered')
        ..body = Code('''
    SchemaRegistry.register<$schemaClassName>(
      (data) => const $schemaClassName().parse(data),
    );
    $dependencies'''),
    );
  }

  List<Method> _buildDiscriminatedGetters(
    ClassElement element,
    DiscriminatedClassInfo discriminatedInfo,
  ) {
    // Create enhanced ClassInfo with discriminator field for consistent handling
    final enhancedClassInfo = _addDiscriminatorToClassInfo(
      ClassAnalyzer.analyzeClass(element, null),
      discriminatedInfo.discriminatorKey,
    );

    final getters = <Method>[];

    // Generate all getters using existing pattern (including discriminator)
    for (final prop in enhancedClassInfo.properties.values) {
      getters.add(_buildPropertyGetter(prop));
    }

    return getters;
  }

  List<Method> _buildPatternMatchingMethods(
    DiscriminatedClassInfo discriminatedInfo,
  ) {
    return [
      _buildWhenMethod(discriminatedInfo),
      _buildMaybeWhenMethod(discriminatedInfo),
    ];
  }

  Method _buildWhenMethod(DiscriminatedClassInfo discriminatedInfo) {
    final parameters = discriminatedInfo.discriminatorMapping.entries
        .map(
          (entry) => Parameter(
            (p) => p
              ..name = _toCamelCase(entry.key)
              ..type = refer('R Function(${entry.value.name}Schema)')
              ..named = true
              ..required = true,
          ),
        )
        .toList();

    final cases = discriminatedInfo.discriminatorMapping.entries
        .map(
          (entry) =>
              "'${entry.key}' => ${_toCamelCase(entry.key)}(const ${entry.value.name}Schema().parse(toMap())),",
        )
        .join('\n        ');

    return Method(
      (b) => b
        ..name = 'when'
        ..types.add(refer('R'))
        ..optionalParameters.addAll(parameters)
        ..returns = refer('R')
        ..body = Code('''switch (${discriminatedInfo.discriminatorKey}) {
        $cases
        _ => throw StateError('Unknown ${discriminatedInfo.baseClass.name.toLowerCase()} type: \$${discriminatedInfo.discriminatorKey}'),
      }''')
        ..lambda = true,
    );
  }

  Method _buildMaybeWhenMethod(DiscriminatedClassInfo discriminatedInfo) {
    final parameters = [
      ...discriminatedInfo.discriminatorMapping.entries.map(
        (entry) => Parameter(
          (p) => p
            ..name = _toCamelCase(entry.key)
            ..type = refer('R Function(${entry.value.name}Schema)?')
            ..named = true,
        ),
      ),
      Parameter(
        (p) => p
          ..name = 'orElse'
          ..type = refer('R Function()')
          ..named = true
          ..required = true,
      ),
    ];

    final cases = discriminatedInfo.discriminatorMapping.entries
        .map(
          (entry) =>
              "'${entry.key}' => ${_toCamelCase(entry.key)}?.call(const ${entry.value.name}Schema().parse(toMap())) ?? orElse(),",
        )
        .join('\n        ');

    return Method(
      (b) => b
        ..name = 'maybeWhen'
        ..types.add(refer('R'))
        ..optionalParameters.addAll(parameters)
        ..returns = refer('R')
        ..body = Code('''switch (${discriminatedInfo.discriminatorKey}) {
        $cases
        _ => orElse(),
      }''')
        ..lambda = true,
    );
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

  /// Check if a class is a subclass of a discriminated union (sealed or abstract)
  /// This prevents duplicate generation of subclass schemas
  bool _isSubclassOfDiscriminatedUnion(ClassElement element) {
    // Check for discriminatedValue annotation
    for (final annotation in element.metadata) {
      if (annotation.element?.displayName == 'Schema') {
        final reader = ConstantReader(annotation.computeConstantValue());
        final discriminatedValue =
            reader.peek('discriminatedValue')?.stringValue;
        if (discriminatedValue != null) {
          // Verify superclass is sealed or abstract
          final supertype = element.supertype;
          if (supertype != null) {
            final superElement = supertype.element;
            if (superElement is ClassElement &&
                (superElement.isSealed || superElement.isAbstract)) {
              // Verify parent has discriminatedKey annotation
              final parentHasDiscriminator = superElement.metadata.any(
                (ann) =>
                    ann.element?.displayName == 'Schema' &&
                    ConstantReader(ann.computeConstantValue())
                            .peek('discriminatedKey')
                            ?.stringValue !=
                        null,
              );

              if (!parentHasDiscriminator) {
                throw InvalidGenerationSourceError(
                  '${element.name} has discriminatedValue but '
                  '${superElement.name} is not a discriminated union. '
                  'Parent class must have @Schema(discriminatedKey: "...") annotation.',
                  element: element,
                );
              }

              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /// Add discriminator field to ClassInfo as PropertyInfo
  ClassInfo _addDiscriminatorToClassInfo(
    ClassInfo classInfo,
    String discriminatorKey,
  ) {
    // Create discriminator as PropertyInfo
    final discriminatorProperty = PropertyInfo(
      name: discriminatorKey,
      typeName: const TypeName('String', []),
      isRequired: true,
      isNullable: false,
      constraints: [],
    );

    // Add discriminator to properties map
    final enhancedProperties = Map<String, PropertyInfo>.from(
      classInfo.properties,
    );
    enhancedProperties[discriminatorKey] = discriminatorProperty;

    return ClassInfo(
      name: classInfo.name,
      constructorParams: classInfo.constructorParams,
      properties: enhancedProperties,
      dependencies: classInfo.dependencies,
    );
  }

  /// Build property schema code from properties
  String _buildPropertySchemaCode(
    Iterable<PropertyInfo> properties, {
    bool includeTrailingComma = true,
    String indent = '        ',
  }) {
    return properties.map((prop) {
      final schemaExpr = _buildPropertySchemaExpression(prop);
      final key = prop.jsonKey ?? prop.name;
      final entry = "$indent'$key': $schemaExpr";
      return includeTrailingComma ? '$entry,' : entry;
    }).join(includeTrailingComma ? '\n' : ',\n');
  }

  /// Build required properties string for schema generation
  String _buildRequiredPropsString(ClassInfo classInfo, SchemaData schemaData) {
    return classInfo
        .getRequiredProperties(
          excludeField: schemaData.additionalPropertiesField,
        )
        .map((p) => "'${p.jsonKey ?? p.name}'")
        .join(', ');
  }

  /// Generate subclass schema that extends the base schema
  String _generateSubclassSchema(
    ClassElement subclassElement,
    ClassElement baseElement,
    DiscriminatedClassInfo discriminatedInfo,
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

    // Get description from subclass annotation
    final description = _getClassDescription(subclassElement);

    // Build the complete subclass using code_builder
    final subclass = Class((b) {
      b
        ..name = schemaClassName
        ..extend = refer('${baseName}Schema')
        ..docs.addAll([
          '/// Generated schema for $subclassName extending ${baseName}Schema',
          if (description != null) '/// $description',
        ])
        ..constructors.addAll([
          _buildDefaultConstructor(),
          _buildValidConstructor(),
        ])
        ..fields.add(
          _buildSubclassSchemaField(
            baseName,
            subclassProperties,
          ),
        )
        ..methods.addAll([
          _buildParseMethod(schemaClassName),
          _buildSubclassEnsureInitializeMethod(schemaClassName),
          _buildDefinitionMethod(),
          ...subclassProperties.map((prop) => _buildPropertyGetter(prop)),
          _buildToJsonSchemaMethod(),
        ]);
    });

    // Generate and format
    final library = Library((b) => b.body.add(subclass));
    final code =
        library.accept(DartEmitter(useNullSafetySyntax: true)).toString();

    try {
      return _formatter.format(code);
    } catch (e) {
      throw Exception(
        'Failed to format generated code for subclass ${subclassElement.name}. '
        'This usually indicates a syntax error in the generated code.\n'
        'Error: $e\n'
        'Generated code:\n$code',
      );
    }
  }

  Field _buildSubclassSchemaField(
    String baseName,
    List<PropertyInfo> subclassProperties,
  ) {
    // Build property map code
    final propertyEntries = subclassProperties.map((prop) {
      final schemaExpr = _buildPropertySchemaExpression(prop);
      final key = prop.jsonKey ?? prop.name;
      return "'$key': $schemaExpr";
    }).join(',\n      ');

    // Build required fields
    final requiredFields = subclassProperties
        .where((prop) => prop.isRequired)
        .map((prop) => "'${prop.jsonKey ?? prop.name}'")
        .join(', ');

    final schemaCode = '''${baseName}Schema.baseSchema.extend(
    {
      ${propertyEntries.isNotEmpty ? propertyEntries : '// No additional properties'}
    },
    ${requiredFields.isNotEmpty ? 'required: [$requiredFields],' : ''}
    additionalProperties: false,
  )''';

    return Field(
      (b) => b
        ..name = 'schema'
        ..static = true
        ..modifier = FieldModifier.final$
        ..type = refer('ObjectSchema')
        ..assignment = Code(schemaCode),
    );
  }

  Method _buildSubclassEnsureInitializeMethod(String schemaClassName) {
    return Method(
      (b) => b
        ..name = 'ensureInitialize'
        ..static = true
        ..returns = refer('void')
        ..docs
            .add('/// Ensures this schema and its dependencies are registered')
        ..body = Code('''
    SchemaRegistry.register<$schemaClassName>(
      (data) => $schemaClassName(data),
    );'''),
    );
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
}
