import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'builders/schema_builder.dart';

/// Generates a complete .g.dart file with all schemas for a source file
class AckFileGenerator extends Generator {
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

    // Generate all schema classes
    final schemaClasses = <Class>[];
    final analyzer = ModelAnalyzer();
    final schemaBuilder = SchemaBuilder();

    for (final element in annotatedElements) {
      try {
        final annotation =
            TypeChecker.fromRuntime(AckModel).firstAnnotationOf(element)!;
        final annotationReader = ConstantReader(annotation);

        final modelInfo = analyzer.analyze(element, annotationReader);
        final schemaClass = schemaBuilder.buildClass(modelInfo);
        schemaClasses.add(schemaClass);
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Error generating schema for ${element.name}: $e',
          element: element,
        );
      }
    }

    // Build the complete library
    final generatedLibrary = Library((b) => b
      ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..directives.addAll([
        Directive.import('package:ack/ack.dart'),
        Directive.import('package:meta/meta.dart'),
      ])
      ..body.addAll(schemaClasses));

    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    return _formatter.format('${generatedLibrary.accept(emitter)}');
  }
}
