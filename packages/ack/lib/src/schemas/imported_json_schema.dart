part of 'schema.dart';

/// An identity boundary/runtime schema compiled by `Ack.fromJsonSchema`.
///
/// It uses JSON semantics rather than Dart factory defaults: property presence
/// is independent of nullability, integers include integral doubles, and
/// type-specific keywords do not themselves require that type. Parsing returns
/// a detached, recursively unmodifiable JSON value; encoding preserves it.
@immutable
@internal
final class ImportedJsonSchema extends AckSchema<Object, Object>
    with FluentSchema<Object, Object, ImportedJsonSchema> {
  factory ImportedJsonSchema.fromDocument(
    Object document, {
    Uri? baseUri,
    Map<Uri, Object> documents = const {},
  }) {
    final compiler = _JsonSchemaCompiler();
    final base = baseUri ?? Uri.parse('ack-import:///root.json');
    final root = compiler.addDocument(document, base);
    for (final entry in documents.entries) {
      compiler.addDocument(entry.value, base.resolveUri(entry.key));
    }
    compiler.compile(root);
    if (compiler.diagnostics.isNotEmpty) {
      throw JsonSchemaImportException._(compiler.diagnostics);
    }
    return ImportedJsonSchema._(root);
  }

  ImportedJsonSchema._(
    this._root, {
    bool? isNullable,
    super.isOptional,
    String? description,
    super.constraints,
    super.refinements,
  }) : super(
         isNullable: isNullable ?? _checkImportedNode(_root, null) == null,
         description: description ?? _root.keywords['description'] as String?,
       );

  final _ImportedNode _root;

  /// Whether the source document itself accepts `null`, before fluent
  /// nullability overrides are applied.
  @internal
  bool get sourceAllowsNull => _checkImportedNode(_root, null) == null;

  @override
  @protected
  SchemaResult<Object> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    if (!_isImportJson(value, HashSet.identity())) {
      return _failNotImportJson(context);
    }
    return _validateImportJson(value!, context);
  }

  @override
  @protected
  SchemaResult<Object> parseWithContext(Object? value, SchemaContext context) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    final copy = _copyImportJson(value, HashSet.identity());
    if (identical(copy, _notImportJson)) return _failNotImportJson(context);
    return _validateImportJson(copy!, context);
  }

  SchemaResult<Object> _failNotImportJson(SchemaContext context) =>
      SchemaResult.fail(
        SchemaValidationError(
          message: 'Expected an acyclic JSON value with finite numbers.',
          context: context,
        ),
      );

  SchemaResult<Object> _validateImportJson(
    Object value,
    SchemaContext context,
  ) {
    final violation = _checkImportedNode(_root, value);
    if (violation != null) {
      var errorContext = context;
      for (final (index, segment) in violation.path.indexed) {
        final childValue = switch (errorContext.value) {
          final Map parent => parent[segment],
          final List parent => parent[int.parse(segment)],
          _ => null,
        };
        errorContext = errorContext.createChild(
          name: segment,
          schema: this,
          value: index == violation.path.length - 1
              ? violation.invalidPropertyName ?? childValue
              : childValue,
          pathSegment: segment,
        );
      }
      return SchemaResult.fail(
        JsonSchemaValidationError._(
          message: violation.message,
          context: errorContext,
          keyword: violation.keyword,
          documentUri: violation.node.documentUri,
          pointer: _keywordPointer(violation.node, violation.keyword),
          keywordLocation: [
            ...violation.evaluationPath,
            if (violation.keyword.isNotEmpty) violation.keyword,
          ].map((token) => '/${_importPointerToken(token)}').join(),
        ),
      );
    }
    return applyConstraintsAndRefinements(value, context);
  }

  /// Builds root-scoped definitions for the shared schema-model renderer.
  @internal
  Map<String, Map<String, Object?>> exportDefinitions(String prefix) {
    final refs = <_ImportedNode, String>{};
    void visit(_ImportedNode node) {
      if (refs.containsKey(node)) return;
      final name = '$prefix${refs.length}';
      refs[node] = '#/definitions/${_importPointerToken(name)}';
      for (final child in node.dependencies) {
        visit(child);
      }
    }

    visit(_root);
    String refOf(_ImportedNode node) => refs[node]!;
    return {
      for (final (i, node) in refs.keys.indexed)
        '$prefix$i': node.render(refOf),
    };
  }

  @override
  ImportedJsonSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) => ImportedJsonSchema._(
    _root,
    isNullable: isNullable ?? this.isNullable,
    isOptional: isOptional ?? this.isOptional,
    description: description ?? this.description,
    constraints: constraints ?? this.constraints,
    refinements: refinements ?? this.refinements,
  );

  @override
  SchemaType get schemaType => SchemaType.any;
}

final class _ImportViolation {
  const _ImportViolation(
    this.node,
    this.keyword, {
    this.path = const [],
    this.evaluationPath = const [],
    this.invalidPropertyName,
  });
  final _ImportedNode node;

  /// Empty when [node] is the boolean schema `false`.
  final String keyword;
  final List<String> path;
  final List<String> evaluationPath;
  final String? invalidPropertyName;

  String get message =>
      'JSON Schema "${keyword.isEmpty ? 'false' : keyword}" failed at '
      '${node.documentUri}${node.pointer}.';

  _ImportViolation at(String segment, [List<String> tokens = const []]) =>
      _ImportViolation(
        node,
        keyword,
        path: [segment, ...path],
        evaluationPath: [...tokens, ...evaluationPath],
        invalidPropertyName: invalidPropertyName,
      );

