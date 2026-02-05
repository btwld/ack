import 'dart:io';

import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'analyzer/schema_ast_analyzer.dart';
import 'builders/schema_builder.dart';
import 'builders/type_builder.dart';
import 'models/model_info.dart';
import 'validation/code_validator.dart';
import 'validation/model_validator.dart';

/// Logger for schema generation warnings and diagnostics.
final _log = Logger('AckSchemaGenerator');

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
    final annotatedElements = <ClassElement2>[];
    final annotatedVariables = <TopLevelVariableElement2>[];
    final annotatedGetters = <GetterElement>[];

    // Find all classes annotated with @AckModel and variables annotated with @AckType
    for (final element in library.allElements) {
      if (element is ClassElement2) {
        if (_hasAckTypeAnnotation(element)) {
          throw InvalidGenerationSourceError(
            '@AckType can only be applied to top-level schema variables or getters, not classes.',
            element: element,
            todo:
                'Remove @AckType from the class and annotate a schema variable instead.',
          );
        }
        final annotation = TypeChecker.typeNamed(
          AckModel,
        ).firstAnnotationOf(element);
        if (annotation != null) {
          annotatedElements.add(element);
        }
      } else if (element is TopLevelVariableElement2) {
        if (_hasAckTypeAnnotation(element)) {
          annotatedVariables.add(element);
        }
      } else if (element is GetterElement) {
        final isTopLevel = element.enclosingElement2 is LibraryElement2;
        if (isTopLevel &&
            !element.isSynthetic &&
            _hasAckTypeAnnotation(element)) {
          annotatedGetters.add(element);
        }
      }
    }

    if (annotatedElements.isEmpty &&
        annotatedVariables.isEmpty &&
        annotatedGetters.isEmpty) {
      return '';
    }

    // Generate all schema fields and extension types for this file
    final schemaFields = <Field>[];
    final extensionTypes = <Spec>[];
    final analyzer = ModelAnalyzer();
    final schemaAstAnalyzer = SchemaAstAnalyzer();
    final schemaBuilder = SchemaBuilder();
    final typeBuilder = TypeBuilder();

    // First pass: Analyze all models individually (from @AckModel classes)
    final modelInfos = <ModelInfo>[];
    for (final element in annotatedElements) {
      try {
        // Validate element can be processed
        _validateElement(element);

        final annotation = TypeChecker.typeNamed(
          AckModel,
        ).firstAnnotationOf(element)!;
        final annotationReader = ConstantReader(annotation);

        // Analyze the model
        final modelInfo = analyzer.analyze(element, annotationReader);
        modelInfos.add(modelInfo);
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Invalid @AckModel annotation on class ${element.name3}: $e',
          element: element,
          todo:
              'Check annotation syntax. See: https://docs.page/btwld/ack/annotations',
        );
      }
    }

    // Also analyze schema variables annotated with @AckType
    for (final variable in annotatedVariables) {
      try {
        String? customTypeName;
        final ackTypeAnnotation = TypeChecker.typeNamed(
          AckType,
        ).firstAnnotationOfExact(variable);
        if (ackTypeAnnotation != null) {
          final annotationReader = ConstantReader(ackTypeAnnotation);
          final nameField = annotationReader.peek('name');
          if (nameField != null && !nameField.isNull) {
            customTypeName = nameField.stringValue;
          }
        }

        final modelInfo = schemaAstAnalyzer.analyzeSchemaVariable(
          variable,
          customTypeName: customTypeName,
        );
        if (modelInfo != null) {
          modelInfos.add(modelInfo);
        }
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Failed to analyze schema variable "${variable.name3}": $e',
          element: variable,
          todo:
              'Ensure the variable uses Ack schema syntax (e.g., Ack.object(), Ack.string())',
        );
      }
    }

    // Also analyze schema getters annotated with @AckType
    for (final getter in annotatedGetters) {
      try {
        String? customTypeName;
        final ackTypeAnnotation = TypeChecker.typeNamed(
          AckType,
        ).firstAnnotationOfExact(getter);
        if (ackTypeAnnotation != null) {
          final annotationReader = ConstantReader(ackTypeAnnotation);
          final nameField = annotationReader.peek('name');
          if (nameField != null && !nameField.isNull) {
            customTypeName = nameField.stringValue;
          }
        }

        final modelInfo = schemaAstAnalyzer.analyzeSchemaGetter(
          getter,
          customTypeName: customTypeName,
        );
        if (modelInfo != null) {
          modelInfos.add(modelInfo);
        }
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Failed to analyze schema getter "${getter.name3}": $e',
          element: getter,
          todo:
              'Ensure the getter returns Ack schema syntax (e.g., Ack.object(), Ack.string()).',
        );
      }
    }

    // Second pass: Build discriminator relationships
    final finalModelInfos = analyzer.buildDiscriminatorRelationships(
      modelInfos,
      annotatedElements,
    );

    // Set all models on schema builder for cross-referencing (e.g., custom schemaNames in discriminated types)
    schemaBuilder.setAllModels(finalModelInfos);

    // Third pass: Generate code for all models
    for (final modelInfo in finalModelInfos) {
      // Skip schema generation for schema variables (they already exist)
      if (modelInfo.isFromSchemaVariable) {
        continue;
      }

      // Find the corresponding element for error reporting
      final element = annotatedElements.firstWhere(
        (e) => e.name3 == modelInfo.className,
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
          'Schema generation failed for ${element.name3}: $e',
          element: element,
          todo:
              'Ensure all field types are supported. See: https://docs.page/btwld/ack/supported-types',
        );
      }
    }

    // Pass 3b: Generate extension types for models with @AckType
    _generateExtensionTypes(
      annotatedElements,
      annotatedVariables,
      annotatedGetters,
      finalModelInfos,
      typeBuilder,
      extensionTypes,
    );

    // Only generate if we have content
    if (schemaFields.isEmpty && extensionTypes.isEmpty) {
      return '';
    }

    // Generate part file with schema variables and extension types
    final inputFileName = buildStep.inputId.pathSegments.last;
    final generatedLibrary = Library(
      (b) => b
        ..comments.add('// GENERATED CODE - DO NOT MODIFY BY HAND')
        ..directives.addAll([Directive.partOf(inputFileName)])
        ..body.addAll([...schemaFields, ...extensionTypes]),
    );

    final emitter = DartEmitter(
      allocator: Allocator.none,
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final generatedCode = generatedLibrary.accept(emitter).toString();

    // Format code first - DartEmitter outputs valid but unformatted code
    String formattedCode;
    try {
      formattedCode = _formatter.format(generatedCode);
    } catch (e) {
      // If formatting fails, use unformatted code but still validate
      _log.warning('Code formatting failed, using unformatted output: $e');
      formattedCode = generatedCode;
    }

    // Validate formatted code to ensure what we write is syntactically correct
    final validation = CodeValidator.validate(formattedCode);
    if (validation.isFailure) {
      String debugInfo = '';

      // Only write debug file if ACK_GENERATOR_DEBUG=true environment variable is set
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
        todo: 'Fix the code generation logic to produce valid Dart syntax',
      );
    }

    return formattedCode;
  }

  /// Validates that the element can be processed by the generator
  void _validateElement(ClassElement2 element) {
    // Check if this is a discriminated base class (abstract is allowed for discriminated types)
    final annotation = TypeChecker.typeNamed(
      AckModel,
    ).firstAnnotationOf(element);
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

  /// Generates extension types for models annotated with @AckType
  void _generateExtensionTypes(
    List<ClassElement2> annotatedElements,
    List<TopLevelVariableElement2> annotatedVariables,
    List<GetterElement> annotatedGetters,
    List<ModelInfo> finalModelInfos,
    TypeBuilder typeBuilder,
    List<Spec> extensionTypes,
  ) {
    // Collect models that have @AckType annotation (schema variables only)
    final typedModels = <ModelInfo>[];
    final typedElements = <Element2>[];

    for (final modelInfo in finalModelInfos) {
      if (!modelInfo.isFromSchemaVariable) {
        continue;
      }

      final element = _findAnnotatedSchemaElement(
        modelInfo.schemaClassName,
        annotatedVariables,
        annotatedGetters,
      );
      if (element == null) {
        throw InvalidGenerationSourceError(
          'Could not find schema declaration "${modelInfo.schemaClassName}"',
          todo:
              'Ensure the schema variable/getter exists and is annotated with @AckType',
        );
      }

      typedModels.add(modelInfo);
      typedElements.add(element);
    }

    if (typedModels.isEmpty) {
      return;
    }

    // Sort by dependencies (topological sort)
    List<ModelInfo> sortedModels;
    try {
      sortedModels = typeBuilder.topologicalSort(typedModels);
    } catch (e) {
      final element = typedElements.first;
      throw InvalidGenerationSourceError(
        'Extension type dependency resolution failed: $e',
        element: element,
        todo:
            'Check for circular dependencies in your model hierarchy. '
            'Ensure all nested types have @AckType annotation.',
      );
    }

    // Generate extension types or sealed classes
    for (final model in sortedModels) {
      // Find the corresponding element (class or variable)
      Element2 element;
      if (model.isFromSchemaVariable) {
        final schemaElement = _findAnnotatedSchemaElement(
          model.schemaClassName,
          annotatedVariables,
          annotatedGetters,
        );
        if (schemaElement == null) {
          throw InvalidGenerationSourceError(
            'Could not find schema declaration "${model.schemaClassName}"',
            todo:
                'Ensure the schema variable/getter exists and is annotated with @AckType',
          );
        }
        element = schemaElement;
      } else {
        element = annotatedElements.firstWhere(
          (e) => e.name3 == model.className,
        );
      }

      try {
        // Check if this is a discriminated base class
        if (model.isDiscriminatedBase) {
          // Generate sealed class for discriminated base
          final sealedClass = typeBuilder.buildSealedClass(model, sortedModels);
          if (sealedClass != null) {
            extensionTypes.add(sealedClass);
          }

          // Generate extension types for subtypes
          final subtypes = model.subtypes;
          if (subtypes != null) {
            for (final subtypeElement in subtypes.values) {
              final subtypeModel = sortedModels.firstWhere(
                (m) => m.className == subtypeElement.name3,
                orElse: () => throw InvalidGenerationSourceError(
                  'Subtype ${subtypeElement.name3} not found in sorted models',
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
              }
            }
          }
        } else if (model.isDiscriminatedSubtype) {
          // Skip - will be generated when processing base class
          continue;
        } else {
          // Generate regular extension type
          final extensionType = typeBuilder.buildExtensionType(
            model,
            sortedModels,
          );
          if (extensionType != null) {
            extensionTypes.add(extensionType);
          }
        }
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Extension type generation failed for ${element.name3}: $e',
          element: element,
          todo:
              'Ensure all nested types have @AckType annotation. '
              'Generic classes are not supported.',
        );
      }
    }
  }

  /// Checks if an element has @AckType annotation
  bool _hasAckTypeAnnotation(Element2 element) {
    return TypeChecker.typeNamed(AckType).hasAnnotationOfExact(element);
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
}
