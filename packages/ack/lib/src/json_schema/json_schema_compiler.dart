part of '../schemas/schema.dart';

String _keywordPointer(_ImportedNode node, String keyword) {
  final pointer = keyword.isEmpty
      ? node.pointer
      : '${node.pointer}/${escapeJsonPointerToken(keyword)}';
  // Internal pointers stay unencoded for lookup. Encode only the public
  // fragment, including literal '%' and '#' characters (RFC 6901 section 6).
  return '#${Uri.encodeFull(pointer.substring(1)).replaceAll('#', '%23')}';
}

final class _ImportedNode {
  _ImportedNode(
    this.source,
    this.documentUri,
    this.pointer,
    this.baseUri,
    this.dialectUri,
  );

  final Object source;
  final Uri documentUri;
  final String pointer;
  final Uri baseUri;
  final Uri dialectUri;
  bool applicatorVocabulary = true;
  bool unevaluatedVocabulary = true;
  bool validationVocabulary = true;
  bool metadataVocabulary = true;
  bool contentVocabulary = true;
  bool formatAnnotationVocabulary = true;
  bool formatAssertion = false;
  final keywords = <String, Object?>{};
  final children = <String, _ImportedNode>{};
  final maps = <String, Map<String, _ImportedNode>>{};
  final lists = <String, List<_ImportedNode>>{};
  _ImportedNode? reference;
  _ImportedNode? dynamicReference;
  String? dynamicReferenceName;
  String? dynamicAnchorName;
  late _ImportedNode resourceRoot;
  final dynamicAnchors = <String, _ImportedNode>{};

  // Typed fields for validation, avoiding per-value map lookups.
  bool get isFalse => identical(source, false);
  List<Object?>? types;
  bool hasConst = false;
  Object? constValue;
  List<Object?>? enumValues;
  num? minimum;
  num? maximum;
  num? exclusiveMinimum;
  num? exclusiveMaximum;
  num? multipleOf;
  num? minLength;
  num? maxLength;
  num? minItems;
  num? maxItems;
  num? minProperties;
  num? maxProperties;
  num? minContains;
  num? maxContains;
  bool uniqueItems = false;
  RegExp? pattern;
  String? format;
  List<String>? required;
  Map<String, List<String>>? dependentRequired;
  Map<String, _ImportedNode>? properties;
  List<(String, RegExp, _ImportedNode)>? patternProperties;
  Map<String, _ImportedNode>? dependentSchemas;
  _ImportedNode? items;
  _ImportedNode? additionalProperties;
  _ImportedNode? not;
  _ImportedNode? contains;
  _ImportedNode? propertyNames;
  _ImportedNode? unevaluatedProperties;
  _ImportedNode? unevaluatedItems;
  _ImportedNode? ifNode;
  _ImportedNode? thenNode;
  _ImportedNode? elseNode;
  List<_ImportedNode>? anyOf;
  List<_ImportedNode>? allOf;
  List<_ImportedNode>? oneOf;
  List<_ImportedNode>? prefixItems;

  /// Keywords outside the selected dialect retain only annotation semantics.
  bool isKeywordActive(String keyword) {
    if (keyword == r'$defs' || keyword == 'definitions') return true;
    if (keyword == 'unevaluatedProperties' || keyword == 'unevaluatedItems') {
      return unevaluatedVocabulary;
    }
    if (_JsonSchemaCompiler.mapKeywords.contains(keyword) ||
        _JsonSchemaCompiler.childKeywords.contains(keyword) ||
        _JsonSchemaCompiler.listKeywords.contains(keyword)) {
      return applicatorVocabulary;
    }
    if (_JsonSchemaCompiler.validationKeywords.contains(keyword)) {
      return validationVocabulary;
    }
    return switch (keyword) {
      'title' ||
      'description' ||
      'default' ||
      'examples' ||
      'readOnly' ||
      'writeOnly' ||
      'deprecated' => metadataVocabulary,
      'contentEncoding' ||
      'contentMediaType' ||
      'contentSchema' => contentVocabulary,
      'format' => formatAnnotationVocabulary || formatAssertion,
      _ => true,
    };
  }

