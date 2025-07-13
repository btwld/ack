import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'builders/schema_builder.dart';
import 'builders/schema_model_builder.dart';
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

    // First pass: Analyze all models individually
    final modelInfos = <ModelInfo>[];
    for (final element in annotatedElements) {
      try {
        // Validate element can be processed
        _validateElement(element);

        final annotation =
            TypeChecker.fromRuntime(AckModel).firstAnnotationOf(element)!;
        final annotationReader = ConstantReader(annotation);

        // Analyze the model
        final modelInfo = analyzer.analyze(element, annotationReader);
        modelInfos.add(modelInfo);
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Error analyzing ${element.name}: $e',
          element: element,
          todo: 'Check annotation parameters and class structure',
        );
      }
    }

    // Second pass: Build discriminator relationships
    final finalModelInfos = analyzer.buildDiscriminatorRelationships(
      modelInfos,
      annotatedElements,
    );

    // Third pass: Generate code for all models
    for (final modelInfo in finalModelInfos) {
      // Find the corresponding element for error reporting
      final element = annotatedElements.firstWhere(
        (e) => e.name == modelInfo.className,
      );

      try {
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
        if (modelInfo.model) {
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
      
      // Add SchemaModel classes using code_builder
      // Use the final ModelInfos with discriminator relationships
      for (final modelInfo in finalModelInfos) {
        if (modelInfo.model) {
          final schemaModelClass = schemaModelBuilder.buildSchemaModelClass(modelInfo);
          final emitter = DartEmitter(allocator: Allocator.none);
          buffer.writeln(schemaModelClass.accept(emitter));
          buffer.writeln();
        }
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
    // Check if this is a discriminated base class (abstract is allowed for discriminated types)
    final annotation = TypeChecker.fromRuntime(AckModel).firstAnnotationOf(element);
    if (annotation != null) {
      final annotationReader = ConstantReader(annotation);
      final discriminatedKey = annotationReader.read('discriminatedKey').isNull
          ? null
          : annotationReader.read('discriminatedKey').stringValue;
      
      // Allow abstract classes only if they have discriminatedKey
      if (element.isAbstract && discriminatedKey == null) {
        throw InvalidGenerationSourceError(
          '@AckModel cannot be applied to abstract classes unless discriminatedKey is specified.',
          element: element,
        );
      }
    }
  }

}
