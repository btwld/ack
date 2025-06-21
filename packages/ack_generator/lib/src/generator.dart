import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
// ignore: unused_import
import 'package:ack/ack.dart' show SchemaModel;

// TODO: Import from ack_annotations when available
// For now, using a temporary annotation class
class AckModel {
  const AckModel();
}

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
      // TODO: Implement actual generation logic
      // 1. Analyze the annotated class
      // final analyzer = ModelAnalyzer();
      // final modelInfo = analyzer.analyze(element, annotation);

      // 2. Build the schema code
      // final builder = SchemaBuilder();
      // return builder.build(modelInfo);
      
      // Temporary implementation - just return a comment
      return '''
// TODO: Generated schema for ${element.name}
class ${element.name}Schema extends SchemaModel {
  const ${element.name}Schema();
}
''';
    } catch (e) {
      throw InvalidGenerationSourceError(
        'Error generating schema for ${element.name}: $e',
        element: element,
        todo: 'Check that all fields have supported types',
      );
    }
  }
}
