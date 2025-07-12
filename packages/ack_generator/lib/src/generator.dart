import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'builders/schema_builder.dart';
import 'builders/schema_model_builder.dart';
import 'models/field_info.dart';
import 'models/model_info.dart';
import 'validation/code_validator.dart';
import 'validation/model_validator.dart';

/// Generates SchemaModel implementations for classes annotated with @AckModel
///
/// This generator processes all annotated classes in a source file together to create
/// a single .g.dart file with proper imports and all schema classes. This approach
/// solves the multiple-classes-per-file issue that occurs with GeneratorForAnnotation.
class AckSchemaGenerator extends Generator {
  final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final annotatedElements = <ClassElement>[];

    // Find all classes annotated with @AckModel
    for (final element in library.allElements) {
      if (element is ClassElement) {
        final annotation =
            TypeChecker.fromRuntime(AckModel).firstAnnotationOf(element);
        if (annotation != null) {
          annotatedElements.add(element);
        }
      }
    }

    if (annotatedElements.isEmpty) {
      return '';
    }

    // Generate all schema fields and SchemaModel classes for this file
    final schemaFields = <Field>[];
    final schemaModelClasses = <Class>[];
    final analyzer = ModelAnalyzer();
    final schemaBuilder = SchemaBuilder();
    final schemaModelBuilder = SchemaModelBuilder();

