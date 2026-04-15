import 'dart:io';

import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/schema_ast_analyzer.dart';
import 'builders/type_builder.dart';
import 'models/model_info.dart';
import 'validation/code_validator.dart';

/// Logger for schema generation warnings and diagnostics.
final _log = Logger('AckSchemaGenerator');

/// Generates extension types for top-level schemas annotated with `@AckType`.
class AckSchemaGenerator extends Generator {
  final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final annotatedVariables = <TopLevelVariableElement2>[];
    final annotatedGetters = <GetterElement>[];

    for (final element in library.allElements) {
      if (element is ClassElement2 && _hasAckTypeAnnotation(element)) {
        throw InvalidGenerationSourceError(
          '@AckType can only be applied to top-level schema variables or getters, not classes.',
          element: element,
          todo:
              'Remove @AckType from the class and annotate a top-level schema variable or getter instead.',
        );
      }

      if (element is TopLevelVariableElement2 &&
          _hasAckTypeAnnotation(element)) {
        annotatedVariables.add(element);
      } else if (element is GetterElement && _hasAckTypeAnnotation(element)) {
        final isTopLevel = element.enclosingElement2 is LibraryElement2;
        if (!isTopLevel) {
          throw InvalidGenerationSourceError(
            '@AckType can only be applied to top-level schema variables or getters.',
            element: element,
            todo:
                'Move this getter to the library level or annotate a top-level schema variable instead.',
          );
        }

        if (!element.isSynthetic) {
          annotatedGetters.add(element);
        }
      }
    }

    for (final classElement in library.classes) {
      for (final getter in classElement.getters) {
        if (_hasAckTypeAnnotation(getter)) {
          throw InvalidGenerationSourceError(
            '@AckType can only be applied to top-level schema variables or getters.',
            element: getter,
            todo:
                'Move this getter to the library level or annotate a top-level schema variable instead.',
          );
        }
      }
    }

    if (annotatedVariables.isEmpty && annotatedGetters.isEmpty) {
      return '';
    }

    final helperMethods = <Method>[];
    final extensionTypes = <Spec>[];
    final schemaAstAnalyzer = SchemaAstAnalyzer();
    final typeBuilder = TypeBuilder();
    typeBuilder.setAckImportPrefix(_resolveAckImportPrefix(library));

    final modelInfos = <ModelInfo>[];

