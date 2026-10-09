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
    final refs = <_ImportedNode, String>{};
    void visit(_ImportedNode node) {
      if (names.containsKey(node)) return;
      final name = '$prefix${names.length}';
      names[node] = name;
      refs[node] = '#/definitions/${_importPointerToken(name)}';
      for (final child in node.dependencies) {
        visit(child);
      }
    }

    visit(_root);
    return {
      for (final entry in names.entries)
        entry.value: entry.key.renderLegacy((node) => refs[node]!),
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
  _ImportEvaluation fail(String keyword) =>
      _ImportEvaluation(_ImportViolation(node, keyword));
  _ImportEvaluation failAt(String keyword, String segment) =>
      _ImportEvaluation(_ImportViolation(node, keyword).at(segment));
  final evaluated = _ImportEvaluation();
  final resource = node.resourceRoot;
  final currentScope = scope.isNotEmpty && identical(scope.last, resource)
      ? scope
      : [...scope, resource];
  if (node.isFalse) return fail('');
  if (node.validationVocabulary) {
    if (node.types case final types?) {
      if (!types.any((t) => _isImportType(t, value))) return fail('type');
    }
    if (node.hasConst && !deepEquals(value, node.constValue)) {
      return fail('const');
    }
    if (node.enumValues case final values?) {
      if (!values.any((v) => deepEquals(v, value))) return fail('enum');
    }
  }
  if (node.reference case final target?) {
    final result = _evaluateImportedNode(target, value, currentScope);
    if (result.error case final error?) {
      return _ImportEvaluation(error.via(const [r'$ref']));
    }
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
    if (result.error case final error?) {
      return _ImportEvaluation(error.via(const [r'$dynamicRef']));
    }
    evaluated.include(result);
  }
  if (node.allOf case final branches?) {
    for (var i = 0; i < branches.length; i++) {
      final result = _evaluateImportedNode(branches[i], value, currentScope);
      if (result.error case final error?) {
        return _ImportEvaluation(error.via(['allOf', '$i']));
      }
      evaluated.include(result);
    }
  }
  if (node.anyOf case final branches?) {
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
  if (node.oneOf case final branches?) {
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
  if (node.not case final target?) {
    if (_evaluateImportedNode(target, value, currentScope).error == null) {
      return fail('not');
    }
  }
  if (node.ifNode case final condition?) {
    final conditionResult = _evaluateImportedNode(
      condition,
      value,
      currentScope,
    );
    final passed = conditionResult.error == null;
    if (passed) evaluated.include(conditionResult);
    final branch = passed ? node.thenNode : node.elseNode;
    if (branch != null) {
      final result = _evaluateImportedNode(branch, value, currentScope);
      if (result.error case final error?) {
        return _ImportEvaluation(error.via([passed ? 'then' : 'else']));
      }
      evaluated.include(result);
    }
  }
  switch (value) {
    case num():
      if (node.validationVocabulary) {
        if (node.multipleOf case final divisor?
            when !_isJsonMultipleOf(value, divisor)) {
          return fail('multipleOf');
        }
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
      }
    case String():
      if (node.validationVocabulary) {
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
        if (node.pattern case final pattern? when !pattern.hasMatch(value)) {
          return fail('pattern');
        }
      }
      if (node.formatAssertion) {
        if (node.format case final format?
            when !_isValidJsonSchemaFormat(format, value)) {
          return fail('format');
        }
      }
    case Map():
      if (node.validationVocabulary) {
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
            if (!value.containsKey(key)) return failAt('required', key);
          }
        }
        if (node.dependentRequired case final requirements?) {
          for (final entry in requirements.entries) {
            if (!value.containsKey(entry.key)) continue;
            for (final dependent in entry.value) {
              if (!value.containsKey(dependent)) {
                return failAt('dependentRequired', dependent);
              }
            }
          }
        }
      }
      final properties = node.properties;
      final patterns = node.patternProperties;
      final additional = node.additionalProperties;
      if (properties != null || patterns != null || additional != null) {
        for (final MapEntry(:key, value: item) in value.entries) {
          final propKey = key as String;
          var matched = false;
          if (properties?[propKey] case final target?) {
            matched = true;
            final result = _evaluateImportedNode(target, item, currentScope);
            if (result.error case final error?) {
              return _ImportEvaluation(
                error.at(propKey, ['properties', propKey]),
              );
            }
            evaluated.properties.add(propKey);
          }
          if (patterns != null) {
            for (final (rawPattern, regex, target) in patterns) {
              if (!regex.hasMatch(propKey)) continue;
              matched = true;
              final result = _evaluateImportedNode(target, item, currentScope);
              if (result.error case final error?) {
                return _ImportEvaluation(
                  error.at(propKey, ['patternProperties', rawPattern]),
                );
              }
              evaluated.properties.add(propKey);
            }
          }
          if (!matched && additional != null) {
            final result = _evaluateImportedNode(
              additional,
              item,
              currentScope,
            );
            if (result.error case final error?) {
              return _ImportEvaluation(
                error.at(propKey, const ['additionalProperties']),
              );
            }
            evaluated.properties.add(propKey);
          }
        }
      }
      if (node.dependentSchemas case final dependencies?) {
        for (final dependency in dependencies.entries) {
          if (!value.containsKey(dependency.key)) continue;
          final result = _evaluateImportedNode(
            dependency.value,
            value,
            currentScope,
          );
          if (result.error case final error?) {
            return _ImportEvaluation(
              error.via(['dependentSchemas', dependency.key]),
            );
          }
          evaluated.include(result);
        }
      }
      if (node.propertyNames case final target?) {
        for (final key in value.keys) {
          final result = _evaluateImportedNode(target, key, currentScope);
          if (result.error case final error?) {
            return _ImportEvaluation(
              error.atPropertyName(key as String, const ['propertyNames']),
            );
          }
        }
      }
      if (node.unevaluatedProperties case final target?) {
        for (final entry in value.entries) {
          final key = entry.key as String;
          if (evaluated.properties.contains(key)) continue;
          final result = _evaluateImportedNode(
            target,
            entry.value,
            currentScope,
          );
          if (result.error case final error?) {
            return _ImportEvaluation(
              error.at(key, const ['unevaluatedProperties']),
            );
          }
          evaluated.properties.add(key);
        }
      }
    case List():
      if (node.validationVocabulary) {
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
      }
      final prefixItems = node.prefixItems ?? const <_ImportedNode>[];
      for (var i = 0; i < prefixItems.length && i < value.length; i++) {
        final result = _evaluateImportedNode(
          prefixItems[i],
          value[i],
          currentScope,
        );
        if (result.error case final error?) {
          return _ImportEvaluation(error.at('$i', ['prefixItems', '$i']));
        }
        evaluated.items.add(i);
      }
      if (node.items case final target?) {
        for (var i = prefixItems.length; i < value.length; i++) {
          final result = _evaluateImportedNode(target, value[i], currentScope);
          if (result.error case final error?) {
            return _ImportEvaluation(error.at('$i', const ['items']));
          }
          evaluated.items.add(i);
        }
      }
      if (node.contains case final target?) {
        var matches = 0;
        for (var i = 0; i < value.length; i++) {
          if (_evaluateImportedNode(target, value[i], currentScope).error ==
              null) {
            matches++;
            evaluated.items.add(i);
          }
        }
        final minimum = node.validationVocabulary ? (node.minContains ?? 1) : 1;
        final maximum = node.validationVocabulary ? node.maxContains : null;
        if (matches < minimum) {
          return fail(
            node.validationVocabulary && node.minContains != null
                ? 'minContains'
                : 'contains',
          );
        }
        if (maximum != null && matches > maximum) return fail('maxContains');
      }
      if (node.unevaluatedItems case final target?) {
        for (var i = 0; i < value.length; i++) {
          if (evaluated.items.contains(i)) continue;
          final result = _evaluateImportedNode(target, value[i], currentScope);
          if (result.error case final error?) {
            return _ImportEvaluation(
              error.at('$i', const ['unevaluatedItems']),
            );
          }
          evaluated.items.add(i);
        }
      }
  }
  return evaluated;
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
