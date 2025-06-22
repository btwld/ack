// ignore: unused_import
import 'package:ack/ack.dart' show SchemaModel;
import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'builders/schema_builder.dart';

/// Generates SchemaModel implementations for classes annotated with @AckModel
class AckSchemaGenerator extends GeneratorForAnnotation<AckModel> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Only process classes
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@AckModel can only be applied to classes.',
        element: element,
      );
    }

    // Don't generate for abstract classes
    if (element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@AckModel cannot be applied to abstract classes.',
        element: element,
      );
    }

    try {
      // 1. Analyze the annotated class
      final analyzer = ModelAnalyzer();
      final modelInfo = analyzer.analyze(element, annotation);

      // 2. Build the schema code
      final builder = SchemaBuilder();
      final sourceFileName = buildStep.inputId.path.split('/').last;
      return builder.build(modelInfo, sourceFileName);
    } catch (e) {
      throw InvalidGenerationSourceError(
        'Error generating schema for ${element.name}: $e',
        element: element,
        todo: 'Check that all fields have supported types',
      );
    }
  }
}
