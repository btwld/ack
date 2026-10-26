import 'package:ack/ack.dart'
    show AnyOfSchema, AnySchema, InstanceSchema, MapSchema;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';
import '../utils/string_literal.dart';
import 'model_graph_builder_base.dart';
import 'schema_first_names.dart';

final class _Declaration {
  const _Declaration({
    required this.element,
    required this.expression,
    required this.id,
    required this.className,
  });

  final Element element;
  final Expression expression;
  final AckSchemaId id;
  final String className;
}

typedef _SchemaTypes = ({AckInferRef boundary, AckInferRef runtime});

/// The effective flags of a schema expression, including referenced aliases.
///
/// DefaultSchema cannot clear a nullable/optional flag inherited from its inner
/// schema. Other public wrappers copy the flags but have no such inner floor.
final class _SchemaMetadata {
  const _SchemaMetadata({
    this.optional = false,
    this.nullable = false,
    this.defaulted = false,
    this.innerOptional = false,
    this.innerNullable = false,
  });

  final bool optional;
  final bool nullable;
  final bool defaulted;
  final bool innerOptional;
  final bool innerNullable;

  _SchemaMetadata copyWith({bool? optional, bool? nullable}) => _SchemaMetadata(
    optional: (optional ?? this.optional) || innerOptional,
    nullable: (nullable ?? this.nullable) || innerNullable,
    defaulted: defaulted,
    innerOptional: innerOptional,
    innerNullable: innerNullable,
  );

  _SchemaMetadata get wrapped =>
      _SchemaMetadata(optional: optional, nullable: nullable);
}

/// Builds the single normalized graph consumed by Ack model emission.
final class SchemaModelGraphBuilder extends ModelGraphBuilderBase {
  SchemaModelGraphBuilder(super.library);

  static const _reservedMembers = ackSchemaFirstReservedMembers;

  static const _anySchemaChecker = TypeChecker.typeNamed(
    AnySchema,
    inPackage: 'ack',
  );
  static const _anyOfSchemaChecker = TypeChecker.typeNamed(
    AnyOfSchema,
    inPackage: 'ack',
  );
  static const _instanceSchemaChecker = TypeChecker.typeNamed(
    InstanceSchema,
    inPackage: 'ack',
  );
  static const _mapSchemaChecker = TypeChecker.typeNamed(
    MapSchema,
    inPackage: 'ack',
  );

  final Map<Element, _Declaration> _declarationsByElement = {};
  final Map<AckSchemaId, _Declaration> _declarationsById = {};
  final Map<AckSchemaId, AckSchemaId> _unionOwnerByBranch = {};

  Future<AckModelGraph> build(List<Element> annotatedElements) async {
    final resolved = await initInputLibrary();
    final libraryElement = library.element;

    for (final element in annotatedElements) {
      _rejectClassOnlyOptions(element);
      final expression = declarationExpression(resolved, element);
      final declarationName = element.name;
      if (declarationName == null || expression == null) {
        throw InvalidGenerationSource(
          'Could not resolve the schema expression for ${element.displayName}.',
          element: element,
        );
      }
      final id = AckSchemaId(
        libraryUri: libraryElement.uri,
        declarationName: declarationName,
      );
      final declaration = _Declaration(
        element: element,
        expression: expression,
        id: id,
        className: _className(
          declarationName,
          schemableCustomName(element),
          element,
        ),
      );
      _registerElement(element, declaration);
      _declarationsById[id] = declaration;
    }

    _validateClassNames();
    for (final declaration in _declarationsById.values) {
      await _resolve(
        declaration,
        throughLazy: false,
        path: declaration.id.declarationName,
      );
    }
    _validateDelegatedHelperNames();
    return graph;
  }

  void _rejectClassOnlyOptions(Element element) {
    final annotation = ModelGraphBuilderBase.schemableChecker
        .firstAnnotationOfExact(propertyDeclaration(element));
    if (annotation == null) return;
    final reader = ConstantReader(annotation);
    int index(String option) =>
        reader.read(option).objectValue.getField('index')!.toIntValue()!;
    final configured = [
      if (!reader.read('schemaName').isNull) 'schemaName',
      if (!reader.read('description').isNull) 'description',
      if (index('caseStyle') != 0) 'caseStyle',
      if (!reader.read('discriminatorKey').isNull) 'discriminatorKey',
      if (!reader.read('discriminatorValue').isNull) 'discriminatorValue',
      if (index('unknownProperties') != 0) 'unknownProperties',
      if (reader.read('captureField').stringValue != 'additionalProperties')
        'captureField',
      if (!reader.read('schemas').isNull) 'schemas',
    ];
    if (configured.isEmpty) return;
    throw InvalidGenerationSource(
      '${element.name} sets @Schemable options that apply only to classes: '
      '${configured.join(', ')}. Configure a top-level schema in its Ack '
      'expression; describe it with .describe(...).',
      element: element,
    );
  }

  void _registerElement(Element element, _Declaration declaration) {
    _declarationsByElement[element.baseElement] = declaration;
    _declarationsByElement[element] = declaration;
    if (element is TopLevelVariableElement) {
      final getter = element.getter;
      if (getter != null) {
        _declarationsByElement[getter.baseElement] = declaration;
      }
    } else if (element is GetterElement) {
      _declarationsByElement[element.variable.baseElement] = declaration;
    }
  }

