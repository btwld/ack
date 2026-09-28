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
    bool assertFormats = false,
  }) {
    final compiler = _JsonSchemaCompiler(assertFormats: assertFormats);
    final base = baseUri ?? Uri.parse('ack-import:///root.json');
    final root = compiler.addDocument(document, base);
    final externalRoots = <_ImportedNode>[];
    for (final entry in documents.entries) {
      externalRoots.add(
        compiler.addDocument(entry.value, base.resolveUri(entry.key)),
      );
    }
    for (final entry in _standardMetaSchemaDocuments.entries) {
      if (!compiler.resources.containsKey(entry.key)) {
        compiler.addDocument(entry.value, entry.key);
      }
    }
    compiler.compile(root);
    if (compiler.diagnostics.isNotEmpty) {
      throw JsonSchemaImportException._(compiler.diagnostics);
    }
    return ImportedJsonSchema._(
      root,
      externalRoots: externalRoots,
      assertFormats: assertFormats,
    );
  }

  ImportedJsonSchema._(
    this._root, {
    required List<_ImportedNode> externalRoots,
    required bool assertFormats,
    bool? isNullable,
    super.isOptional,
    String? description,
    super.constraints,
    super.refinements,
  }) : _externalRoots = externalRoots,
       _assertFormats = assertFormats,
       super(
         isNullable: isNullable ?? _checkImportedNode(_root, null) == null,
         description: description ?? _root.keywords['description'] as String?,
       );

  final _ImportedNode _root;
  final List<_ImportedNode> _externalRoots;
  final bool _assertFormats;

  static final _assertionDialect = Uri.parse(
    'urn:ack:json-schema:2020-12:format-assertion',
  );

  /// Keeps the documented 1.x Draft-7 definitions/ref export for imports.
  @internal
  Map<String, Map<String, Object?>> exportDefinitions(String prefix) {
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
        entry.value: entry.key.renderLegacy((node) => names[node]!),
    };
  }

  /// Exports the original resources with 2020-12 identity and reference
  /// semantics intact. Supplied documents are embedded as distinct resources.
  @internal
  Map<String, Object?> export2020Document({required int importIndex}) {
    Map<String, Object?> resource(_ImportedNode node, {Uri? syntheticId}) {
      final source = cloneDefault(node.source);
      return {
        if (source is Map<String, Object?>) ...source,
        r'$id': (syntheticId ?? node.baseUri).toString(),
        if (_assertFormats &&
            node.dialectUri == _JsonSchemaCompiler.standardDialect)
          r'$schema': _assertionDialect.toString(),
        if (source is bool) 'allOf': [source],
      };
    }

    final syntheticId =
        _root.documentUri.toString() == 'ack-import:///root.json' &&
            !(_root.source is Map<String, Object?> &&
                (_root.source as Map<String, Object?>).containsKey(r'$id'))
        ? Uri.parse('ack-import:///root-$importIndex.json')
        : null;
    final root = resource(_root, syntheticId: syntheticId);
    root.putIfAbsent(
      r'$schema',
      () => _JsonSchemaCompiler.standardDialect.toString(),
    );
    if (_externalRoots.isNotEmpty || _assertFormats) {
      final definitions = <String, Object?>{
        ...?root[r'$defs'] as Map<String, Object?>?,
      };
      var index = 0;
      var aliasIndex = 0;
      for (final external in _externalRoots) {
        while (definitions.containsKey('_ack_document_$index')) {
          index++;
        }
        final name = '_ack_document_${index++}';
        definitions[name] = resource(external);
        if (external.documentUri != external.baseUri) {
          while (definitions.containsKey('_ack_retrieval_$aliasIndex')) {
            aliasIndex++;
          }
          definitions['_ack_retrieval_${aliasIndex++}'] = {
            r'$id': external.documentUri.toString(),
            r'$ref': external.baseUri.toString(),
          };
        }
      }
      if (_assertFormats) {
        var name = '_ack_format_assertion_dialect';
        while (definitions.containsKey(name)) {
          name = '${name}_';
        }
        definitions[name] = {
          r'$id': _assertionDialect.toString(),
          r'$schema': _JsonSchemaCompiler.standardDialect.toString(),
          r'$vocabulary': {
            for (final uri in _JsonSchemaCompiler.knownVocabularies) uri: true,
          },
          r'$dynamicAnchor': 'meta',
          'allOf': [
            for (final name in [
              'core',
              'applicator',
              'unevaluated',
              'validation',
              'meta-data',
              'format-annotation',
              'format-assertion',
              'content',
            ])
              {r'$ref': 'https://json-schema.org/draft/2020-12/meta/$name'},
          ],
        };
      }
      root[r'$defs'] = definitions;
    }
    if (!isNullable && sourceAllowsNull) {
      root['allOf'] = [
        ...?root['allOf'] as List<Object?>?,
        const {
          'not': {'type': 'null'},
        },
      ];
    }
    return root;
  }

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

  @override
  ImportedJsonSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) => ImportedJsonSchema._(
    _root,
    externalRoots: _externalRoots,
    assertFormats: _assertFormats,
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
    this.message, {
    this.path = const [],
    this.invalidPropertyName,
  });
  final String message;
  final List<String> path;
  final String? invalidPropertyName;

  _ImportViolation at(String segment) => _ImportViolation(
    message,
    path: [segment, ...path],
    invalidPropertyName: invalidPropertyName,
  );

  _ImportViolation atPropertyName(String name) => _ImportViolation(
    message,
    path: [name, ...path],
    invalidPropertyName: name,
  );
}