  List<_ImportedNode> get dependencies => [
    ?reference,
    ?dynamicReference,
    ...children.values,
    for (final map in maps.values) ...map.values,
    for (final list in lists.values) ...list,
  ];

  /// Sub-schemas applied to the same instance, for the cycle check.
  List<_ImportedNode> get inPlaceDependencies => [
    ?reference,
    ?dynamicReference,
    if (applicatorVocabulary) ...[
      ?not,
      ?ifNode,
      ?thenNode,
      ?elseNode,
      ...?anyOf,
      ...?allOf,
      ...?oneOf,
      ...?dependentSchemas?.values,
    ],
  ];

  /// The Draft-7 representation of an imported node, used by
  /// `toJsonSchemaDraft7()`. 2020-12 assertions that cannot be lowered fail.
  Map<String, Object?> renderDraft7(String Function(_ImportedNode) refOf) {
    // Draft-7 silently ignores these keywords (and applies `items` to the
    // entire array instead of only the suffix after `prefixItems`). Until a
    // semantics-preserving lowering exists, fail instead of changing which
    // instances the exported schema accepts.
    const unsupportedKeywords = {
      'prefixItems',
      'dependentRequired',
      'dependentSchemas',
      'unevaluatedProperties',
      'unevaluatedItems',
      'minContains',
      'maxContains',
    };
    if (source case final Map<String, Object?> document) {
      for (final keyword in unsupportedKeywords) {
        if (isKeywordActive(keyword) && document.containsKey(keyword)) {
          throw UnsupportedError(
            'Cannot lower "$keyword" at ${_keywordPointer(this, keyword)} '
            'with toJsonSchemaDraft7(); use toJsonSchema() for 2020-12 semantics.',
          );
        }
      }
    }
    if (dynamicReference != null ||
        dynamicAnchorName != null ||
        (isKeywordActive('format') &&
            source is Map<String, Object?> &&
            (source as Map<String, Object?>).containsKey('format'))) {
      throw UnsupportedError(
        'This imported schema needs 2020-12 semantics and cannot be lowered '
        'with toJsonSchemaDraft7().',
      );
    }
    if (isFalse) return {'not': <String, Object?>{}};
    // Empty enums are valid in 2020-12 but not Draft-7's meta-schema.
    if (keywords['enum'] case []) return {'not': <String, Object?>{}};
    Map<String, Object?> ref(_ImportedNode node) => {r'$ref': refOf(node)};
    return {
      ...keywords,
      // Draft-7 ignores $ref siblings; an allOf envelope preserves them.
      if (reference != null)
        'allOf': [ref(reference!), ...?lists['allOf']?.map(ref)],
      for (final entry in children.entries) entry.key: ref(entry.value),
      for (final entry in maps.entries)
        entry.key: entry.value.map((key, value) => MapEntry(key, ref(value))),
      for (final entry in lists.entries)
        if (entry.key != 'allOf' || reference == null)
          entry.key: entry.value.map(ref).toList(),
    };
  }
}

final class _JsonSchemaCompiler {
  _JsonSchemaCompiler({this.assertFormats = false});

  final bool assertFormats;
  static final standardDialect = Uri.parse(
    'https://json-schema.org/draft/2020-12/schema',
  );
  static final draft7Dialects = {
    Uri.parse('http://json-schema.org/draft-07/schema'),
    Uri.parse('https://json-schema.org/draft-07/schema'),
  };
  static final _anchorPattern = RegExp(r'^[A-Za-z_][-A-Za-z0-9._]*$');
  static const applicatorVocabularyUri =
      'https://json-schema.org/draft/2020-12/vocab/applicator';
  static const unevaluatedVocabularyUri =
      'https://json-schema.org/draft/2020-12/vocab/unevaluated';
  static const validationVocabularyUri =
      'https://json-schema.org/draft/2020-12/vocab/validation';
  static const formatAssertionVocabularyUri =
      'https://json-schema.org/draft/2020-12/vocab/format-assertion';
  final diagnostics = <JsonSchemaImportDiagnostic>[];
  final locations = <(Uri, String), _ImportedNode>{};
  final resources = <Uri, _ImportedNode>{};
  final anchors = <Uri, _ImportedNode>{};
  final dynamicAnchors = <Uri, _ImportedNode>{};
  final _pendingChildren = Queue<_ImportedNode>();
  final _fallbackDocumentUris = <Uri>{};