  Future<void> _resolve(
    _Declaration declaration, {
    required bool throughLazy,
    required String path,
  }) async {
    switch (graph.stateOf(declaration.id)) {
      case AckResolutionState.resolved:
        return;
      case AckResolutionState.visiting:
        if (throughLazy) return;
        throw InvalidGenerationSource(
          'Ordinary schema alias cycle detected at $path. Recursive model '
          'edges must use named Ack.lazy(...).',
          element: declaration.element,
        );
      case AckResolutionState.unseen:
        break;
    }

    graph.begin(declaration.id);
    final chain = parseSchemaChain(declaration.expression);
    _rejectTransform(chain, path, declaration.element);
    await _rejectObjectShapeChanges(
      declaration.expression,
      path: path,
      context: declaration.element,
    );
    final metadata = await _schemaMetadata(
      declaration.expression,
      path: path,
      context: declaration.element,
    );
    if (metadata.nullable) {
      throw InvalidGenerationSource(
        '$path is a nullable root. Generated Ack models are non-nullable.',
        element: declaration.element,
        todo: 'Remove .nullable() from the annotated root schema.',
      );
    }

    final baseName = chain.base?.methodName.name;
    final AckModelNode node;
    if (chain.hasCodec) {
      node = await _valueNode(declaration, path);
    } else if (baseName == 'object') {
      node = await _objectNode(declaration, chain, path);
    } else if (baseName == 'discriminated') {
      node = await _unionNode(declaration, chain, path);
    } else if (chain.reference != null &&
        _localDeclaration(chain.reference!) != null) {
      node = await _aliasNode(declaration, chain.reference!, path);
    } else if (chain.reference != null &&
        _isCrossLibrarySchemable(chain.reference!)) {
      throw InvalidGenerationSource(
        '$path aliases a cross-library '
        '${annotationName(referencedElement(chain.reference!)!)} schema. '
        'Use the original model directly.',
        element: declaration.element,
      );
    } else {
      const supportedValueRoots = {
        'string',
        'integer',
        'double',
        'number',
        'boolean',
        'list',
        'literal',
        'enumString',
        'enumValues',
        'uri',
        'date',
        'datetime',
        'duration',
        'codec',
        'lazy',
      };
      // Ack.any() and Ack.map() are valid fields but never model roots,
      // whether written inline or reached through an unannotated variable.
      final rootType = declaration.expression.staticType;
      if (rootType != null &&
          _anySchemaChecker.isAssignableFromType(rootType)) {
        _rejectUnsupportedRoot('any', path, declaration.element);
      }
      if (rootType != null &&
          _mapSchemaChecker.isAssignableFromType(rootType)) {
        throw InvalidGenerationSource(
          '$path uses an Ack.map() root. Generated models need an object or '
          'value root.',
          element: declaration.element,
          todo: 'Use Ack.map(...) as a field of an Ack.object(...) model.',
        );
      }
      if (baseName != null && !supportedValueRoots.contains(baseName)) {
        _rejectUnsupportedRoot(baseName, path, declaration.element);
      }
      node = await _valueNode(declaration, path);
    }
    graph.complete(node);
  }

  Future<AckValueModelNode> _valueNode(
    _Declaration declaration,
    String path,
  ) async {
    final expression = declaration.expression;
    final types = _schemaTypes(expression, path, declaration.element);
    return AckValueModelNode(
      id: declaration.id,
      className: declaration.className,
      boundaryType: types.boundary,
      runtimeRef: await _runtimeRefForSchema(
        expression,
        path: path,
        context: declaration.element,
        throughLazy: false,
      ),
      description: descriptionFromExpression(expression),
    );
  }

  Future<AckModelNode> _aliasNode(
    _Declaration declaration,
    Expression reference,
    String path,
  ) async {
    final target = _localDeclaration(reference);
    if (target == null) {
      throw InvalidGenerationSource(
        '$path is an unresolvable dynamic schema alias.',
        element: declaration.element,
      );
    }
    await _resolve(
      target,
      throughLazy: false,
      path: '$path -> ${target.id.declarationName}',
    );
    final source = graph.nodeFor(target.id)!;
    if (source is AckObjectModelNode) {
      final additionalProperties = await _additionalProperties(
        declaration.expression,
        path: path,
        context: declaration.element,
      );
      return AckObjectModelNode(
        id: declaration.id,
        className: declaration.className,
        fields: source.fields,
        unknownPropertyPolicy: additionalProperties
            ? AckUnknownPropertyPolicy.capture
            : AckUnknownPropertyPolicy.reject,
        captureFieldName: additionalProperties ? 'additionalProperties' : null,
        constructorParameters: _schemaFirstConstructorParameters(
          source.fields,
          capture: additionalProperties,
        ),
        description: source.description,
      );
    }
    if (source is AckUnionModelNode) {
      throw InvalidGenerationSource(
        '$path aliases a discriminated union. Annotate and use the original '
        'union model directly.',
        element: declaration.element,
      );
    }
    final valueSource = source as AckValueModelNode;
    return AckValueModelNode(
      id: declaration.id,
      className: declaration.className,
      boundaryType: valueSource.boundaryType,
      runtimeRef: valueSource.runtimeRef,
      description: valueSource.description,
    );
  }

  Future<AckObjectModelNode> _objectNode(
    _Declaration declaration,
    SchemaChain chain,
    String path,
  ) async {
    _schemaTypes(declaration.expression, path, declaration.element);
    final invocation = chain.base!;
    final arguments = argumentExpressions(invocation.argumentList);
    if (arguments.isEmpty || arguments.first is! SetOrMapLiteral) {
      throw InvalidGenerationSource(
        '$path must use a map literal in Ack.object(...).',
        element: declaration.element,
      );
    }
    final literal = arguments.first as SetOrMapLiteral;
    final additionalProperties = await _additionalProperties(
      declaration.expression,
      path: path,
      context: declaration.element,
    );
    final fields = <AckFieldNode>[];
    for (final entry in literal.elements) {
      if (entry is! MapLiteralEntry || entry.key is! SimpleStringLiteral) {
        throw InvalidGenerationSource(
          '$path object keys must be string literals.',
          element: declaration.element,
        );
      }
      final jsonKey = (entry.key as SimpleStringLiteral).value;
      final problem = ackSchemaFirstFieldNameProblem(
        jsonKey,
        capturesExtras: additionalProperties,
      );
      if (problem != null) {
        throw InvalidGenerationSource(
          '$path.$jsonKey $problem',
          element: declaration.element,
        );
      }
      final fieldPath = '$path.$jsonKey';
      final fieldChain = parseSchemaChain(entry.value);
      final fieldMetadata = await _schemaMetadata(
        entry.value,
        path: fieldPath,
        context: declaration.element,
      );
      _rejectTransform(fieldChain, fieldPath, declaration.element);
      if (fieldChain.base?.methodName.name == 'object') {
        throw InvalidGenerationSource(
          '$fieldPath uses an anonymous inline Ack.object(...).',
          element: declaration.element,
          todo: 'Extract it to a named @Schemable schema declaration.',
        );
      }
      final runtimeRef = await _runtimeRefForSchema(
        entry.value,
        path: fieldPath,
        context: declaration.element,
        throughLazy: false,
      );
      fields.add(
        AckFieldNode(
          dartName: jsonKey,
          jsonKey: jsonKey,
          presence: _fieldPresence(fieldMetadata),
          nullable: fieldMetadata.nullable,
          runtimeRef: runtimeRef,
          description: descriptionFromExpression(entry.value),
        ),
      );
    }
    return AckObjectModelNode(
      id: declaration.id,
      className: declaration.className,
      fields: fields,
      constructorParameters: _schemaFirstConstructorParameters(
        fields,
        capture: additionalProperties,
      ),
      unknownPropertyPolicy: additionalProperties
          ? AckUnknownPropertyPolicy.capture
          : AckUnknownPropertyPolicy.reject,
      captureFieldName: additionalProperties ? 'additionalProperties' : null,
      description: descriptionFromExpression(declaration.expression),
    );
  }

