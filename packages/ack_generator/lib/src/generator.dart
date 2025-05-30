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
import 'models/property_constraint_info.dart';
import 'models/property_info.dart';
import 'models/schema_data.dart';

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

    // Analyze class (reuse existing analyzer)
    ClassInfo classInfo = ClassAnalyzer.analyzeClass(
      element,
      schemaData.additionalPropertiesField,
    );

    // Add dependencies
    final dependencies =
        ClassAnalyzer.findClassDependencies(classInfo.properties);
    classInfo = classInfo.withDependencies(dependencies);

    // Special handling for sealed classes (keep current behavior)
    if (element.isSealed && schemaData.discriminatedKey != null) {
      // Return current string-based implementation for now
      // TODO: Migrate this in phase 2
      return _currentDiscriminatedImplementation(
        element,
        schemaData,
        classInfo,
      );
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
        ..type = refer('ObjectSchema')
        ..assignment = const Code('_createSchema()')
        ..docs.add(
          '// Schema definition moved to a static field for easier access',
        ),
    );
  }

  Constructor _buildConstructor() {
    return Constructor(
      (b) => b
        ..docs.add('// Constructor that validates input')
        ..optionalParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer('Object?')
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

    // Build property schemas map
    final propertyCode = properties.map((prop) {
      final schemaExpr = _buildPropertySchemaExpression(prop);
      return "        '${prop.name}': $schemaExpr,";
    }).join('\n');

    // Required properties
    final requiredProps = classInfo
        .getRequiredProperties(
          excludeField: schemaData.additionalPropertiesField,
        )
        .map((p) => "'${p.name}'")
        .join(', ');

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
        ..returns = refer('ObjectSchema')
        ..docs.add('// Create the validation schema')
        ..body = Code(body),
    );
  }

  String _buildPropertySchemaExpression(PropertyInfo property) {
    // Direct string building (matches current implementation)
    var expr = TypeAnalyzer.getBaseSchemaType(property.typeName);

    // Apply constraints
    for (final constraint in property.constraints) {
      expr = _applyConstraintToExpression(expr, constraint);
    }

    // Apply nullable
    if (property.isNullable) {
      expr += '.nullable()';
    }

    return expr;
  }

  String _applyConstraintToExpression(
    String expr,
    PropertyConstraintInfo constraint,
  ) {
    return ConstraintAnalyzer.applyConstraint(expr, constraint);
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
        ..returns = refer('AckSchema')
        ..annotations.add(refer('override'))
        ..docs.add('// Override to return the schema for validation')
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
        ..docs.add('// Type-safe getters')
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
    final properties = classInfo
        .getPropertiesExcluding(schemaData.additionalPropertiesField)
        .values
        .map((p) => "'${p.name}'")
        .join(', ');

    final body = '''
    final result = <String, Object?>{};
    final knownFields = [$properties];

    for (final key in toMap().keys) {
      if (!knownFields.contains(key)) {
        result[key] = toMap()[key];
      }
    }
    return result;''';

    return Method(
      (b) => b
        ..name = fieldName
        ..type = MethodType.getter
        ..returns = refer('Map<String, Object?>')
        ..docs.addAll(['', '// Get metadata with fallback'])
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
        ..docs.add('// Model conversion methods')
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
    final hasNamedParams =
        constructor?.parameters.any((p) => p.isNamed) ?? true;

    final args = <String>[];
    final properties = classInfo.properties.values;

    if (!hasNamedParams && constructor != null) {
      // Positional parameters
      for (final param in constructor.parameters) {
        final property = classInfo.properties[param.name];
        if (property != null) {
          args.add('      ${_getPropertyConversion(property, schemaData)},');
        }
      }
      return '''
    return $modelClassName(
${args.join('\n')}
    );''';
    } else {
      // Named parameters
      for (final property in properties) {
        final conversion = _getPropertyConversion(property, schemaData);
        args.add('      ${property.name}: $conversion,');
      }
      return '''
    return $modelClassName(
${args.join('\n')}
    );''';
    }
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
        ..returns = refer('Map<String, Object?>')
        ..docs.add('/// Convert the schema to a JSON Schema')
        ..body = Code(body),
    );
  }

  String _currentDiscriminatedImplementation(
    ClassElement element,
    SchemaData schemaData,
    ClassInfo classInfo,
  ) {
    // For MVP, use current string-based implementation
    // This is a placeholder - in real implementation, would copy logic from current generator
    return '''
// TODO: Migrate discriminated union generation to code_builder
// Using string-based generation for sealed classes temporarily
class ${element.name}Schema {
  // Discriminated schema implementation would go here
  // See sealed_block_model.g.dart for reference
}
''';
  }
}