  static final _standardMetaSchemaIndex = () {
    final compiler = _JsonSchemaCompiler();
    for (final entry in _standardMetaSchemaDocuments.entries) {
      compiler.addDocument(entry.value, entry.key, isFallback: true);
    }
    compiler._indexPendingChildren();
    return compiler;
  }();

  void _addStandardMetaSchemas() {
    // Caller-owned standard resources can change dialect interpretation.
    // Preserve normal indexing for those overrides, including duplicate IDs.
    if (_standardMetaSchemaDocuments.keys.any(resources.containsKey)) {
      for (final entry in _standardMetaSchemaDocuments.entries) {
        if (!resources.containsKey(entry.key)) {
          addDocument(entry.value, entry.key, isFallback: true);
        }
      }
      return;
    }
    final index = _standardMetaSchemaIndex;
    final copies = HashMap<_ImportedNode, _ImportedNode>.identity();
    for (final entry in index.locations.entries) {
      final node = entry.value;
      // Share immutable sources and locations; compiled state stays local.
      final copy =
          _ImportedNode(
              node.source,
              node.documentUri,
              node.pointer,
              node.baseUri,
              node.dialectUri,
            )
            ..applicatorVocabulary = node.applicatorVocabulary
            ..unevaluatedVocabulary = node.unevaluatedVocabulary
            ..validationVocabulary = node.validationVocabulary
            ..metadataVocabulary = node.metadataVocabulary
            ..contentVocabulary = node.contentVocabulary
            ..formatAnnotationVocabulary = node.formatAnnotationVocabulary
            ..formatAssertion = assertFormats || node.formatAssertion
            ..dynamicAnchorName = node.dynamicAnchorName;
      locations[entry.key] = copies[node] = copy;
    }
    void copyRegistry(
      Map<Uri, _ImportedNode> target,
      Map<Uri, _ImportedNode> source,
    ) {
      for (final entry in source.entries) {
        target[entry.key] = copies[entry.value]!;
      }
    }

    copyRegistry(resources, index.resources);
    copyRegistry(anchors, index.anchors);
    copyRegistry(dynamicAnchors, index.dynamicAnchors);
    _fallbackDocumentUris.addAll(_standardMetaSchemaDocuments.keys);
  }

  static const mapKeywords = {
    r'$defs',
    'definitions',
    'properties',
    'patternProperties',
    'dependentSchemas',
  };
  static const childKeywords = {
    'items',
    'additionalProperties',
    'not',
    'contains',
    'propertyNames',
    'if',
    'then',
    'else',
    'unevaluatedProperties',
    'unevaluatedItems',
  };
  static const listKeywords = {'anyOf', 'allOf', 'oneOf', 'prefixItems'};
  static const annotations = {
    'title',
    'description',
    'default',
    'examples',
    r'$comment',
    'readOnly',
    'writeOnly',
    'deprecated',
    'format',
    'contentEncoding',
    'contentMediaType',
    'contentSchema',
  };
  static const knownVocabularies = {
    'https://json-schema.org/draft/2020-12/vocab/core',
    'https://json-schema.org/draft/2020-12/vocab/applicator',
    'https://json-schema.org/draft/2020-12/vocab/unevaluated',
    'https://json-schema.org/draft/2020-12/vocab/validation',
    'https://json-schema.org/draft/2020-12/vocab/meta-data',
    'https://json-schema.org/draft/2020-12/vocab/format-annotation',
    formatAssertionVocabularyUri,
    'https://json-schema.org/draft/2020-12/vocab/content',
  };
  static const counts = {
    'minLength',
    'maxLength',
    'minItems',
    'maxItems',
    'minProperties',
    'maxProperties',
  };
  static const bounds = {
    'minimum',
    'maximum',
    'exclusiveMinimum',
    'exclusiveMaximum',
  };
  static const validationKeywords = {
    ...counts,
    ...bounds,
    'type',
    'const',
    'enum',
    'multipleOf',
    'minContains',
    'maxContains',
    'uniqueItems',
    'pattern',
    'required',
    'dependentRequired',
  };

