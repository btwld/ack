// ignore_for_file: deprecated_member_use

import 'package:collection/collection.dart';
import 'package:ack/annotations.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';

import '../json/helper_names.dart';
import '../models/field_info.dart';
import '../models/model_info.dart';

/// Logger for schema AST analysis warnings and diagnostics.
final _log = Logger('SchemaAstAnalyzer');

typedef _SchemaReference = ({String name, String? prefix});
typedef _ListElementRef = ({
  MethodInvocation? invocation,
  _SchemaReference? schemaRef,
});
typedef _SchemaChainInfo = ({
  MethodInvocation? ackBase,
  _SchemaReference? schemaReference,
  bool isOptional,
  bool isNullable,
  bool wasTruncated,
  MethodInvocation? transformInvocation,
  DartType? transformOutputType,
  String? transformOutputTypeString,
});

typedef _SchemaTypeMapping = ({
  DartType dartType,
  String? listElementSchemaRef,
  String? listElementDisplayTypeOverride,
  String? listElementCastTypeOverride,
  bool listElementIsCustomType,
});
typedef _ListElementAnalysis = ({
  _SchemaTypeMapping mapping,
  String elementRepresentationType,
});
typedef _ResolvedSchemaElement = ({
  Element element,
  LibraryImport? importDirective,
});

class _ResolvedSchemaReference {
  final String schemaName;
  final ModelInfo modelInfo;
  final String? importPrefix;
  final LibraryImport? importDirective;
  final bool hasAckTypeAnnotation;
  final Element sourceDeclaration;
  final Uri? sourceLibraryUri;

  const _ResolvedSchemaReference({
    required this.schemaName,
    required this.modelInfo,
    required this.importPrefix,
    required this.importDirective,
    required this.hasAckTypeAnnotation,
    required this.sourceDeclaration,
    required this.sourceLibraryUri,
  });
}

/// Analyzes schema variables by walking the AST
///
/// This analyzer inspects the AST structure of schema definitions
/// (like `Ack.object({...})`) to extract field type information without
/// requiring const evaluation or string parsing.
class SchemaAstAnalyzer {
  static const _ackTypeChecker = TypeChecker.typeNamed(
    AckType,
    inPackage: 'ack',
  );
  static const _ackModelChecker = TypeChecker.typeNamed(
    AckModel,
    inPackage: 'ack',
  );

  final Map<String, String> _schemaVariableTypeCache = {};
  final Set<String> _schemaVariableTypeStack = {};
  final Map<String, _ResolvedSchemaReference?> _schemaReferenceCache = {};
  final Set<String> _schemaReferenceResolutionStack = {};
  final Map<LibraryElement, Map<String, ClassElement>> _classByNameCache = {};
  final Map<LibraryElement, Map<String, TopLevelVariableElement>>
  _schemaVarByNameCache = {};
  final Map<LibraryElement, Map<String, GetterElement>>
  _schemaGetterByNameCache = {};

  Map<String, ClassElement> _classesByName(LibraryElement library) {
    return _classByNameCache.putIfAbsent(library, () {
      final map = <String, ClassElement>{};
      for (final classElement in library.classes) {
        final name = classElement.name;
        if (name != null) {
          map.putIfAbsent(name, () => classElement);
        }
      }
      return map;
    });
  }

  Map<String, TopLevelVariableElement> _schemaVarsByName(
    LibraryElement library,
  ) {
    return _schemaVarByNameCache.putIfAbsent(library, () {
      final map = <String, TopLevelVariableElement>{};
      for (final variable in library.topLevelVariables) {
        final name = variable.name;
        if (name != null) {
          map.putIfAbsent(name, () => variable);
        }
      }
      return map;
    });
  }

  Map<String, GetterElement> _schemaGettersByName(LibraryElement library) {
    return _schemaGetterByNameCache.putIfAbsent(library, () {
      final map = <String, GetterElement>{};
      for (final getter in library.getters) {
        if (!getter.isOriginDeclaration) continue;

        final name = getter.name;
        if (name != null) {
          map.putIfAbsent(name, () => getter);
        }
      }
      return map;
    });
  }

  /// Analyzes a schema variable annotated with @AckType
  ///
  /// Walks the AST to extract type information from the schema definition.
  ModelInfo? analyzeSchemaVariable(
    TopLevelVariableElement element, {
    String? customTypeName,
  }) {
    // Get the AST node for this variable using the fragment
    final fragment = element.firstFragment;
    final session = fragment.libraryFragment.element.session;
    final library = element.library;

    final parsedLibResult = session.getParsedLibraryByElement(library);

    // getParsedLibraryByElement returns a SomeParsedLibraryResult which might not have getElementDeclaration
    // We need to check if it's actually a ParsedLibraryResult
    if (parsedLibResult is! ParsedLibraryResult) {
      throw InvalidGenerationSource(
        'Could not get parsed library for "${element.name}"',
        element: element,
      );
    }

    final declaration = parsedLibResult.getFragmentDeclaration(fragment);
    if (declaration == null || declaration.node is! VariableDeclaration) {
      throw InvalidGenerationSource(
        'Could not find variable declaration for "${element.name}"',
        element: element,
      );
    }

    final varDecl = declaration.node as VariableDeclaration;
    final initializer = varDecl.initializer;

    if (initializer == null) {
      throw InvalidGenerationSource(
        'Schema variable "${element.name}" must have an initializer',
        element: element,
      );
    }

    _rejectAckModelFacadeExpression(
      initializer,
      element,
      diagnosticPath: element.name,
    );

    if (initializer is MethodInvocation) {
      final model = _parseSchemaFromAST(
        element.name!,
        initializer,
        element,
        customTypeName: customTypeName,
      );
      if (model == null) return null;
      return _withSchemaIdentity(model, element);
    }

    final schemaReference = _extractSchemaReference(initializer);
    if (schemaReference != null) {
      final model = _parseSchemaAlias(
        variableName: element.name!,
        reference: schemaReference,
        element: element,
        customTypeName: customTypeName,
      );
      return _withSchemaIdentity(model, element);
    }

    throw InvalidGenerationSource(
      'Schema variable "${element.name}" must be initialized with a schema '
      '(e.g., Ack.object({...}))',
      element: element,
    );
  }

  /// Analyzes a top-level schema getter annotated with @AckType.
  ///
  /// Supported forms:
  /// - `AckSchema get userSchema => Ack.object({...});`
  /// - `AckSchema get userSchema { return Ack.object({...}); }`
  ModelInfo? analyzeSchemaGetter(
    GetterElement element, {
    String? customTypeName,
  }) {
    final fragment = element.firstFragment;
    final session = fragment.libraryFragment.element.session;
    final library = element.library;

    final parsedLibResult = session.getParsedLibraryByElement(library);
    if (parsedLibResult is! ParsedLibraryResult) {
      throw InvalidGenerationSource(
        'Could not get parsed library for getter "${element.name}"',
        element: element,
      );
    }

    final declaration = parsedLibResult.getFragmentDeclaration(fragment);
    if (declaration == null || declaration.node is! FunctionDeclaration) {
      throw InvalidGenerationSource(
        'Could not find getter declaration for "${element.name}"',
        element: element,
      );
    }

    final getterDecl = declaration.node as FunctionDeclaration;
    if (!getterDecl.isGetter) {
      throw InvalidGenerationSource(
        '"${element.name}" is not a getter declaration',
        element: element,
      );
    }

    final body = getterDecl.functionExpression.body;
    Expression? schemaExpression;

    if (body is ExpressionFunctionBody) {
      schemaExpression = body.expression;
    } else if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length != 1 || statements.first is! ReturnStatement) {
        throw InvalidGenerationSource(
          'Schema getter "${element.name}" must return a schema expression',
          element: element,
          todo: 'Use an expression body or a single return statement (e.g., return Ack.object({...});).',
        );
      }

