// ignore: unused_import

import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'builders/schema_builder.dart';
import 'builders/schema_model_builder.dart';

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
  String generate(LibraryReader libraryReader, BuildStep buildStep) {
    final annotatedElements = <ClassElement>[];

    // Find all classes annotated with @AckModel
    for (final element in libraryReader.allElements) {
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
      // Generate as a part file
      final fileName = buildStep.inputId.pathSegments.last.replaceAll('.g.dart', '.dart');
      final library = Library((b) => b
        ..body.addAll(allGeneratedElements));
      
      final emitter = DartEmitter(
        allocator: Allocator.none,
        orderDirectives: true,
        useNullSafetySyntax: true,
      );
      
      final code = library.accept(emitter);
      final output = '''part of '$fileName';

$code''';
      
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

      return _formatter.format('${generatedLibrary.accept(emitter)}');
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
}