  _ImportedNode addDocument(
    Object document,
    Uri uri, {
    bool isFallback = false,
  }) {
    if (uri.hasFragment && uri.fragment.isNotEmpty) {
      throw ArgumentError.value(uri, 'baseUri', 'Must not contain a fragment.');
    }
    final copy = _copyImportJson(document, HashSet.identity());
    if (identical(copy, _notImportJson)) {
      throw JsonSchemaImportException._([
        JsonSchemaImportDiagnostic._(
          code: 'invalid_schema',
          documentUri: uri,
          pointer: '#',
          keyword: '',
          message: 'Expected an acyclic JSON document.',
        ),
      ]);
    }
    final prior = resources[uri.removeFragment()];
    if (prior != null && prior.documentUri == uri.removeFragment()) {
      if (deepEquals(prior.source, document)) return prior;
      _fail(
        prior,
        '',
        'Conflicting schema documents for retrieval URI: ${uri.removeFragment()}.',
      );
    }
    if (isFallback) _fallbackDocumentUris.add(uri.removeFragment());
    return _index(
      copy!,
      uri.removeFragment(),
      '#',
      uri.removeFragment(),
      dialect: standardDialect,
      isRoot: true,
    );
  }

  Uri _resolve(_ImportedNode node, String key, Uri base, String reference) {
    try {
      return base.resolve(reference);
    } on FormatException {
      return _fail(node, key, 'Invalid URI reference: $reference.');
    }
  }

  void _checkRequiredVocabularies(
    _ImportedNode node,
    String key,
    Map<String, Object?> vocabulary,
  ) {
    for (final entry in vocabulary.entries) {
      if (entry.value == true && !knownVocabularies.contains(entry.key)) {
        _fail(
          node,
          key,
          'Unknown required vocabulary: ${entry.key}.',
          code: 'unsupported_vocabulary',
        );
      }
    }
  }

  List<String> _requireUniqueStringList(
    _ImportedNode node,
    String key,
    Object? value,
    String message,
  ) {
    if (value is! List ||
        value.any((v) => v is! String) ||
        value.toSet().length != value.length) {
      _fail(node, key, message);
    }
    return List<String>.unmodifiable(value);
  }

  void compile(_ImportedNode root) {
    _indexPendingChildren();
    final nodes = _compileReachable(root);
    for (final node in locations.values) {
      node.resourceRoot = resources[node.baseUri]!;
    }
    for (final entry in dynamicAnchors.entries) {
      resources[entry.key.removeFragment()]!.dynamicAnchors[Uri.decodeComponent(
            entry.key.fragment,
          )] =
          entry.value;
    }
    _checkProductiveCycles(nodes);
  }

  List<_ImportedNode> _compileReachable(_ImportedNode root) {
    final nodes = <_ImportedNode>[];
    final pending = Queue<_ImportedNode>()..add(root);
    final compiled = <_ImportedNode>{};
    while (true) {
      while (pending.isNotEmpty) {
        final node = pending.removeFirst();
        if (!compiled.add(node)) continue;
        _compileNode(node);
        nodes.add(node);
        pending.addAll(node.dependencies);
      }
      if (!nodes.any((node) => node.dynamicReference != null)) break;
      final activeResources = nodes.map((node) => node.baseUri).toSet();
      final anchorsToCompile = dynamicAnchors.entries
          .where(
            (entry) => activeResources.contains(entry.key.removeFragment()),
          )
          .map((entry) => entry.value)
          .where((node) => !compiled.contains(node));
      if (anchorsToCompile.isEmpty) break;
      pending.addAll(anchorsToCompile);
    }
    return nodes;
  }

