// ignore: unused_import

import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'builders/schema_builder.dart';

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

    // Generate all schema fields for this file
    final schemaFields = <Field>[];
    final analyzer = ModelAnalyzer();
    final schemaBuilder = SchemaBuilder();

    for (final element in annotatedElements) {
      try {
        // Validate element can be processed
        _validateElement(element);

        final annotation =
            TypeChecker.fromRuntime(AckModel).firstAnnotationOf(element)!;
        final annotationReader = ConstantReader(annotation);

        // Analyze the model and build the schema field
        final modelInfo = analyzer.analyze(element, annotationReader);
        final schemaField = schemaBuilder.buildSchemaField(modelInfo);
        schemaFields.add(schemaField);
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Error generating schema for ${element.name}: $e',
          element: element,
          todo: 'Check that all fields have supported types',
        );
      }
    }

    // Build the complete library with all schemas
    final generatedLibrary = Library((b) => b
      ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..directives.addAll([
        Directive.import('package:ack/ack.dart'),
      ])
      ..body.addAll(schemaFields));

    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    return _formatter.format('${generatedLibrary.accept(emitter)}');
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