  Future<AckUnionModelNode> _unionNode(
    _Declaration declaration,
    SchemaChain chain,
    String path,
  ) async {
    _schemaTypes(declaration.expression, path, declaration.element);
    String? discriminatorKey;
    SetOrMapLiteral? branchesLiteral;
    for (final argumentNode in chain.base!.argumentList.arguments) {
      final argument = namedArgument(argumentNode);
      if (argument == null) continue;
      switch (argument.name) {
        case 'discriminatorKey':
          final value = argument.expression;
          if (value is SimpleStringLiteral) discriminatorKey = value.value;
        case 'schemas':
          final value = argument.expression;
          if (value is SetOrMapLiteral) branchesLiteral = value;
      }
    }
    if (discriminatorKey == null || branchesLiteral == null) {
      throw InvalidGenerationSource(
        '$path must provide literal discriminatorKey and schemas arguments.',
        element: declaration.element,
      );
    }
    _rejectInvalidMemberName(discriminatorKey, path, declaration.element);
    if (_reservedMembers.contains(discriminatorKey) ||
        discriminatorKey == 'additionalProperties') {
      throw InvalidGenerationSource(
        '$path.$discriminatorKey conflicts with a generated member or Dart '
        'keyword.',
        element: declaration.element,
      );
    }

    final branches = <String, AckSchemaId>{};
    for (final element in branchesLiteral.elements) {
      if (element is! MapLiteralEntry || element.key is! SimpleStringLiteral) {
        throw InvalidGenerationSource(
          '$path discriminated branches must be a string-keyed map literal.',
          element: declaration.element,
        );
      }
      final value = (element.key as SimpleStringLiteral).value;
      final target = _localDeclaration(element.value);
      if (target == null) {
        throw InvalidGenerationSource(
          '$path.$value is a cross-library or unresolvable discriminated branch.',
          element: declaration.element,
        );
      }
      _validateUnionBranchDiscriminator(target, discriminatorKey, value);
      await _resolve(target, throughLazy: false, path: '$path.$value');
      final branch = graph.nodeFor(target.id);
      if (branch is! AckObjectModelNode) {
        throw InvalidGenerationSource(
          '$path.$value must reference an '
          '${annotationName(declaration.element)} object schema.',
          element: declaration.element,
        );
      }
      final owner = _unionOwnerByBranch[target.id];
      if (owner != null && owner != declaration.id) {
        throw InvalidGenerationSource(
          '${target.id.declarationName} belongs to multiple discriminated unions.',
          element: declaration.element,
        );
      }
      _unionOwnerByBranch[target.id] = declaration.id;
      graph.replace(
        AckObjectModelNode(
          id: branch.id,
          className: branch.className,
          fields: branch.fields,
          constructorParameters: branch.constructorParameters,
          unknownPropertyPolicy: branch.unknownPropertyPolicy,
          captureFieldName: branch.captureFieldName,
          unionId: declaration.id,
          discriminatorKey: discriminatorKey,
          discriminatorValue: value,
          description: branch.description,
        ),
      );
      branches[value] = target.id;
    }
    if (branches.isEmpty) {
      throw InvalidGenerationSource(
        '$path must declare at least one discriminated branch.',
        element: declaration.element,
      );
    }
    return AckUnionModelNode(
      id: declaration.id,
      className: declaration.className,
      discriminatorKey: discriminatorKey,
      branches: branches,
      description: descriptionFromExpression(declaration.expression),
    );
  }

