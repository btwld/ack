import 'package:ack/ack.dart'
    show AckSchema, AnyOfSchema, AnySchema, InstanceSchema, MapSchema;
import 'package:ack/annotations.dart' hide AckUnknownPropertyPolicy;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';
import 'generated_companion_visibility.dart';
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

final class _SchemaChain {
  const _SchemaChain({
    required this.base,
    required this.reference,
    required this.optional,
    required this.nullable,
    required this.defaulted,
    required this.hasTransform,
    required this.hasCodec,
  });

  final MethodInvocation? base;
  final Expression? reference;
  final bool optional;
  final bool nullable;
  final bool defaulted;
  final bool hasTransform;
  final bool hasCodec;
}

typedef _SchemaTypes = ({AckInferRef boundary, AckInferRef runtime});

/// Builds the single normalized graph consumed by Ack model emission.
final class SchemaModelGraphBuilder {
  SchemaModelGraphBuilder(this.library);

  static const _reservedMembers = ackSchemaFirstReservedMembers;
  static const _dartKeywords = ackDartReservedWords;

  static const _oneWayTransformMethods = {'transform'};

  static const _maxReferenceDepth = 16;

  static const _schemableChecker = TypeChecker.typeNamed(
    Schemable,
    inPackage: 'ack',
  );
  static const _ackSchemaChecker = TypeChecker.typeNamed(
    AckSchema,
    inPackage: 'ack',
  );
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

  final LibraryReader library;
  final AckModelGraph _graph = AckModelGraph();
  final Map<Element, _Declaration> _declarationsByElement = {};
  final Map<AckSchemaId, _Declaration> _declarationsById = {};
  final Map<AckSchemaId, AckSchemaId> _unionOwnerByBranch = {};
  ResolvedLibraryResult? _inputResolved;
  final Map<Uri, ResolvedLibraryResult> _resolvedByUri = {};