  _ImportViolation atPropertyName(String name, List<String> tokens) =>
      _ImportViolation(
        node,
        keyword,
        path: [name, ...path],
        evaluationPath: [...tokens, ...evaluationPath],
        invalidPropertyName: name,
      );

  _ImportViolation via(List<String> tokens) => _ImportViolation(
    node,
    keyword,
    path: path,
    evaluationPath: [...tokens, ...evaluationPath],
    invalidPropertyName: invalidPropertyName,
  );
}

_ImportViolation? _checkImportedNode(_ImportedNode node, Object? value) {
  _ImportViolation fail(String keyword) => _ImportViolation(node, keyword);
  if (node.isFalse) return fail('');
  if (node.types case final types?) {
    if (!types.any((t) => _isImportType(t, value))) return fail('type');
  }
  if (node.hasConst && !deepEquals(value, node.constValue)) {
    return fail('const');
  }
  if (node.enumValues case final values?) {
    if (!values.any((v) => deepEquals(v, value))) return fail('enum');
  }
  if (node.reference case final target?) {
    final error = _checkImportedNode(target, value);
    if (error != null) return error.via(const [r'$ref']);
  }
  if (node.allOf case final targets?) {
    for (final (i, target) in targets.indexed) {
      final error = _checkImportedNode(target, value);
      if (error != null) return error.via(['allOf', '$i']);
    }
  }
  if (node.anyOf case final branches?) {
    if (!branches.any((n) => _checkImportedNode(n, value) == null)) {
      return fail('anyOf');
    }
  }
  if (node.oneOf case final branches?) {
    var matches = 0;
    for (final branch in branches) {
      if (_checkImportedNode(branch, value) == null && ++matches > 1) break;
    }
    if (matches != 1) return fail('oneOf');
  }
  if (node.not case final target?) {
    if (_checkImportedNode(target, value) == null) return fail('not');
  }
  if (node.ifNode case final condition?) {
    final passed = _checkImportedNode(condition, value) == null;
    final branch = passed ? node.thenNode : node.elseNode;
    if (branch != null) {
      final error = _checkImportedNode(branch, value);
      if (error != null) return error.via([passed ? 'then' : 'else']);
    }
  }
  switch (value) {
    case num():
      if (node.minimum case final limit? when value < limit) {
        return fail('minimum');
      }
      if (node.maximum case final limit? when value > limit) {
        return fail('maximum');
      }
      if (node.exclusiveMinimum case final limit? when value <= limit) {
        return fail('exclusiveMinimum');
      }
      if (node.exclusiveMaximum case final limit? when value >= limit) {
        return fail('exclusiveMaximum');
      }
    case String():
      // Counting code points allocates, so only do it when a bound exists.
      if (node.minLength != null || node.maxLength != null) {
        final keyword = _sizeViolation(
          value.runes.length,
          node.minLength,
          node.maxLength,
          'minLength',
          'maxLength',
        );
        if (keyword != null) return fail(keyword);
      }
      if (node.dateTime && !isValidRfc3339DateTime(value)) {
        return fail('format');
      }
      if (node.pattern case final pattern? when !pattern.hasMatch(value)) {
        return fail('pattern');
      }
    case Map():
      final keyword = _sizeViolation(
        value.length,
        node.minProperties,
        node.maxProperties,
        'minProperties',
        'maxProperties',
      );
      if (keyword != null) return fail(keyword);
      if (node.required case final required?) {
        for (final key in required) {
          if (!value.containsKey(key)) return fail('required').at(key);
        }
      }
      final properties = node.properties;
      final additional = node.additionalProperties;
      if (properties != null || additional != null) {
        for (final MapEntry(:key, value: item) in value.entries) {
          final declared = properties?[key];
          final target = declared ?? additional;
          if (target == null) continue;
          final error = _checkImportedNode(target, item);
          if (error != null) {
            return error.at(
              key as String,
              declared == null
                  ? const ['additionalProperties']
                  : ['properties', key],
            );
          }
        }
      }
      if (node.propertyNames case final target?) {
        for (final key in value.keys) {
          final error = _checkImportedNode(target, key);
          if (error != null) {
            return error.atPropertyName(key as String, const ['propertyNames']);
          }
        }
      }
    case List():
      final keyword = _sizeViolation(
        value.length,
        node.minItems,
        node.maxItems,
        'minItems',
        'maxItems',
      );
      if (keyword != null) return fail(keyword);
      if (node.uniqueItems) {
        for (var i = 0; i < value.length; i++) {
          for (var j = 0; j < i; j++) {
            if (deepEquals(value[i], value[j])) {
              return fail('uniqueItems');
            }
          }
        }
      }
      if (node.contains case final target?) {
        if (!value.any((item) => _checkImportedNode(target, item) == null)) {
          return fail('contains');
        }
      }
      if (node.items case final target?) {
        for (var i = 0; i < value.length; i++) {
          final error = _checkImportedNode(target, value[i]);
          if (error != null) return error.at('$i', const ['items']);
        }
      }
  }
  return null;
}

/// The failing size keyword, if any.
String? _sizeViolation(
  int size,
  num? min,
  num? max,
  String minKey,
  String maxKey,
) {
  if (min != null && size < min) return minKey;
  if (max != null && size > max) return maxKey;
  return null;
}

bool _isImportType(Object? type, Object? value) => switch (type) {
  'null' => value == null,
  'string' => value is String,
  'boolean' => value is bool,
  'integer' => value is num && value.isFinite && value % 1 == 0,
  'number' => value is num && value.isFinite,
  'array' => value is List,
  'object' => value is Map,
  _ => false,
};
