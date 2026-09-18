part of '../schemas/schema.dart';

String _importPointerToken(String token) =>
    token.replaceAll('~', '~0').replaceAll('/', '~1');

final class _ImportedNode {
  _ImportedNode(this.source, this.documentUri, this.pointer, this.baseUri);

  final Object source;
  final Uri documentUri;
  final String pointer;
  final Uri baseUri;
  final keywords = <String, Object?>{};
  final children = <String, _ImportedNode>{};
  final maps = <String, Map<String, _ImportedNode>>{};
  final lists = <String, List<_ImportedNode>>{};
  _ImportedNode? reference;
  Iterable<_ImportedNode> get dependencies sync* {
    if (reference case final target?) yield target;
    yield* children.values;
    for (final map in maps.values) {
      yield* map.values;
    }
    for (final list in lists.values) {
      yield* list;
    }
  }

  Iterable<_ImportedNode> get inPlaceDependencies sync* {
    if (reference case final target?) yield target;
    if (children['not'] case final target?) yield target;
    for (final key in ['anyOf', 'allOf', 'oneOf']) {
      yield* lists[key] ?? const <_ImportedNode>[];
    }
  }

  Map<String, Object?> render(String Function(_ImportedNode) name) {
    if (source == false) return {'not': <String, Object?>{}};
    // Empty enums are valid in 2020-12 but not Draft-7's meta-schema.
    if (keywords['enum'] case []) return {'not': <String, Object?>{}};
    Map<String, Object?> ref(_ImportedNode node) => {
      r'$ref': '#/definitions/${_importPointerToken(name(node))}',
    };
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
  final diagnostics = <JsonSchemaImportDiagnostic>[];
  final locations = <(Uri, String), _ImportedNode>{};
  final resources = <Uri, _ImportedNode>{};
  final anchors = <Uri, _ImportedNode>{};

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
    'unevaluatedProperties',
    'unevaluatedItems',
    'if',
    'then',
    'else',
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
    if (!_isImportJson(document, HashSet.identity())) {
      throw JsonSchemaImportException([
        JsonSchemaImportDiagnostic(
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
      cloneDefault(document)!,
      uri.removeFragment(),
      '#',
      uri.removeFragment(),
      isRoot: true,
    );
  }

  _ImportedNode _index(
    Object source,
    Uri document,
    String pointer,
    Uri base, {
    bool isRoot = false,
  }) {
    if (locations[(document, pointer)] case final existing?) return existing;
    final provisional = _ImportedNode(source, document, pointer, base);
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
    final node = _ImportedNode(source, document, pointer, base);
    locations[(document, pointer)] = node;
    if (isRoot) _register(resources, document, node, r'$id');
    if (isRoot || (source is Map && source.containsKey(r'$id'))) {
      _register(resources, base, node, r'$id');
    }
    if (source is! Map<String, Object?>) return node;
    if (source.containsKey(r'$schema')) {
      final dialect = source[r'$schema'];
      // An empty fragment identifies the same meta-schema resource.
      if (dialect != 'https://json-schema.org/draft/2020-12/schema' &&
          dialect != 'https://json-schema.org/draft/2020-12/schema#') {
        _fail(
          node,
          r'$schema',
          'Only draft 2020-12 input is supported.',
          code: 'unsupported_dialect',
        );
      }
    }
    if (source.containsKey(r'$anchor')) {
      final anchor = source[r'$anchor'];
      if (anchor is! String ||
          !RegExp(r'^[A-Za-z_][-A-Za-z0-9._]*$').hasMatch(anchor)) {
        _fail(node, r'$anchor', 'Invalid anchor name.');
      }
      _register(anchors, base.replace(fragment: anchor), node, r'$anchor');
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
          );
        }
      } else if (childKeywords.contains(key)) {
        _index(value ?? _invalidSchema(node, key), document, path, base);
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
    final nodes = _compileReachable(root);
    _checkProductiveCycles(nodes);
  }

  List<_ImportedNode> _compileReachable(_ImportedNode root) {
    final nodes = <_ImportedNode>[];
    final pending = Queue<_ImportedNode>()..add(root);
    final compiled = <_ImportedNode>{};
    while (pending.isNotEmpty) {
      final node = pending.removeFirst();
      if (!compiled.add(node)) continue;
      _compileNode(node);
      nodes.add(node);
      pending.addAll(node.dependencies);
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
    return _index(value!, resource.documentUri, pointer, base);
  }

  void _compileNode(_ImportedNode node) {
    final source = node.source;
    if (source is! Map<String, Object?>) return;
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      if ({
        r'$id',
        r'$schema',
        r'$anchor',
        r'$defs',
        'definitions',
      }.contains(key)) {
        continue;
      }
      if (annotations.contains(key)) {
        final valid = switch (key) {
          'title' || 'description' || r'$comment' => value is String,
          'readOnly' || 'writeOnly' || 'deprecated' => value is bool,
          'examples' => value is List,
          _ => true,
        };
        if (!valid) _fail(node, key, 'Invalid annotation value for "$key".');
        node.keywords[key] = value;
      } else if (key == r'$ref') {
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
        node.reference = target;
      } else if (key == 'properties') {
        node.maps[key] = {
          for (final name in (value as Map<String, Object?>).keys)
            name: _child(node, '$key/${_importPointerToken(name)}'),
        };
      } else if ({'items', 'additionalProperties', 'not'}.contains(key)) {
        if ((key == 'items' && source.containsKey('prefixItems')) ||
            (key == 'additionalProperties' &&
                source.containsKey('patternProperties'))) {
          _unsupported(
            node,
            key,
            'Cannot retain $key without its unsupported sibling.',
          );
        } else {
          node.children[key] = _child(node, key);
        }
      } else if ({'anyOf', 'allOf', 'oneOf'}.contains(key)) {
        node.lists[key] = [
          for (var i = 0; i < (value as List).length; i++)
            _child(node, '$key/$i'),
        ];
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
      } else if (key == 'required') {
        if (value is! List ||
            value.any((v) => v is! String) ||
            value.toSet().length != value.length) {
          _fail(node, key, 'Expected a list of unique property names.');
        }
        node.keywords[key] = value;
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
        node.keywords[key] = List<Object?>.unmodifiable(unique);
      } else if (key == 'const') {
        node.keywords[key] = value;
      } else if (counts.contains(key)) {
        if (value is! num || value < 0 || value % 1 != 0) {
          _fail(node, key, 'Expected a non-negative integer.');
        }
        node.keywords[key] = value;
      } else if (bounds.contains(key)) {
        if (value is! num) _fail(node, key, 'Expected a number.');
        node.keywords[key] = value;
      } else if (key == 'uniqueItems') {
        if (value is! bool) _fail(node, key, 'Expected a boolean.');
        node.keywords[key] = value;
      } else {
        _unsupported(node, key, 'Keyword "$key" is not supported.');
      }
    }
  }

  JsonSchemaImportDiagnostic _diagnostic(
    _ImportedNode node,
    String key,
    String message,
    String code,
  ) => JsonSchemaImportDiagnostic(
    code: code,
    documentUri: node.documentUri,
    pointer: key.isEmpty
        ? node.pointer
        : '${node.pointer}/${_importPointerToken(key)}',
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
  }) => throw JsonSchemaImportException([
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