  void _checkProductiveCycles(List<_ImportedNode> nodes) {
    final visited = <_ImportedNode>{};
    final active = <_ImportedNode>{};
    void checkCycle(_ImportedNode node) {
      if (active.contains(node)) {
        _fail(
          node,
          r'$ref',
          'Reference cycle does not descend into an instance.',
          code: 'nonproductive_reference_cycle',
        );
      }
      if (!visited.add(node)) return;
      active.add(node);
      for (final child in node.inPlaceDependencies) {
        checkCycle(child);
      }
      active.remove(node);
    }

    for (final node in nodes) {
      checkCycle(node);
    }
  }

  _ImportedNode _child(_ImportedNode node, String suffix) =>
      locations[(node.documentUri, '${node.pointer}/$suffix')]!;

  void _compileNode(_ImportedNode node) {
    final source = node.source;
    if (source is! Map<String, Object?>) return;
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      if (!node.isKeywordActive(key)) continue;
      if (const {
        r'$id',
        r'$schema',
        r'$anchor',
        r'$dynamicAnchor',
        r'$defs',
        'definitions',
      }.contains(key)) {
        continue;
      }
      if (annotations.contains(key)) {
        final valid = switch (key) {
          'title' ||
          'description' ||
          r'$comment' ||
          'format' ||
          'contentEncoding' ||
          'contentMediaType' => value is String,
          'readOnly' || 'writeOnly' || 'deprecated' => value is bool,
          'examples' => value is List,
          'contentSchema' => value is bool || value is Map<String, Object?>,
          _ => true,
        };
        if (!valid) _fail(node, key, 'Invalid annotation value for "$key".');
        if (key == 'format') {
          if (node.formatAssertion &&
              !_isSupportedJsonSchemaFormat(value as String)) {
            _fail(
              node,
              key,
              'Unknown asserted format: $value.',
              code: 'unsupported_format',
            );
          }
          node.format = value as String;
        }
        node.keywords[key] = value;
      } else if (key == r'$vocabulary') {
        if (value is! Map<String, Object?> ||
            value.values.any((required) => required is! bool)) {
          _fail(node, key, 'Expected a map of vocabulary URIs to booleans.');
        }
        _checkRequiredVocabularies(node, key, value);
        node.keywords[key] = value;
      } else if (key == r'$ref' || key == r'$dynamicRef') {
        if (value is! String) _fail(node, key, 'Expected a URI string.');
        final uri = _resolve(node, key, node.baseUri, value);
        final resource = resources[uri.removeFragment()];
        var target = anchors[uri];
        if (resource != null && uri.fragment.isEmpty) target = resource;
        final String fragment;
        try {
          fragment = Uri.decodeComponent(uri.fragment);
        } on FormatException {
          _fail(node, key, 'Invalid UTF-8 URI fragment.');
        }
        if (resource != null && fragment.startsWith('/')) {
          target = _resolvePointer(resource, fragment);
        }
        if (target == null) {
          if (uri.host == 'json-schema.org' &&
              uri.path.startsWith('/draft/2020-12/')) {
            _unsupported(
              node,
              key,
              'Meta-schema validation is not supported.',
              code: 'unsupported_reference',
            );
            continue;
          }
          _fail(
            node,
            key,
            'Unresolved schema reference: $uri.',
            code: 'unresolved_reference',
          );
        }
        if (key == r'$ref') {
          node.reference = target;
        } else {
          node.dynamicReference = target;
          if (!fragment.startsWith('/') &&
              target.dynamicAnchorName == fragment) {
            node.dynamicReferenceName = fragment;
          }
        }
      } else if (key == 'properties' ||
          key == 'patternProperties' ||
          key == 'dependentSchemas') {
        final compiledMap = {
          for (final name in (value as Map<String, Object?>).keys)
            name: _child(node, '$key/${escapeJsonPointerToken(name)}'),
        };
        node.maps[key] = compiledMap;
        switch (key) {
          case 'properties':
            node.properties = compiledMap;
          case 'dependentSchemas':
            node.dependentSchemas = compiledMap;
          case 'patternProperties':
            final compiledPatterns = <(String, RegExp, _ImportedNode)>[];
            for (final entry in compiledMap.entries) {
              try {
                compiledPatterns.add((
                  entry.key,
                  RegExp(entry.key, unicode: true),
                  entry.value,
                ));
              } on FormatException catch (e) {
                _fail(node, key, 'Invalid pattern property: ${e.message}');
              }
            }
            node.patternProperties = compiledPatterns;
        }
      } else if (childKeywords.contains(key)) {
        final child = node.children[key] = _child(node, key);
        switch (key) {
          case 'items':
            node.items = child;
          case 'additionalProperties':
            node.additionalProperties = child;
          case 'not':
            node.not = child;
          case 'contains':
            node.contains = child;
          case 'propertyNames':
            node.propertyNames = child;
          case 'unevaluatedProperties':
            node.unevaluatedProperties = child;
          case 'unevaluatedItems':
            node.unevaluatedItems = child;
          case 'if':
            node.ifNode = child;
          case 'then':
            node.thenNode = child;
          case 'else':
            node.elseNode = child;
        }
      } else if (listKeywords.contains(key)) {
        final targets = node.lists[key] = [
          for (var i = 0; i < (value as List).length; i++)
            _child(node, '$key/$i'),
        ];
        switch (key) {
          case 'anyOf':
            node.anyOf = targets;
          case 'allOf':
            node.allOf = targets;
          case 'oneOf':
            node.oneOf = targets;
          case 'prefixItems':
            node.prefixItems = targets;
        }
      } else if (key == 'type') {
        const types = {
          'null',
          'boolean',
          'object',
          'array',
          'number',
          'integer',
          'string',
        };
        final values = value is List ? value : [value];
        if (values.isEmpty ||
            values.any((v) => !types.contains(v)) ||
            values.toSet().length != values.length) {
          _fail(
            node,
            key,
            'Expected a JSON type or non-empty unique type list.',
          );
        }
        node.keywords[key] = value;
        node.types = values;
      } else if (key == 'required') {
        node.keywords[key] = value;
        node.required = _requireUniqueStringList(
          node,
          key,
          value,
          'Expected a list of unique property names.',
        );
      } else if (key == 'dependentRequired') {
        if (value is! Map<String, Object?>) {
          _fail(node, key, 'Expected a map of unique property-name lists.');
        }
        node.keywords[key] = value;
        node.dependentRequired = {
          for (final entry in value.entries)
            entry.key: _requireUniqueStringList(
              node,
              key,
              entry.value,
              'Expected a map of unique property-name lists.',
            ),
        };
      } else if (key == 'enum') {
        if (value is! List) {
          _fail(node, key, 'Expected an enum array.');
        }
        // Draft-7 requires unique enum entries; 2020-12 merely recommends it.
        final unique = LinkedHashSet<Object?>(
          equals: deepEquals,
          hashCode: deepHashCode,
        )..addAll(value);
        node.keywords[key] = node.enumValues = List<Object?>.unmodifiable(
          unique,
        );
      } else if (key == 'const') {
        node.keywords[key] = node.constValue = value;
        node.hasConst = true;
      } else if (counts.contains(key) ||
          key == 'minContains' ||
          key == 'maxContains') {
        if (value is! num || value < 0 || value % 1 != 0) {
          _fail(node, key, 'Expected a non-negative integer.');
        }
        node.keywords[key] = value;
        switch (key) {
          case 'minLength':
            node.minLength = value;
          case 'maxLength':
            node.maxLength = value;
          case 'minItems':
            node.minItems = value;
          case 'maxItems':
            node.maxItems = value;
          case 'minProperties':
            node.minProperties = value;
          case 'maxProperties':
            node.maxProperties = value;
          case 'minContains':
            node.minContains = value;
          case 'maxContains':
            node.maxContains = value;
        }
      } else if (bounds.contains(key)) {
        if (value is! num) _fail(node, key, 'Expected a number.');
        node.keywords[key] = value;
        switch (key) {
          case 'minimum':
            node.minimum = value;
          case 'maximum':
            node.maximum = value;
          case 'exclusiveMinimum':
            node.exclusiveMinimum = value;
          case 'exclusiveMaximum':
            node.exclusiveMaximum = value;
        }
      } else if (key == 'multipleOf') {
        if (value is! num || !value.isFinite || value <= 0) {
          _fail(node, key, 'Expected a positive finite number.');
        }
        node.keywords[key] = node.multipleOf = value;
      } else if (key == 'uniqueItems') {
        if (value is! bool) _fail(node, key, 'Expected a boolean.');
        node.keywords[key] = node.uniqueItems = value;
      } else if (key == 'pattern') {
        if (value is! String) {
          _fail(node, key, 'Expected a regular expression string.');
        }
        try {
          node.pattern = RegExp(value, unicode: true);
        } on FormatException catch (e) {
          _fail(node, key, 'Invalid regular expression: ${e.message}');
        }
        node.keywords[key] = value;
      } else {
        // Unknown keywords are annotations in the standard 2020-12 dialect.
        // Their JSON values survive export, but never assert against instances.
        node.keywords[key] = value;
      }
    }
  }

  JsonSchemaImportDiagnostic _diagnostic(
    _ImportedNode node,
    String key,
    String message,
    String code,
  ) => JsonSchemaImportDiagnostic._(
    code: code,
    documentUri: node.documentUri,
    pointer: _keywordPointer(node, key),
    keyword: key,
    message: message,
  );

  void _unsupported(
    _ImportedNode node,
    String key,
    String message, {
    String code = 'unsupported_keyword',
  }) {
    diagnostics.add(_diagnostic(node, key, message, code));
  }

  Never _fail(
    _ImportedNode node,
    String key,
    String message, {
    String code = 'invalid_schema',
  }) => throw JsonSchemaImportException._([
    ...diagnostics,
    _diagnostic(node, key, message, code),
  ]);
}