  Future<AckInferRef> _runtimeRefForSchema(
    Expression expression, {
    required String path,
    required Element context,
    required bool throughLazy,
    Set<Element>? visited,
    int depth = 0,
    String? followedName,
    bool collectionElement = false,
  }) async {
    final chain = parseSchemaChain(expression);
    _rejectTransform(chain, path, context);
    await _rejectObjectShapeChanges(expression, path: path, context: context);
    if (collectionElement &&
        (await _schemaMetadata(
          expression,
          path: path,
          context: context,
        )).nullable) {
      throw InvalidGenerationSource(
        '$path uses nullable collection elements (${expression.toSource()}). '
        'Ack.list does not support '
        'nullable item schemas.',
        element: context,
        todo:
            'Remove .nullable() from the item schema. Make the list itself '
            'nullable with Ack.list(item).nullable() when needed.',
      );
    }
    if (chain.hasCodec) {
      await _rejectReferencedTransform(
        chain.reference,
        path: path,
        context: context,
      );
      return _schemaTypes(expression, path, context).runtime;
    }
    final baseName = chain.base?.methodName.name;
    switch (baseName) {
      case 'object':
        if (followedName != null) {
          throw InvalidGenerationSource(
            "$path references '$followedName', an Ack.object schema without "
            '@Schemable. Annotate it to generate a model.',
            element: context,
          );
        }
        throw InvalidGenerationSource(
          '$path uses an anonymous inline Ack.object(...).',
          element: context,
        );
      case 'any':
        // A JSON-safe value field. Ack.any() roots are rejected in _resolve.
        return const AckScalarTypeRef('Object', isJsonValue: true);
      case 'preserveBoundary':
        final arguments = argumentExpressions(chain.base!.argumentList);
        if (arguments.length != 1) {
          _rejectUnsupportedRoot('preserveBoundary', path, context);
        }
        return _jsonBoundaryRef(arguments.single, path: path, context: context);
      case 'anyOf':
      case 'instance':
        _rejectUnsupportedRoot(baseName, path, context);
      case 'map':
        final arguments = argumentExpressions(chain.base!.argumentList);
        if (arguments.isEmpty) {
          throw InvalidGenerationSource(
            '$path has an empty Ack.map().',
            element: context,
          );
        }
        final valueType = await _runtimeRefForSchema(
          arguments.first,
          path: '$path{}',
          context: context,
          throughLazy: throughLazy,
          visited: visited,
          depth: depth,
        );
        // Unlike list items, JSON object values may be null.
        final nullableValue = (await _schemaMetadata(
          arguments.first,
          path: '$path{}',
          context: context,
        )).nullable;
        return AckMapTypeRef(
          nullableValue && valueType is! AckNullableTypeRef
              ? AckNullableTypeRef(valueType)
              : valueType,
        );
      case 'list':
        final arguments = argumentExpressions(chain.base!.argumentList);
        if (arguments.isEmpty) {
          throw InvalidGenerationSource(
            '$path has an empty Ack.list().',
            element: context,
          );
        }
        return AckListTypeRef(
          await _runtimeRefForSchema(
            arguments.first,
            path: '$path[]',
            context: context,
            throughLazy: throughLazy,
            visited: visited,
            depth: depth,
            collectionElement: true,
          ),
        );
      case 'enumValues':
        final arguments = argumentExpressions(chain.base!.argumentList);
        final valuesType = arguments.firstOrNull?.staticType;
        if (valuesType is InterfaceType &&
            valuesType.isDartCoreList &&
            valuesType.typeArguments.length == 1) {
          return _typeRef(valuesType.typeArguments.single, path, context);
        }
        throw InvalidGenerationSource(
          '$path Ack.enumValues(...) enum type is not statically resolvable.',
          element: context,
        );
      case 'lazy':
        return _lazyType(chain.base!, path, context);
      case 'discriminated':
        if (followedName != null) {
          throw InvalidGenerationSource(
            "$path references '$followedName', an Ack.discriminated schema "
            'without @Schemable. Annotate it to generate a model.',
            element: context,
          );
        }
        throw InvalidGenerationSource(
          '$path uses an anonymous discriminated union.',
          element: context,
        );
    }

    final reference = chain.reference;
    if (reference != null) {
      final classFirst = resolveClassFirstModelReference(reference, context);
      if (classFirst != null) return classFirst;
      final member = memberElement(reference);
      if (isTypeOwnedSchema(member)) {
        final owner = member!.enclosingElement! as InterfaceElement;
        // A class-first model's own schema may point at a facade generated
        // in this build, so its type is the model rather than the static's.
        if (owner is ClassElement && classFirstFacadeName(owner) != null) {
          return AckExternalTypeRef(
            name: owner.name!,
            importPrefix: visiblePrefixFor(owner, path: path, context: context),
          );
        }
        return _schemaTypes(reference, path, context).runtime;
      }
      final model = await _modelReference(
        reference,
        path: path,
        context: context,
        throughLazy: throughLazy,
      );
      if (model != null) return model;
      if (chain.base == null) {
        final followed = await _followUnannotatedReference(
          reference,
          path: path,
          context: context,
          throughLazy: throughLazy,
          visited: visited ?? {},
          depth: depth,
        );
        if (followed != null) return followed;
      }
    }

    _rejectUnsupportedSchemaType(expression, path, context);
    if (chain.base == null) {
      _rejectUnsupportedRoot(null, path, context);
    }
    return _schemaTypes(expression, path, context).runtime;
  }

  Future<AckInferRef?> _followUnannotatedReference(
    Expression reference, {
    required String path,
    required Element context,
    required bool throughLazy,
    required Set<Element> visited,
    required int depth,
  }) async {
    final element = referencedElement(reference);
    if (element == null) return null;
    if (element is! TopLevelVariableElement && element is! GetterElement) {
      return null;
    }
    if (hasSchemable(element)) return null;
    if (depth >= ModelGraphBuilderBase.maxReferenceDepth) {
      throw InvalidGenerationSource(
        '$path exceeds schema reference depth '
        '${ModelGraphBuilderBase.maxReferenceDepth}.',
        element: context,
      );
    }
    final canonical = element.baseElement;
    if (visited.contains(canonical)) {
      throw InvalidGenerationSource(
        "$path follows a cyclic schema reference through '${element.name}'.",
        element: context,
      );
    }
    final declaration = propertyDeclaration(element);
    final owningLibrary = declaration.library;
    if (owningLibrary == null) return null;
    final resolved = await resolvedLibraryFor(owningLibrary);
    final initializer = declarationExpression(resolved, declaration);
    if (initializer == null) {
      throw InvalidGenerationSource(
        "$path references '${element.name}', which has no statically "
        'resolvable initializer.',
        element: context,
      );
    }
    return _runtimeRefForSchema(
      initializer,
      path: '$path(→ ${element.name})',
      context: context,
      throughLazy: throughLazy,
      visited: {...visited, canonical},
      depth: depth + 1,
      followedName: element.name,
    );
  }

