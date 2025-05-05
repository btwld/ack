import 'package:ack/ack.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import '../ack_generator.dart';

/// Builder that produces SchemaModel-based schema classes
class SchemaModelBuilder implements Builder {
  final BuilderOptions options;

  const SchemaModelBuilder(this.options);

  @override
  Future<void> build(BuildStep buildStep) async {
    // Get the library
    final inputId = buildStep.inputId;

    if (!await buildStep.canRead(inputId)) {
      return;
    }

    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(inputId)) {
      return;
    }

    final library = await resolver.libraryFor(inputId);
    final libraryReader = LibraryReader(library);

    // Find classes annotated with @Schema
    final annotatedElements = libraryReader.annotatedWith(
      TypeChecker.fromRuntime(Schema),
    );

    if (annotatedElements.isEmpty) {
      return;
    }

    // Generate schema code
    final generator = SchemaModelGenerator();

    try {
      final StringBuffer buffer = StringBuffer();

      // Add default header
      final defaultHeader = options.config['header'] as String? ??
          '''
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names
''';

      buffer.writeln(defaultHeader);

      // Get the model file name for the part directive
      final modelPath = p.basename(inputId.path);
      buffer.writeln("part of '$modelPath';");
      buffer.writeln();

      for (final annotatedElement in annotatedElements) {
        final element = annotatedElement.element;
        final annotation = annotatedElement.annotation;

        if (element is! ClassElement) {
          throw InvalidGenerationSourceError(
            '@Schema can only be used on classes.',
            element: element,
          );
        }

        final modelData = _extractModelData(element, annotation);
        final code = generator.generateForAnnotatedElement(element, modelData);

        buffer.writeln(code);
      }

      // Write the output file
      final outputId = inputId.changeExtension('.g.dart');
      await buildStep.writeAsString(outputId, buffer.toString());
    } catch (e, stack) {
      log.severe('Error generating schema for ${inputId.path}', e, stack);
      rethrow;
    }
  }

  /// Extract model data from the annotation
  SchemaData _extractModelData(
    ClassElement element,
    ConstantReader annotation,
  ) {
    final description = annotation.peek('description')?.stringValue;
    final additionalProperties =
        annotation.peek('additionalProperties')?.boolValue ?? false;
    final additionalPropertiesField =
        annotation.peek('additionalPropertiesField')?.stringValue;
    final schemaClassName = annotation.peek('schemaClassName')?.stringValue ??
        '${element.name}Schema';

    return SchemaData(
      description: description,
      additionalProperties: additionalProperties,
      additionalPropertiesField: additionalPropertiesField,
      schemaClassName: schemaClassName,
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.g.dart'],
      };
}