    for (final element in annotatedElements) {
      try {
        // Validate element can be processed
        _validateElement(element);

        final annotation =
            TypeChecker.fromRuntime(AckModel).firstAnnotationOf(element)!;
        final annotationReader = ConstantReader(annotation);

        // Analyze the model
        final modelInfo = analyzer.analyze(element, annotationReader);
        
        // Validate the model before generating code
        final modelValidation = ModelValidator.validateModel(modelInfo);
        if (modelValidation.isFailure) {
          throw InvalidGenerationSourceError(
            'Model validation failed: ${modelValidation.errorMessage}',
            element: element,
            todo: 'Simplify complex generic types or fix circular references',
          );
        }
        
        // Always build the schema field
        final schemaField = schemaBuilder.buildSchemaField(modelInfo);
        schemaFields.add(schemaField);
        
        // Check if model generation is requested
        final generateModel = annotationReader.read('model').isNull
            ? false
            : annotationReader.read('model').boolValue;
            
        if (generateModel) {
          // Build SchemaModel class too
          final schemaModelClass = schemaModelBuilder.buildSchemaModelClass(modelInfo);
          schemaModelClasses.add(schemaModelClass);
        }
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Error generating schemas for ${element.name}: $e',
          element: element,
          todo: 'Check that all fields have supported types',
        );
      }
    }

    // Build the complete library with all schemas
    // Schema variables must come first as SchemaModel classes depend on them
    final allGeneratedElements = <Spec>[
      ...schemaFields,       // Schema variables first (dependencies)
      ...schemaModelClasses, // SchemaModel classes after (use schemas)
    ];
    
    // Only add imports and headers if we have content
    if (allGeneratedElements.isEmpty) {
      return '';
    }
    
    // Check if we need to generate as a part file or standalone
    final needsPartOf = schemaModelClasses.isNotEmpty;
    
    if (needsPartOf) {
      // Generate as a part file manually to avoid import issues
      final fileName = buildStep.inputId.pathSegments.last.replaceAll('.g.dart', '.dart');
      
      // Manually build the content to avoid emitter import issues
      final buffer = StringBuffer();
      buffer.writeln("part of '$fileName';");
      buffer.writeln();
      
      // Add schema fields first
      for (final schemaField in schemaFields) {
        final emitter = DartEmitter(allocator: Allocator.none);
        buffer.writeln(schemaField.accept(emitter));
        buffer.writeln();
      }
      
      // Add SchemaModel classes manually to avoid import issues
      // We need to regenerate them here with the proper ModelInfo
      for (int i = 0; i < schemaModelClasses.length; i++) {
        final element = annotatedElements[i];
        final annotation = TypeChecker.fromRuntime(AckModel).firstAnnotationOf(element)!;
        final annotationReader = ConstantReader(annotation);
        final modelInfo = analyzer.analyze(element, annotationReader);
        
        buffer.writeln(_buildSchemaModelClassManually(modelInfo));
        buffer.writeln();
      }
      
      final output = buffer.toString();
      
      // Validate generated code before formatting
      final validation = CodeValidator.validate(output);
      if (validation.isFailure) {
        throw InvalidGenerationSourceError(
          'Generated code validation failed: ${validation.errorMessage}',
          todo: 'Fix the code generation logic to produce valid Dart syntax',
        );
      }
      
      try {
        return _formatter.format(output);
      } catch (e) {
        // If formatting fails, return unformatted code
        print('Warning: Failed to format generated code: $e');
        return output;
      }
    } else {
      // Generate as standalone file with imports
      final generatedLibrary = Library((b) => b
        ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
        ..directives.addAll([
          Directive.import('package:ack/ack.dart'),
        ])
        ..body.addAll(allGeneratedElements));

      final emitter = DartEmitter(
        allocator: Allocator.none,
        orderDirectives: true,
        useNullSafetySyntax: true,
      );

      final generatedCode = generatedLibrary.accept(emitter).toString();
      
      // Validate generated code before formatting
      final validation = CodeValidator.validate(generatedCode);
      if (validation.isFailure) {
        throw InvalidGenerationSourceError(
          'Generated code validation failed: ${validation.errorMessage}',
          todo: 'Fix the code generation logic to produce valid Dart syntax',
        );
      }

      return _formatter.format(generatedCode);
    }
  }

  /// Validates that the element can be processed by the generator
  void _validateElement(ClassElement element) {
    // Don't generate for abstract classes
    if (element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@AckModel cannot be applied to abstract classes.',
        element: element,
      );
    }
  }

  /// Manually builds SchemaModel class to avoid import issues in part files
  String _buildSchemaModelClassManually(ModelInfo modelInfo) {
    final className = '${modelInfo.className}SchemaModel';
    final baseClassName = modelInfo.className;
    final schemaVarName = _toCamelCase(modelInfo.schemaClassName);
    
    // Generate createFromMap body using the same logic as SchemaModelBuilder
    final createFromMapBody = _generateCreateFromMapBodyManually(modelInfo);
    
    return '''
/// Generated SchemaModel for [$baseClassName].
class $className extends SchemaModel<$baseClassName> {
  $className._();
  
  factory $className() {
    return _instance;
  }
  
  static final _instance = $className._();
  
  @override
  ObjectSchema buildSchema() {
    return $schemaVarName;
  }
  
  @override
  $baseClassName createFromMap(Map<String, dynamic> map) {
    $createFromMapBody
  }
}''';
  }

  /// Generate createFromMap method body - enhanced version matching SchemaModelBuilder
  String _generateCreateFromMapBodyManually(ModelInfo modelInfo) {
    final params = <String>[];

    // Process all regular fields
    for (final field in modelInfo.fields) {
      final param = _generateFieldMappingManually(field);
      params.add('      $param');
    }

    // Add additional properties field if configured
    if (modelInfo.additionalProperties &&
        modelInfo.additionalPropertiesField != null) {
      params.add(
          '      ${modelInfo.additionalPropertiesField}: extractAdditionalProperties(map, {${_getKnownFieldsManually(modelInfo)}})');
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
  String _getKnownFieldsManually(ModelInfo modelInfo) {
    final knownFields = modelInfo.fields
        .where((f) => f.name != modelInfo.additionalPropertiesField)
        .map((f) => "'${f.jsonKey}'")
        .join(', ');
    return knownFields;
  }

  /// Generates the field mapping for createFromMap - manual version
  String _generateFieldMappingManually(FieldInfo field) {
    final mapKey = "'${field.jsonKey}'";

    // Handle different field types
    if (field.isEnum) {
      return _generateEnumMappingManually(field, mapKey);
    } else if (field.isNestedSchema) {
      return _generateNestedSchemaMappingManually(field, mapKey);
    } else if (field.isList) {
      return _generateListMappingManually(field, mapKey);
    } else if (field.isMap) {
      return _generateMapMappingManually(field, mapKey);
    } else if (field.isSet) {
      return _generateSetMappingManually(field, mapKey);
    } else {
      // Simple field
      return _generateSimpleMappingManually(field, mapKey);
    }
  }

  /// Generates mapping for simple fields
  String _generateSimpleMappingManually(FieldInfo field, String mapKey) {
    final cast = field.type.getDisplayString();

    if (field.isNullable) {
      return '${field.name}: map[$mapKey] as $cast';
    } else {
      return '${field.name}: map[$mapKey] as $cast';
    }
  }

  /// Generates mapping for enum fields
  String _generateEnumMappingManually(FieldInfo field, String mapKey) {
    final enumTypeName = field.type.getDisplayString().replaceAll('?', '');

    if (field.isNullable) {
      return '${field.name}: map[$mapKey] != null ? $enumTypeName.values.byName(map[$mapKey] as String) : null';
    } else {
      return '${field.name}: $enumTypeName.values.byName(map[$mapKey] as String)';
    }
  }

  /// Generates mapping for nested schema fields
  String _generateNestedSchemaMappingManually(FieldInfo field, String mapKey) {
    final typeName = field.type.getDisplayString().replaceAll('?', '');

    if (field.isNullable) {
      return '${field.name}: map[$mapKey] != null ? ${typeName}SchemaModel._instance.createFromMap(map[$mapKey] as Map<String, dynamic>) : null';
    } else {
      return '${field.name}: ${typeName}SchemaModel._instance.createFromMap(map[$mapKey] as Map<String, dynamic>)';
    }
  }

  /// Generates mapping for List fields
  String _generateListMappingManually(FieldInfo field, String mapKey) {
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
    if (field.isNullable) {
      final paramType = listType as ParameterizedType;
      return '${field.name}: (map[$mapKey] as List?)?.cast<${paramType.typeArguments.first.getDisplayString()}>()';
    } else {
      final paramType = listType as ParameterizedType;
      return '${field.name}: (map[$mapKey] as List).cast<${paramType.typeArguments.first.getDisplayString()}>()';
    }
  }

  /// Generates mapping for Map fields
  String _generateMapMappingManually(FieldInfo field, String mapKey) {
    final mapTypeString = field.type.getDisplayString();
    return '${field.name}: map[$mapKey] as $mapTypeString';
  }

  /// Generates mapping for Set fields
  String _generateSetMappingManually(FieldInfo field, String mapKey) {
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