  Future<AckModelGraph> build(List<Element> annotatedElements) async {
    final libraryElement = library.element;
    final resolved = await libraryElement.session.getResolvedLibraryByElement(
      libraryElement,
    );
    if (resolved is! ResolvedLibraryResult) {
      throw InvalidGenerationSource(
        'Could not resolve ${libraryElement.uri} for Ack model generation.',
      );
    }
    _inputResolved = resolved;
    _resolvedByUri[libraryElement.uri] = resolved;

    for (final element in annotatedElements) {
      _rejectClassOnlyOptions(element);
      final expression = _declarationExpression(resolved, element);
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
          _annotationName(element),
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
    return _graph;
  }

  void _rejectClassOnlyOptions(Element element) {
    final annotation = _schemableChecker.firstAnnotationOfExact(
      _propertyDeclaration(element),
    );
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

  Expression? _declarationExpression(
    ResolvedLibraryResult result,
    Element element,
  ) {
    final declaration = result.getFragmentDeclaration(element.firstFragment);
    final node = declaration?.node;
    if (node is VariableDeclaration) return node.initializer;
    if (node is FunctionDeclaration) {
      return _functionBodyExpression(node.functionExpression.body);
    }
    return null;
  }

  Expression? _functionBodyExpression(FunctionBody body) {
    if (body is ExpressionFunctionBody) return body.expression;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      final statement = body.block.statements.single;
      if (statement is ReturnStatement) return statement.expression;
    }
    return null;
  }

  Future<ResolvedLibraryResult> _resolvedLibraryFor(
    LibraryElement libraryElement,
  ) async {
    if (identical(libraryElement, library.element) && _inputResolved != null) {
      return _inputResolved!;
    }
    final cached = _resolvedByUri[libraryElement.uri];
    if (cached != null) return cached;
    final resolved = await libraryElement.session.getResolvedLibraryByElement(
      libraryElement,
    );
    if (resolved is! ResolvedLibraryResult) {
      throw InvalidGenerationSource(
        'Could not resolve ${libraryElement.uri} for Ack model generation.',
      );
    }
    _resolvedByUri[libraryElement.uri] = resolved;
    return resolved;
  }

  Future<void> _resolve(
    _Declaration declaration, {
    required bool throughLazy,
    required String path,
  }) async {
    switch (_graph.stateOf(declaration.id)) {
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

    _graph.begin(declaration.id);
    final chain = _chain(declaration.expression);
    _rejectTransform(chain, path, declaration.element);
    if (chain.nullable) {
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
        _isCrossLibraryAckInfer(chain.reference!)) {
      throw InvalidGenerationSource(
        '$path aliases a cross-library '
        '${_annotationLabel(_referencedElement(chain.reference!)!)} schema. '
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
    _graph.complete(node);
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
      description: _description(expression),
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
    final source = _graph.nodeFor(target.id)!;
    if (source is AckObjectModelNode) {
      return AckObjectModelNode(
        id: declaration.id,
        className: declaration.className,
        boundaryType: source.boundaryType,
        runtimeRef: source.runtimeRef,
        fields: source.fields,
        unknownPropertyPolicy: source.unknownPropertyPolicy,
        captureFieldName: source.captureFieldName,
        captureJsonKey: source.captureJsonKey,
        constructorParameters: source.constructorParameters,
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
    return AckValueModelNode(
      id: declaration.id,
      className: declaration.className,
      boundaryType: source.boundaryType,
      runtimeRef: source.runtimeRef,
      description: source.description,
    );
  }

  Future<AckObjectModelNode> _objectNode(
    _Declaration declaration,
    _SchemaChain chain,
    String path,
  ) async {
    final invocation = chain.base!;
    final arguments = _argumentExpressions(invocation.argumentList);
    if (arguments.isEmpty || arguments.first is! SetOrMapLiteral) {
      throw InvalidGenerationSource(
        '$path must use a map literal in Ack.object(...).',
        element: declaration.element,
      );
    }
    final literal = arguments.first as SetOrMapLiteral;
    final additionalProperties = _additionalProperties(
      declaration.expression,
      path: path,
      element: declaration.element,
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
      _rejectInvalidMemberName(jsonKey, path, declaration.element);
      if (_reservedMembers.contains(jsonKey)) {
        throw InvalidGenerationSource(
          '$path.$jsonKey conflicts with generated/Object member "$jsonKey".',
          element: declaration.element,
        );
      }
      if (additionalProperties && jsonKey == 'additionalProperties') {
        throw InvalidGenerationSource(
          '$path.$jsonKey conflicts with the generated additional-properties '
          'member.',
          element: declaration.element,
        );
      }
      final fieldPath = '$path.$jsonKey';
      final fieldChain = _chain(entry.value);
      _rejectTransform(fieldChain, fieldPath, declaration.element);
      if (fieldChain.base?.methodName.name == 'object') {
        throw InvalidGenerationSource(
          '$fieldPath uses an anonymous inline Ack.object(...).',
          element: declaration.element,
          todo: 'Extract it to a named @Schemable schema declaration.',
        );
      }
      fields.add(
        AckFieldNode(
          dartName: jsonKey,
          jsonKey: jsonKey,
          presence: _fieldPresence(fieldChain),
          nullable: fieldChain.nullable,
          runtimeRef: await _runtimeRefForSchema(
            entry.value,
            path: fieldPath,
            context: declaration.element,
            throughLazy: false,
          ),
          description: _description(entry.value),
        ),
      );
    }
    final types = _schemaTypes(
      declaration.expression,
      path,
      declaration.element,
    );
    return AckObjectModelNode(
      id: declaration.id,
      className: declaration.className,
      boundaryType: types.boundary,
      runtimeRef: types.runtime,
      fields: fields,
      constructorParameters: _schemaFirstConstructorParameters(
        fields,
        capture: additionalProperties,
      ),
      unknownPropertyPolicy: additionalProperties
          ? AckUnknownPropertyPolicy.capture
          : AckUnknownPropertyPolicy.reject,
      captureFieldName: additionalProperties ? 'additionalProperties' : null,
      captureJsonKey: additionalProperties ? 'additionalProperties' : null,
      description: _description(declaration.expression),
    );
  }

  Future<AckUnionModelNode> _unionNode(
    _Declaration declaration,
    _SchemaChain chain,
    String path,
  ) async {
    String? discriminatorKey;
    SetOrMapLiteral? branchesLiteral;
    for (final argumentNode in chain.base!.argumentList.arguments) {
      final argument = _namedArgument(argumentNode);
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
      final branch = _graph.nodeFor(target.id);
      if (branch is! AckObjectModelNode) {
        throw InvalidGenerationSource(
          '$path.$value must reference an '
          '${_annotationLabel(declaration.element)} object schema.',
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
      _graph.replace(
        AckObjectModelNode(
          id: branch.id,
          className: branch.className,
          boundaryType: branch.boundaryType,
          runtimeRef: branch.runtimeRef,
          fields: branch.fields,
          constructorParameters: branch.constructorParameters,
          unknownPropertyPolicy: branch.unknownPropertyPolicy,
          captureFieldName: branch.captureFieldName,
          captureJsonKey: branch.captureJsonKey,
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
    final types = _schemaTypes(
      declaration.expression,
      path,
      declaration.element,
    );
    return AckUnionModelNode(
      id: declaration.id,
      className: declaration.className,
      boundaryType: types.boundary,
      runtimeRef: types.runtime,
      discriminatorKey: discriminatorKey,
      branches: branches,
      description: _description(declaration.expression),
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
    final chain = _chain(expression);
    _rejectTransform(chain, path, context);
    if (collectionElement && chain.nullable) {
      throw InvalidGenerationSource(
        '$path uses nullable collection elements. Ack.list does not support '
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
        return const AckScalarTypeRef('Object');
      case 'anyOf':
      case 'instance':
        _rejectUnsupportedRoot(baseName, path, context);
      case 'map':
        final arguments = _argumentExpressions(chain.base!.argumentList);
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
        final nullableValue = await _isNullableSchema(arguments.first);
        return AckMapTypeRef(
          nullableValue && valueType is! AckNullableTypeRef
              ? AckNullableTypeRef(valueType)
              : valueType,
        );
      case 'list':
        final arguments = _argumentExpressions(chain.base!.argumentList);
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
        final arguments = _argumentExpressions(chain.base!.argumentList);
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
      final classFirst = _classFirstModelReference(reference, context);
      if (classFirst != null) return classFirst;
      final member = _memberElement(reference);
      if (_isTypeOwnedSchema(member)) {
        final owner = member!.enclosingElement! as InterfaceElement;
        // A class-first model's own schema may point at a facade generated
        // in this build, so its type is the model rather than the static's.
        if (owner is ClassElement && _classFirstFacadeName(owner) != null) {
          return AckExternalTypeRef(
            name: owner.name!,
            importPrefix: _visiblePrefix(owner, path, context),
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
          collectionElement: collectionElement,
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
    required bool collectionElement,
  }) async {
    final element = _referencedElement(reference);
    if (element == null) return null;
    if (element is! TopLevelVariableElement && element is! GetterElement) {
      return null;
    }
    if (_hasAckInfer(element)) return null;
    if (depth >= _maxReferenceDepth) {
      throw InvalidGenerationSource(
        '$path exceeds schema reference depth $_maxReferenceDepth.',
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
    final declaration = _propertyDeclaration(element);
    final owningLibrary = declaration.library;
    if (owningLibrary == null) return null;
    final resolved = await _resolvedLibraryFor(owningLibrary);
    final initializer = _declarationExpression(resolved, declaration);
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
      collectionElement: collectionElement,
    );
  }

  /// Whether [expression] marks its schema `.nullable()`, following
  /// unannotated variable references such as `Ack.map(nullableLabel)`.
  Future<bool> _isNullableSchema(Expression expression, {int depth = 0}) async {
    final chain = _chain(expression);
    if (chain.nullable) return true;
    final reference = chain.reference;
    if (chain.base != null ||
        reference == null ||
        depth >= _maxReferenceDepth) {
      return false;
    }
    final element = _referencedElement(reference);
    if (element == null ||
        (element is! TopLevelVariableElement && element is! GetterElement)) {
      return false;
    }
    final declaration = _propertyDeclaration(element);
    final owningLibrary = declaration.library;
    if (owningLibrary == null) return false;
    final initializer = _declarationExpression(
      await _resolvedLibraryFor(owningLibrary),
      declaration,
    );
    return initializer != null &&
        await _isNullableSchema(initializer, depth: depth + 1);
  }

  Future<AckInferRef> _lazyType(
    MethodInvocation invocation,
    String path,
    Element context,
  ) async {
    final arguments = _argumentExpressions(invocation.argumentList);
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
    final body = callback.body;
    Expression? target;
    if (body is ExpressionFunctionBody) target = body.expression;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      final statement = body.block.statements.single;
      if (statement is ReturnStatement) target = statement.expression;
    }
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
        '$path Ack.lazy must resolve to a named ${_annotationLabel(context)} '
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
    final element = _referencedElement(expression);
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
    if (!_hasAckInfer(element)) return null;
    final declaration = _propertyDeclaration(element);
    final name = declaration.name;
    final owningLibrary = declaration.library;
    if (name == null || owningLibrary == null) return null;
    final className = _className(
      name,
      _annotationName(declaration),
      declaration,
    );
    final prefix = _expressionPrefix(expression);
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
    if (declaration.library == library.element) return;
    final declarationName = declaration.name;
    if (declarationName == null) return;
    var declarationVisible = false;
    var generatedModelVisible = false;
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final importPrefix = import.prefix?.element.name;
      if (importPrefix != prefix) continue;
      final candidate = prefix == null
          ? import.namespace.get2(declarationName)
          : import.namespace.getPrefixed2(prefix, declarationName);
      if (candidate != null &&
          _propertyDeclaration(candidate).baseElement ==
              declaration.baseElement) {
        declarationVisible = true;
      }
      if (importExposesGeneratedCompanion(
        import,
        definingLibrary: declaration.library!,
        generatedName: className,
      )) {
        generatedModelVisible = true;
      }
    }
    if (declarationVisible && generatedModelVisible) return;
    if (declarationVisible) {
      throw InvalidGenerationSource(
        '$path resolves to generated model "$className", which is hidden by '
        'an import combinator or an upstream export combinator. Expose both '
        '$declarationName and $className through the full import route.',
        element: context,
      );
    }
  }

  AckExternalTypeRef? _classFirstModelReference(
    Expression expression,
    Element context,
  ) {
    final match = RegExp(
      r'^(?:([A-Za-z$][A-Za-z0-9_$]*)\.)?'
      r'([A-Z][A-Za-z0-9_$]*)\.schema$',
    ).firstMatch(expression.toSource());
    if (match == null) return null;
    final prefix = match.group(1);
    final facadeName = match.group(2)!;
    final matches = <ClassElement>{};
    final candidates = <ClassElement>{};
    final visibleModels = <ClassElement>{};
    String? hiddenModelName;

    void consider(ClassElement element) {
      final generatedFacade = _classFirstFacadeName(element);
      if (generatedFacade != facadeName) return;
      candidates.add(element);
    }

    if (prefix == null) {
      for (final element in library.element.classes) {
        if (_classFirstFacadeName(element) == facadeName) {
          matches.add(element);
        }
      }
    }
    final imports = <LibraryImport>[];
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final importPrefix = import.prefix?.element.name;
      if (importPrefix != prefix) continue;
      imports.add(import);
      final importedLibrary = import.importedLibrary;
      if (importedLibrary == null) continue;
      for (final element in _classesInExportClosure(importedLibrary)) {
        consider(element);
        final modelName = element.name;
        if (modelName == null) continue;
        final visible = prefix == null
            ? import.namespace.get2(modelName)
            : import.namespace.getPrefixed2(prefix, modelName);
        if (visible?.baseElement == element.baseElement) {
          visibleModels.add(element);
        }
      }
    }
    for (final target in candidates) {
      final facadeVisible = imports.any(
        (import) => importExposesGeneratedCompanion(
          import,
          definingLibrary: target.library,
          generatedName: facadeName,
        ),
      );
      if (visibleModels.contains(target) && facadeVisible) {
        matches.add(target);
      } else {
        hiddenModelName = target.name;
      }
    }
    if (matches.isEmpty) {
      if (hiddenModelName != null) {
        throw InvalidGenerationSource(
          'Generated facade "$facadeName" is hidden by an import combinator '
          'or an upstream export combinator. Expose both $hiddenModelName and '
          '$facadeName through the full import route.',
          element: context,
        );
      }
      return null;
    }
    if (matches.length > 1) {
      throw InvalidGenerationSource(
        'Generated facade reference ${expression.toSource()} is ambiguous.',
        element: context,
      );
    }
    final target = matches.single;
    return AckExternalTypeRef(name: target.name!, importPrefix: prefix);
  }

  Iterable<ClassElement> _classesInExportClosure(LibraryElement root) sync* {
    final pending = <LibraryElement>[root];
    final visited = <Uri>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current.uri)) continue;
      yield* current.classes;
      for (final export in current.firstFragment.libraryExports) {
        if (export.exportedLibrary case final exported?) {
          pending.add(exported);
        }
      }
    }
  }

  String? _classFirstFacadeName(ClassElement element) {
    final annotation = _schemableChecker.firstAnnotationOfExact(element);
    if (annotation != null) {
      final value = ConstantReader(annotation).read('schemaName');
      return ackClassSchemaFacadeName(
        element.name!,
        override: value.isNull ? null : value.stringValue,
      );
    }
    final isImplicitUnionBranch = element.allSupertypes.any((supertype) {
      final base = supertype.element;
      return base is ClassElement &&
          base.library == element.library &&
          base.isSealed &&
          _schemableChecker.hasAnnotationOfExact(base);
    });
    return isImplicitUnionBranch
        ? ackClassSchemaFacadeName(element.name!)
        : null;
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
    final InterfaceElement? ackElement = _isAckSchema(type)
        ? type.element
        : type.element.allSupertypes.where(_isAckSchema).firstOrNull?.element;
    final ackInfer = ackElement == null ? null : type.asInstanceOf(ackElement);
    if (ackInfer == null || ackInfer.typeArguments.length != 2) {
      throw InvalidGenerationSource(
        '$path does not resolve to AckSchema<Boundary, Runtime>.',
        element: context,
      );
    }
    return (
      boundary: _typeRef(ackInfer.typeArguments[0], path, context),
      runtime: _typeRef(ackInfer.typeArguments[1], path, context),
    );
  }

  bool _isAckSchema(InterfaceType type) {
    return _ackSchemaChecker.isExactlyType(type);
  }

  AckInferRef _typeArgumentRef(DartType type, String path, Element context) =>
      type is VoidType
      ? const AckExternalTypeRef(name: 'void')
      : _typeRef(type, path, context);

  AckInferRef _typeRef(DartType type, String path, Element context) {
    if (type is DynamicType) {
      return const AckNullableTypeRef(AckScalarTypeRef('Object'));
    }
    if (type is TypeParameterType) {
      return AckExternalTypeRef(name: type.element.name ?? 'Object');
    }
    if (type is! InterfaceType) {
      throw InvalidGenerationSource(
        'Unsupported runtime type ${type.getDisplayString()}.',
        element: context,
      );
    }
    final nullable = type.nullabilitySuffix == NullabilitySuffix.question;
    final name = type.element.name ?? type.getDisplayString();
    AckInferRef result;
    if (type.isDartCoreList && type.typeArguments.length == 1) {
      result = AckListTypeRef(
        _typeRef(type.typeArguments.single, path, context),
      );
    } else if (type.isDartCoreSet && type.typeArguments.length == 1) {
      result = AckSetTypeRef(
        _typeRef(type.typeArguments.single, path, context),
      );
    } else if (type.isDartCoreMap && type.typeArguments.length == 2) {
      final keyType = type.typeArguments.first;
      if (keyType is! InterfaceType || !keyType.isDartCoreString) {
        throw InvalidGenerationSource(
          'Generated Ack models support only Map<String, T> runtime types; '
          'received ${type.getDisplayString()}.',
          element: context,
          todo:
              'Use a string-keyed map or codec the value to a supported '
              'runtime type before generating the model.',
        );
      }
      result = AckMapTypeRef(_typeRef(type.typeArguments[1], path, context));
    } else if (type.element.library.uri.toString() == 'dart:core' &&
        const {
          'String',
          'int',
          'double',
          'num',
          'bool',
          'Object',
        }.contains(name)) {
      result = AckScalarTypeRef(name);
    } else {
      result = AckExternalTypeRef(
        name: name,
        importPrefix: _visiblePrefix(type.element, path, context),
        typeArguments: [
          for (final argument in type.typeArguments)
            _typeArgumentRef(argument, path, context),
        ],
      );
    }
    return nullable ? AckNullableTypeRef(result) : result;
  }

  /// The import prefix that names [target] in this library, or null when an
  /// unprefixed name reaches it.
  ///
  /// Throws when [target] is not visible, because a part cannot add imports.
  String? _visiblePrefix(
    InterfaceElement target,
    String path,
    Element context,
  ) {
    if (target.library == library.element) return null;
    final name = target.name;
    if (name == null) return null;
    String? prefixed;
    var unprefixed = false;
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) {
        continue;
      }
      final prefix = import.prefix?.element.name;
      final candidate = prefix == null
          ? import.namespace.get2(name)
          : import.namespace.getPrefixed2(prefix, name);
      if (candidate != target) continue;
      if (prefix != null && prefix.isNotEmpty) {
        prefixed ??= prefix;
      } else {
        unprefixed = true;
      }
    }
    if (prefixed != null || unprefixed) return prefixed;
    if (library.element.firstFragment.scope.lookup(name).getter == target) {
      return null;
    }
    throw InvalidGenerationSource(
      '$path uses $name, which is not visible in this library. Import '
      '${target.library.uri}.',
      element: context,
    );
  }

  _SchemaChain _chain(Expression expression) {
    if (expression is! MethodInvocation) {
      return _SchemaChain(
        base: null,
        reference: expression,
        optional: false,
        nullable: false,
        defaulted: false,
        hasTransform: false,
        hasCodec: false,
      );
    }
    MethodInvocation? current = expression;
    MethodInvocation? base;
    Expression? reference;
    var optional = false;
    var nullable = false;
    var defaulted = false;
    var transform = false;
    var codec = false;
    while (current != null) {
      final name = current.methodName.name;
      optional |= name == 'optional';
      nullable |= name == 'nullable';
      defaulted |= name == 'withDefault';
      transform |= _oneWayTransformMethods.contains(name);
      codec |= name == 'codec';
      if (current.methodName.element is TopLevelFunctionElement ||
          _isTypeOwnedSchema(current.methodName.element)) {
        reference = current;
        break;
      }
      final target = current.target;
      if (_isAckTarget(target)) {
        base = current;
        break;
      }
      if (target is MethodInvocation) {
        current = target;
      } else {
        reference = target;
        break;
      }
    }
    return _SchemaChain(
      base: base,
      reference: reference,
      optional: optional,
      nullable: nullable,
      defaulted: defaulted,
      hasTransform: transform,
      hasCodec: codec,
    );
  }

  bool _isAckTarget(Expression? expression) {
    if (expression is SimpleIdentifier) return expression.name == 'Ack';
    if (expression is PrefixedIdentifier) {
      return expression.identifier.name == 'Ack';
    }
    return false;
  }

  Element? _referencedElement(Expression expression) {
    if (expression is ParenthesizedExpression) {
      return _referencedElement(expression.expression);
    }
    if (expression is SimpleIdentifier) {
      final element = expression.element;
      return element == null ? null : _propertyDeclaration(element);
    }
    if (expression is PrefixedIdentifier) {
      final element = expression.identifier.element;
      return element == null ? null : _propertyDeclaration(element);
    }
    if (expression is MethodInvocation) {
      final method = expression.methodName.element;
      if (method is TopLevelFunctionElement) {
        return _propertyDeclaration(method);
      }
      final chain = _chain(expression);
      final reference = chain.reference;
      return reference == null ? null : _referencedElement(reference);
    }
    return null;
  }

  /// Whether [element] is a static `schema` member that a type declares.
  bool _isTypeOwnedSchema(Element? element) =>
      (element is GetterElement || element is MethodElement) &&
      element is ExecutableElement &&
      element.isStatic &&
      element.name == 'schema' &&
      element.enclosingElement is InterfaceElement;

  Element? _memberElement(Expression expression) => switch (expression) {
    PrefixedIdentifier() => expression.identifier.element,
    PropertyAccess() => expression.propertyName.element,
    MethodInvocation() => expression.methodName.element,
    _ => null,
  };

  Element _propertyDeclaration(Element element) {
    if (element is GetterElement && element.isOriginVariable) {
      return element.variable.baseElement;
    }
    return element.baseElement;
  }

  _Declaration? _localDeclaration(Expression expression) {
    final element = _referencedElement(expression);
    return element == null ? null : _declarationsByElement[element.baseElement];
  }

  bool _isCrossLibraryAckInfer(Expression expression) {
    final element = _referencedElement(expression);
    if (element == null) return false;
    if (_declarationsByElement[element.baseElement] != null) return false;
    return _hasAckInfer(element);
  }

  String? _expressionPrefix(Expression expression) {
    if (expression is PrefixedIdentifier) return expression.prefix.name;
    if (expression is MethodInvocation && expression.target != null) {
      return _expressionPrefix(expression.target!);
    }
    return null;
  }

  bool _hasAckInfer(Element element) {
    final declaration = _propertyDeclaration(element);
    return _schemableChecker.hasAnnotationOfExact(declaration);
  }

  /// The annotation spelling that marks the declaration behind [element].
  String _annotationLabel(Element element) => '@Schemable';

  String? _annotationName(Element element) {
    final declaration = _propertyDeclaration(element);
    final annotation = _schemableChecker.firstAnnotationOfExact(declaration);
    final field = annotation == null
        ? null
        : ConstantReader(annotation).peek('name');
    return field == null || field.isNull ? null : field.stringValue;
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

  AckSchemaFieldPresence _fieldPresence(_SchemaChain chain) {
    if (chain.defaulted) return AckSchemaFieldPresence.defaulted;
    if (chain.optional) return AckSchemaFieldPresence.optional;
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
          'Invalid ${_annotationLabel(element)} name "$customName". Names must '
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
    final localNames = {
      for (final element in library.allElements)
        if (element.name case final name?) name,
    };
    for (final declaration in _declarationsById.values) {
      final name = declaration.className;
      if (!generated.add(name)) {
        throw InvalidGenerationSource(
          'Multiple ${_annotationLabel(declaration.element)} declarations '
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
    final localNames = _localDeclarationNames();
    for (final node in _graph.nodes) {
      final declaration = _declarationsById[node.id];
      if (declaration == null) continue;
      switch (node) {
        case AckUnionModelNode():
        case AckValueModelNode():
          continue;
        case AckObjectModelNode():
          _validateClassHelperNames(
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

  void _validateClassHelperNames({
    required String className,
    required bool needsCopyWithSentinel,
    required Element element,
    required Set<String> localNames,
  }) {
    final sentinelType = ackCopyWithUnsetTypeName(className);
    if (needsCopyWithSentinel && localNames.contains(sentinelType)) {
      throw InvalidGenerationSource(
        'Generated helper "$sentinelType" conflicts with a local declaration.',
        element: element,
      );
    }
    for (final copyWithType in [
      ackCopyWithInterfaceName(className),
      ackCopyWithImplementationName(className),
    ]) {
      if (!localNames.contains(copyWithType)) continue;
      throw InvalidGenerationSource(
        'Generated helper "$copyWithType" conflicts with a local declaration.',
        element: element,
      );
    }
  }

  Set<String> _localDeclarationNames() => {
    for (final element in library.allElements)
      if (element.name case final name?) name,
  };

  void _validateUnionBranchDiscriminator(
    _Declaration branch,
    String discriminatorKey,
    String discriminatorValue,
  ) {
    final chain = _chain(branch.expression);
    final object = chain.base;
    if (object?.methodName.name != 'object') return;
    final arguments = _argumentExpressions(object!.argumentList);
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
    final chain = _chain(expression);
    final base = chain.base;
    if (base == null || !identical(base, expression)) return false;
    final arguments = _argumentExpressions(base.argumentList);
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
        _dartKeywords.contains(jsonKey)) {
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

  void _rejectTransform(_SchemaChain chain, String path, Element element) {
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
    final directChain = _chain(directExpression);
    _rejectTransform(directChain, path, context);

    final referenced = _referencedElement(
      directChain.reference ?? directExpression,
    );
    if (referenced == null) return;
    final declaration = _propertyDeclaration(referenced);
    if (declaration is! TopLevelVariableElement &&
        declaration is! GetterElement &&
        declaration is! TopLevelFunctionElement) {
      return;
    }
    final canonical = declaration.baseElement;
    if (visited.contains(canonical) || visited.length >= _maxReferenceDepth) {
      return;
    }
    final owningLibrary = declaration.library;
    if (owningLibrary == null) return;
    final resolved = await _resolvedLibraryFor(owningLibrary);
    final expression = _declarationExpression(resolved, declaration);
    if (expression == null) return;

    final referencePath = '$path(→ ${declaration.name})';
    final chain = _chain(expression);
    _rejectTransform(chain, referencePath, context);
    await _rejectReferencedTransform(
      chain.reference,
      path: referencePath,
      context: context,
      visited: {...visited, canonical},
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

  bool _additionalProperties(
    Expression expression, {
    required String path,
    required Element element,
  }) {
    Expression? current = expression;
    while (current is MethodInvocation) {
      if (current.methodName.name == 'passthrough') return true;
      if (current.methodName.name == 'object') {
        for (final argumentNode in current.argumentList.arguments) {
          final argument = _namedArgument(argumentNode);
          if (argument != null && argument.name == 'additionalProperties') {
            final value = _constantBool(argument.expression);
            if (value != null) return value;
            throw InvalidGenerationSource(
              '$path additionalProperties must be a bool literal or const '
              'variable reference.',
              element: element,
            );
          }
        }
      }
      current = current.target;
    }
    return false;
  }

  bool? _constantBool(Expression expression) {
    while (expression is ParenthesizedExpression) {
      expression = expression.expression;
    }
    if (expression is BooleanLiteral) return expression.value;

    final element = switch (expression) {
      SimpleIdentifier() => expression.element,
      PrefixedIdentifier() => expression.identifier.element,
      PropertyAccess() => expression.propertyName.element,
      _ => null,
    };
    final declaration = element == null ? null : _propertyDeclaration(element);
    return declaration is VariableElement
        ? declaration.computeConstantValue()?.toBoolValue()
        : null;
  }

  String? _description(Expression expression) {
    Expression? current = expression;
    while (current is MethodInvocation) {
      final arguments = _argumentExpressions(current.argumentList);
      if (current.methodName.name == 'describe' &&
          arguments.firstOrNull is SimpleStringLiteral) {
        return (arguments.first as SimpleStringLiteral).value;
      }
      current = current.target;
    }
    return null;
  }

  /// Normalizes Analyzer 10 argument nodes into the expression API used by the
  /// graph.
  List<Expression> _argumentExpressions(ArgumentList argumentList) =>
      argumentList.arguments
          .map((argument) => _argumentExpression(argument))
          .toList(growable: false);

  Expression _argumentExpression(Expression argument) =>
      argument is NamedExpression ? argument.expression : argument;

  ({String name, Expression expression})? _namedArgument(Expression argument) =>
      argument is NamedExpression
      ? (name: argument.name.label.name, expression: argument.expression)
      : null;
}