      final returnStatement = statements.first as ReturnStatement;
      schemaExpression = returnStatement.expression;
    }

    if (schemaExpression != null) {
      _rejectAckModelFacadeExpression(
        schemaExpression,
        element,
        diagnosticPath: element.name,
      );
    }

    if (schemaExpression is MethodInvocation) {
      final model = _parseSchemaFromAST(
        element.name!,
        schemaExpression,
        element,
        customTypeName: customTypeName,
      );
      if (model == null) return null;
      return _withSchemaIdentity(model, element);
    }

    final schemaReference = _extractSchemaReference(schemaExpression);
    if (schemaReference != null) {
      final model = _parseSchemaAlias(
        variableName: element.name!,
        reference: schemaReference,
        element: element,
        customTypeName: customTypeName,
      );
      return _withSchemaIdentity(model, element);
    }

    throw InvalidGenerationSource(
      'Schema getter "${element.name}" must return an Ack schema invocation or schema reference',
      element: element,
      todo: 'Return a schema expression such as Ack.object({...}), Ack.string(), or another @AckType schema variable/getter.',
    );
  }

  ModelInfo _parseSchemaAlias({
    required String variableName,
    required _SchemaReference reference,
    required Element element,
    String? customTypeName,
  }) {
    final resolved = _resolveSchemaReference(reference, element);
    if (resolved == null) {
      final referenceLabel = _formatSchemaReference(reference);
      throw InvalidGenerationSource(
        'Could not resolve schema alias "$variableName" '
        'to "$referenceLabel"',
        element: element,
      );
    }

    final aliasTypeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );
    final sourceModel = resolved.modelInfo;

    return ModelInfo(
      className: aliasTypeName,
      schemaClassName: variableName,
      fields: sourceModel.fields,
      additionalProperties: sourceModel.additionalProperties,
      discriminatorKey: sourceModel.discriminatorKey,
      discriminatorValue: sourceModel.discriminatorValue,
      subtypeNames: sourceModel.subtypeNames,
      schemaIdentity:
          sourceModel.schemaIdentity ??
          _declarationVisitKey(resolved.sourceDeclaration),
      discriminatedBaseClassName: sourceModel.discriminatedBaseClassName,
      representationType: sourceModel.representationType,

      isNullableSchema: sourceModel.isNullableSchema,
    );
  }

  /// Parses a schema from a MethodInvocation AST node
  ModelInfo? _parseSchemaFromAST(
    String variableName,
    MethodInvocation invocation,
    Element element, {
    String? customTypeName,
  }) {
    final chain = _analyzeSchemaChain(invocation);
    final baseInvocation = chain.ackBase;
    final schemaReference = chain.schemaReference;

    if (schemaReference != null) {
      return _parseSchemaReferenceChain(
        variableName: variableName,
        schemaReference: schemaReference,
        element: element,
        customTypeName: customTypeName,
        isNullable: chain.isNullable,
        transformOutputTypeString: _requireTransformOutputType(
          chain,
          element,
          contextLabel: 'Schema "$variableName"',
        ),
      );
    }

    if (baseInvocation == null) {
      throw InvalidGenerationSource(
        'Schema must be an Ack.xxx() method call (e.g., Ack.object(), Ack.string()) or a schema reference.',
        element: element,
      );
    }

    final methodName = baseInvocation.methodName.name;
    final isNullable = chain.isNullable;
    final transformOutputTypeString = _requireTransformOutputType(
      chain,
      element,
      contextLabel: 'Schema "$variableName"',
    );
    _throwIfUnsupportedTransformedBaseSchema(
      schemaMethod: methodName,
      transformOutputTypeString: transformOutputTypeString,
      element: element,
      contextLabel: 'Schema "$variableName"',
    );

    late final ModelInfo model;
    switch (methodName) {
      case 'object':
        model = _parseObjectSchema(
          variableName,
          baseInvocation,
          invocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      case 'string':
        model = _parseStringSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      case 'integer':
        model = _parseIntegerSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      case 'double':
        model = _parseDoubleSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      case 'boolean':
        model = _parseBooleanSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      case 'list':
        final typeProvider = element.library?.typeProvider;
        if (typeProvider == null) {
          throw InvalidGenerationSource(
            'Could not get type provider for library',
            element: element,
          );
        }
        final listElementAnalysis = _analyzeListElement(
          baseInvocation,
          element,
          typeProvider,
        );
        model = _parseListSchema(
          variableName,
          element,
          isNullable: isNullable,
          listElementAnalysis: listElementAnalysis,
          customTypeName: customTypeName,
        );
        break;
      case 'literal':
        model = _parseLiteralSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      case 'enumString':
        model = _parseEnumStringSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      case 'enumValues':
        model = _parseEnumValuesSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      case 'uri':
        model = _parseRepresentationSchema(
          variableName,
          element,
          representationType: 'Uri',
          isNullable: isNullable,

          customTypeName: customTypeName,
        );
        break;
      case 'date':
      case 'datetime':
        model = _parseRepresentationSchema(
          variableName,
          element,
          representationType: 'DateTime',
          isNullable: isNullable,

          customTypeName: customTypeName,
        );
        break;
      case 'duration':
        model = _parseRepresentationSchema(
          variableName,
          element,
          representationType: 'Duration',
          isNullable: isNullable,

          customTypeName: customTypeName,
        );
        break;
      case 'discriminated':
        model = _parseDiscriminatedSchema(
          variableName,
          baseInvocation,
          element,
          isNullable: isNullable,
          customTypeName: customTypeName,
        );
        break;
      default:
        throw InvalidGenerationSource(
          'Unsupported schema type for @AckType: Ack.$methodName(). '
          'Supported types: object, string, integer, double, boolean, list, literal, enumString, enumValues, uri, date, datetime, duration, discriminated',
          element: element,
        );
    }

    if (transformOutputTypeString != null) {
      return _withRepresentationType(model, transformOutputTypeString);
    }

    return model;
  }

  ModelInfo _parseSchemaReferenceChain({
    required String variableName,
    required _SchemaReference schemaReference,
    required Element element,
    String? customTypeName,
    required bool isNullable,
    required String? transformOutputTypeString,
  }) {
    final resolved = _resolveSchemaReference(schemaReference, element);
    if (resolved == null) {
      final referenceLabel = _formatSchemaReference(schemaReference);
      throw InvalidGenerationSource(
        'Could not resolve schema reference "$referenceLabel" for "$variableName".',
        element: element,
      );
    }

    if (transformOutputTypeString != null) {
      _throwIfUnsupportedTransformedReferencedSchema(
        resolved: resolved,
        element: element,
        contextLabel: 'Schema "$variableName"',
      );
    }

    final aliasTypeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );
    final sourceModel = resolved.modelInfo;

    return ModelInfo(
      className: aliasTypeName,
      schemaClassName: variableName,
      fields: sourceModel.fields,
      additionalProperties: sourceModel.additionalProperties,
      discriminatorKey: sourceModel.discriminatorKey,
      discriminatorValue: sourceModel.discriminatorValue,
      subtypeNames: sourceModel.subtypeNames,
      schemaIdentity:
          sourceModel.schemaIdentity ??
          _declarationVisitKey(resolved.sourceDeclaration),
      discriminatedBaseClassName: sourceModel.discriminatedBaseClassName,
      representationType:
          transformOutputTypeString ?? sourceModel.representationType,
      isNullableSchema: isNullable || sourceModel.isNullableSchema,
    );
  }

  /// Parses Ack.object() schema
  ModelInfo _parseObjectSchema(
    String variableName,
    MethodInvocation baseInvocation,
    MethodInvocation fullInvocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    // Extract the properties map from the first argument
    final args = baseInvocation.argumentList.arguments;
    if (args.isEmpty) {
      throw InvalidGenerationSource(
        'Ack.object() requires a properties map argument',
        element: element,
      );
    }

    final firstArg = args.first;
    if (firstArg is! SetOrMapLiteral) {
      throw InvalidGenerationSource(
        'Ack.object() first argument must be a map literal',
        element: element,
      );
    }

    // Extract fields from the map literal
    final fields = _extractFieldsFromMapLiteral(firstArg, element);

    // Check if additionalProperties is enabled via passthrough() or parameter
    final hasAdditionalProperties = _hasAdditionalPropertiesFromInvocation(
      baseInvocation,
      fullInvocation,
    );

    // Generate extension type name from variable name or custom override
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: fields,
      additionalProperties: hasAdditionalProperties,
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.discriminated(...) schema for @AckType bases.
  ///
  /// Current constraints:
  /// - Base cannot be nullable
  /// - `schemas` must be a non-empty map literal
  /// - Branches must be top-level schema variable/getter references
  /// - Branches must be @AckType object schemas and non-nullable
  /// - Branch discriminator properties may be omitted or compatible
  /// - Each branch schema can only appear once per discriminated base
  /// - Branches must be declared in the same library
  ModelInfo _parseDiscriminatedSchema(
    String variableName,
    MethodInvocation baseInvocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    if (isNullable) {
      throw InvalidGenerationSource(
        'Ack.discriminated(...) cannot be nullable when used with @AckType.',
        element: element,
        todo: 'Remove `.nullable()` from the discriminated base schema.',
      );
    }

    String? discriminatorKey;
    SetOrMapLiteral? schemasLiteral;

    for (final argument in baseInvocation.argumentList.arguments) {
      if (argument is! NamedArgument) continue;

      final name = argument.name.lexeme;
      if (name == 'discriminatorKey') {
        final expression = argument.argumentExpression;
        if (expression is! SimpleStringLiteral) {
          throw InvalidGenerationSource(
            'Ack.discriminated(...): `discriminatorKey` must be a string literal.',
            element: element,
          );
        }
        discriminatorKey = expression.value;
      } else if (name == 'schemas') {
        final expression = argument.argumentExpression;
        if (expression is! SetOrMapLiteral) {
          throw InvalidGenerationSource(
            'Ack.discriminated(...): `schemas` must be a map literal.',
            element: element,
          );
        }
        // Check actual content: if non-empty, entries must be MapLiteralEntry.
        // We avoid relying on `isMap` since it may return false in unresolved
        // contexts (e.g., build_test / source_gen pipelines).
        if (expression.elements.isNotEmpty &&
            expression.elements.first is! MapLiteralEntry) {
          throw InvalidGenerationSource(
            'Ack.discriminated(...): `schemas` must be a map literal.',
            element: element,
          );
        }
        schemasLiteral = expression;
      }
    }

    final resolvedDiscriminatorKey = discriminatorKey;
    if (resolvedDiscriminatorKey == null || resolvedDiscriminatorKey.isEmpty) {
      throw InvalidGenerationSource(
        'Ack.discriminated(...): missing required `discriminatorKey` string literal.',
        element: element,
      );
    }

    final resolvedSchemasLiteral = schemasLiteral;
    if (resolvedSchemasLiteral == null) {
      throw InvalidGenerationSource(
        'Ack.discriminated(...): missing required `schemas` map literal.',
        element: element,
      );
    }
    if (resolvedSchemasLiteral.elements.isEmpty) {
      throw InvalidGenerationSource(
        'Ack.discriminated(...): `schemas` must contain at least one branch.',
        element: element,
      );
    }

    final currentLibraryUri = element.library?.uri;
    final subtypeNames = <String, String>{};

    for (final schemaEntry in resolvedSchemasLiteral.elements) {
      if (schemaEntry is! MapLiteralEntry) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): `schemas` must contain key/value map entries.',
          element: element,
        );
      }

      final keyExpression = schemaEntry.key;
      if (keyExpression is! SimpleStringLiteral) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): discriminator values in `schemas` must be string literals.',
          element: element,
        );
      }

      final discriminatorValue = keyExpression.value;
      if (subtypeNames.containsKey(discriminatorValue)) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): duplicate discriminator value "$discriminatorValue".',
          element: element,
        );
      }

      _rejectAckModelFacadeExpression(
        schemaEntry.value,
        element,
        diagnosticPath: '$variableName.$discriminatorValue',
      );

      final branchReference = _extractSchemaReference(schemaEntry.value);
      if (branchReference == null) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): branch "$discriminatorValue" must reference a top-level schema variable/getter.',
          element: element,
          todo: 'Extract inline expressions to a top-level @AckType schema variable/getter and reference it.',
        );
      }

      final resolvedBranch = _resolveSchemaReference(branchReference, element);
      if (resolvedBranch == null) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): could not resolve branch reference "${_formatSchemaReference(branchReference)}".',
          element: element,
        );
      }

      if (!resolvedBranch.hasAckTypeAnnotation) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): branch "${resolvedBranch.schemaName}" must be annotated with @AckType.',
          element: element,
        );
      }

      if (resolvedBranch.modelInfo.representationType != kMapType) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): branch "${resolvedBranch.schemaName}" must be an object schema (Map<String, Object?> representation).',
          element: element,
        );
      }

      if (resolvedBranch.modelInfo.isNullableSchema) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): branch "${resolvedBranch.schemaName}" cannot be nullable.',
          element: element,
        );
      }

      if (resolvedBranch.sourceLibraryUri != currentLibraryUri) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): branch "${resolvedBranch.schemaName}" must be declared in the same library as "$variableName".',
          element: element,
        );
      }

      if (resolvedBranch.modelInfo.isDiscriminatedBase) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): branch "${resolvedBranch.schemaName}" is itself a discriminated base. '
          'Nested discriminated unions are not supported.',
          element: element,
          todo: 'Use a plain Ack.object(...) schema for each branch, not another Ack.discriminated(...).',
        );
      }

      final discriminatorCompatibilityError =
          _analyzeDiscriminatorPropertyCompatibility(
            declaration: resolvedBranch.sourceDeclaration,
            discriminatorKey: resolvedDiscriminatorKey,
            discriminatorValue: discriminatorValue,
            visitedDeclarations: <String>{},
          );

      if (discriminatorCompatibilityError != null) {
        throw InvalidGenerationSource(
          'Ack.discriminated(...): branch "${resolvedBranch.schemaName}" '
          '$discriminatorCompatibilityError',
          element: element,
          todo:
              'Omit "$resolvedDiscriminatorKey" from the branch schema, or make it accept "$discriminatorValue".',
        );
      }

      subtypeNames[discriminatorValue] =
          resolvedBranch.modelInfo.schemaClassName;
    }

    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: const [],
      representationType: kMapType,
      isNullableSchema: false,
      discriminatorKey: resolvedDiscriminatorKey,
      subtypeNames: subtypeNames,
    );
  }

  String? _analyzeDiscriminatorPropertyCompatibility({
    required Element declaration,
    required String discriminatorKey,
    required String discriminatorValue,
    required Set<String> visitedDeclarations,
  }) {
    final declarationKey = _declarationVisitKey(declaration);
    if (!visitedDeclarations.add(declarationKey)) {
      return 'has a recursive discriminator property reference that cannot be analyzed.';
    }

    final schemaExpression = _extractSchemaExpressionForDeclaration(
      declaration,
    );
    if (schemaExpression == null) {
      return 'has a discriminator property that could not be analyzed.';
    }

    return _analyzeDiscriminatorSchemaExpressionCompatibility(
      expression: schemaExpression,
      contextElement: declaration,
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      visitedDeclarations: visitedDeclarations,
    );
  }

  String? _analyzeDiscriminatorSchemaExpressionCompatibility({
    required Expression expression,
    required Element contextElement,
    required String discriminatorKey,
    required String discriminatorValue,
    required Set<String> visitedDeclarations,
  }) {
    if (expression is MethodInvocation) {
      final schemaReferenceBase = _findSchemaVariableBase(expression);
      if (schemaReferenceBase != null) {
        final resolvedBranch = _resolveSchemaReference(
          schemaReferenceBase,
          contextElement,
        );
        if (resolvedBranch == null) {
          return 'has a discriminator property reference that could not be resolved.';
        }

        return _analyzeDiscriminatorPropertyCompatibility(
          declaration: resolvedBranch.sourceDeclaration,
          discriminatorKey: discriminatorKey,
          discriminatorValue: discriminatorValue,
          visitedDeclarations: visitedDeclarations,
        );
      }

      final baseInvocation = _findBaseAckInvocation(expression);
      if (baseInvocation == null ||
          baseInvocation.methodName.name != 'object') {
        return _analyzeDiscriminatorPropertySchemaExpression(
          expression: expression,
          contextElement: contextElement,
          discriminatorValue: discriminatorValue,
          visitedDeclarations: visitedDeclarations,
        );
      }

      return _analyzeDiscriminatorObjectInvocation(
        objectInvocation: baseInvocation,
        contextElement: contextElement,
        discriminatorKey: discriminatorKey,
        discriminatorValue: discriminatorValue,
        visitedDeclarations: visitedDeclarations,
      );
    }

    final schemaReference = _extractSchemaReference(expression);
    if (schemaReference == null) {
      return 'has a discriminator property that could not be analyzed.';
    }
    final resolvedBranch = _resolveSchemaReference(
      schemaReference,
      contextElement,
    );
    if (resolvedBranch == null) {
      return 'has a discriminator property reference that could not be resolved.';
    }

    return _analyzeDiscriminatorPropertyCompatibility(
      declaration: resolvedBranch.sourceDeclaration,
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      visitedDeclarations: visitedDeclarations,
    );
  }

  String? _analyzeDiscriminatorObjectInvocation({
    required MethodInvocation objectInvocation,
    required Element contextElement,
    required String discriminatorKey,
    required String discriminatorValue,
    required Set<String> visitedDeclarations,
  }) {
    final args = objectInvocation.argumentList.arguments;
    if (args.isEmpty) return null;

    final firstArg = args.first;
    if (firstArg is! SetOrMapLiteral) return null;

    for (final mapElement in firstArg.elements) {
      if (mapElement is! MapLiteralEntry) continue;
      final keyExpression = mapElement.key;
      if (keyExpression is! SimpleStringLiteral ||
          keyExpression.value != discriminatorKey) {
        continue;
      }

      return _analyzeDiscriminatorPropertySchemaExpression(
        expression: mapElement.value,
        contextElement: contextElement,
        discriminatorValue: discriminatorValue,
        visitedDeclarations: visitedDeclarations,
      );
    }

    return null;
  }

  String? _analyzeDiscriminatorPropertySchemaExpression({
    required Expression expression,
    required Element contextElement,
    required String discriminatorValue,
    required Set<String> visitedDeclarations,
  }) {
    if (expression is MethodInvocation) {
      final schemaReferenceBase = _findSchemaVariableBase(expression);
      if (schemaReferenceBase != null) {
        final resolved = _resolveSchemaReference(
          schemaReferenceBase,
          contextElement,
        );
        if (resolved == null) {
          return 'has a discriminator property reference that could not be resolved.';
        }

        return _analyzeDiscriminatorPropertySchemaDeclaration(
          declaration: resolved.sourceDeclaration,
          discriminatorValue: discriminatorValue,
          visitedDeclarations: visitedDeclarations,
        );
      }

      final baseInvocation = _findBaseAckInvocation(expression);
      if (baseInvocation == null) {
        return 'has a discriminator property that could not be analyzed.';
      }

      final schemaMethod = baseInvocation.methodName.name;
      if (schemaMethod == 'literal') {
        if (!_hasOnlyNonRestrictiveDiscriminatorMethods(
          expression,
          baseInvocation,
          baseMethod: 'literal',
        )) {
          return 'has discriminator property schema ${expression.toSource()} that could not be proven to accept "$discriminatorValue".';
        }

        final literalValue = _extractSingleStringArgument(baseInvocation);
        if (literalValue == null) {
          return 'has a discriminator literal that is not a string literal.';
        }
        if (literalValue == discriminatorValue) {
          return null;
        }
        return 'has discriminator literal "$literalValue", but is mapped as "$discriminatorValue".';
      }

      if (schemaMethod == 'enumString') {
        if (!_hasOnlyNonRestrictiveDiscriminatorMethods(
          expression,
          baseInvocation,
          baseMethod: 'enumString',
        )) {
          return 'has discriminator property schema ${expression.toSource()} that could not be proven to accept "$discriminatorValue".';
        }

        final allowedValues = _extractStringListArgument(baseInvocation);
        if (allowedValues == null) {
          return 'has an Ack.enumString(...) discriminator that is not a string list literal.';
        }
        if (allowedValues.contains(discriminatorValue)) {
          return null;
        }
        return 'has discriminator enum values ${allowedValues.map((v) => '"$v"').join(', ')}, '
            'which do not include "$discriminatorValue".';
      }

      return 'has discriminator property schema ${expression.toSource()} that could not be proven to accept "$discriminatorValue".';
    }

    final schemaReference = _extractSchemaReference(expression);
    if (schemaReference == null) {
      return 'has a discriminator property that could not be analyzed.';
    }
    final resolved = _resolveSchemaReference(schemaReference, contextElement);
    if (resolved == null) {
      return 'has a discriminator property reference that could not be resolved.';
    }

    return _analyzeDiscriminatorPropertySchemaDeclaration(
      declaration: resolved.sourceDeclaration,
      discriminatorValue: discriminatorValue,
      visitedDeclarations: visitedDeclarations,
    );
  }

  String? _analyzeDiscriminatorPropertySchemaDeclaration({
    required Element declaration,
    required String discriminatorValue,
    required Set<String> visitedDeclarations,
  }) {
    final declarationKey = _declarationVisitKey(declaration);
    if (!visitedDeclarations.add(declarationKey)) {
      return 'has a recursive discriminator property reference that cannot be analyzed.';
    }

    final schemaExpression = _extractSchemaExpressionForDeclaration(
      declaration,
    );
    if (schemaExpression == null) {
      return 'has a discriminator property reference that could not be analyzed.';
    }

    return _analyzeDiscriminatorPropertySchemaExpression(
      expression: schemaExpression,
      contextElement: declaration,
      discriminatorValue: discriminatorValue,
      visitedDeclarations: visitedDeclarations,
    );
  }

  String? _extractSingleStringArgument(MethodInvocation invocation) {
    final arguments = invocation.argumentList.arguments;
    if (arguments.length != 1 || arguments.first is! SimpleStringLiteral) {
      return null;
    }
    return (arguments.first as SimpleStringLiteral).value;
  }

  List<String>? _extractStringListArgument(MethodInvocation invocation) {
    final arguments = invocation.argumentList.arguments;
    if (arguments.length != 1 || arguments.first is! ListLiteral) {
      return null;
    }

    final values = <String>[];
    for (final element in (arguments.first as ListLiteral).elements) {
      if (element is! SimpleStringLiteral) return null;
      values.add(element.value);
    }
    return values;
  }

  bool _hasOnlyNonRestrictiveDiscriminatorMethods(
    MethodInvocation expression,
    MethodInvocation baseInvocation, {
    required String baseMethod,
  }) {
    final (chain, _) = _collectMethodChain(expression);
    const allowedMethods = {'optional', 'nullable', 'describe'};

    for (final invocation in chain) {
      final methodName = invocation.methodName.name;
      if (identical(invocation, baseInvocation)) {
        return methodName == baseMethod;
      }
      if (!allowedMethods.contains(methodName)) {
        return false;
      }
    }

    return true;
  }

  String _declarationVisitKey(Element declaration) {
    final libraryUri = declaration.library?.uri.toString() ?? 'unknown';
    final name = declaration.name ?? '<unnamed>';
    return '$libraryUri::$name';
  }

  ModelInfo _withSchemaIdentity(ModelInfo model, Element declaration) {
    if (model.schemaIdentity != null) {
      return model;
    }

    return ModelInfo(
      className: model.className,
      schemaClassName: model.schemaClassName,
      description: model.description,
      fields: model.fields,
      additionalProperties: model.additionalProperties,
      discriminatorKey: model.discriminatorKey,
      discriminatorValue: model.discriminatorValue,
      subtypeNames: model.subtypeNames,
      schemaIdentity: _declarationVisitKey(declaration),
      discriminatedBaseClassName: model.discriminatedBaseClassName,
      representationType: model.representationType,
      isNullableSchema: model.isNullableSchema,
    );
  }

  Expression? _extractSchemaExpressionForDeclaration(Element declaration) {
    if (declaration is TopLevelVariableElement) {
      final fragment = declaration.firstFragment;
      final session = fragment.libraryFragment.element.session;
      final library = declaration.library;
      final parsedLibResult = session.getParsedLibraryByElement(library);
      if (parsedLibResult is! ParsedLibraryResult) {
        return null;
      }

      final variableDeclaration = parsedLibResult.getFragmentDeclaration(
        fragment,
      );
      if (variableDeclaration == null ||
          variableDeclaration.node is! VariableDeclaration) {
        return null;
      }

      final variableNode = variableDeclaration.node as VariableDeclaration;
      return variableNode.initializer;
    }

    if (declaration is GetterElement) {
      final fragment = declaration.firstFragment;
      final session = fragment.libraryFragment.element.session;
      final library = declaration.library;
      final parsedLibResult = session.getParsedLibraryByElement(library);
      if (parsedLibResult is! ParsedLibraryResult) {
        return null;
      }

      final getterDeclaration = parsedLibResult.getFragmentDeclaration(
        fragment,
      );
      if (getterDeclaration == null ||
          getterDeclaration.node is! FunctionDeclaration) {
        return null;
      }

      final functionDeclaration = getterDeclaration.node as FunctionDeclaration;
      if (!functionDeclaration.isGetter) return null;

      final body = functionDeclaration.functionExpression.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      }

      if (body is BlockFunctionBody) {
        final statements = body.block.statements;
        if (statements.length != 1 || statements.first is! ReturnStatement) {
          return null;
        }

        final returnStatement = statements.first as ReturnStatement;
        return returnStatement.expression;
      }
    }

    return null;
  }

  bool _hasAdditionalPropertiesFromInvocation(
    MethodInvocation baseInvocation,
    MethodInvocation fullInvocation,
  ) {
    bool hasAdditionalProperties = false;

    // First check for named parameter in the base Ack.object() call
    for (final arg in baseInvocation.argumentList.arguments) {
      if (arg is NamedArgument && arg.name.lexeme == 'additionalProperties') {
        if (arg.argumentExpression is BooleanLiteral) {
          hasAdditionalProperties =
              (arg.argumentExpression as BooleanLiteral).value;
        }
      }
    }

    // Then walk forward from fullInvocation to find passthrough() in the chain
    // The chain looks like: Ack.object({...}).passthrough()
    // fullInvocation is the outermost call (passthrough if present)
    // We need to check if passthrough() was called
    MethodInvocation? current = fullInvocation;
    while (current != null && current != baseInvocation) {
      final methodName = current.methodName.name;

      if (methodName == 'passthrough') {
        hasAdditionalProperties = true;
        break;
      }

      // Move down the chain towards the base
      final target = current.target;
      if (target is MethodInvocation) {
        current = target;
      } else {
        break;
      }
    }

    return hasAdditionalProperties;
  }

  /// Extracts field information from a map literal
  List<FieldInfo> _extractFieldsFromMapLiteral(
    SetOrMapLiteral mapLiteral,
    Element element,
  ) {
    final fields = <FieldInfo>[];

    for (final mapElement in mapLiteral.elements) {
      if (mapElement is! MapLiteralEntry) continue;

      final key = mapElement.key;
      final value = mapElement.value;

      // Key should be a string literal
      if (key is! SimpleStringLiteral) {
        throw InvalidGenerationSource(
          'Map keys must be string literals in schema definition',
          element: element,
        );
      }

      final fieldName = key.value;

      // Validate that the field name is a valid Dart identifier
      _validateFieldName(fieldName, element);

      final fieldInfo = _parseFieldValue(fieldName, value, element);
      if (fieldInfo == null) {
        throw InvalidGenerationSource(
          '${element.name}.$fieldName uses unsupported schema expression '
          '`${value.toSource()}`. Use a directly analyzable Ack schema call '
          'or named schema reference.',
          element: element,
        );
      }
      fields.add(fieldInfo);
    }

    return fields;
  }

  /// Parses a field's value expression to determine its type
  FieldInfo? _parseFieldValue(
    String fieldName,
    Expression value,
    Element element,
  ) {
    _rejectAckModelFacadeExpression(
      value,
      element,
      diagnosticPath: '${element.name}.$fieldName',
    );

    // Handle Ack.xxx() method calls
    if (value is MethodInvocation) {
      final schemaReferenceField = _parseSchemaReferenceMethod(
        fieldName,
        value,
        element,
      );
      if (schemaReferenceField != null) {
        return schemaReferenceField;
      }
      return _parseSchemaMethod(fieldName, value, element);
    }

    // Handle references to other schema variables (for nested objects)
    final schemaReference = _extractSchemaReference(value);
    if (schemaReference != null) {
      return _buildFieldInfoForSchemaReference(
        fieldName: fieldName,
        schemaReference: schemaReference,
        element: element,
      );
    }

    return null;
  }

  FieldInfo? _parseSchemaReferenceMethod(
    String fieldName,
    MethodInvocation invocation,
    Element element,
  ) {
    final chain = _analyzeSchemaChain(invocation);
    final schemaReference = chain.schemaReference;
    if (schemaReference == null) {
      return null;
    }

    return _buildFieldInfoForSchemaReference(
      fieldName: fieldName,
      schemaReference: schemaReference,
      element: element,
      isRequired: !chain.isOptional,
      isNullable: chain.isNullable,
      transformedOutputType: chain.transformOutputType,
      transformedRepresentationType: _requireTransformOutputType(
        chain,
        element,
        contextLabel: 'Field "$fieldName"',
      ),
    );
  }

  FieldInfo _buildFieldInfoForSchemaReference({
    required String fieldName,
    required _SchemaReference schemaReference,
    required Element element,
    bool isRequired = true,
    bool isNullable = false,
    DartType? transformedOutputType,
    String? transformedRepresentationType,
  }) {
    final schemaVarName = schemaReference.name;
    final library = element.library;

    final typeProvider = library?.typeProvider;
    if (typeProvider == null) {
      throw InvalidGenerationSource(
        'Could not get type provider for library',
        element: element,
      );
    }

    final resolvedReference = _resolveSchemaReference(
      schemaReference,
      element,
      diagnosticPath: '${element.name}.$fieldName',
    );
    if (resolvedReference == null) {
      throw InvalidGenerationSource(
        'Could not resolve schema reference "$schemaVarName" for field '
        '"$fieldName".',
        element: element,
        todo:
            'Ensure "$schemaVarName" exists, is imported, and is declared as an Ack schema.',
      );
    }

    final hasTransformOverride = transformedRepresentationType != null;
    if (hasTransformOverride) {
      _throwIfUnsupportedTransformedReferencedSchema(
        resolved: resolvedReference,
        element: element,
        contextLabel: 'Field "$fieldName"',
      );
    }

    final representationType =
        transformedRepresentationType ??
        resolvedReference.modelInfo.representationType;
    final visibleRepresentationType = _resolveVisibleRepresentationType(
      representationType: representationType,
      resolved: resolvedReference,
      contextElement: element,
    );
    final hasTypedReference =
        resolvedReference.hasAckTypeAnnotation && !hasTransformOverride;
    final isObjectRepresentation = representationType == kMapType;
    if (isObjectRepresentation && !hasTypedReference) {
      throw InvalidGenerationSource(
        'Field "$fieldName" references object schema "$schemaVarName" '
        'without @AckType. This would fall back to Map<String, Object?>.',
        element: element,
        todo:
            'Annotate "$schemaVarName" with @AckType() so the generator can emit a typed wrapper.',
      );
    }

    final mappedType =
        transformedOutputType ??
        _representationTypeToDartType(representationType, typeProvider);
    final typeBaseName = hasTypedReference
        ? _qualifyTypeBaseName(
            resolvedReference.modelInfo.className,
            resolvedReference.importPrefix,
          )
        : null;
    final rawDisplayTypeOverride =
        !hasTypedReference &&
            !mappedType.isDartCoreString &&
            !mappedType.isDartCoreInt &&
            !mappedType.isDartCoreDouble &&
            !mappedType.isDartCoreBool &&
            !mappedType.isDartCoreNum &&
            !mappedType.isDartCoreList &&
            !mappedType.isDartCoreMap &&
            !mappedType.isDartCoreSet
        ? visibleRepresentationType
        : null;

    return FieldInfo(
      name: fieldName,
      jsonKey: fieldName,
      type: mappedType,
      isRequired: isRequired,
      isNullable: isNullable,
      constraints: [],
      nestedSchemaRef: hasTypedReference ? schemaVarName : null,
      displayTypeOverride: hasTypedReference
          ? '${typeBaseName}Type'
          : rawDisplayTypeOverride,
      nestedSchemaCastTypeOverride: hasTypedReference
          ? visibleRepresentationType
          : null,
    );
  }

  /// Parses a schema method call (e.g., Ack.string(), Ack.integer().optional())
  FieldInfo _parseSchemaMethod(
    String fieldName,
    MethodInvocation invocation,
    Element element,
  ) {
    final chain = _analyzeSchemaChain(invocation);
    final baseInvocation = chain.ackBase;

    if (baseInvocation == null) {
      if (chain.wasTruncated) {
        throw InvalidGenerationSource(
          'Field "$fieldName" schema method chain exceeded max depth of 20. '
          '@AckType requires statically analyzable schema chains.',
          element: element,
          todo: 'Reduce the chaining depth or extract part of the schema into a named variable.',
        );
      }

      throw InvalidGenerationSource(
        'Could not determine schema type for field "$fieldName"',
        element: element,
      );
    }

    final schemaMethod = baseInvocation.methodName.name;
    final transformOutputTypeString = _requireTransformOutputType(
      chain,
      element,
      contextLabel: 'Field "$fieldName"',
    );
    _throwIfUnsupportedTransformedBaseSchema(
      schemaMethod: schemaMethod,
      transformOutputTypeString: transformOutputTypeString,
      element: element,
      contextLabel: 'Field "$fieldName"',
    );

    if (schemaMethod == 'object') {
      throw InvalidGenerationSource(
        'Field "$fieldName" uses anonymous inline Ack.object(...). '
        'Strict typed generation requires a named schema reference.',
        element: element,
        todo: 'Extract this inline object schema into a top-level @AckType() variable and reference it by name.',
      );
    }

    final typeProvider = element.library!.typeProvider;
    final listElementAnalysis =
        schemaMethod == 'list' && transformOutputTypeString == null
        ? _analyzeListElement(
            baseInvocation,
            element,
            typeProvider,
            diagnosticPath: '${element.name}.$fieldName',
          )
        : null;
    // Map schema type to Dart type (passing full invocation for context)
    // Also captures schema variable reference and list metadata for typed wrappers.
    final mappedType =
        listElementAnalysis?.mapping ??
        _mapSchemaTypeToDartType(invocation, element);

    String? displayTypeOverride;
    var collectionElementDisplayTypeOverride =
        mappedType.listElementDisplayTypeOverride;

    if (schemaMethod == 'enumValues') {
      displayTypeOverride = _extractEnumTypeNameFromInvocation(baseInvocation);
    } else if (schemaMethod == 'list') {
      collectionElementDisplayTypeOverride =
          _extractListEnumElementTypeName(baseInvocation) ??
          collectionElementDisplayTypeOverride;
    }

    return FieldInfo(
      name: fieldName,
      jsonKey: fieldName,
      type: mappedType.dartType,
      isRequired: !chain.isOptional,
      isNullable: chain.isNullable,
      constraints: [],
      listElementSchemaRef: mappedType.listElementSchemaRef,
      displayTypeOverride:
          displayTypeOverride ??
          (transformOutputTypeString != null &&
                  !mappedType.dartType.isDartCoreString &&
                  !mappedType.dartType.isDartCoreInt &&
                  !mappedType.dartType.isDartCoreDouble &&
                  !mappedType.dartType.isDartCoreBool &&
                  !mappedType.dartType.isDartCoreNum &&
                  !mappedType.dartType.isDartCoreList &&
                  !mappedType.dartType.isDartCoreMap &&
                  !mappedType.dartType.isDartCoreSet
              ? transformOutputTypeString
              : null),
      collectionElementDisplayTypeOverride:
          collectionElementDisplayTypeOverride,
      collectionElementCastTypeOverride: mappedType.listElementCastTypeOverride,
      collectionElementIsCustomType: mappedType.listElementIsCustomType,
    );
  }

  /// Maps a schema method invocation to a Dart type and optional schema reference
  ///
  /// Returns a record containing the field [DartType] plus list metadata used
  /// by the type builder for typed list getters.
  _SchemaTypeMapping _mapSchemaTypeToDartType(
    MethodInvocation invocation,
    Element element,
  ) {
    final chain = _analyzeSchemaChain(invocation);
    final schemaReference = chain.schemaReference;
    final baseInvocation = chain.ackBase;

    // We need to get the type provider from the element's library
    final library = element.library!;
    final typeProvider = library.typeProvider;
    final transformOutputTypeString = _requireTransformOutputType(
      chain,
      element,
      contextLabel: 'Schema expression',
    );

    if (schemaReference != null) {
      return _resolveSchemaVariableType(
        schemaReference,
        element,
        typeProvider,
        transformedOutputType: chain.transformOutputType,
        transformedRepresentationType: transformOutputTypeString,
      );
    }

    if (baseInvocation == null) {
      throw InvalidGenerationSource(
        'Could not determine schema type for "${invocation.toSource()}".',
        element: element,
      );
    }

    final schemaMethod = baseInvocation.methodName.name;
    _throwIfUnsupportedTransformedBaseSchema(
      schemaMethod: schemaMethod,
      transformOutputTypeString: transformOutputTypeString,
      element: element,
      contextLabel: 'Schema expression',
    );

    if (transformOutputTypeString != null) {
      return (
        dartType: chain.transformOutputType ?? typeProvider.dynamicType,
        listElementSchemaRef: null,
        listElementDisplayTypeOverride: null,
        listElementCastTypeOverride: null,
        listElementIsCustomType: false,
      );
    }

    switch (schemaMethod) {
      case 'string':
        return (
          dartType: typeProvider.stringType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'integer':
        return (
          dartType: typeProvider.intType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'double':
        return (
          dartType: typeProvider.doubleType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'boolean':
        return (
          dartType: typeProvider.boolType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'list':
        // Extract element type from Ack.list(elementSchema) argument
        // This may return a schema variable reference for nested schemas
        return _analyzeListElement(
          baseInvocation,
          element,
          typeProvider,
        ).mapping;
      case 'object':
        // Nested objects represented as Map<String, Object?>
        // Note: Using dynamicType for analyzer; generated code uses Object?
        return (
          dartType: typeProvider.mapType(
            typeProvider.stringType,
            typeProvider.dynamicType,
          ),
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'enumString':
      case 'literal':
        return (
          dartType: typeProvider.stringType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'enumValues':
        final resolvedType = _resolveEnumValuesType(
          baseInvocation,
          library: library,
        );
        if (resolvedType != null) {
          return (
            dartType: resolvedType,
            listElementSchemaRef: null,
            listElementDisplayTypeOverride: null,
            listElementCastTypeOverride: null,
            listElementIsCustomType: false,
          );
        }
        // Fallback to `dynamic` if the enum type can't be resolved.
        // This avoids incorrectly assuming `String` when EnumSchema<T>.parse()
        // returns the enum value type T.
        _log.warning(
          'Could not resolve enum type for Ack.enumValues(); falling back to dynamic.',
        );
        return (
          dartType: typeProvider.dynamicType,
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'uri':
        return (
          dartType: _dartCoreType(typeProvider, 'Uri'),
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'date':
      case 'datetime':
        return (
          dartType: _dartCoreType(typeProvider, 'DateTime'),
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      case 'duration':
        return (
          dartType: _dartCoreType(typeProvider, 'Duration'),
          listElementSchemaRef: null,
          listElementDisplayTypeOverride: null,
          listElementCastTypeOverride: null,
          listElementIsCustomType: false,
        );
      default:
        throw InvalidGenerationSource(
          'Unsupported schema method: Ack.$schemaMethod()',
          element: element,
        );
    }
  }

  /// Extracts the enum type name from an `Ack.enumValues<T>(...)` invocation.
  ///
  /// Prefers source text only when it contains a qualifier
  /// (e.g., `alias.UserRole`) so import prefixes are preserved in generated
  /// part files.
  ///
  /// For non-qualified names, prefers resolved static types to avoid
  /// incorrectly treating arbitrary `.values` receivers as enum type names
  /// (for example, `holder.values` should resolve to the list element type).
  String? _extractEnumTypeNameFromInvocation(MethodInvocation invocation) {
    final sourceTypeName = _extractEnumTypeNameFromSource(invocation);
    if (sourceTypeName != null && sourceTypeName.contains('.')) {
      return sourceTypeName;
    }

    final resolvedType = _resolveEnumValuesType(invocation);
    if (resolvedType != null) {
      return resolvedType.getDisplayString();
    }

    return sourceTypeName;
  }

  String? _extractEnumTypeNameFromSource(MethodInvocation invocation) {
    // From type argument: Ack.enumValues<UserRole>(...) or Ack.enumValues<foo.UserRole>(...)
    final typeArgs = invocation.typeArguments?.arguments;
    if (typeArgs != null && typeArgs.isNotEmpty) {
      return typeArgs.first.toSource();
    }

    // From argument pattern: Ack.enumValues(UserRole.values) / Ack.enumValues(alias.UserRole.values)
    final args = invocation.argumentList.arguments;
    if (args.isNotEmpty) {
      final firstArg = args.first;
      if (firstArg is PrefixedIdentifier &&
          firstArg.identifier.name == 'values') {
        final targetSource = firstArg.prefix.toSource();
        if (_looksLikeTypeReference(targetSource)) {
          return targetSource;
        }
      }
      if (firstArg is PropertyAccess &&
          firstArg.propertyName.name == 'values') {
        final targetSource = firstArg.target?.toSource();
        if (targetSource != null && _looksLikeTypeReference(targetSource)) {
          return targetSource;
        }
      }
    }

    return null;
  }

  bool _looksLikeTypeReference(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return false;

    final identifier = trimmed.split('.').last;
    if (identifier.isEmpty) return false;

    final firstCodeUnit = identifier.codeUnitAt(0);
    const uppercaseA = 65;
    const uppercaseZ = 90;
    const underscore = 95;
    return (firstCodeUnit >= uppercaseA && firstCodeUnit <= uppercaseZ) ||
        firstCodeUnit == underscore;
  }

  String? _extractListEnumElementTypeName(MethodInvocation listInvocation) {
    final args = listInvocation.argumentList.arguments;
    if (args.isEmpty) return null;

    final ref = _resolveListElementRef(args.first.argumentExpression);
    final elementSchema = ref.invocation == null
        ? null
        : _analyzeSchemaChain(ref.invocation!).ackBase;
    if (elementSchema == null ||
        elementSchema.methodName.name != 'enumValues') {
      return null;
    }

    return _extractEnumTypeNameFromInvocation(elementSchema);
  }

  /// Resolves enum type `T` from an `Ack.enumValues<T>(...)` invocation.
  ///
  /// Resolution strategy (in order):
  /// 1. Explicit type argument's resolved type (`Ack.enumValues<T>(...)`)
  /// 2. Invocation static type argument (`EnumSchema<T>`)
  /// 3. First argument static type (`List<T>` from `T.values`)
  /// 4. Source name lookup in the library/import scope
  DartType? _resolveEnumValuesType(
    MethodInvocation invocation, {
    LibraryElement? library,
  }) {
    final typeArgs = invocation.typeArguments?.arguments;
    if (typeArgs != null && typeArgs.isNotEmpty) {
      final explicitType = typeArgs.first.type;
      if (explicitType is InterfaceType) {
        return explicitType;
      }
    }

    final invocationType = invocation.staticType;
    if (invocationType is InterfaceType &&
        invocationType.typeArguments.isNotEmpty) {
      final schemaTypeArg = invocationType.typeArguments.first;
      if (schemaTypeArg is InterfaceType) {
        return schemaTypeArg;
      }
    }

    final args = invocation.argumentList.arguments;
    if (args.isNotEmpty) {
      final resolvedFromArgument = _resolveEnumValuesTypeFromArgument(
        args.first.argumentExpression,
        library: library,
      );
      if (resolvedFromArgument != null) {
        return resolvedFromArgument;
      }
    }

    if (library != null) {
      final enumTypeName = _extractEnumTypeNameFromSource(invocation);
      if (enumTypeName != null) {
        final resolvedByName = _resolveTypeByName(enumTypeName, library);
        if (resolvedByName != null) {
          return resolvedByName;
        }
      }
    }

    return null;
  }

  DartType? _resolveEnumValuesTypeFromArgument(
    Expression argument, {
    LibraryElement? library,
  }) {
    final enumFromStaticType = _extractEnumTypeFromCandidate(
      argument.staticType,
    );
    if (enumFromStaticType != null) {
      return enumFromStaticType;
    }

    if (library == null) {
      return null;
    }

    final resolvedExpressionType = _resolveExpressionType(argument, library);
    return _extractEnumTypeFromCandidate(resolvedExpressionType);
  }

  DartType? _extractEnumTypeFromCandidate(DartType? candidate) {
    if (candidate is! InterfaceType) {
      return null;
    }

    if (candidate.element is EnumElement) {
      return candidate;
    }

    if (candidate.isDartCoreList && candidate.typeArguments.isNotEmpty) {
      final elementType = candidate.typeArguments.first;
      if (elementType is InterfaceType && elementType.element is EnumElement) {
        return elementType;
      }
    }

    return null;
  }

  DartType? _resolveExpressionType(
    Expression expression,
    LibraryElement library,
  ) {
    final staticType = expression.staticType;
    if (staticType != null && staticType is! DynamicType) {
      return staticType;
    }

    if (expression is SimpleIdentifier) {
      final variableType = _schemaVarsByName(library)[expression.name]?.type;
      if (variableType != null) {
        return variableType;
      }

      final getterType = _schemaGettersByName(
        library,
      )[expression.name]?.returnType;
      if (getterType != null) {
        return getterType;
      }

      return _resolveTypeByName(expression.name, library);
    }

    if (expression is PrefixedIdentifier) {
      final targetType = _resolveExpressionType(expression.prefix, library);
      if (targetType is InterfaceType) {
        final memberType = _resolveClassMemberType(
          targetType: targetType,
          memberName: expression.identifier.name,
          library: library,
        );
        if (memberType != null) {
          return memberType;
        }
      }

      return _resolveTypeByName(expression.toSource(), library);
    }

    if (expression is PropertyAccess) {
      final target = expression.target;
      if (target != null) {
        final targetType = _resolveExpressionType(target, library);
        if (targetType is InterfaceType) {
          final memberType = _resolveClassMemberType(
            targetType: targetType,
            memberName: expression.propertyName.name,
            library: library,
          );
          if (memberType != null) {
            return memberType;
          }
        }
      }
    }

    return null;
  }

  DartType? _resolveClassMemberType({
    required InterfaceType targetType,
    required String memberName,
    required LibraryElement library,
  }) {
    final className = targetType.element.name;
    if (className == null) return null;

    final classElement = _classesByName(library)[className];
    if (classElement == null) return null;

    final allFields = [
      ...classElement.fields,
      ...classElement.allSupertypes.expand((type) => type.element.fields),
    ];

    final field = allFields.firstWhereOrNull(
      (current) => current.name == memberName,
    );
    if (field != null) {
      return field.type;
    }

    final allGetters = [
      ...classElement.getters,
      ...classElement.allSupertypes.expand((type) => type.element.getters),
    ];

    final getter = allGetters.firstWhereOrNull(
      (current) => current.name == memberName,
    );
    return getter?.returnType;
  }

  DartType? _resolveTypeByName(String typeName, LibraryElement library) {
    final normalizedTypeName = typeName.trim();
    if (normalizedTypeName.isEmpty) return null;

    final scopeResult = library.firstFragment.scope.lookup(normalizedTypeName);
    final scopeType = _resolveTypeFromElement(scopeResult.getter);
    if (scopeType != null) {
      return scopeType;
    }

    // Try import namespaces directly as a fallback for simple imported names.
    for (final import in library.firstFragment.libraryImports) {
      final importedElement = import.namespace.get2(normalizedTypeName);
      final importedType = _resolveTypeFromElement(importedElement);
      if (importedType != null) {
        return importedType;
      }
    }

    // Last-resort local lookup.
    for (final enumElement in library.enums) {
      if (enumElement.name == normalizedTypeName) {
        return enumElement.thisType;
      }
    }
    for (final classElement in library.classes) {
      if (classElement.name == normalizedTypeName) {
        return classElement.thisType;
      }
    }

    return null;
  }

  DartType? _resolveTypeFromElement(Element? element) {
    if (element is EnumElement) {
      return element.thisType;
    }

    if (element is ClassElement) {
      return element.thisType;
    }

    if (element is TypeAliasElement) {
      final aliasedType = element.aliasedType;
      if (aliasedType is InterfaceType) {
        return aliasedType;
      }
    }

    return null;
  }

  _ListElementRef _resolveListElementRef(Expression firstArg) {
    if (firstArg is MethodInvocation) {
      final schemaRef = _findSchemaVariableBase(firstArg);
      if (schemaRef != null) {
        return (invocation: firstArg, schemaRef: schemaRef);
      }

      return (invocation: firstArg, schemaRef: null);
    }

    final schemaRef = _extractSchemaReference(firstArg);
    if (schemaRef != null) {
      return (invocation: null, schemaRef: schemaRef);
    }

    return (invocation: null, schemaRef: null);
  }

  /// Analyzes the element schema used by Ack.list(...).
  ///
  /// Returns the generated list mapping and the list element representation
  /// type string.
  _ListElementAnalysis _analyzeListElement(
    MethodInvocation listInvocation,
    Element element,
    TypeProvider typeProvider, {
    String? diagnosticPath,
  }) {
    final args = listInvocation.argumentList.arguments;

    if (args.isEmpty) {
      throw InvalidGenerationSource(
        'Ack.list(...) requires an element schema argument for strict typed generation.',
        element: element,
        todo: 'Provide a concrete element schema, e.g. Ack.list(Ack.string()) or Ack.list(namedSchema).',
      );
    }

    final firstArg = args.first;
    _rejectAckModelFacadeExpression(
      firstArg.argumentExpression,
      element,
      diagnosticPath: diagnosticPath,
    );

    final ref = _resolveListElementRef(firstArg.argumentExpression);
    if (ref.invocation != null) {
      final chain = _analyzeSchemaChain(ref.invocation!);
      _rejectNullableListElement(chain.isNullable, element);
      final baseInvocation = chain.ackBase;
      final transformOutputTypeString = _requireTransformOutputType(
        chain,
        element,
        contextLabel: 'Ack.list(...) element schema',
      );

      if (baseInvocation != null &&
          baseInvocation.methodName.name == 'object') {
        throw InvalidGenerationSource(
          'Ack.list(Ack.object(...)) uses an anonymous inline object schema. '
          'Strict typed generation requires a named schema reference.',
          element: element,
          todo: 'Extract the inline object to a top-level @AckType() variable and use Ack.list(namedSchema).',
        );
      }

      if (chain.schemaReference != null) {
        _rejectIfReferencesNullableSchema(chain.schemaReference!, element);
        final mapping = _resolveSchemaVariableType(
          chain.schemaReference!,
          element,
          typeProvider,
          transformedOutputType: chain.transformOutputType,
          transformedRepresentationType: transformOutputTypeString,
        );
        return (
          mapping: mapping,
          elementRepresentationType: _resolveSchemaVariableElementTypeString(
            chain.schemaReference!,
            element,
            transformedRepresentationType: transformOutputTypeString,
          ),
        );
      }

      if (baseInvocation == null) {
        final rawExpression = firstArg.toSource();
        throw InvalidGenerationSource(
          'Could not statically resolve Ack.list($rawExpression) element type.',
          element: element,
          todo: 'Use Ack.list(Ack.<primitive>()), Ack.list(enumSchema), or Ack.list(namedSchema) so the generator can infer a concrete element type.',
        );
      }

      final methodName = baseInvocation.methodName.name;
      _throwIfUnsupportedTransformedBaseSchema(
        schemaMethod: methodName,
        transformOutputTypeString: transformOutputTypeString,
        element: element,
        contextLabel: 'Ack.list(...) element schema',
      );

      if (methodName == 'list') {
        final nested = _analyzeListElement(
          baseInvocation,
          element,
          typeProvider,
          diagnosticPath: diagnosticPath,
        );
        return (
          mapping: _wrapListElementMapping(nested.mapping, typeProvider),
          elementRepresentationType:
              transformOutputTypeString ??
              'List<${nested.elementRepresentationType}>',
        );
      }

      final elementMapping = _mapSchemaTypeToDartType(ref.invocation!, element);
      final elementRepresentationType =
          transformOutputTypeString ??
          (methodName == 'enumValues'
              ? _extractEnumTypeNameFromInvocation(baseInvocation) ?? 'dynamic'
              : _mapSchemaMethodToType(methodName));
      return (
        mapping: _wrapListElementMapping(elementMapping, typeProvider),
        elementRepresentationType: elementRepresentationType,
      );
    }

    if (ref.schemaRef != null) {
      _rejectIfReferencesNullableSchema(ref.schemaRef!, element);
      final mapping = _resolveSchemaVariableType(
        ref.schemaRef!,
        element,
        typeProvider,
      );
      return (
        mapping: mapping,
        elementRepresentationType: _resolveSchemaVariableElementTypeString(
          ref.schemaRef!,
          element,
        ),
      );
    }

    final rawExpression = firstArg.toSource();
    throw InvalidGenerationSource(
      'Could not statically resolve Ack.list($rawExpression) element type.',
      element: element,
      todo: 'Use Ack.list(Ack.<primitive>()), Ack.list(enumSchema), or Ack.list(namedSchema) so the generator can infer a concrete element type.',
    );
  }

  void _rejectNullableListElement(bool isNullable, Element element) {
    if (!isNullable) return;

    throw InvalidGenerationSource(
      'Ack.list(...) does not support nullable element schemas.',
      element: element,
      todo: 'Remove `.nullable()` from the element schema. Make the list itself nullable with `Ack.list(item).nullable()` when needed.',
    );
  }

  void _rejectIfReferencesNullableSchema(
    _SchemaReference reference,
    Element element,
  ) {
    final resolved = _resolveSchemaReference(reference, element);
    _rejectNullableListElement(
      resolved?.modelInfo.isNullableSchema ?? false,
      element,
    );
  }

  _SchemaTypeMapping _wrapListElementMapping(
    _SchemaTypeMapping elementMapping,
    TypeProvider typeProvider,
  ) {
    return (
      dartType: typeProvider.listType(elementMapping.dartType),
      listElementSchemaRef: elementMapping.listElementSchemaRef,
      listElementDisplayTypeOverride:
          elementMapping.listElementDisplayTypeOverride,
      listElementCastTypeOverride: elementMapping.listElementCastTypeOverride,
      listElementIsCustomType: elementMapping.listElementIsCustomType,
    );
  }

  /// Resolves a schema reference to its list element type.
  ///
  /// Looks up the schema in local/imported namespaces and returns the
  /// appropriate list type plus metadata needed by the type builder.
  _SchemaTypeMapping _resolveSchemaVariableType(
    _SchemaReference schemaReference,
    Element element,
    TypeProvider typeProvider, {
    DartType? transformedOutputType,
    String? transformedRepresentationType,
  }) {
    final resolved = _resolveSchemaReference(schemaReference, element);
    if (resolved == null) {
      throw InvalidGenerationSource(
        'Could not resolve schema reference "${schemaReference.name}" '
        'used in Ack.list(...)',
        element: element,
        todo:
            'Ensure "${schemaReference.name}" exists, is imported, and is declared as an Ack schema.',
      );
    }

    final modelInfo = resolved.modelInfo;
    final hasTransformOverride = transformedRepresentationType != null;
    if (hasTransformOverride) {
      _throwIfUnsupportedTransformedReferencedSchema(
        resolved: resolved,
        element: element,
        contextLabel: 'Ack.list(${schemaReference.name}) element schema',
      );
    }

    final representationType =
        transformedRepresentationType ?? modelInfo.representationType;
    final visibleRepresentationType = _resolveVisibleRepresentationType(
      representationType: representationType,
      resolved: resolved,
      contextElement: element,
    );
    final hasTypedReference =
        resolved.hasAckTypeAnnotation && !hasTransformOverride;
    final isObjectRepresentation = representationType == kMapType;
    if (isObjectRepresentation && !hasTypedReference) {
      throw InvalidGenerationSource(
        'Ack.list(${schemaReference.name}) references object schema '
        '"${schemaReference.name}" without @AckType. This would fall back to '
        'Map<String, Object?>.',
        element: element,
        todo:
            'Annotate "${schemaReference.name}" with @AckType() so list getters can emit typed wrappers.',
      );
    }

    final elementDartType =
        transformedOutputType ??
        _representationTypeToDartType(representationType, typeProvider);

    final typeBaseName = hasTypedReference
        ? _qualifyTypeBaseName(modelInfo.className, resolved.importPrefix)
        : null;
    final listElementDisplayTypeOverride = hasTypedReference
        ? typeBaseName
        : (!elementDartType.isDartCoreString &&
                  !elementDartType.isDartCoreInt &&
                  !elementDartType.isDartCoreDouble &&
                  !elementDartType.isDartCoreBool &&
                  !elementDartType.isDartCoreNum &&
                  !elementDartType.isDartCoreList &&
                  !elementDartType.isDartCoreMap &&
                  !elementDartType.isDartCoreSet
              ? visibleRepresentationType
              : null);

    return (
      dartType: typeProvider.listType(elementDartType),
      listElementSchemaRef: hasTypedReference ? resolved.schemaName : null,
      listElementDisplayTypeOverride: listElementDisplayTypeOverride,
      listElementCastTypeOverride: hasTypedReference
          ? visibleRepresentationType
          : null,
      listElementIsCustomType: hasTypedReference,
    );
  }

  /// Resolves a schema reference to its representation type string.
  ///
  /// This is used for top-level list schemas so we can cast to the correct
  /// element type (e.g., `String` for `Ack.string()` schema variables).
  ///
  /// Throws when the schema variable cannot be resolved or if a circular
  /// reference is detected.
  String _resolveSchemaVariableElementTypeString(
    _SchemaReference schemaReference,
    Element element, {
    String? transformedRepresentationType,
  }) {
    final library = element.library;
    // Use library-scoped cache key to prevent collisions across libraries
    final prefix = schemaReference.prefix ?? '';
    final transformKey = transformedRepresentationType ?? '';
    final cacheKey =
        '${library?.uri ?? 'unknown'}::$prefix::${schemaReference.name}::$transformKey';

    final cached = _schemaVariableTypeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (_schemaVariableTypeStack.contains(cacheKey)) {
      throw InvalidGenerationSource(
        'Circular schema variable reference detected for '
        '"${schemaReference.name}" in Ack.list(...).',
        element: element,
        todo:
            'Break the circular Ack.list(...) schema references so element types '
            'can be resolved statically.',
      );
    }

    _schemaVariableTypeStack.add(cacheKey);

    String? resolvedType;
    try {
      if (library == null) {
        throw InvalidGenerationSource(
          'Could not resolve library while analyzing schema reference '
          '"${schemaReference.name}"',
          element: element,
        );
      }

      final resolved = _resolveSchemaReference(schemaReference, element);
      if (resolved == null) {
        throw InvalidGenerationSource(
          'Could not resolve schema reference "${schemaReference.name}" '
          'used in Ack.list(...)',
          element: element,
          todo:
              'Ensure "${schemaReference.name}" exists, is imported, and is declared as an Ack schema.',
        );
      }

      final representationType =
          transformedRepresentationType ??
          resolved.modelInfo.representationType;
      final hasTypedReference =
          resolved.hasAckTypeAnnotation &&
          transformedRepresentationType == null;

      if (representationType == kMapType && !hasTypedReference) {
        throw InvalidGenerationSource(
          'Ack.list(${schemaReference.name}) references object schema '
          '"${schemaReference.name}" without @AckType. This would fall back to '
          'Map<String, Object?>.',
          element: element,
          todo:
              'Annotate "${schemaReference.name}" with @AckType() so list getters can emit typed wrappers.',
        );
      }

      resolvedType = _resolveVisibleRepresentationType(
        representationType: representationType,
        resolved: resolved,
        contextElement: element,
      );
      return resolvedType;
    } finally {
      _schemaVariableTypeStack.remove(cacheKey);
      if (resolvedType != null) {
        _schemaVariableTypeCache[cacheKey] = resolvedType;
      }
    }
  }

  _ResolvedSchemaReference? _resolveSchemaReference(
    _SchemaReference reference,
    Element contextElement, {
    String? diagnosticPath,
  }) {
    final library = contextElement.library;
    if (library == null) {
      return null;
    }

    final cacheKey = _schemaReferenceCacheKey(reference, library);
    final cached = _schemaReferenceCache[cacheKey];
    if (cached != null || _schemaReferenceCache.containsKey(cacheKey)) {
      return cached;
    }

    if (_schemaReferenceResolutionStack.contains(cacheKey)) {
      final referenceLabel = _formatSchemaReference(reference);
      throw InvalidGenerationSource(
        'Circular schema reference detected for "$referenceLabel".',
        element: contextElement,
        todo: 'Break the circular alias/reference chain between @AckType schemas.',
      );
    }

    _schemaReferenceResolutionStack.add(cacheKey);

    _ResolvedSchemaReference? resolvedReference;
    var shouldCacheResult = false;

    try {
      final resolvedElementMatch = _resolveSchemaElement(reference, library);
      if (resolvedElementMatch == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }
      final resolvedElement = resolvedElementMatch.element;

      TopLevelVariableElement? schemaVariable;
      GetterElement? schemaGetter;
      Element? sourceDeclaration;

      if (resolvedElement is TopLevelVariableElement) {
        schemaVariable = resolvedElement;
        sourceDeclaration = resolvedElement;
      } else if (resolvedElement is GetterElement) {
        if (resolvedElement.isOriginVariable) {
          final variable = resolvedElement.variable;
          if (variable is TopLevelVariableElement) {
            schemaVariable = variable;
            sourceDeclaration = variable;
          }
        } else {
          schemaGetter = resolvedElement;
          sourceDeclaration = resolvedElement;
        }
      }

      if (schemaVariable == null && schemaGetter != null) {
        // Ensure this is top-level only.
        if (schemaGetter.enclosingElement is! LibraryElement) {
          shouldCacheResult = true;
          resolvedReference = null;
          return null;
        }
      }

      if (schemaVariable == null && schemaGetter == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }

      final schemaName = schemaVariable?.name ?? schemaGetter?.name;
      if (schemaName == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }

      final declarationForMetadata =
          sourceDeclaration ?? schemaVariable ?? schemaGetter;
      if (declarationForMetadata == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }

      if (_hasAckInferAnnotation(declarationForMetadata)) {
        final path = diagnosticPath ?? contextElement.name ?? 'legacy schema';
        throw InvalidGenerationSource(
          '$path crosses from legacy @AckType into modern @AckInfer schema '
          '"$schemaName". '
          'AckType and modern models intentionally use isolated generators; '
          'migrate this connected graph together.',
          element: contextElement,
        );
      }

      final hasAckTypeAnnotation = _hasAckTypeAnnotation(
        declarationForMetadata,
      );

      final customTypeName = _extractAckTypeName(declarationForMetadata);

      ModelInfo? modelInfo;
      if (schemaVariable != null) {
        modelInfo = analyzeSchemaVariable(
          schemaVariable,
          customTypeName: customTypeName,
        );
      } else if (schemaGetter != null) {
        modelInfo = analyzeSchemaGetter(
          schemaGetter,
          customTypeName: customTypeName,
        );
      }

      if (modelInfo == null) {
        shouldCacheResult = true;
        resolvedReference = null;
        return null;
      }

      resolvedReference = _ResolvedSchemaReference(
        schemaName: schemaName,
        modelInfo: modelInfo,
        importPrefix: reference.prefix,
        importDirective: resolvedElementMatch.importDirective,
        hasAckTypeAnnotation: hasAckTypeAnnotation,
        sourceDeclaration: declarationForMetadata,
        sourceLibraryUri: declarationForMetadata.library?.uri,
      );
      shouldCacheResult = true;
      return resolvedReference;
    } on InvalidGenerationSource {
      rethrow;
    } catch (e, st) {
      _log.warning(
        'Unexpected error resolving schema reference '
        '"${_formatSchemaReference(reference)}": $e\n$st',
      );
      shouldCacheResult = true;
      resolvedReference = null;
      return null;
    } finally {
      _schemaReferenceResolutionStack.remove(cacheKey);
      if (shouldCacheResult) {
        _schemaReferenceCache[cacheKey] = resolvedReference;
      }
    }
  }

  _ResolvedSchemaElement? _resolveSchemaElement(
    _SchemaReference reference,
    LibraryElement library,
  ) {
    if (reference.prefix != null) {
      // Prefer an exact prefix match when the source used `prefix.symbol`.
      for (final import in library.firstFragment.libraryImports) {
        final prefixName = _elementName(import.prefix?.element);
        if (prefixName != reference.prefix) continue;

        final importedElement = import.namespace.getPrefixed2(
          reference.prefix!,
          reference.name,
        );
        if (importedElement != null) {
          return (element: importedElement, importDirective: import);
        }
      }

      // Strict behavior: when a prefix is specified, never resolve from a
      // different namespace.
      return null;
    }

    final scopeResult = library.firstFragment.scope.lookup(reference.name);
    final scopedElement = scopeResult.getter;
    if (scopedElement != null) {
      return (
        element: scopedElement,
        importDirective: _findImportDirectiveForElement(
          reference.name,
          scopedElement,
          library,
        ),
      );
    }

    for (final import in library.firstFragment.libraryImports) {
      final importedElement = import.namespace.get2(reference.name);
      if (importedElement != null) {
        return (element: importedElement, importDirective: import);
      }
    }

    return null;
  }

  void _rejectAckModelFacadeExpression(
    Expression expression,
    Element contextElement, {
    String? diagnosticPath,
  }) {
    final reference = _ackModelFacadeReference(expression);
    if (reference == null) return;

    final (:prefix, :facadeName) = reference;
    final library = contextElement.library;
    if (library == null) return;
    final matches = <ClassElement>{};

    void consider(ClassElement element, LibraryImport? import) {
      if (_classFirstFacadeName(element) != facadeName) return;
      if (import != null &&
          (!_importAllowsName(import, element.name!) ||
              !_importAllowsName(import, facadeName))) {
        return;
      }
      matches.add(element);
    }

    if (prefix == null) {
      for (final element in library.classes) {
        consider(element, null);
      }
    }
    for (final import in library.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      if (_elementName(import.prefix?.element) != prefix) continue;
      final elements = <Element>{
        ...import.namespace.definedNames2.values,
        ...?import.importedLibrary?.classes,
      };
      for (final element in elements.whereType<ClassElement>()) {
        consider(element, import);
      }
    }
    if (matches.isEmpty) return;
    if (matches.length > 1) {
      throw InvalidGenerationSource(
        'Modern @AckModel facade reference ${expression.toSource()} is '
        'ambiguous.',
        element: contextElement,
      );
    }

    final path = diagnosticPath ?? contextElement.name ?? 'legacy schema';
    throw InvalidGenerationSource(
      '$path crosses from legacy @AckType into modern @AckModel facade '
      '"$facadeName.schema". AckType and modern models intentionally use '
      'isolated generators; migrate this connected graph together.',
      element: contextElement,
    );
  }

  ({String? prefix, String facadeName})? _ackModelFacadeReference(
    Expression expression,
  ) {
    final path = _schemaAccessPath(expression);
    if (path == null ||
        path.last != 'schema' ||
        (path.length != 2 && path.length != 3)) {
      return null;
    }

    return (
      prefix: path.length == 3 ? path.first : null,
      facadeName: path[path.length - 2],
    );
  }

  List<String>? _schemaAccessPath(Expression expression) {
    if (expression is ParenthesizedExpression) {
      return _schemaAccessPath(expression.expression);
    }
    if (expression is PostfixExpression && expression.operator.lexeme == '!') {
      return _schemaAccessPath(expression.operand);
    }
    if (expression is MethodInvocation) {
      final target = expression.target;
      return target == null ? null : _schemaAccessPath(target);
    }
    if (expression is PropertyAccess) {
      final target = expression.target;
      final targetPath = target == null ? null : _schemaAccessPath(target);
      if (targetPath == null) return null;
      return [...targetPath, expression.propertyName.name];
    }
    if (expression is PrefixedIdentifier) {
      return [expression.prefix.name, expression.identifier.name];
    }
    if (expression is SimpleIdentifier) {
      return [expression.name];
    }
    return null;
  }

  String? _classFirstFacadeName(ClassElement element) {
    final annotation = _ackModelChecker.firstAnnotationOfExact(element);
    if (annotation != null) {
      final configuredName = ConstantReader(annotation).read('schemaName');
      return ackClassSchemaFacadeName(
        element.name!,
        override: configuredName.isNull ? null : configuredName.stringValue,
      );
    }
    final isImplicitUnionBranch = element.allSupertypes.any((supertype) {
      final base = supertype.element;
      return base is ClassElement &&
          base.library == element.library &&
          base.isSealed &&
          _ackModelChecker.hasAnnotationOfExact(base);
    });
    return isImplicitUnionBranch
        ? ackClassSchemaFacadeName(element.name!)
        : null;
  }

  bool _importAllowsName(LibraryImport import, String name) {
    for (final combinator in import.combinators) {
      if (combinator is ShowElementCombinator &&
          !combinator.shownNames.contains(name)) {
        return false;
      }
      if (combinator is HideElementCombinator &&
          combinator.hiddenNames.contains(name)) {
        return false;
      }
    }
    return true;
  }

  LibraryImport? _findImportDirectiveForElement(
    String name,
    Element element,
    LibraryElement library,
  ) {
    for (final import in library.firstFragment.libraryImports) {
      final importedElement = import.namespace.get2(name);
      if (_elementsMatch(importedElement, element)) {
        return import;
      }
    }
    return null;
  }

  bool _elementsMatch(Element? first, Element? second) {
    if (identical(first, second)) {
      return true;
    }
    if (first == null || second == null) {
      return false;
    }
    return first.library?.uri == second.library?.uri &&
        first.name == second.name;
  }

  String? _elementName(Element? element) {
    final modernName = element?.name;
    if (modernName != null && modernName.isNotEmpty) {
      return modernName;
    }
    return null;
  }

  bool _hasAckTypeAnnotation(Element element) {
    return _ackTypeChecker.hasAnnotationOfExact(element);
  }

  bool _hasAckInferAnnotation(Element element) {
    return TypeChecker.typeNamed(
      AckInfer,
      inPackage: 'ack',
    ).hasAnnotationOfExact(element);
  }

  String? _extractAckTypeName(Element element) {
    final annotation = _ackTypeChecker.firstAnnotationOfExact(element);
    if (annotation == null) return null;

    final nameField = ConstantReader(annotation).peek('name');
    return (nameField != null && !nameField.isNull)
        ? nameField.stringValue
        : null;
  }

  String _qualifyTypeBaseName(String baseTypeName, String? prefix) {
    if (prefix == null || prefix.isEmpty) {
      return baseTypeName;
    }
    return '$prefix.$baseTypeName';
  }

  String _resolveVisibleRepresentationType({
    required String representationType,
    required _ResolvedSchemaReference resolved,
    required Element contextElement,
  }) {
    final contextLibrary = contextElement.library;
    if (contextLibrary == null) {
      throw InvalidGenerationSource(
        'Could not resolve libraries while qualifying transformed representation '
        'type "$representationType".',
        element: contextElement,
      );
    }

    if (resolved.sourceLibraryUri == contextLibrary.uri) {
      return representationType;
    }

    if (_containsUnsupportedRepresentationSyntax(representationType)) {
      throw InvalidGenerationSource(
        'Transformed representation type "$representationType" for '
        '"${resolved.schemaName}" uses unsupported syntax for cross-file '
        'generation.',
        element: contextElement,
        todo: 'Use a nominal type with optional nested generics/nullability, or keep the schema in the same library.',
      );
    }

    final tokenPattern = RegExp(r'[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*');
    final buffer = StringBuffer();
    var lastIndex = 0;

    for (final match in tokenPattern.allMatches(representationType)) {
      buffer.write(representationType.substring(lastIndex, match.start));
      final token = match.group(0)!;
      buffer.write(
        _resolveVisibleRepresentationToken(
          token: token,
          resolved: resolved,
          contextLibrary: contextLibrary,
          fullRepresentationType: representationType,
          contextElement: contextElement,
        ),
      );
      lastIndex = match.end;
    }

    buffer.write(representationType.substring(lastIndex));
    return buffer.toString();
  }

  String _resolveVisibleRepresentationToken({
    required String token,
    required _ResolvedSchemaReference resolved,
    required LibraryElement contextLibrary,
    required String fullRepresentationType,
    required Element contextElement,
  }) {
    if (_isBuiltInRepresentationIdentifier(token)) {
      return token;
    }

    if (token.contains('.')) {
      throw InvalidGenerationSource(
        'Transformed representation type "$fullRepresentationType" for '
        '"${resolved.schemaName}" uses a qualified type that cannot be '
        'referenced across library boundaries.',
        element: contextElement,
        todo: 'Use an unqualified exported representation type, import that type directly into the consuming library, or keep the schema in the same library.',
      );
    }

    final importNamespaceType = _resolveImportedType(token, resolved);
    final scopedElement = contextLibrary.firstFragment.scope
        .lookup(token)
        .getter;
    final scopedType = _resolveTypeFromElement(scopedElement);
    final localContextType =
        scopedElement != null &&
            _findImportDirectiveForElement(
                  token,
                  scopedElement,
                  contextLibrary,
                ) ==
                null
        ? scopedType
        : null;
    final importedContextTypes = _resolveImportedTypesByName(
      token,
      contextLibrary,
    );
    final unqualifiedContextType =
        localContextType ??
        (importedContextTypes.length == 1 ? importedContextTypes.single : null);
    final hasAmbiguousImportedTypes =
        localContextType == null && importedContextTypes.length > 1;
    final prefix = resolved.importPrefix;

    if (importNamespaceType != null && prefix != null && prefix.isNotEmpty) {
      return '$prefix.$token';
    }

    if (importNamespaceType != null) {
      if (unqualifiedContextType != null &&
          _sameResolvedType(importNamespaceType, unqualifiedContextType)) {
        return token;
      }

      if (hasAmbiguousImportedTypes || unqualifiedContextType != null) {
        throw InvalidGenerationSource(
          'Transformed representation type "$fullRepresentationType" for '
          '"${resolved.schemaName}" is ambiguous in this library.',
          element: contextElement,
          todo: 'Use a prefixed schema import or rename/import the representation type so the generated cast resolves unambiguously.',
        );
      }
    }

    if (hasAmbiguousImportedTypes) {
      throw InvalidGenerationSource(
        'Transformed representation type "$fullRepresentationType" for '
        '"${resolved.schemaName}" is ambiguous in this library.',
        element: contextElement,
        todo: 'Use a prefixed schema import or rename/import the representation type so the generated cast resolves unambiguously.',
      );
    }

    if (unqualifiedContextType != null) {
      return token;
    }

    throw InvalidGenerationSource(
      'Transformed representation type "$fullRepresentationType" for '
      '"${resolved.schemaName}" is not visible from this library.',
      element: contextElement,
      todo: 'Export the representation type from the referenced schema library or import that type directly into this library.',
    );
  }

  bool _sameResolvedType(DartType first, DartType second) {
    return _resolvedTypeIdentity(first) == _resolvedTypeIdentity(second);
  }

  List<DartType> _resolveImportedTypesByName(
    String token,
    LibraryElement library,
  ) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return const [];
    }

    final importedTypesByIdentity = <String, DartType>{};
    for (final import in library.firstFragment.libraryImports) {
      final importedElement = import.namespace.get2(normalizedToken);
      final importedType = _resolveTypeFromElement(importedElement);
      if (importedType == null) {
        continue;
      }

      importedTypesByIdentity.putIfAbsent(
        _resolvedTypeIdentity(importedType),
        () => importedType,
      );
    }

    return importedTypesByIdentity.values.toList(growable: false);
  }

  DartType? _resolveImportedType(
    String token,
    _ResolvedSchemaReference resolved,
  ) {
    final importDirective = resolved.importDirective;
    if (importDirective == null) {
      return null;
    }

    final prefix = resolved.importPrefix;
    final importedElement = prefix != null && prefix.isNotEmpty
        ? importDirective.namespace.getPrefixed2(prefix, token)
        : importDirective.namespace.get2(token);
    return _resolveTypeFromElement(importedElement);
  }

  String _resolvedTypeIdentity(DartType type) {
    if (type is InterfaceType) {
      final element = type.element;
      final libraryUri = element.library.uri.toString();
      final name = element.name ?? type.getDisplayString();
      return '$libraryUri::$name';
    }

    return type.getDisplayString();
  }

  bool _isBuiltInRepresentationIdentifier(String token) {
    return token == 'String' ||
        token == 'int' ||
        token == 'double' ||
        token == 'bool' ||
        token == 'num' ||
        token == 'dynamic' ||
        token == 'Object' ||
        token == 'Null' ||
        token == 'Never' ||
        token == 'void' ||
        token == 'Uri' ||
        token == 'DateTime' ||
        token == 'Duration' ||
        token == 'List' ||
        token == 'Set' ||
        token == 'Map';
  }

  bool _containsUnsupportedRepresentationSyntax(String representationType) {
    return representationType.contains('(') ||
        representationType.contains(')') ||
        representationType.contains('{') ||
        representationType.contains('}') ||
        representationType.contains('=>');
  }

  String _schemaReferenceCacheKey(
    _SchemaReference reference,
    LibraryElement library,
  ) {
    final prefix = reference.prefix ?? '';
    return '${library.uri}::$prefix::${reference.name}';
  }

  String _formatSchemaReference(_SchemaReference reference) {
    final prefix = reference.prefix;
    if (prefix == null || prefix.isEmpty) {
      return reference.name;
    }
    return '$prefix.${reference.name}';
  }

  DartType _representationTypeToDartType(
    String representationType,
    TypeProvider typeProvider,
  ) {
    return switch (representationType) {
      'String' => typeProvider.stringType,
      'int' => typeProvider.intType,
      'double' => typeProvider.doubleType,
      'bool' => typeProvider.boolType,
      'num' => typeProvider.numType,
      'Uri' => _dartCoreType(typeProvider, 'Uri'),
      'DateTime' => _dartCoreType(typeProvider, 'DateTime'),
      'Duration' => _dartCoreType(typeProvider, 'Duration'),
      _ when representationType.startsWith('Map<') => typeProvider.mapType(
        typeProvider.stringType,
        typeProvider.dynamicType,
      ),
      _ when representationType.startsWith('List<') => typeProvider.listType(
        typeProvider.dynamicType,
      ),
      _ => typeProvider.dynamicType,
    };
  }

  DartType _dartCoreType(TypeProvider typeProvider, String typeName) {
    final type = _resolveTypeByName(
      typeName,
      typeProvider.stringType.element.library,
    );
    return type ?? typeProvider.dynamicType;
  }

  /// Extracts the identifier name from different expression forms.
  ///
  /// Supports simple identifiers, prefixed identifiers (`prefix.name`),
  /// and property accesses (`expr.name`).
  String? _identifierName(Expression? expression) {
    if (expression == null) return null;

    if (expression is SimpleIdentifier) {
      return expression.name;
    }

    if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    }

    if (expression is PropertyAccess) {
      return expression.propertyName.name;
    }

    return null;
  }

  bool _isAckTarget(Expression? target) {
    return _identifierName(target) == 'Ack';
  }

  _SchemaReference? _extractSchemaReference(Expression? target) {
    if (target == null) return null;

    if (target is SimpleIdentifier) {
      if (target.name == 'Ack') return null;
      return (name: target.name, prefix: null);
    }

    if (target is PrefixedIdentifier) {
      final name = target.identifier.name;
      if (name == 'Ack') return null;
      return (name: name, prefix: target.prefix.name);
    }

    if (target is PropertyAccess) {
      final name = target.propertyName.name;
      if (name == 'Ack') return null;

      final targetExpression = target.target;
      String? prefix;
      if (targetExpression is SimpleIdentifier) {
        prefix = targetExpression.name;
      } else if (targetExpression is PrefixedIdentifier) {
        prefix = targetExpression.identifier.name;
      }

      return (name: name, prefix: prefix);
    }

    return null;
  }

  (List<MethodInvocation>, bool) _collectMethodChain(
    MethodInvocation invocation,
  ) {
    final chain = <MethodInvocation>[];
    MethodInvocation? current = invocation;

    // Safety limit to prevent infinite loops on malformed AST
    const maxDepth = 20;
    var depth = 0;

    while (current != null && depth < maxDepth) {
      chain.add(current);
      final target = current.target;
      if (target is MethodInvocation) {
        current = target;
        depth++;
      } else {
        break;
      }
    }

    return (chain, depth >= maxDepth);
  }

  _SchemaChainInfo _analyzeSchemaChain(MethodInvocation invocation) {
    final (chain, truncated) = _collectMethodChain(invocation);
    MethodInvocation? ackBase;
    _SchemaReference? schemaReference;
    var isOptional = false;
    var isNullable = false;
    MethodInvocation? transformInvocation;
    DartType? transformOutputType;
    String? transformOutputTypeString;

    for (final current in chain) {
      final methodName = current.methodName.name;

      if (methodName == 'optional') {
        isOptional = true;
      } else if (methodName == 'nullable') {
        isNullable = true;
      } else if (methodName == 'transform' && transformInvocation == null) {
        transformInvocation = current;
        final typeArgs = current.typeArguments?.arguments;
        if (typeArgs != null && typeArgs.isNotEmpty) {
          final typeArg = typeArgs.first;
          transformOutputType = typeArg.type;
          transformOutputTypeString = typeArg.toSource();
        }
      }

      final target = current.target;
      if (ackBase == null && _isAckTarget(target)) {
        ackBase = current;
      }

      if (schemaReference == null) {
        final reference = _extractSchemaReference(target);
        if (reference != null) {
          schemaReference = reference;
        }
      }
    }

    if (truncated) {
      _log.warning(
        'Schema method chain exceeded max depth of 20. '
        'Type inference may fall back to dynamic.',
      );
    }

    return (
      ackBase: ackBase,
      schemaReference: schemaReference,
      isOptional: isOptional,
      isNullable: isNullable,
      wasTruncated: truncated,
      transformInvocation: transformInvocation,
      transformOutputType: transformOutputType,
      transformOutputTypeString: transformOutputTypeString,
    );
  }

  String? _requireTransformOutputType(
    _SchemaChainInfo chain,
    Element element, {
    required String contextLabel,
  }) {
    if (chain.transformInvocation == null) {
      return null;
    }

    final typeName = chain.transformOutputTypeString;
    if (typeName != null && typeName.isNotEmpty) {
      return typeName;
    }

    throw InvalidGenerationSource(
      '$contextLabel uses .transform(...) without an explicit output type. '
      '@AckType requires .transform<T>(...) so the generated type can be inferred.',
      element: element,
      todo: 'Add an explicit type argument, for example .transform<Uri>((value) => ...).',
    );
  }

  void _throwIfUnsupportedTransformedBaseSchema({
    required String schemaMethod,
    required String? transformOutputTypeString,
    required Element element,
    required String contextLabel,
  }) {
    if (transformOutputTypeString == null) {
      return;
    }

    if (schemaMethod == 'object') {
      throw InvalidGenerationSource(
        '$contextLabel transforms an Ack.object(...) schema. '
        'Transformed object schemas are not supported by @AckType.',
        element: element,
        todo: 'Remove .transform<T>() from the object schema or expose the transformed result through a separate non-object schema.',
      );
    }

    if (schemaMethod == 'discriminated') {
      throw InvalidGenerationSource(
        '$contextLabel transforms an Ack.discriminated(...) schema. '
        'Transformed discriminated schemas are not supported by @AckType.',
        element: element,
        todo: 'Remove .transform<T>() from the discriminated schema or expose the transformed result through a separate non-object schema.',
      );
    }
  }

  void _throwIfUnsupportedTransformedReferencedSchema({
    required _ResolvedSchemaReference resolved,
    required Element element,
    required String contextLabel,
  }) {
    final modelInfo = resolved.modelInfo;
    if (modelInfo.isDiscriminatedBaseDefinition) {
      throw InvalidGenerationSource(
        '$contextLabel transforms referenced discriminated schema '
        '"${resolved.schemaName}". Transformed discriminated schemas are not supported by @AckType.',
        element: element,
        todo: 'Remove .transform<T>() from the referenced discriminated schema or expose a separate non-object schema.',
      );
    }

    if (modelInfo.representationType == kMapType) {
      throw InvalidGenerationSource(
        '$contextLabel transforms referenced object schema '
        '"${resolved.schemaName}". Transformed object schemas are not supported by @AckType.',
        element: element,
        todo: 'Remove .transform<T>() from the referenced object schema or expose a separate non-object schema.',
      );
    }
  }

  /// Walks a method chain to find the base Ack.xxx() invocation.
  ///
  /// For `Ack.string().describe('...').optional()`, returns `Ack.string()`.
  /// For `Ack.integer().min(0).max(100)`, returns `Ack.integer()`.
  ///
  /// Returns `null` if no Ack.xxx() base is found.
  MethodInvocation? _findBaseAckInvocation(MethodInvocation invocation) {
    final (chain, truncated) = _collectMethodChain(invocation);

    for (final current in chain) {
      final target = current.target;
      if (_isAckTarget(target)) {
        return current;
      }
    }

    if (truncated) {
      _log.warning(
        'Method chain exceeded max depth of 20. '
        'List element type will fall back to dynamic.',
      );
    }
    return null;
  }

  /// Walks a method chain to find a schema variable base reference.
  ///
  /// For `itemSchema.optional().nullable()`, returns `(name: itemSchema)`.
  /// For `deck.slideSchema.describe('...')`, returns
  /// `(name: slideSchema, prefix: deck)`.
  ///
  /// Returns `null` if the chain doesn't end with a schema variable identifier
  /// (e.g., if it's an Ack.xxx() chain or unknown structure).
  ///
  _SchemaReference? _findSchemaVariableBase(MethodInvocation invocation) {
    final (chain, truncated) = _collectMethodChain(invocation);

    for (final current in chain) {
      final target = current.target;

      final schemaReference = _extractSchemaReference(target);
      if (schemaReference != null) {
        return schemaReference;
      }

      // If target resolves to Ack, this is an Ack.xxx() chain
      if (_isAckTarget(target)) {
        return null;
      }
    }

    if (truncated) {
      _log.warning(
        'Schema variable method chain exceeded max depth of 20. '
        'List element type will fall back to dynamic.',
      );
    }
    return null;
  }

  /// Resolves the base class name for a schema variable, honoring custom overrides.
  String _resolveModelClassName(
    String variableName,
    Element element, {
    String? customTypeName,
  }) {
    if (customTypeName == null) {
      return _generateTypeNameFromVariable(variableName);
    }

    final trimmed = customTypeName.trim();
    if (trimmed.isEmpty) {
      throw InvalidGenerationSource(
        'Custom @AckType name cannot be empty',
        element: element,
        todo: 'Provide a non-empty type name in the @AckType annotation.',
      );
    }

    const identifierPattern = r'^[A-Za-z_][A-Za-z0-9_]*$';
    if (!RegExp(identifierPattern).hasMatch(trimmed)) {
      throw InvalidGenerationSource(
        'Invalid custom @AckType name "$customTypeName". '
        'Type names must start with a letter or underscore and can only contain letters, numbers, and underscores.',
        element: element,
        todo: 'Update the @AckType annotation to use a valid Dart identifier.',
      );
    }

    // Ensure leading character is uppercase for consistency.
    if (trimmed.length == 1) {
      return trimmed.toUpperCase();
    }

    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  /// Generates an extension type name from a schema variable name
  ///
  /// Examples:
  /// - "userSchema" → "User"
  /// - "addressSchema" → "Address"
  /// - "myDataSchema" → "MyData"
  String _generateTypeNameFromVariable(String variableName) {
    // Remove "Schema" suffix if present
    var name = variableName;
    if (name.endsWith('Schema')) {
      name = name.substring(0, name.length - 'Schema'.length);
    }

    // Capitalize first letter
    if (name.isEmpty) return 'Type';
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Parses Ack.string() schema
  ModelInfo _parseStringSchema(
    String variableName,
    MethodInvocation invocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      representationType: 'String',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.integer() schema
  ModelInfo _parseIntegerSchema(
    String variableName,
    MethodInvocation invocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      representationType: 'int',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.double() schema
  ModelInfo _parseDoubleSchema(
    String variableName,
    MethodInvocation invocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      representationType: 'double',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.boolean() schema
  ModelInfo _parseBooleanSchema(
    String variableName,
    MethodInvocation invocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      representationType: 'bool',
      isNullableSchema: isNullable,
    );
  }

  /// Parses Ack.list() schema
  ///
  /// Extracts the element type from list schema definitions to generate
  /// correctly typed extension types (e.g., `List<String>` not `List<dynamic>`).
  ///
  /// Examples:
  /// - `Ack.list(Ack.string())` → `List<String>`
  /// - `Ack.list(Ack.integer())` → `List<int>`
  /// - `Ack.list(Ack.list(Ack.double()))` → `List<List<double>>` (nested)
  /// - `Ack.list(addressSchema)` → `List<Map<String, Object?>>` (schema reference)
  ModelInfo _parseListSchema(
    String variableName,
    Element element, {
    required bool isNullable,
    required _ListElementAnalysis listElementAnalysis,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      representationType:
          'List<${listElementAnalysis.elementRepresentationType}>',
      isNullableSchema: isNullable,
    );
  }

  ModelInfo _parseRepresentationSchema(
    String variableName,
    Element element, {
    required String representationType,
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: const [],
      representationType: representationType,
      isNullableSchema: isNullable,
    );
  }

  ModelInfo _withRepresentationType(
    ModelInfo model,
    String representationType,
  ) {
    return ModelInfo(
      className: model.className,
      schemaClassName: model.schemaClassName,
      description: model.description,
      fields: model.fields,
      additionalProperties: model.additionalProperties,
      discriminatorKey: model.discriminatorKey,
      discriminatorValue: model.discriminatorValue,
      subtypeNames: model.subtypeNames,
      schemaIdentity: model.schemaIdentity,
      discriminatedBaseClassName: model.discriminatedBaseClassName,
      representationType: representationType,
      isNullableSchema: model.isNullableSchema,
    );
  }

  /// Parses Ack.literal() schema
  ///
  /// Literal schemas are StringSchema with a literal constraint.
  /// The constraint is enforced at runtime, not in the extension type.
  ///
  /// Example: Ack.literal('active') → extension type StatusType(String)
  ModelInfo _parseLiteralSchema(
    String variableName,
    MethodInvocation invocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      representationType: 'String',
      isNullableSchema: isNullable,
    );
  }

  /// Parses `Ack.enumString()` schema.
  ///
  /// String-enum schemas are `StringSchema` values with an enum constraint.
  /// The allowed values are enforced at runtime, not in the extension type.
  ///
  /// Example: `Ack.enumString(['a', 'b'])` -> `extension type XType(String)`
  ModelInfo _parseEnumStringSchema(
    String variableName,
    MethodInvocation invocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      representationType: 'String',
      isNullableSchema: isNullable,
    );
  }

  /// Parses `Ack.enumValues<T>()` schema
  ///
  /// EnumValues schemas wrap Dart enum types with validation.
  /// The representation type is the enum type itself.
  ///
  /// Example: `Ack.enumValues<UserRole>([...])` → extension type XType(UserRole)
  ModelInfo _parseEnumValuesSchema(
    String variableName,
    MethodInvocation invocation,
    Element element, {
    required bool isNullable,
    String? customTypeName,
  }) {
    final typeName = _resolveModelClassName(
      variableName,
      element,
      customTypeName: customTypeName,
    );

    final enumTypeName = _extractEnumTypeNameFromInvocation(invocation);

    // If we couldn't extract the enum type, throw an error
    if (enumTypeName == null) {
      throw InvalidGenerationSource(
        'Could not determine enum type for Ack.enumValues(). '
        'Use explicit type argument: Ack.enumValues<YourEnum>([...]) '
        'or pass enum.values: Ack.enumValues(YourEnum.values)',
        element: element,
      );
    }

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: [],
      representationType: enumTypeName,
      isNullableSchema: isNullable,
    );
  }

  /// Maps Ack schema method names to Dart type strings
  ///
  /// Used for generating string representations of types in list element contexts.
  /// For nested lists, this function is called recursively via [_parseListSchema].
  String _mapSchemaMethodToType(String methodName) {
    return switch (methodName) {
      'string' || 'enumString' || 'literal' => 'String',
      'integer' => 'int',
      'double' => 'double',
      'boolean' => 'bool',
      'uri' => 'Uri',
      'date' || 'datetime' => 'DateTime',
      'duration' => 'Duration',
      'object' => kMapType,
      'list' => 'List<dynamic>',
      _ => 'dynamic',
    };
  }

  /// Validates that a field name is a valid Dart identifier
  ///
  /// Throws [InvalidGenerationSource] if the field name:
  /// - Contains invalid characters (must match [a-zA-Z_$][a-zA-Z0-9_$]*)
  /// - Is a Dart reserved keyword
  void _validateFieldName(String fieldName, Element element) {
    // Check if key is a valid Dart identifier
    final identifierRegex = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');
    if (!identifierRegex.hasMatch(fieldName)) {
      throw InvalidGenerationSource(
        'JSON key "$fieldName" is not a valid Dart identifier. '
        'Keys must start with a letter, underscore, or dollar sign, and can only '
        'contain letters, numbers, underscores, and dollar signs.',
        element: element,
        todo:
            'Use a valid Dart identifier as the key, or consider transforming '
            'the key to a valid identifier (e.g., "user-id" → "userId").',
      );
    }

    // Reject only reserved words. Built-in and pseudo keywords are allowed
    // as identifiers in many contexts (for example `of`, `augment`).
    final keyword = Keyword.keywords[fieldName];
    if (keyword?.isReservedWord == true) {
      throw InvalidGenerationSource(
        'JSON key "$fieldName" is a Dart reserved keyword and cannot be used as a field name.',
        element: element,
        todo:
            'Use a different key that is not a Dart reserved keyword, or prefix it '
            '(e.g., "class" → "classValue" or "klass").',
      );
    }
  }
}
