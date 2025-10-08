import 'dart:io';

import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'analyzer/model_analyzer.dart';
import 'analyzer/schema_ast_analyzer.dart';
import 'builders/schema_builder.dart';
import 'builders/type_builder.dart';
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
    final annotatedVariables = <TopLevelVariableElement>[];

    // Find all classes annotated with @AckModel and variables annotated with @AckType
    for (final element in library.allElements) {
      if (element is ClassElement) {
        final annotation = TypeChecker.fromRuntime(
          AckModel,
        ).firstAnnotationOf(element);
        if (annotation != null) {
          annotatedElements.add(element);
        }
      } else if (element is TopLevelVariableElement) {
        if (_hasAckTypeAnnotation(element)) {
          annotatedVariables.add(element);
        }
      }
    }

    if (annotatedElements.isEmpty && annotatedVariables.isEmpty) {
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

        final annotation = TypeChecker.fromRuntime(
          AckModel,
        ).firstAnnotationOf(element)!;
        final annotationReader = ConstantReader(annotation);

        // Analyze the model
        final modelInfo = analyzer.analyze(element, annotationReader);
        modelInfos.add(modelInfo);
      } catch (e) {
        throw InvalidGenerationSourceError(
          'Invalid @AckModel annotation on class ${element.name}: $e',
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
        final ackTypeAnnotation = TypeChecker.fromRuntime(
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
          'Failed to analyze schema variable "${variable.name}": $e',
          element: variable,
          todo:
              'Ensure the variable uses Ack schema syntax (e.g., Ack.object(), Ack.string())',
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
      // Skip schema generation for schema variables (they already exist)
      if (modelInfo.isFromSchemaVariable) {
        continue;
      }

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
          todo:
              'Ensure all field types are supported. See: https://docs.page/btwld/ack/supported-types',
        );
      }
    }

    // Pass 3b: Generate extension types for models with @AckType
    _generateExtensionTypes(
      annotatedElements,
      annotatedVariables,
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
      print('Warning: Failed to format generated code: $e');
      formattedCode = generatedCode;
    }

    // Validate formatted code to ensure what we write is syntactically correct
    final validation = CodeValidator.validate(formattedCode);
    if (validation.isFailure) {
      // Write to file for debugging
      final outputPath = buildStep.inputId.changeExtension('.g.dart.debug');
      final file = File(outputPath.path);
      file.writeAsStringSync(formattedCode);

      throw InvalidGenerationSourceError(
        'Generated code validation failed: ${validation.errorMessage}\n'
        'Debug output written to: ${outputPath.path}',
        todo: 'Fix the code generation logic to produce valid Dart syntax',
      );
    }

    return formattedCode;
  }

  /// Validates that the element can be processed by the generator
  void _validateElement(ClassElement element) {
    // Check if this is a discriminated base class (abstract is allowed for discriminated types)
    final annotation = TypeChecker.fromRuntime(
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
    List<ClassElement> annotatedElements,
    List<TopLevelVariableElement> annotatedVariables,
    List<ModelInfo> finalModelInfos,
    TypeBuilder typeBuilder,
    List<Spec> extensionTypes,
  ) {
    // Collect models that have @AckType annotation
    final typedModels = <ModelInfo>[];
    final typedElements = <Element>[];

    for (final modelInfo in finalModelInfos) {
      Element? element;

      // Find the corresponding element (class or variable)
      if (modelInfo.isFromSchemaVariable) {
        element = annotatedVariables.firstWhere(
          (e) => e.name == modelInfo.schemaClassName,
          orElse: () => throw InvalidGenerationSourceError(
            'Could not find schema variable "${modelInfo.schemaClassName}"',
            todo:
                'Ensure the schema variable exists and is annotated with @AckType',
          ),
        );
      } else {
        element = annotatedElements.firstWhere(
          (e) => e.name == modelInfo.className,
          orElse: () => throw InvalidGenerationSourceError(
            'Could not find class "${modelInfo.className}"',
            todo: 'Ensure the class exists and is annotated with @AckModel',
          ),
        );
      }

      if (_hasAckTypeAnnotation(element)) {
        typedModels.add(modelInfo);
        typedElements.add(element);
      }
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
      Element element;
      if (model.isFromSchemaVariable) {
        element = annotatedVariables.firstWhere(
          (e) => e.name == model.schemaClassName,
        );
      } else {
        element = annotatedElements.firstWhere(
          (e) => e.name == model.className,
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
                (m) => m.className == subtypeElement.name,
                orElse: () => throw InvalidGenerationSourceError(
                  'Subtype ${subtypeElement.name} not found in sorted models',
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
          'Extension type generation failed for ${element.name}: $e',
          element: element,
          todo:
              'Ensure all nested types have @AckType annotation. '
              'Generic classes are not supported.',
        );
      }
    }
  }

  /// Checks if an element has @AckType annotation
  bool _hasAckTypeAnnotation(Element element) {
    return TypeChecker.fromRuntime(AckType).hasAnnotationOfExact(element);
  }
}
