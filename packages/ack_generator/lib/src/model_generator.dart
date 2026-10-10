import 'package:ack/annotations.dart';
import 'package:ack/ack.dart'
    show Ack, AckModelAdapter, AckSchema, AckSchemaModel, SchemaResult;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/class_model_graph_builder.dart';
import 'analyzer/schema_model_graph_builder.dart';
import 'builders/class_model_emitter.dart';
import 'builders/model_emitter.dart';
import 'models/schema_model_graph.dart';

/// Generates Ack models for `@Schemable` top-level schemas and classes.
final class AckModelGenerator extends Generator {
  static const _schemableChecker = TypeChecker.typeNamed(
    Schemable,
    inPackage: 'ack',
  );
  static const _ackChecker = TypeChecker.typeNamed(Ack, inPackage: 'ack');
  static const _ackModelAdapterChecker = TypeChecker.typeNamed(
    AckModelAdapter,
    inPackage: 'ack',
  );
  static const _schemaResultChecker = TypeChecker.typeNamed(
    SchemaResult,
    inPackage: 'ack',
  );
  static const _ackSchemaChecker = TypeChecker.typeNamed(
    AckSchema,
    inPackage: 'ack',
  );
  static const _ackSchemaModelChecker = TypeChecker.typeNamed(
    AckSchemaModel,
    inPackage: 'ack',
  );

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    _validateLibrarySchemable(library.element);
    final annotated = <Element>[];
    final annotatedModels = <ClassElement>[];

    for (final element in library.allElements) {
      if (!_hasSchemableSchema(element)) continue;
      if (element is TopLevelVariableElement) {
        annotated.add(element);
      } else if (element is GetterElement) {
        if (!element.isOriginDeclaration) continue;
        if (element.enclosingElement is! LibraryElement) {
          throw InvalidGenerationSource(
            '@Schemable can only be applied to top-level schema variables or '
            'getters.',
            element: element,
          );
        }
        annotated.add(element);
      } else {
        throw InvalidGenerationSource(
          '@Schemable can only be applied to classes or top-level schema '
          'variables and getters, or library directives.',
          element: element,
        );
      }
    }

    for (final classElement in library.classes) {
      if (_schemableChecker.hasAnnotationOfExact(classElement)) {
        annotatedModels.add(classElement);
      }
      for (final getter in classElement.getters) {
        if (_hasSchemableSchema(getter)) {
          throw InvalidGenerationSource(
            '@Schemable can only be applied to top-level schema variables or '
            'getters.',
            element: getter,
          );
        }
      }
    }

    if (annotated.isEmpty && annotatedModels.isEmpty) return '';
    await _requirePartDirectives(
      buildStep,
      annotated.isNotEmpty ? annotated.first : annotatedModels.first,
    );

    ({AckModelGraph graph, String? ackPrefix})? schemaFirst;
    if (annotated.isNotEmpty) {
      final graph = await SchemaModelGraphBuilder(library).build(annotated);
      schemaFirst = (
        graph: graph,
        ackPrefix: _ackRuntimeQualifier(library, annotated.first),
      );
    }
    ({AckModelGraph graph, String? ackPrefix})? classFirst;
    if (annotatedModels.isNotEmpty) {
      final ackPrefix = _classFirstAckQualifier(library, annotatedModels.first);
      classFirst = (
        graph: await ClassModelGraphBuilder(
          library,
          ackPrefix: ackPrefix,
        ).build(annotatedModels),
        ackPrefix: ackPrefix,
      );
    }
    if (schemaFirst != null && classFirst != null) {
      _validateModernGeneratedNames(
        library,
        schemaFirst.graph,
        classFirst.graph,
      );
    }