bool _isImportJson(Object? value, Set<Object> active) {
  if (value == null || value is String || value is bool) return true;
  if (value is num) return value.isFinite;
  if (value is! List && value is! Map) return false;
  if (!active.add(value)) return false;
  final valid = value is List
      ? value.every((v) => _isImportJson(v, active))
      : (value as Map).entries.every(
          (e) => e.key is String && _isImportJson(e.value, active),
        );
  active.remove(value);
  return valid;
}

final _notImportJson = Object();

/// Returns [_notImportJson] where [_isImportJson] returns false.
Object? _copyImportJson(Object? value, Set<Object> active) {
  if (value == null || value is String || value is bool) return value;
  if (value is num) return value.isFinite ? value : _notImportJson;
  if (value is! List && value is! Map) return _notImportJson;
  if (!active.add(value)) return _notImportJson;
  final Object copy;
  if (value is List) {
    final items = List<Object?>.filled(value.length, null);
    for (var i = 0; i < items.length; i++) {
      final item = _copyImportJson(value[i], active);
      if (identical(item, _notImportJson)) return item;
      items[i] = item;
    }
    copy = UnmodifiableListView(items);
  } else {
    final entries = <String, Object?>{};
    for (final MapEntry(:key, value: item) in (value as Map).entries) {
      if (key is! String) return _notImportJson;
      final itemCopy = _copyImportJson(item, active);
      if (identical(itemCopy, _notImportJson)) return itemCopy;
      entries[key] = itemCopy;
    }
    copy = UnmodifiableMapView(entries);
  }
  active.remove(value);
  return copy;
}