  /// Infers an explicitly preserved JSON boundary without inferring opaque
  /// codec runtime values. Reuses the normal source/reference machinery.
  Future<AckInferRef> _jsonBoundaryRef(
    Expression expression, {
    required String path,
    required Element context,
    Set<Element> visited = const {},
    int depth = 0,
  }) async {
    if (depth >= ModelGraphBuilderBase.maxReferenceDepth) {
      throw InvalidGenerationSource(
        '$path exceeds JSON boundary reference depth.',
        element: context,
      );
    }
    final chain = parseSchemaChain(expression);
    _rejectTransform(chain, path, context);
    final base = chain.base;
    AckInferRef result;
    switch (base?.methodName.name) {
      case 'string' ||
          'literal' ||
          'enumString' ||
          'integer' ||
          'number' ||
          'double' ||
          'boolean' ||
          'date' ||
          'datetime' ||
          'uri' ||
          'duration' ||
          'enumValues':
        // Native factories own their boundary types; decoded codec types do
        // not belong in a preserved wire field.
        result = _schemaTypes(base!, path, context).boundary;
      case 'any':
        result = const AckScalarTypeRef('Object', isJsonValue: true);
      case 'codec':
        Expression? input;
        for (final node in base!.argumentList.arguments) {
          final argument = namedArgument(node);
          if (argument?.name == 'input') {
            input = argument!.expression;
            break;
          }
        }
        if (input == null) return _unsupportedJsonBoundary(path, context);
        result = await _jsonBoundaryRef(
          input,
          path: '$path.input',
          context: context,
          visited: visited,
          depth: depth + 1,
        );
      case 'lazy':
        final arguments = argumentExpressions(base!.argumentList);
        if (arguments.length < 2 || arguments[1] is! FunctionExpression) {
          return _unsupportedJsonBoundary(path, context);
        }
        final target = functionBodyExpression(
          (arguments[1] as FunctionExpression).body,
        );
        if (target == null) return _unsupportedJsonBoundary(path, context);
        result = await _jsonBoundaryRef(
          target,
          path: '$path.lazy',
          context: context,
          visited: visited,
          depth: depth + 1,
        );
      case 'list' || 'map' || 'preserveBoundary':
        final arguments = argumentExpressions(base!.argumentList);
        if (arguments.length != 1) {
          return _unsupportedJsonBoundary(path, context);
        }
        var inner = await _jsonBoundaryRef(
          arguments.single,
          path: '$path[]',
          context: context,
          visited: visited,
          depth: depth + 1,
        );
        if (base.methodName.name == 'list') {
          if (inner is AckNullableTypeRef) {
            return _unsupportedJsonBoundary(path, context);
          }
          result = AckListTypeRef(inner);
        } else if (base.methodName.name == 'map') {
          result = AckMapTypeRef(inner);
        } else {
          result = inner;
        }
      case 'object':
        final arguments = argumentExpressions(base!.argumentList);
        if (arguments.firstOrNull case SetOrMapLiteral(:final elements)) {
          for (final entry in elements) {
            if (entry is! MapLiteralEntry) {
              return _unsupportedJsonBoundary(path, context);
            }
            await _jsonBoundaryRef(
              entry.value,
              path: '$path{}',
              context: context,
              visited: visited,
              depth: depth + 1,
            );
          }
          result = const AckMapTypeRef(
            AckNullableTypeRef(AckScalarTypeRef('Object', isJsonValue: true)),
          );
        } else {
          return _unsupportedJsonBoundary(path, context);
        }
      case 'anyOf':
        final arguments = argumentExpressions(base!.argumentList);
        if (arguments.firstOrNull case ListLiteral(
          :final elements,
        ) when elements.isNotEmpty) {
          for (final branch in elements) {
            if (branch is! Expression) {
              return _unsupportedJsonBoundary(path, context);
            }
            final inner = await _jsonBoundaryRef(
              branch,
              path: '$path.anyOf',
              context: context,
              visited: visited,
              depth: depth + 1,
            );
            // Nullable alternatives require an explicit union .nullable() so
            // the field's storage/constructor nullability remains unambiguous.
            if (inner is AckNullableTypeRef) {
              return _unsupportedJsonBoundary(path, context);
            }
          }
          result = const AckScalarTypeRef('Object', isJsonValue: true);
        } else {
          return _unsupportedJsonBoundary(path, context);
        }
      default:
        final reference = chain.reference;
        final element = reference == null ? null : referencedElement(reference);
        if (element == null ||
            (element is! TopLevelVariableElement &&
                element is! GetterElement) ||
            visited.contains(element.baseElement)) {
          return _unsupportedJsonBoundary(path, context);
        }
        final declaration = propertyDeclaration(element);
        final owningLibrary = declaration.library;
        if (owningLibrary == null) {
          return _unsupportedJsonBoundary(path, context);
        }
        final initializer = declarationExpression(
          await resolvedLibraryFor(owningLibrary),
          declaration,
        );
        if (initializer == null) return _unsupportedJsonBoundary(path, context);
        result = await _jsonBoundaryRef(
          initializer,
          path: '$path(→ ${element.name})',
          context: context,
          visited: {...visited, element.baseElement},
          depth: depth + 1,
        );
    }
    // Codec outputs are intentionally ignored here: preserveBoundary stores
    // and validates the original input-side JSON, not decoded runtime objects.
    final metadata = await _schemaMetadata(
      expression,
      path: path,
      context: context,
    );
    final nonNullable = result is AckNullableTypeRef ? result.inner : result;
    return metadata.nullable ? AckNullableTypeRef(nonNullable) : nonNullable;
  }

  Never _unsupportedJsonBoundary(String path, Element context) =>
      throw InvalidGenerationSource(
        '$path cannot prove a native JSON boundary. Use Ack.preserveBoundary '
        'with statically resolvable JSON schemas; opaque instance/codec input '
        'types and nullable union alternatives are not inferred.',
        element: context,
      );

