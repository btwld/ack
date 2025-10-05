import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'builders/schema_builder.dart';
import 'models/model_info.dart';
import 'validation/code_validator.dart';
import 'validation/model_validator.dart';

/// Generates schemas for classes annotated with @AckModel
///
/// This generator processes all annotated classes in a source file together to create
/// a single .g.dart file with schema variables.
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

    // Generate all schema fields for this file
    final schemaFields = <Field>[];
    final analyzer = ModelAnalyzer();
    final schemaBuilder = SchemaBuilder();

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
          'Invalid @AckModel annotation on class ${element.name}: $e',
          element: element,
          todo: 'Check annotation syntax. See: https://docs.page/btwld/ack/annotations',
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

        // Build the schema field
        final schemaField = schemaBuilder.buildSchemaField(modelInfo);
        schemaFields.add(schemaField);
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Schema generation failed for ${element.name}: $e',
          element: element,
          todo: 'Ensure all field types are supported. See: https://docs.page/btwld/ack/supported-types',
        );
      }
    }

    // Only generate if we have content
    if (schemaFields.isEmpty) {
      return '';
    }

    // Generate part file with schema variables only
    final inputFileName = buildStep.inputId.pathSegments.last;
    final generatedLibrary = Library((b) => b
      ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..directives.addAll([
        Directive.partOf(inputFileName),
      ])
      ..body.addAll(schemaFields));

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

    try {
      return _formatter.format(generatedCode);
    } catch (e) {
      // If formatting fails, return unformatted code
      print('Warning: Failed to format generated code: $e');
      return generatedCode;
    }
  }

  /// Validates that the element can be processed by the generator
  void _validateElement(ClassElement element) {
    // Check if this is a discriminated base class (abstract is allowed for discriminated types)
    final annotation =
        TypeChecker.fromRuntime(AckModel).firstAnnotationOf(element);
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