    for (final variable in annotatedVariables) {
      try {
        final modelInfo = schemaAstAnalyzer.analyzeSchemaVariable(
          variable,
          customTypeName: _extractAckTypeName(variable),
        );
        if (modelInfo != null) {
          modelInfos.add(modelInfo);
        }
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Failed to analyze schema variable "${variable.name3}": $e',
          element: variable,
          todo:
              'Ensure the variable uses Ack schema syntax such as Ack.object(), Ack.string(), or another @AckType schema reference.',
        );
      }
    }

    for (final getter in annotatedGetters) {
      try {
        final modelInfo = schemaAstAnalyzer.analyzeSchemaGetter(
          getter,
          customTypeName: _extractAckTypeName(getter),
        );
        if (modelInfo != null) {
          modelInfos.add(modelInfo);
        }
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Failed to analyze schema getter "${getter.name3}": $e',
          element: getter,
          todo:
              'Ensure the getter returns Ack schema syntax such as Ack.object(), Ack.string(), or another @AckType schema reference.',
        );
      }
    }

    final linkedModelInfos = _linkDiscriminatedModels(modelInfos);

    _generateExtensionTypes(
      annotatedVariables,
      annotatedGetters,
      linkedModelInfos,
      typeBuilder,
      helperMethods,
      extensionTypes,
    );

    if (extensionTypes.isEmpty) {
      return '';
    }

    final inputFileName = buildStep.inputId.pathSegments.last;
    final generatedLibrary = Library(
      (b) => b
        ..directives.add(Directive.partOf(inputFileName))
        ..body.addAll([...helperMethods, ...extensionTypes]),
    );

    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final generatedCode = generatedLibrary.accept(emitter).toString();

    String formattedCode;
    try {
      formattedCode = _formatter.format(generatedCode);
    } catch (e) {
      _log.warning('Code formatting failed, using unformatted output: $e');
      formattedCode = generatedCode;
    }

    final validation = CodeValidator.validate(formattedCode);
    if (validation.isFailure) {
      var debugInfo = '';
      final debugEnabled =
          Platform.environment['ACK_GENERATOR_DEBUG']?.toLowerCase() == 'true';
      if (debugEnabled) {
        final outputPath = buildStep.inputId.changeExtension('.g.dart.debug');
        final file = File(outputPath.path);
        file.writeAsStringSync(formattedCode);
        debugInfo = '\nDebug output written to: ${outputPath.path}';
      }

      throw InvalidGenerationSourceError(
        'Generated code validation failed: ${validation.errorMessage}$debugInfo',
        todo: 'Fix the code generation logic to produce valid Dart syntax.',
      );
    }

    return formattedCode;
  }

  void _generateExtensionTypes(
    List<TopLevelVariableElement2> annotatedVariables,
    List<GetterElement> annotatedGetters,
    List<ModelInfo> models,
    TypeBuilder typeBuilder,
    List<Method> helperMethods,
    List<Spec> extensionTypes,
  ) {
    final typedElements = <Element2>[
      for (final model in models)
        _findAnnotatedSchemaElement(
              model.schemaClassName,
              annotatedVariables,
              annotatedGetters,
            ) ??
            (throw InvalidGenerationSourceError(
              'Could not find schema declaration "${model.schemaClassName}"',
              todo:
                  'Ensure the schema variable or getter exists and is annotated with @AckType.',
            )),
    ];

    List<ModelInfo> sortedModels;
    try {
      sortedModels = typeBuilder.topologicalSort(models);
    } catch (e) {
      final element = typedElements.first;
      throw InvalidGenerationSourceError(
        'Extension type dependency resolution failed: $e',
        element: element,
        todo:
            'Check for circular dependencies in the typed schema graph and ensure nested schemas resolve to @AckType declarations.',
      );
    }

    final generatedTypeModels = <ModelInfo>[];

    for (final model in sortedModels) {
      final element = _findAnnotatedSchemaElement(
        model.schemaClassName,
        annotatedVariables,
        annotatedGetters,
      );
      if (element == null) {
        throw InvalidGenerationSourceError(
          'Could not find schema declaration "${model.schemaClassName}"',
          todo:
              'Ensure the schema variable or getter exists and is annotated with @AckType.',
        );
      }

      try {
        if (model.isDiscriminatedBaseDefinition) {
          final baseExtension = typeBuilder.buildDiscriminatedExtensionBase(
            model,
            sortedModels,
          );
          if (baseExtension != null) {
            extensionTypes.add(baseExtension);
          }

          final subtypeNames = model.subtypeNames;
          if (subtypeNames == null) {
            continue;
          }

          final emittedSubtypeSchemaNames = <String>{};
          for (final subtypeSchemaName in subtypeNames.values) {
            if (!emittedSubtypeSchemaNames.add(subtypeSchemaName)) {
              throw InvalidGenerationSourceError(
                'Discriminated base "${model.schemaClassName}" maps multiple discriminator values to subtype "$subtypeSchemaName".',
                element: element,
                todo:
                    'Ensure each discriminator value maps to a unique branch schema.',
              );
            }

            final subtypeModel = sortedModels.firstWhere(
              (candidate) => candidate.schemaClassName == subtypeSchemaName,
              orElse: () => throw InvalidGenerationSourceError(
                'Subtype "$subtypeSchemaName" was not found while generating "${model.schemaClassName}".',
                element: element,
              ),
            );

            final subtypeExtension = typeBuilder.buildDiscriminatedSubtype(
              subtypeModel,
              model,
              sortedModels,
            );
            if (subtypeExtension != null) {
              extensionTypes.add(subtypeExtension);
              generatedTypeModels.add(subtypeModel);
            }
          }
          continue;
        }

        if (model.isDiscriminatedSubtype) {
          continue;
        }

        final extensionType = typeBuilder.buildExtensionType(
          model,
          sortedModels,
        );
        if (extensionType != null) {
          extensionTypes.add(extensionType);
          generatedTypeModels.add(model);
        }
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Extension type generation failed for ${element.name3}: $e',
          element: element,
          todo:
              'Ensure nested schemas resolve to @AckType declarations and unsupported schema shapes are not annotated.',
        );
      }
    }

    if (generatedTypeModels.isNotEmpty) {
      helperMethods.addAll(
        typeBuilder.buildTopLevelHelpers(generatedTypeModels),
      );
    }
  }

  List<ModelInfo> _linkDiscriminatedModels(List<ModelInfo> models) {
    final linked = List<ModelInfo>.from(models);
    final modelIndexBySchemaClassName = <String, int>{
      for (var i = 0; i < linked.length; i++) linked[i].schemaClassName: i,
    };
    final branchOwnerByCanonicalIdentity = <String, String>{};

    for (var i = 0; i < linked.length; i++) {
      final baseModel = linked[i];
      if (!baseModel.isDiscriminatedBaseDefinition) {
        continue;
      }

      final discriminatorKey = baseModel.discriminatorKey;
      final subtypeNames = baseModel.subtypeNames;
      if (discriminatorKey == null || subtypeNames == null) {
        continue;
      }

      for (final entry in subtypeNames.entries) {
        final discriminatorValue = entry.key;
        final branchSchemaClassName = entry.value;
        final branchIndex = modelIndexBySchemaClassName[branchSchemaClassName];

        if (branchIndex == null) {
          throw InvalidGenerationSourceError(
            'Could not resolve discriminated branch "$branchSchemaClassName" for base "${baseModel.schemaClassName}".',
            todo:
                'Ensure every Ack.discriminated(...) branch references an @AckType schema declared in the same library.',
          );
        }

        final branchModel = linked[branchIndex];
        final canonicalBranchIdentity =
            branchModel.schemaIdentity ?? branchSchemaClassName;
        final existingOwner =
            branchOwnerByCanonicalIdentity[canonicalBranchIdentity];
        if (existingOwner != null &&
            existingOwner != baseModel.schemaClassName) {
          throw InvalidGenerationSourceError(
            'Branch schema "$branchSchemaClassName" is mapped to multiple discriminated bases: "$existingOwner" and "${baseModel.schemaClassName}".',
            todo:
                'A branch schema can only belong to one Ack.discriminated(...) base.',
          );
        }
        branchOwnerByCanonicalIdentity[canonicalBranchIdentity] =
            baseModel.schemaClassName;

        linked[branchIndex] = _copyModelInfo(
          branchModel,
          discriminatorKey: discriminatorKey,
          discriminatorValue: discriminatorValue,
          discriminatedBaseClassName: baseModel.className,
        );
      }
    }

    return linked;
  }

  ModelInfo _copyModelInfo(
    ModelInfo model, {
    String? discriminatorKey,
    String? discriminatorValue,
    Map<String, String>? subtypeNames,
    String? discriminatedBaseClassName,
  }) {
    return ModelInfo(
      className: model.className,
      schemaClassName: model.schemaClassName,
      description: model.description,
      fields: model.fields,
      additionalProperties: model.additionalProperties,
      discriminatorKey: discriminatorKey ?? model.discriminatorKey,
      discriminatorValue: discriminatorValue ?? model.discriminatorValue,
      subtypeNames: subtypeNames ?? model.subtypeNames,
      schemaIdentity: model.schemaIdentity,
      discriminatedBaseClassName:
          discriminatedBaseClassName ?? model.discriminatedBaseClassName,
      representationType: model.representationType,
      isNullableSchema: model.isNullableSchema,
    );
  }

  bool _hasAckTypeAnnotation(Element2 element) {
    return TypeChecker.typeNamed(AckType).hasAnnotationOfExact(element);
  }

  String? _extractAckTypeName(Element2 element) {
    final annotation = TypeChecker.typeNamed(
      AckType,
    ).firstAnnotationOfExact(element);
    if (annotation == null) {
      return null;
    }

    final nameField = ConstantReader(annotation).peek('name');
    return nameField != null && !nameField.isNull
        ? nameField.stringValue
        : null;
  }

  Element2? _findAnnotatedSchemaElement(
    String schemaName,
    List<TopLevelVariableElement2> annotatedVariables,
    List<GetterElement> annotatedGetters,
  ) {
    for (final variable in annotatedVariables) {
      if (variable.name3 == schemaName) {
        return variable;
      }
    }

    for (final getter in annotatedGetters) {
      if (getter.name3 == schemaName) {
        return getter;
      }
    }

    return null;
  }

  String? _resolveAckImportPrefix(LibraryReader library) {
    for (final import in library.element.firstFragment.libraryImports2) {
      if (!_isAckImport(import)) {
        continue;
      }

      final prefixElement = import.prefix2?.element;
      final prefix = prefixElement?.name3;
      if (prefix != null && prefix.isNotEmpty) {
        return prefix;
      }
      return null;
    }

    return null;
  }

  bool _isAckImport(LibraryImport import) {
    final importedLibrary = import.importedLibrary2;
    if (importedLibrary != null &&
        importedLibrary.uri.toString() == 'package:ack/ack.dart') {
      return true;
    }

    return import.uri.toString().contains('package:ack/ack.dart');
  }
}