  Future<AckInferRef> _lazyType(
    MethodInvocation invocation,
    String path,
    Element context,
  ) async {
    final arguments = argumentExpressions(invocation.argumentList);
    if (arguments.length < 2 || arguments.first is! SimpleStringLiteral) {
      throw InvalidGenerationSource(
        '$path must use named Ack.lazy(name, () => schema) recursion.',
        element: context,
      );
    }
    final callback = arguments[1];
    if (callback is! FunctionExpression) {
      throw InvalidGenerationSource(
        '$path Ack.lazy builder must be a closure.',
        element: context,
      );
    }
    final target = functionBodyExpression(callback.body);
    if (target == null) {
      throw InvalidGenerationSource(
        '$path Ack.lazy builder is not statically resolvable.',
        element: context,
      );
    }
    final model = await _modelReference(
      target,
      path: path,
      context: context,
      throughLazy: true,
    );
    if (model == null) {
      throw InvalidGenerationSource(
        '$path Ack.lazy must resolve to a named ${annotationName(context)} '
        'schema.',
        element: context,
      );
    }
    return model;
  }

  Future<AckModelTypeRef?> _modelReference(
    Expression expression, {
    required String path,
    required Element context,
    required bool throughLazy,
  }) async {
    final element = referencedElement(expression);
    if (element == null) return null;
    final local = _declarationsByElement[element.baseElement];
    if (local != null) {
      await _resolve(local, throughLazy: throughLazy, path: path);
      final runtime = _schemaTypes(
        local.expression,
        path,
        local.element,
      ).runtime;
      return AckModelTypeRef(
        schemaId: local.id,
        className: local.className,
        runtimeRef: runtime,
      );
    }
    if (!hasSchemable(element)) return null;
    final declaration = propertyDeclaration(element);
    final name = declaration.name;
    final owningLibrary = declaration.library;
    if (name == null || owningLibrary == null) return null;
    final className = _className(
      name,
      schemableCustomName(declaration),
      declaration,
    );
    final prefix = expressionPrefix(expression);
    _validateGeneratedModelImport(
      declaration,
      className,
      prefix: prefix,
      path: path,
      context: context,
    );
    return AckModelTypeRef(
      schemaId: AckSchemaId(
        libraryUri: owningLibrary.uri,
        declarationName: name,
      ),
      className: className,
      runtimeRef: _schemaTypes(expression, path, context).runtime,
      importPrefix: prefix,
    );
  }

  void _validateGeneratedModelImport(
    Element declaration,
    String className, {
    required String? prefix,
    required String path,
    required Element context,
  }) {
    final declarationName = declaration.name;
    if (declarationName == null) return;
    final visibility = checkCompanionVisibility(
      declaration,
      className,
      prefix: prefix,
    );
    if (visibility.declarationVisible && visibility.companionVisible) return;
    if (visibility.declarationVisible) {
      throw InvalidGenerationSource(
        '$path resolves to generated model "$className", which is hidden by '
        'an import combinator or an upstream export combinator. Expose both '
        '$declarationName and $className through the full import route.',
        element: context,
      );
    }
  }

  _SchemaTypes _schemaTypes(
    Expression expression,
    String path,
    Element context,
  ) {
    final type = expression.staticType;
    if (type is! InterfaceType) {
      throw InvalidGenerationSource(
        '$path has no resolvable AckSchema<Boundary, Runtime> type.',
        element: context,
      );
    }
    final ackInfer = ackSchemaTypeArguments(type);
    if (ackInfer == null) {
      throw InvalidGenerationSource(
        '$path does not resolve to AckSchema<Boundary, Runtime>.',
        element: context,
      );
    }
    return (
      boundary: _typeRef(ackInfer.boundary, path, context),
      runtime: _typeRef(ackInfer.runtime, path, context),
    );
  }

  AckInferRef _typeRef(DartType type, String path, Element context) =>
      inferTypeRef(type, path: path, context: context);

  _Declaration? _localDeclaration(Expression expression) {
    final element = referencedElement(expression);
    return element == null ? null : _declarationsByElement[element.baseElement];
  }

  bool _isCrossLibrarySchemable(Expression expression) {
    final element = referencedElement(expression);
    if (element == null) return false;
    if (_declarationsByElement[element.baseElement] != null) return false;
    return hasSchemable(element);
  }

  List<AckConstructorParameter> _schemaFirstConstructorParameters(
    List<AckFieldNode> fields, {
    required bool capture,
  }) {
    return [
      for (final field in fields)
        AckConstructorParameter(
          name: field.dartName,
          kind: AckConstructorParameterKind.named,
          fieldName: field.dartName,
          typeRef: field.runtimeRef,
          defaultExpression: field.defaultExpression,
        ),
      if (capture)
        const AckConstructorParameter(
          name: 'additionalProperties',
          kind: AckConstructorParameterKind.named,
          fieldName: 'additionalProperties',
          typeRef: AckMapTypeRef(
            AckNullableTypeRef(AckScalarTypeRef('Object')),
          ),
          defaultExpression: 'const {}',
        ),
    ];
  }

  AckSchemaFieldPresence _fieldPresence(_SchemaMetadata metadata) {
    if (metadata.defaulted) return AckSchemaFieldPresence.defaulted;
    if (metadata.optional) return AckSchemaFieldPresence.optional;
    return AckSchemaFieldPresence.required;
  }

  String _className(
    String declarationName,
    String? customName,
    Element element,
  ) {
    if (customName != null) {
      if (customName.trim() != customName ||
          !RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(customName)) {
        throw InvalidGenerationSource(
          'Invalid ${annotationName(element)} name "$customName". Names must '
          'be unchanged UpperCamelCase identifiers.',
          element: element,
        );
      }
      return ackInferModelClassName(declarationName, override: customName);
    }
    var stem = declarationName;
    if (stem.endsWith('Schema')) {
      stem = stem.substring(0, stem.length - 'Schema'.length);
    }
    if (stem.isEmpty || !RegExp(r'^[A-Za-z][A-Za-z0-9]*$').hasMatch(stem)) {
      throw InvalidGenerationSource(
        'Cannot derive an UpperCamelCase model name from "$declarationName".',
        element: element,
      );
    }
    return ackInferModelClassName(declarationName);
  }

