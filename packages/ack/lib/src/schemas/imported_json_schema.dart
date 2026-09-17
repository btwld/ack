part of 'schema.dart';

/// An identity boundary/runtime schema compiled by [importJsonSchema].
///
/// It uses JSON semantics rather than Dart factory defaults: property presence
/// is independent of nullability, integers include integral doubles, and
/// type-specific keywords do not themselves require that type. Parsing returns
/// a detached, recursively unmodifiable JSON value; encoding preserves it.
@immutable
@internal
final class ImportedJsonSchema extends AckSchema<Object, Object>
    with FluentSchema<Object, Object, ImportedJsonSchema> {
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
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Expected an acyclic JSON value with finite numbers.',
          context: context,
        ),
      );
    }
    final violation = _checkImportedNode(_root, value);
    if (violation != null) {
      var errorContext = context;
      for (final segment in violation.path) {
        final childValue = switch (errorContext.value) {
          final Map parent => parent[segment],
          final List parent => parent[int.parse(segment)],
          _ => null,
        };
        errorContext = errorContext.createChild(
          name: segment,
          schema: this,
          value: childValue,
          pathSegment: segment,
        );
      }
      return SchemaResult.fail(
        SchemaValidationError(
          message: violation.message,
          context: errorContext,
        ),
      );
    }
    return applyConstraintsAndRefinements(value!, context);
  }

  @override
  @protected
  SchemaResult<Object> parseWithContext(Object? value, SchemaContext context) {
    final result = validateRuntimeWithContext(value, context);
    if (result.isFail) return result;
    return SchemaResult.ok(cloneDefault(result.getOrNull()));
  }

  /// Builds root-scoped definitions for the shared schema-model renderer.
  @internal
  Map<String, JsonSchema> exportDefinitions(String prefix) {
    final names = <_ImportedNode, String>{};
    void visit(_ImportedNode node) {
      if (names.containsKey(node)) return;
      names[node] = '$prefix${names.length}';
      for (final child in node.dependencies) {
        visit(child);
      }
    }

    visit(_root);
    return {
      for (final entry in names.entries)
        entry.value: JsonSchema.fromMap(
          entry.key.render((node) => names[node]!),
        ),
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
  const _ImportViolation(this.message, [this.path = const []]);
  final String message;
  final List<String> path;

  _ImportViolation at(String segment) =>
      _ImportViolation(message, [segment, ...path]);
}

_ImportViolation? _checkImportedNode(_ImportedNode node, Object? value) {
  _ImportViolation fail(String keyword) => _ImportViolation(
    'JSON Schema "$keyword" failed at ${node.documentUri}${node.pointer}.',
  );
  if (node.source == false) return fail('false');
  final keywords = node.keywords;
  if (keywords['type'] case final type?) {
    final types = type is List ? type : [type];
    if (!types.any(
      (t) => switch (t) {
        'null' => value == null,
        'string' => value is String,
        'boolean' => value is bool,
        'integer' => value is num && value.isFinite && value % 1 == 0,
        'number' => value is num && value.isFinite,
        'array' => value is List,
        'object' => value is Map,
        _ => false,
      },
    )) {
      return fail('type');
    }
  }
  if (keywords.containsKey('const') && !deepEquals(value, keywords['const'])) {
    return fail('const');
  }
  if (keywords['enum'] case final List values) {
    if (!values.any((v) => deepEquals(v, value))) return fail('enum');
  }
  if (node.reference case final target?) {
    final error = _checkImportedNode(target, value);
    if (error != null) return error;
  }
  for (final target in node.lists['allOf'] ?? const <_ImportedNode>[]) {
    final error = _checkImportedNode(target, value);
    if (error != null) return error;
  }
  if (node.lists['anyOf'] case final branches?) {
    if (!branches.any((n) => _checkImportedNode(n, value) == null)) {
      return fail('anyOf');
    }
  }
  if (node.lists['oneOf'] case final branches?) {
    if (branches.where((n) => _checkImportedNode(n, value) == null).length !=
        1) {
      return fail('oneOf');
    }
  }
  if (node.children['not'] case final target?) {
    if (_checkImportedNode(target, value) == null) return fail('not');
  }
  if (value is num) {
    for (final key in _JsonSchemaCompiler.bounds) {
      if (keywords[key] case final num limit) {
        final valid = switch (key) {
          'minimum' => value >= limit,
          'maximum' => value <= limit,
          'exclusiveMinimum' => value > limit,
          _ => value < limit,
        };
        if (!valid) return fail(key);
      }
    }
  }
  final (length, suffix) = switch (value) {
    String() => (value.runes.length, 'Length'),
    List() => (value.length, 'Items'),
    Map() => (value.length, 'Properties'),
    _ => (null, ''),
  };
  if (length != null) {
    if (keywords['min$suffix'] case final num minimum) {
      if (length < minimum) return fail('min$suffix');
    }
    if (keywords['max$suffix'] case final num maximum) {
      if (length > maximum) return fail('max$suffix');
    }
  }
  if (value is Map) {
    for (final key in keywords['required'] as List? ?? const []) {
      if (!value.containsKey(key)) return fail('required').at(key as String);
    }
    final properties = node.maps['properties'] ?? const {};
    for (final entry in value.entries) {
      final target =
          properties[entry.key] ?? node.children['additionalProperties'];
      if (target == null) continue;
      final error = _checkImportedNode(target, entry.value);
      if (error != null) return error.at(entry.key as String);
    }
  }
  if (value is List) {
    if (keywords['uniqueItems'] == true) {
      for (var i = 0; i < value.length; i++) {
        for (var j = 0; j < i; j++) {
          if (deepEquals(value[i], value[j])) {
            return fail('uniqueItems').at('$i');
          }
        }
      }
    }
    if (node.children['items'] case final target?) {
      for (var i = 0; i < value.length; i++) {
        final error = _checkImportedNode(target, value[i]);
        if (error != null) return error.at('$i');
      }
    }
  }
  return null;
}
