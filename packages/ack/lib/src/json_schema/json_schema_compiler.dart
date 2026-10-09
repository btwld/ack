part of '../schemas/schema.dart';

String _importPointerToken(String token) =>
    token.replaceAll('~', '~0').replaceAll('/', '~1');

String _keywordPointer(_ImportedNode node, String keyword) {
  final pointer = keyword.isEmpty
      ? node.pointer
      : '${node.pointer}/${_importPointerToken(keyword)}';
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
  bool validationVocabulary = true;
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
    ?not,
    ?ifNode,
    ?thenNode,
    ?elseNode,
    ...?anyOf,
    ...?allOf,
    ...?oneOf,
    ...?dependentSchemas?.values,
  ];

  /// The 1.x Draft-7 representation of an imported node. Newer 2020-12
  /// assertions that cannot be lowered must use the preserving export.
  Map<String, Object?> renderLegacy(String Function(_ImportedNode) refOf) {
    if (dynamicReference != null ||
        dynamicAnchorName != null ||
        (source is Map<String, Object?> &&
            (source as Map<String, Object?>).containsKey('format'))) {
      throw UnsupportedError(
        'This imported schema needs 2020-12 semantics. Use '
        'toJsonSchemaPreservingImportedDialect().',
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
  static const validationVocabularyUri =
      'https://json-schema.org/draft/2020-12/vocab/validation';
  static const formatAssertionVocabularyUri =
      'https://json-schema.org/draft/2020-12/vocab/format-assertion';
  final diagnostics = <JsonSchemaImportDiagnostic>[];
  final locations = <(Uri, String), _ImportedNode>{};
  final resources = <Uri, _ImportedNode>{};
  final anchors = <Uri, _ImportedNode>{};
  final dynamicAnchors = <Uri, _ImportedNode>{};

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

  _ImportedNode addDocument(Object document, Uri uri) {
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
    return _index(
      copy!,
      uri.removeFragment(),
      '#',
      uri.removeFragment(),
      dialect: standardDialect,
      isRoot: true,
    );
  }

  _ImportedNode _index(
    Object source,
    Uri document,
    String pointer,
    Uri base, {
    Uri? dialect,
    bool isRoot = false,
  }) {
    if (locations[(document, pointer)] case final existing?) return existing;
    dialect ??= standardDialect;
    final provisional = _ImportedNode(source, document, pointer, base, dialect);
    if (source is! bool && source is! Map<String, Object?>) {
      _fail(provisional, '', 'Expected a schema object or boolean.');
    }
    if (source is Map<String, Object?> && source.containsKey(r'$id')) {
      final id = source[r'$id'];
      if (id is! String) _fail(provisional, r'$id', 'Expected a URI string.');
      base = _resolve(provisional, r'$id', base, id);
      if (base.hasFragment && base.fragment.isNotEmpty) {
        _fail(provisional, r'$id', 'Schema IDs must not contain fragments.');
      }
      base = base.removeFragment();
    }
    if (source is Map<String, Object?> && source.containsKey(r'$schema')) {
      final declared = source[r'$schema'];
      if (declared is! String) {
        _fail(provisional, r'$schema', 'Expected a URI string.');
      }
      final resolved = _resolve(provisional, r'$schema', base, declared);
      if (resolved.fragment.isNotEmpty) {
        _fail(provisional, r'$schema', 'Dialect URIs must not have fragments.');
      }
      dialect = resolved.removeFragment();
    }
    final node = _ImportedNode(source, document, pointer, base, dialect);
    locations[(document, pointer)] = node;
    if (isRoot) _register(resources, document, node, r'$id');
    if (isRoot || (source is Map && source.containsKey(r'$id'))) {
      _register(resources, base, node, r'$id');
    }
    if (source is! Map<String, Object?>) return node;
    if (source.containsKey(r'$anchor')) {
      final anchor = source[r'$anchor'];
      if (anchor is! String ||
          !RegExp(r'^[A-Za-z_][-A-Za-z0-9._]*$').hasMatch(anchor)) {
        _fail(node, r'$anchor', 'Invalid anchor name.');
      }
      _register(anchors, base.replace(fragment: anchor), node, r'$anchor');
    }
    if (source.containsKey(r'$dynamicAnchor')) {
      final anchor = source[r'$dynamicAnchor'];
      if (anchor is! String ||
          !RegExp(r'^[A-Za-z_][-A-Za-z0-9._]*$').hasMatch(anchor)) {
        _fail(node, r'$dynamicAnchor', 'Invalid dynamic anchor name.');
      }
      node.dynamicAnchorName = anchor;
      final uri = base.replace(fragment: anchor);
      _register(dynamicAnchors, uri, node, r'$dynamicAnchor');
      _register(anchors, uri, node, r'$dynamicAnchor');
    }
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      final path = '$pointer/${_importPointerToken(key)}';
      if (mapKeywords.contains(key)) {
        if (value is! Map<String, Object?>) {
          _fail(node, key, 'Expected a map of schemas.');
        }
        for (final child in value.entries) {
          _index(
            child.value ?? _invalidSchema(node, key),
            document,
            '$path/${_importPointerToken(child.key)}',
            base,
            dialect: dialect,
          );
        }
      } else if (childKeywords.contains(key)) {
        _index(
          value ?? _invalidSchema(node, key),
          document,
          path,
          base,
          dialect: dialect,
        );
      } else if (listKeywords.contains(key)) {
        if (value is! List || value.isEmpty) {
          _fail(node, key, 'Expected a non-empty list of schemas.');
        }
        for (final (i, child) in value.indexed) {
          _index(
            child ?? _invalidSchema(node, key),
            document,
            '$path/$i',
            base,
            dialect: dialect,
          );
        }
      }
    }
    return node;
  }

  Never _invalidSchema(_ImportedNode node, String key) =>
      _fail(node, key, 'Expected a schema object or boolean.');

  void _register(
    Map<Uri, _ImportedNode> registry,
    Uri uri,
    _ImportedNode node,
    String keyword,
  ) {
    if (registry[uri] case final prior?) {
      if (!identical(prior, node)) {
        _fail(node, keyword, 'Duplicate schema identifier: $uri.');
      }
    }
    registry[uri] = node;
  }

  Uri _resolve(_ImportedNode node, String key, Uri base, String reference) {
    try {
      return base.resolve(reference);
    } on FormatException {
      return _fail(node, key, 'Invalid URI reference: $reference.');
    }
  }

  void compile(_ImportedNode root) {
    for (final node in locations.values) {
      _configureDialect(node);
    }
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

  void _configureDialect(_ImportedNode node) {
    final dialect = resources[node.dialectUri];
    if (dialect == null) {
      _fail(
        node,
        r'$schema',
        'Unsupported or unsupplied dialect: ${node.dialectUri}.',
        code: 'unsupported_dialect',
      );
    }
    final vocabulary = switch (dialect.source) {
      final Map<String, Object?> source => source[r'$vocabulary'],
      _ => null,
    };
    if (vocabulary is! Map<String, Object?>) {
      _fail(
        node,
        r'$schema',
        'Dialect has no declared vocabularies: ${node.dialectUri}.',
        code: 'unsupported_dialect',
      );
    }
    for (final entry in vocabulary.entries) {
      if (entry.value == true && !knownVocabularies.contains(entry.key)) {
        _fail(
          node,
          r'$schema',
          'Unknown required vocabulary: ${entry.key}.',
          code: 'unsupported_vocabulary',
        );
      }
    }
    node.validationVocabulary = vocabulary.containsKey(validationVocabularyUri);
    node.formatAssertion =
        assertFormats || vocabulary.containsKey(formatAssertionVocabularyUri);
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

  _ImportedNode? _resolvePointer(_ImportedNode resource, String fragment) {
    var pointer = resource.pointer;
    var base = resource.baseUri;
    Object? value = resource.source;
    for (final encoded in fragment.substring(1).split('/')) {
      if (RegExp(r'~(?![01])').hasMatch(encoded)) return null;
      final token = encoded.replaceAll('~1', '/').replaceAll('~0', '~');
      if (value is Map<String, Object?> && value.containsKey(token)) {
        value = value[token];
      } else if (value is List &&
          RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(token)) {
        final index = int.tryParse(token);
        if (index == null || index >= value.length) return null;
        value = value[index];
      } else {
        return null;
      }
      pointer = '$pointer/${_importPointerToken(token)}';
      if (locations[(resource.documentUri, pointer)] case final indexed?) {
        base = indexed.baseUri;
      }
    }
    if (value is! Map<String, Object?> && value is! bool) return null;
    // A reference can designate a schema inside an extension container, such
    // as A2UI's /components/Text. Only explicitly targeted locations become
    // schemas; objects in defaults and enum values are never scanned as schemas.
    final indexed = _index(
      value!,
      resource.documentUri,
      pointer,
      base,
      dialect: resource.dialectUri,
    );
    _configureDialect(indexed);
    return indexed;
  }

  void _compileNode(_ImportedNode node) {
    final source = node.source;
    if (source is! Map<String, Object?>) return;
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
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
        for (final entry in value.entries) {
          if (entry.value == true && !knownVocabularies.contains(entry.key)) {
            _fail(
              node,
              key,
              'Unknown required vocabulary: ${entry.key}.',
              code: 'unsupported_vocabulary',
            );
          }
        }
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
            name: _child(node, '$key/${_importPointerToken(name)}'),
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
        if (value is! List ||
            value.any((v) => v is! String) ||
            value.toSet().length != value.length) {
          _fail(node, key, 'Expected a list of unique property names.');
        }
        node.keywords[key] = value;
        node.required = List<String>.unmodifiable(value);
      } else if (key == 'dependentRequired') {
        if (value is! Map<String, Object?> ||
            value.values.any(
              (names) =>
                  names is! List ||
                  names.any((name) => name is! String) ||
                  names.toSet().length != names.length,
            )) {
          _fail(node, key, 'Expected a map of unique property-name lists.');
        }
        node.keywords[key] = value;
        node.dependentRequired = {
          for (final entry in value.entries)
            entry.key: List<String>.unmodifiable(entry.value! as List),
        };
      } else if (key == 'enum') {
        if (value is! List) {
          _fail(node, key, 'Expected an enum array.');
        }
        // Draft-7 requires unique enum entries; 2020-12 merely recommends it.
        final unique = <Object?>[];
        for (final candidate in value) {
          if (!unique.any((v) => deepEquals(v, candidate))) {
            unique.add(candidate);
          }
        }
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