  void _validateClassNames() {
    final generated = <String>{};
    final localNames = localDeclarationNames();
    for (final declaration in _declarationsById.values) {
      final name = declaration.className;
      if (!generated.add(name)) {
        throw InvalidGenerationSource(
          'Multiple ${annotationName(declaration.element)} declarations '
          'generate "$name".',
          element: declaration.element,
        );
      }
      if (localNames.contains(name)) {
        throw InvalidGenerationSource(
          'Generated class "$name" conflicts with a local declaration.',
          element: declaration.element,
        );
      }
      final visible = library.element.firstFragment.scope.lookup(name).getter;
      if (visible != null) {
        throw InvalidGenerationSource(
          'Generated class "$name" conflicts with a visible unprefixed import.',
          element: declaration.element,
        );
      }
    }
  }

  void _validateDelegatedHelperNames() {
    final localNames = localDeclarationNames();
    for (final node in graph.nodes) {
      final declaration = _declarationsById[node.id];
      if (declaration == null) continue;
      switch (node) {
        case AckUnionModelNode():
        case AckValueModelNode():
          continue;
        case AckObjectModelNode():
          validateCopyWithHelperNames(
            className: node.className,
            needsCopyWithSentinel: node.fields.any(
              (field) =>
                  field.jsonKey != node.discriminatorKey &&
                  (field.nullable || !field.isRequired),
            ),
            element: declaration.element,
            localNames: localNames,
          );
      }
    }
  }

  void _validateUnionBranchDiscriminator(
    _Declaration branch,
    String discriminatorKey,
    String discriminatorValue,
  ) {
    final chain = parseSchemaChain(branch.expression);
    final object = chain.base;
    if (object?.methodName.name != 'object') return;
    final arguments = argumentExpressions(object!.argumentList);
    if (arguments.firstOrNull case SetOrMapLiteral(:final elements)) {
      for (final entry in elements.whereType<MapLiteralEntry>()) {
        final key = entry.key;
        if (key is! SimpleStringLiteral || key.value != discriminatorKey) {
          continue;
        }
        if (_matchesDiscriminator(entry.value, discriminatorValue)) return;
        throw InvalidGenerationSource(
          '${branch.id.declarationName}.$discriminatorKey must be an exact '
          'literal or enum containing "$discriminatorValue".',
          element: branch.element,
        );
      }
    }
  }

  bool _matchesDiscriminator(Expression expression, String expected) {
    final chain = parseSchemaChain(expression);
    final base = chain.base;
    if (base == null || !identical(base, expression)) return false;
    final arguments = argumentExpressions(base.argumentList);
    return switch (base.methodName.name) {
      'literal' =>
        arguments.firstOrNull is SimpleStringLiteral &&
            (arguments.first as SimpleStringLiteral).value == expected,
      'enumString' =>
        arguments.firstOrNull is ListLiteral &&
            (arguments.first as ListLiteral).elements.any(
              (element) =>
                  element is SimpleStringLiteral && element.value == expected,
            ),
      _ => false,
    };
  }

  void _rejectInvalidMemberName(String jsonKey, String path, Element element) {
    if (jsonKey.startsWith('_')) {
      throw InvalidGenerationSource(
        "$path.$jsonKey cannot start with '_' (private Dart member).",
        element: element,
      );
    }
    if (!RegExp(r'^[A-Za-z$][A-Za-z0-9_$]*$').hasMatch(jsonKey) ||
        isDartReservedWord(jsonKey)) {
      throw InvalidGenerationSource(
        '$path.$jsonKey cannot be represented as a Dart field name.',
        element: element,
      );
    }
  }

  void _rejectUnsupportedSchemaType(
    Expression expression,
    String path,
    Element element,
  ) {
    final type = expression.staticType;
    if (type == null) return;
    if (_anyOfSchemaChecker.isAssignableFromType(type)) {
      _rejectUnsupportedRoot('anyOf', path, element);
    }
    if (_instanceSchemaChecker.isAssignableFromType(type)) {
      _rejectUnsupportedRoot('instance', path, element);
    }
  }

  void _rejectTransform(SchemaChain chain, String path, Element element) {
    if (!chain.hasTransform) return;
    throw InvalidGenerationSource(
      '$path uses one-way .transform(). Migrate this path to .codec() with an encoder.',
      element: element,
    );
  }

  Future<void> _rejectReferencedTransform(
    Expression? reference, {
    required String path,
    required Element context,
    Set<Element> visited = const {},
  }) async {
    if (reference == null) return;
    var directExpression = reference;
    while (directExpression is ParenthesizedExpression) {
      directExpression = directExpression.expression;
    }
    final directChain = parseSchemaChain(directExpression);
    _rejectTransform(directChain, path, context);

    final referenced = referencedElement(
      directChain.reference ?? directExpression,
    );
    final target = await resolveReferencedTopLevelExpression(
      referenced,
      visited: visited,
    );
    if (target == null) return;

    final referencePath = '$path(→ ${target.declaration.name})';
    final chain = parseSchemaChain(target.expression);
    _rejectTransform(chain, referencePath, context);
    await _rejectReferencedTransform(
      chain.reference,
      path: referencePath,
      context: context,
      visited: {...visited, target.declaration.baseElement},
    );
  }

  Never _rejectUnsupportedRoot(String? name, String path, Element element) {
    final label = switch (name) {
      'any' => 'Ack.any()',
      'anyOf' => 'Ack.anyOf()',
      'instance' => 'bare Ack.instance<T>()',
      null => 'an unresolvable dynamic schema factory',
      _ => 'Ack.$name()',
    };
    throw InvalidGenerationSource(
      '$path uses unsupported $label; it cannot provide a static model shape.',
      element: element,
    );
  }

