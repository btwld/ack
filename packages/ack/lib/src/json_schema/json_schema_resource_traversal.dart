part of '../schemas/schema.dart';

/// Indexes resource scopes and discovers dialects through shared schema locations.
extension _JsonSchemaResourceTraversal on _JsonSchemaCompiler {
  /// Resolves resource scope without registering it or traversing children.
  /// Discovery uses the same rules on detached nodes and suppresses diagnostics
  /// for candidates that may turn out to be inert annotation payloads.
  _ImportedNode _resourceNode(
    Object source,
    Uri document,
    String pointer,
    Uri base,
    Uri dialect,
  ) {
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
    return node;
  }

  /// Enumerates schema-valued locations in document order. Normal indexing
  /// selects core/non-core locations and validates active containers. Detached
  /// dialect discovery omits [coreOnly], probing all recognized locations before
  /// their vocabulary is known; malformed containers remain inert in that pass.
  Iterable<({Object? source, String keyword, String suffix})> _schemaChildren(
    _ImportedNode node, {
    bool? coreOnly,
  }) sync* {
    final source = node.source;
    if (source is! Map<String, Object?>) return;
    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      if (coreOnly != null) {
        final coreLocation = key == r'$defs' || key == 'definitions';
        if (coreLocation != coreOnly || !node.isKeywordActive(key)) continue;
      }
      if (_JsonSchemaCompiler.mapKeywords.contains(key)) {
        if (value is! Map<String, Object?>) {
          if (coreOnly != null) _fail(node, key, 'Expected a map of schemas.');
          continue;
        }
        for (final child in value.entries) {
          yield (
            source: child.value,
            keyword: key,
            suffix: '$key/${escapeJsonPointerToken(child.key)}',
          );
        }
      } else if (_JsonSchemaCompiler.childKeywords.contains(key)) {
        yield (source: value, keyword: key, suffix: key);
      } else if (_JsonSchemaCompiler.listKeywords.contains(key)) {
        if (value is! List || value.isEmpty) {
          if (coreOnly != null) {
            _fail(node, key, 'Expected a non-empty list of schemas.');
          }
          continue;
        }
        for (final (i, child) in value.indexed) {
          yield (source: child, keyword: key, suffix: '$key/$i');
        }
      }
    }
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
    final node = _resourceNode(
      source,
      document,
      pointer,
      base,
      dialect ?? _JsonSchemaCompiler.standardDialect,
    );
    base = node.baseUri;
    locations[(document, pointer)] = node;
    if (isRoot) _register(resources, document, node, r'$id');
    if (isRoot || (source is Map && source.containsKey(r'$id'))) {
      _register(resources, base, node, r'$id');
    }
    if (source is! Map<String, Object?>) return node;
    if (source.containsKey(r'$anchor')) {
      final anchor = source[r'$anchor'];
      if (anchor is! String ||
          !_JsonSchemaCompiler._anchorPattern.hasMatch(anchor)) {
        _fail(node, r'$anchor', 'Invalid anchor name.');
      }
      _register(anchors, base.replace(fragment: anchor), node, r'$anchor');
    }
    if (source.containsKey(r'$dynamicAnchor')) {
      final anchor = source[r'$dynamicAnchor'];
      if (anchor is! String ||
          !_JsonSchemaCompiler._anchorPattern.hasMatch(anchor)) {
        _fail(node, r'$dynamicAnchor', 'Invalid dynamic anchor name.');
      }
      node.dynamicAnchorName = anchor;
      final uri = base.replace(fragment: anchor);
      _register(dynamicAnchors, uri, node, r'$dynamicAnchor');
      _register(anchors, uri, node, r'$dynamicAnchor');
    }
    // Core definition locations cannot be disabled. Register them now so a
    // bundled dialect can be found before interpreting optional keywords.
    _indexChildren(node, coreOnly: true);
    _pendingChildren.add(node);
    return node;
  }

  void _indexChildren(_ImportedNode node, {required bool coreOnly}) {
    for (final child in _schemaChildren(node, coreOnly: coreOnly)) {
      _index(
        child.source ?? _invalidSchema(node, child.keyword),
        node.documentUri,
        '${node.pointer}/${child.suffix}',
        node.baseUri,
        dialect: node.dialectUri,
      );
    }
  }

  void _indexPendingChildren() {
    while (_pendingChildren.isNotEmpty) {
      final count = _pendingChildren.length;
      var progressed = false;
      for (var i = 0; i < count; i++) {
        final node = _pendingChildren.removeFirst();
        if (!resources.containsKey(node.dialectUri) &&
            !_JsonSchemaCompiler.draft7Dialects.contains(node.dialectUri)) {
          _pendingChildren.add(node);
          continue;
        }
        _configureDialect(node);
        _indexChildren(node, coreOnly: false);
        progressed = true;
      }
      // A selected dialect can be bundled beneath its own applicator keywords.
      // Discover that resource before reporting an unresolved dependency, but
      // only when its vocabulary makes the containing locations schemas.
      if (!progressed &&
          !_pendingChildren
              .toList(growable: false)
              .any(_discoverBundledDialect)) {
        _configureDialect(_pendingChildren.first);
      }
    }
  }

  bool _discoverBundledDialect(_ImportedNode node) {
    final wanted = node.dialectUri;

    bool visit(_ImportedNode parent, List<(_ImportedNode, String)> path) {
      final source = parent.source;
      if (source is! Map<String, Object?>) return false;

      bool visitChild(Object? value, String keyword, String suffix) {
        if (value is! Map<String, Object?>) return false;
        final _ImportedNode child;
        try {
          child = _resourceNode(
            value,
            parent.documentUri,
            '${parent.pointer}/$suffix',
            parent.baseUri,
            parent.dialectUri,
          );
        } on JsonSchemaImportException {
          // Probing must not validate unrelated, potentially inert payloads.
          return false;
        }
        final childPath = [...path, (parent, keyword)];
        if (value.containsKey(r'$id') && child.baseUri == wanted) {
          if (value[r'$vocabulary'] is! Map<String, Object?>) return false;
          for (final (scope, key) in childPath) {
            if (scope.dialectUri != wanted &&
                !resources.containsKey(scope.dialectUri) &&
                !_JsonSchemaCompiler.draft7Dialects.contains(
                  scope.dialectUri,
                )) {
              return false;
            }
            _configureDialect(scope, bundledDialect: child);
            if (!scope.isKeywordActive(key)) return false;
          }
          _index(
            value,
            child.documentUri,
            child.pointer,
            parent.baseUri,
            dialect: parent.dialectUri,
          );
          return true;
        }
        return visit(child, childPath);
      }

      for (final child in _schemaChildren(parent)) {
        if (visitChild(child.source, child.keyword, child.suffix)) return true;
      }
      return false;
    }

    // Probe detached nodes so unsuccessful candidates cannot alter compilation.
    return visit(
      _ImportedNode(
        node.source,
        node.documentUri,
        node.pointer,
        node.baseUri,
        node.dialectUri,
      ),
      [],
    );
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
        // Delayed optional-keyword indexing can discover an explicitly supplied
        // copy after the offline fallback was registered. Only an identical
        // fallback may be replaced; two caller-owned identifiers still conflict.
        final replacesFallback =
            _fallbackDocumentUris.contains(prior.documentUri) &&
            !_fallbackDocumentUris.contains(node.documentUri) &&
            deepEquals(prior.source, node.source);
        if (!replacesFallback) {
          _fail(node, keyword, 'Duplicate schema identifier: $uri.');
        }
      }
    }
    registry[uri] = node;
  }

  void _configureDialect(_ImportedNode node, {_ImportedNode? bundledDialect}) {
    final dialect = bundledDialect?.baseUri == node.dialectUri
        ? bundledDialect
        : resources[node.dialectUri];
    if (dialect == null) {
      if (_JsonSchemaCompiler.draft7Dialects.contains(node.dialectUri)) {
        node.applicatorVocabulary = true;
        node.unevaluatedVocabulary = true;
        node.validationVocabulary = true;
        node.formatAssertion = assertFormats;
        return;
      }
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
    // A discovery candidate may live in an inactive keyword's annotation data.
    // Check its requirements only after discovery proves it is a schema and
    // normal indexing registers it as a resource.
    if (bundledDialect == null) {
      _checkRequiredVocabularies(node, r'$schema', vocabulary);
    }
    node.applicatorVocabulary = vocabulary.containsKey(
      _JsonSchemaCompiler.applicatorVocabularyUri,
    );
    node.unevaluatedVocabulary = vocabulary.containsKey(
      _JsonSchemaCompiler.unevaluatedVocabularyUri,
    );
    node.validationVocabulary = vocabulary.containsKey(
      _JsonSchemaCompiler.validationVocabularyUri,
    );
    node.metadataVocabulary = vocabulary.containsKey(
      'https://json-schema.org/draft/2020-12/vocab/meta-data',
    );
    node.contentVocabulary = vocabulary.containsKey(
      'https://json-schema.org/draft/2020-12/vocab/content',
    );
    node.formatAnnotationVocabulary = vocabulary.containsKey(
      'https://json-schema.org/draft/2020-12/vocab/format-annotation',
    );
    node.formatAssertion =
        assertFormats ||
        vocabulary.containsKey(
          _JsonSchemaCompiler.formatAssertionVocabularyUri,
        );
  }

  _ImportedNode? _resolvePointer(_ImportedNode resource, String fragment) {
    var pointer = resource.pointer;
    var base = resource.baseUri;
    var dialect = resource.dialectUri;
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
      pointer = '$pointer/${escapeJsonPointerToken(token)}';
      if (locations[(resource.documentUri, pointer)] case final indexed?) {
        base = indexed.baseUri;
        dialect = indexed.dialectUri;
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
      dialect: dialect,
    );
    _indexPendingChildren();
    return indexed;
  }
}