    final output = <String>[];
    if (schemaFirst != null) {
      final specs = AckModelEmitter(
        ackPrefix: schemaFirst.ackPrefix,
        schemaPrefixInScope: library.element.firstFragment.libraryImports.any(
          (import) => import.prefix?.element.name == 'schema',
        ),
      ).emit(schemaFirst.graph);
      output.add(
        Library((b) => b.body.addAll(specs))
            .accept(
              DartEmitter(
                allocator: Allocator.none,
                orderDirectives: true,
                useNullSafetySyntax: true,
              ),
            )
            .toString(),
      );
    }
    if (classFirst != null) {
      output.add(
        AckClassModelEmitter(
          ackPrefix: classFirst.ackPrefix,
        ).emit(classFirst.graph),
      );
    }
    final body = output.where((chunk) => chunk.trim().isNotEmpty).join('\n\n');
    if (body.isEmpty) return '';
    return '// ignore_for_file: type=lint\n'
        '// coverage:ignore-file\n\n'
        '$body';
  }

  void _validateModernGeneratedNames(
    LibraryReader library,
    AckModelGraph schemaFirst,
    AckModelGraph classFirst,
  ) {
    final schemaClassNames = {
      for (final node in schemaFirst.nodes) node.className,
    };
    final classesByName = {
      for (final element in library.classes) element.name!: element,
    };
    for (final node in classFirst.nodes) {
      final facadeName = classFirst.classMetadataFor(node.id)!.facadeName;
      if (!schemaClassNames.contains(facadeName)) continue;
      throw InvalidGenerationSource(
        'Generated schema-first class "$facadeName" conflicts with the '
        'class-first facade for ${node.className}. Choose a different '
        'Schemable.name or Schemable.schemaName.',
        element: classesByName[node.className],
      );
    }
  }

  String? _classFirstAckQualifier(
    LibraryReader library,
    Element annotatedElement,
  ) => _visibleQualifier(
    library,
    annotatedElement,
    requiredTypes: const {
      'Ack': _ackChecker,
      'AckSchema': _ackSchemaChecker,
      'AckSchemaModel': _ackSchemaModelChecker,
      'SchemaResult': _schemaResultChecker,
    },
    requiredElements: const {
      'AckSchemaModelExtension':
          'package:ack/src/schema_model/ack_schema_model_builder.dart',
      'deepEquals': 'package:ack/src/utils/collection_utils.dart',
      'deepHashCode': 'package:ack/src/utils/collection_utils.dart',
    },
    message:
        'Generated class-first schemas require visible exact Ack, AckSchema, '
        'AckSchemaModel, AckSchemaModelExtension, SchemaResult, deepEquals, '
        'and deepHashCode imports in this library.',
    todo: 'Import package:ack/ack.dart, directly or through a barrel.',
  );

  bool _hasSchemableSchema(Element element) =>
      element is! ClassElement &&
      element is! LibraryElement &&
      _schemableChecker.hasAnnotationOfExact(element);

  void _validateLibrarySchemable(LibraryElement libraryElement) {
    final annotation = _schemableChecker.firstAnnotationOfExact(libraryElement);
    if (annotation == null) return;
    final reader = ConstantReader(annotation);
    int index(String option) =>
        reader.read(option).objectValue.getField('index')!.toIntValue()!;
    final configured = [
      if (!reader.read('name').isNull) 'name',
      if (!reader.read('schemaName').isNull) 'schemaName',
      if (!reader.read('description').isNull) 'description',
      if (index('caseStyle') != 0) 'caseStyle',
      if (!reader.read('discriminatorKey').isNull) 'discriminatorKey',
      if (!reader.read('discriminatorValue').isNull) 'discriminatorValue',
      if (index('unknownProperties') != 0) 'unknownProperties',
      if (reader.read('captureField').stringValue != 'additionalProperties')
        'captureField',
    ];
    if (configured.isNotEmpty) {
      throw InvalidGenerationSource(
        '@Schemable on a library directive only supports schemas; received: '
        '${configured.join(', ')}.',
        element: libraryElement,
      );
    }
    final schemasReader = reader.read('schemas');
    if (schemasReader.isNull || schemasReader.listValue.isEmpty) {
      throw InvalidGenerationSource(
        '@Schemable on a library directive must specify a non-empty schemas '
        'list.',
        element: libraryElement,
      );
    }
  }

  /// Strips `./` segments so `part './user.g.dart'` matches the file next to
  /// the input, without treating `part 'sub/user.g.dart'` as the same path.
  String _normalizedPartUri(String uri) {
    final segments = [
      for (final segment in Uri.parse(uri).pathSegments)
        if (segment.isNotEmpty && segment != '.') segment,
    ];
    return segments.join('/');
  }

  Future<void> _requirePartDirectives(
    BuildStep buildStep,
    Element annotatedElement,
  ) async {
    final inputName = buildStep.inputId.pathSegments.last;
    final baseName = inputName.substring(0, inputName.length - '.dart'.length);
    final expectedPart = '$baseName.g.dart';
    final unit = await buildStep.resolver.compilationUnitFor(buildStep.inputId);
    final parts = {
      for (final directive in unit.directives.whereType<PartDirective>())
        if (directive.uri.stringValue case final uri?) _normalizedPartUri(uri),
    };
    if (parts.contains(expectedPart)) {
      return;
    }
    throw InvalidGenerationSource(
      "Ack model generation requires `part '$expectedPart';` in this library.",
      element: annotatedElement,
      todo: "Add `part '$expectedPart';` next to the library's directives.",
    );
  }

  /// Resolves the qualifier that exposes Ack's generated-model support types.
  ///
  /// Looking through import namespaces supports package barrels, local barrels,
  /// prefixes, and combinators without tying generation to one exact URI.
  String? _ackRuntimeQualifier(
    LibraryReader library,
    Element annotatedElement,
  ) => _visibleQualifier(
    library,
    annotatedElement,
    requiredTypes: const {
      'AckModelAdapter': _ackModelAdapterChecker,
      'SchemaResult': _schemaResultChecker,
    },
    requiredElements: const {
      'deepEquals': 'package:ack/src/utils/collection_utils.dart',
      'deepHashCode': 'package:ack/src/utils/collection_utils.dart',
    },
    message:
        'Generated Ack models require visible exact AckModelAdapter, '
        'SchemaResult, deepEquals, and deepHashCode imports in this library.',
    todo:
        'Import package:ack/ack.dart, directly or through a barrel, and '
        'ensure AckModelAdapter, SchemaResult, deepEquals, and deepHashCode '
        'are exposed.',
  );

  String? _visibleQualifier(
    LibraryReader library,
    Element annotatedElement, {
    required Map<String, TypeChecker> requiredTypes,
    Map<String, String> requiredElements = const {},
    required String message,
    required String todo,
  }) {
    String? prefixed;
    var hasUnprefixed = false;
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) {
        continue;
      }
      final prefix = import.prefix?.element.name;
      final exposesRequiredTypes = requiredTypes.entries.every((entry) {
        final candidate = prefix == null
            ? import.namespace.get2(entry.key)
            : import.namespace.getPrefixed2(prefix, entry.key);
        return candidate != null && entry.value.isExactly(candidate);
      });
      final exposesRequiredElements = requiredElements.entries.every((entry) {
        final candidate = prefix == null
            ? import.namespace.get2(entry.key)
            : import.namespace.getPrefixed2(prefix, entry.key);
        return candidate?.library?.uri.toString() == entry.value;
      });
      if (!exposesRequiredTypes || !exposesRequiredElements) continue;
      if (prefix != null && prefix.isNotEmpty) {
        prefixed ??= prefix;
      } else {
        hasUnprefixed = true;
      }
    }
    if (prefixed != null) return prefixed;
    if (hasUnprefixed) return null;
    throw InvalidGenerationSource(
      message,
      element: annotatedElement,
      todo: todo,
    );
  }
}