  Future<void> _rejectObjectShapeChanges(
    Expression expression, {
    required String path,
    required Element context,
    Set<Element> visited = const {},
  }) async {
    Expression? current = expression;
    while (current is ParenthesizedExpression) {
      current = current.expression;
    }
    while (current is MethodInvocation) {
      final name = current.methodName.name;
      // A value codec owns its runtime shape, so its input need not expose
      // statically generated object fields.
      if (name == 'codec') return;
      if (const {'extend', 'partial', 'merge', 'pick', 'omit'}.contains(name) ||
          (name == 'copyWith' &&
              current.argumentList.arguments.any(
                (argument) => const {
                  'properties',
                  'schemas',
                  'discriminatorKey',
                }.contains(namedArgument(argument)?.name),
              ))) {
        throw InvalidGenerationSource(
          '$path uses .$name(...), which changes the object shape and cannot '
          'be modeled statically. Declare the final shape in literal '
          'Ack.object({...}) or Ack.discriminated(...) arguments instead.',
          element: context,
        );
      }
      if (isAckTarget(current.target)) return;
      if (current.methodName.element is TopLevelFunctionElement ||
          isTypeOwnedSchema(current.methodName.element)) {
        break;
      }
      current = current.target;
    }
    if (current == null) return;
    final target = await resolveReferencedTopLevelExpression(
      memberElement(current) ?? referencedElement(current),
      visited: visited,
    );
    if (target == null) return;
    await _rejectObjectShapeChanges(
      target.expression,
      path: '$path(→ ${target.declaration.name})',
      context: context,
      visited: {...visited, target.declaration.baseElement},
    );
  }

  Future<bool> _additionalProperties(
    Expression expression, {
    required String path,
    required Element context,
    Set<Element> visited = const {},
  }) async {
    Expression? current = expression;
    while (current is MethodInvocation) {
      final name = current.methodName.name;
      // The outermost policy wins; an earlier dynamic value is irrelevant
      // when strict() or passthrough() replaces it.
      if (name == 'strict') return false;
      if (name == 'passthrough') return true;
      if (name == 'object' || name == 'copyWith') {
        for (final argument in current.argumentList.arguments) {
          final entry = namedArgument(argument);
          if (entry?.name != 'additionalProperties') continue;
          if (entry!.expression is NullLiteral && name == 'copyWith') continue;
          final value = constantBool(entry.expression);
          if (value != null) return value;
          throw InvalidGenerationSource(
            '$path additionalProperties must be a bool literal or const '
            'variable reference.',
            element: context,
          );
        }
      }
      if (isAckTarget(current.target)) return false;
      current = current.target;
    }
    if (current == null) return false;
    if (current is ParenthesizedExpression) {
      return _additionalProperties(
        current.expression,
        path: path,
        context: context,
        visited: visited,
      );
    }
    final referenced = referencedElement(current);
    final target = await resolveReferencedTopLevelExpression(
      referenced,
      visited: visited,
    );
    if (target == null) return false;
    return _additionalProperties(
      target.expression,
      path: path,
      context: context,
      visited: {...visited, target.declaration.baseElement},
    );
  }

  Future<_SchemaMetadata> _schemaMetadata(
    Expression expression, {
    required String path,
    required Element context,
    Set<Element> visited = const {},
  }) async {
    if (expression is ParenthesizedExpression) {
      return _schemaMetadata(
        expression.expression,
        path: path,
        context: context,
        visited: visited,
      );
    }
    if (expression is MethodInvocation) {
      final name = expression.methodName.name;
      final arguments = expression.argumentList.arguments;
      Expression? named(String key) {
        for (final argument in arguments) {
          final entry = namedArgument(argument);
          if (entry?.name == key) return entry!.expression;
        }
        return null;
      }

      bool flag(Expression value, String option) {
        final resolved = constantBool(value);
        if (resolved != null) return resolved;
        throw InvalidGenerationSource(
          '$path $option must be a bool literal or const variable reference.',
          element: context,
        );
      }

      if (isAckTarget(expression.target)) {
        final input = name == 'codec'
            ? named('input')
            : name == 'preserveBoundary'
            ? argumentExpressions(expression.argumentList).firstOrNull
            : null;
        if (input != null) {
          return (await _schemaMetadata(
            input,
            path: path,
            context: context,
            visited: visited,
          )).wrapped;
        }
        // Factories, including Ack.lazy, start with their own unset flags.
        return const _SchemaMetadata();
      }

      final target = expression.target;
      if (target != null && !isTypeOwnedSchema(expression.methodName.element)) {
        final inner = await _schemaMetadata(
          target,
          path: path,
          context: context,
          visited: visited,
        );
        switch (name) {
          case 'nullable':
            final value = named('value');
            return inner.copyWith(
              nullable: value == null ? true : flag(value, 'nullable value'),
            );
          case 'optional':
            final value = named('value');
            return inner.copyWith(
              optional: value == null ? true : flag(value, 'optional value'),
            );
          case 'withDefault':
            return _SchemaMetadata(
              optional: inner.optional,
              nullable: inner.nullable,
              defaulted: true,
              innerOptional: inner.optional,
              innerNullable: inner.nullable,
            );
          case 'codec' || 'transform':
            return inner.wrapped;
          case 'copyWith' || 'withRuntimeConfig' || 'extend':
            final nullable = named('isNullable');
            final optional = named('isOptional');
            return inner.copyWith(
              nullable: nullable == null || nullable is NullLiteral
                  ? null
                  : flag(nullable, '$name isNullable'),
              optional: optional == null || optional is NullLiteral
                  ? null
                  : flag(optional, '$name isOptional'),
            );
          default:
            return inner;
        }
      }
    }

    final element = memberElement(expression) ?? referencedElement(expression);
    final declaration = element == null ? null : propertyDeclaration(element);
    if (declaration == null ||
        visited.contains(declaration.baseElement) ||
        visited.length >= ModelGraphBuilderBase.maxReferenceDepth) {
      // Shape/type resolution owns cycle and depth diagnostics. Do not hide
      // its actionable alias trace while resolving only metadata.
      return const _SchemaMetadata();
    }
    final owningLibrary = declaration.library;
    if (owningLibrary == null) return const _SchemaMetadata();
    final initializer = declarationExpression(
      await resolvedLibraryFor(owningLibrary),
      declaration,
    );
    if (initializer == null) return const _SchemaMetadata();
    return _schemaMetadata(
      initializer,
      path: path,
      context: context,
      visited: {...visited, declaration.baseElement},
    );
  }
}