final class _ImportEvaluation {
  _ImportEvaluation([this.error]);

  final _ImportViolation? error;
  final properties = <String>{};
  final items = <int>{};

  void include(_ImportEvaluation other) {
    properties.addAll(other.properties);
    items.addAll(other.items);
  }
}

_ImportViolation? _checkImportedNode(_ImportedNode node, Object? value) =>
    _evaluateImportedNode(node, value).error;

_ImportEvaluation _evaluateImportedNode(
  _ImportedNode node,
  Object? value, [
  List<_ImportedNode> scope = const [],
]) {
  _ImportEvaluation fail(String keyword) => _ImportEvaluation(
    _ImportViolation(
      'JSON Schema "$keyword" failed at ${node.documentUri}${node.pointer}.',
    ),
  );
  _ImportEvaluation failAt(String keyword, String segment) =>
      _ImportEvaluation(fail(keyword).error!.at(segment));
  final evaluated = _ImportEvaluation();
  final resource = node.resourceRoot;
  final currentScope = scope.isNotEmpty && identical(scope.last, resource)
      ? scope
      : [...scope, resource];
  if (node.source == false) return fail('false');
  final keywords = node.keywords;
  if (node.validationVocabulary) {
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
  }
  if (node.validationVocabulary &&
      keywords.containsKey('const') &&
      !deepEquals(value, keywords['const'])) {
    return fail('const');
  }
  if (node.validationVocabulary) {
    if (keywords['enum'] case final List values) {
      if (!values.any((v) => deepEquals(v, value))) return fail('enum');
    }
  }
  if (node.reference case final target?) {
    final result = _evaluateImportedNode(target, value, currentScope);
    if (result.error != null) return result;
    evaluated.include(result);
  }
  if (node.dynamicReference case final staticTarget?) {
    var target = staticTarget;
    if (node.dynamicReferenceName case final name?) {
      for (final resource in currentScope) {
        if (resource.dynamicAnchors[name] case final override?) {
          target = override;
          break;
        }
      }
    }
    final result = _evaluateImportedNode(target, value, currentScope);
    if (result.error != null) return result;
    evaluated.include(result);
  }
  for (final target in node.lists['allOf'] ?? const <_ImportedNode>[]) {
    final result = _evaluateImportedNode(target, value, currentScope);
    if (result.error != null) return result;
    evaluated.include(result);
  }
  if (node.lists['anyOf'] case final branches?) {
    var success = false;
    for (final branch in branches) {
      final result = _evaluateImportedNode(branch, value, currentScope);
      if (result.error == null) {
        success = true;
        evaluated.include(result);
      }
    }
    if (!success) return fail('anyOf');
  }
  if (node.lists['oneOf'] case final branches?) {
    var successes = 0;
    _ImportEvaluation? matched;
    for (final branch in branches) {
      final result = _evaluateImportedNode(branch, value, currentScope);
      if (result.error == null) {
        successes++;
        matched = result;
      }
    }
    if (successes != 1) return fail('oneOf');
    evaluated.include(matched!);
  }
  if (node.children['not'] case final target?) {
    if (_evaluateImportedNode(target, value, currentScope).error == null) {
      return fail('not');
    }
  }
  if (node.children['if'] case final condition?) {
    final conditionResult = _evaluateImportedNode(
      condition,
      value,
      currentScope,
    );
    if (conditionResult.error == null) evaluated.include(conditionResult);
    final branch = conditionResult.error == null
        ? node.children['then']
        : node.children['else'];
    if (branch != null) {
      final result = _evaluateImportedNode(branch, value, currentScope);
      if (result.error != null) return result;
      evaluated.include(result);
    }
  }
  if (node.validationVocabulary && value is num) {
    if (keywords['multipleOf'] case final num divisor) {
      if (!_isJsonMultipleOf(value, divisor)) return fail('multipleOf');
    }
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
  if (node.validationVocabulary && length != null) {
    if (keywords['min$suffix'] case final num minimum) {
      if (length < minimum) return fail('min$suffix');
    }
    if (keywords['max$suffix'] case final num maximum) {
      if (length > maximum) return fail('max$suffix');
    }
  }
  if (node.validationVocabulary && value is String) {
    if (keywords['pattern'] case final String source) {
      if (!RegExp(source, unicode: true).hasMatch(value)) {
        return fail('pattern');
      }
    }
  }
  if (node.formatAssertion && value is String) {
    if (keywords['format'] case final String format) {
      if (!_isValidJsonSchemaFormat(format, value)) return fail('format');
    }
  }
  if (value is Map) {
    for (final key
        in node.validationVocabulary
            ? keywords['required'] as List? ?? const []
            : const []) {
      if (!value.containsKey(key)) return failAt('required', key as String);
    }
    if (node.validationVocabulary) {
      if (keywords['dependentRequired'] case final Map requirements) {
        for (final entry in requirements.entries) {
          if (!value.containsKey(entry.key)) continue;
          for (final dependent in entry.value as List) {
            if (!value.containsKey(dependent)) {
              return failAt('dependentRequired', dependent as String);
            }
          }
        }
      }
    }
    final properties = node.maps['properties'] ?? const {};
    final patterns = node.maps['patternProperties'] ?? const {};
    for (final entry in value.entries) {
      final key = entry.key as String;
      var matched = false;
      if (properties[key] case final target?) {
        matched = true;
        final result = _evaluateImportedNode(target, entry.value, currentScope);
        if (result.error case final error?) {
          return _ImportEvaluation(error.at(key));
        }
        evaluated.properties.add(key);
      }
      for (final pattern in patterns.entries) {
        if (!RegExp(pattern.key, unicode: true).hasMatch(key)) continue;
        matched = true;
        final result = _evaluateImportedNode(
          pattern.value,
          entry.value,
          currentScope,
        );
        if (result.error case final error?) {
          return _ImportEvaluation(error.at(key));
        }
        evaluated.properties.add(key);
      }
      if (!matched) {
        if (node.children['additionalProperties'] case final target?) {
          final result = _evaluateImportedNode(
            target,
            entry.value,
            currentScope,
          );
          if (result.error case final error?) {
            return _ImportEvaluation(error.at(key));
          }
          evaluated.properties.add(key);
        }
      }
    }
    for (final dependency
        in node.maps['dependentSchemas']?.entries ??
            const <MapEntry<String, _ImportedNode>>[]) {
      if (!value.containsKey(dependency.key)) continue;
      final result = _evaluateImportedNode(
        dependency.value,
        value,
        currentScope,
      );
      if (result.error != null) return result;
      evaluated.include(result);
    }
    if (node.children['propertyNames'] case final target?) {
      for (final key in value.keys) {
        final result = _evaluateImportedNode(target, key, currentScope);
        if (result.error case final error?) {
          return _ImportEvaluation(error.atPropertyName(key as String));
        }
      }
    }
    if (node.children['unevaluatedProperties'] case final target?) {
      for (final entry in value.entries) {
        final key = entry.key as String;
        if (evaluated.properties.contains(key)) continue;
        final result = _evaluateImportedNode(target, entry.value, currentScope);
        if (result.error case final error?) {
          return _ImportEvaluation(error.at(key));
        }
        evaluated.properties.add(key);
      }
    }
  }
  if (value is List) {
    if (node.validationVocabulary && keywords['uniqueItems'] == true) {
      for (var i = 0; i < value.length; i++) {
        for (var j = 0; j < i; j++) {
          if (deepEquals(value[i], value[j])) {
            return failAt('uniqueItems', '$i');
          }
        }
      }
    }
    final prefixItems = node.lists['prefixItems'] ?? const <_ImportedNode>[];
    for (var i = 0; i < prefixItems.length && i < value.length; i++) {
      final result = _evaluateImportedNode(
        prefixItems[i],
        value[i],
        currentScope,
      );
      if (result.error case final error?) {
        return _ImportEvaluation(error.at('$i'));
      }
      evaluated.items.add(i);
    }
    if (node.children['items'] case final target?) {
      for (var i = prefixItems.length; i < value.length; i++) {
        final result = _evaluateImportedNode(target, value[i], currentScope);
        if (result.error case final error?) {
          return _ImportEvaluation(error.at('$i'));
        }
        evaluated.items.add(i);
      }
    }
    if (node.children['contains'] case final target?) {
      var matches = 0;
      for (var i = 0; i < value.length; i++) {
        if (_evaluateImportedNode(target, value[i], currentScope).error ==
            null) {
          matches++;
          evaluated.items.add(i);
        }
      }
      final minimum = node.validationVocabulary
          ? (keywords['minContains'] as num?) ?? 1
          : 1;
      final maximum = node.validationVocabulary
          ? keywords['maxContains'] as num?
          : null;
      if (matches < minimum) return fail('minContains');
      if (maximum != null && matches > maximum) return fail('maxContains');
    }
    if (node.children['unevaluatedItems'] case final target?) {
      for (var i = 0; i < value.length; i++) {
        if (evaluated.items.contains(i)) continue;
        final result = _evaluateImportedNode(target, value[i], currentScope);
        if (result.error case final error?) {
          return _ImportEvaluation(error.at('$i'));
        }
        evaluated.items.add(i);
      }
    }
  }
  return evaluated;
}

/// Compares the decimal values represented by finite Dart numbers. Dividing
/// binary floating-point values directly would reject JSON decimals such as
/// `0.3` with `multipleOf: 0.1`.
bool _isJsonMultipleOf(num value, num divisor) {
  final (valueCoefficient, valueScale) = _decimalParts(value);
  final (divisorCoefficient, divisorScale) = _decimalParts(divisor);
  final scale = valueScale > divisorScale ? valueScale : divisorScale;
  final ten = BigInt.from(10);
  final numerator = valueCoefficient * ten.pow(scale - valueScale);
  final denominator = divisorCoefficient * ten.pow(scale - divisorScale);
  return numerator % denominator == BigInt.zero;
}

(BigInt, int) _decimalParts(num value) {
  final text = value.toString().toLowerCase();
  final exponentIndex = text.indexOf('e');
  final mantissa = exponentIndex < 0 ? text : text.substring(0, exponentIndex);
  final exponent = exponentIndex < 0
      ? 0
      : int.parse(text.substring(exponentIndex + 1));
  final pointIndex = mantissa.indexOf('.');
  final fractionalDigits = pointIndex < 0
      ? 0
      : mantissa.length - pointIndex - 1;
  var coefficient = BigInt.parse(mantissa.replaceAll('.', ''));
  final scale = fractionalDigits - exponent;
  if (scale < 0) {
    coefficient *= BigInt.from(10).pow(-scale);
    return (coefficient, 0);
  }
  return (coefficient, scale);
}
