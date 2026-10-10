import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer/schema_first_names.dart';
import 'json_schema_generation_exception.dart';

/// How generated models treat properties a JSON Schema object doesn't declare.
enum AckUnknownPropertiesMode {
  /// Follow the schema: `additionalProperties: false` rejects unknown keys.
  schema,

  /// Accept and keep unknown keys on every object, for clients that must
  /// tolerate additive server changes to strict schemas.
  preserve,
}

/// Whether to prefer typed fields or exact source-schema value wrappers.
enum AckJsonSchemaModelMode { auto, validated }

/// Options for [generateAckSchemaLibrary].
final class AckJsonSchemaLibraryOptions {
  /// Creates generation options.
  const AckJsonSchemaLibraryOptions({
    this.unknownProperties = AckUnknownPropertiesMode.schema,
    this.documentPaths = const {},
    this.assertFormats = false,
    this.modelMode = AckJsonSchemaModelMode.auto,
  });

  /// Parses builder options from `build.yaml`.
  ///
  /// Throws an [ArgumentError] for an unknown key or value.
  factory AckJsonSchemaLibraryOptions.fromConfig(Map<String, Object?> config) {
    final unknown = config.keys.toSet().difference({
      'unknown_properties',
      'documents',
      'assert_formats',
      'model_mode',
    });
    if (unknown.isNotEmpty) {
      throw ArgumentError(
        'Unknown ack_json_schema options: ${unknown.join(', ')}. '
        'Supported: unknown_properties, documents, assert_formats, model_mode.',
      );
    }
    final mode = config['unknown_properties'] ?? 'schema';
    final paths = config['documents'] ?? const <String, String>{};
    if (paths is! Map ||
        paths.keys.any((key) => key is! String) ||
        paths.values.any((value) => value is! String)) {
      throw ArgumentError.value(
        paths,
        'documents',
        'Must map retrieval URI strings to package asset paths.',
      );
    }
    final assertFormats = config['assert_formats'] ?? false;
    if (assertFormats is! bool) {
      throw ArgumentError.value(
        assertFormats,
        'assert_formats',
        'Must be a boolean.',
      );
    }
    return AckJsonSchemaLibraryOptions(
      assertFormats: assertFormats,
      modelMode: switch (config['model_mode'] ?? 'auto') {
        'auto' => AckJsonSchemaModelMode.auto,
        'validated' => AckJsonSchemaModelMode.validated,
        final value => throw ArgumentError.value(
          value,
          'model_mode',
          'Must be "auto" or "validated".',
        ),
      },
      documentPaths: {
        for (final entry in paths.entries)
          Uri.parse(entry.key as String): entry.value as String,
      },
      unknownProperties: switch (mode) {
        'schema' => AckUnknownPropertiesMode.schema,
        'preserve' => AckUnknownPropertiesMode.preserve,
        _ => throw ArgumentError.value(
          mode,
          'unknown_properties',
          'Must be "schema" or "preserve".',
        ),
      },
    );
  }

  /// How objects treat undeclared properties.
  final AckUnknownPropertiesMode unknownProperties;

  /// External schema resources declared in `build.yaml`, keyed by retrieval
  /// URI and stored at package-local asset paths.
  final Map<Uri, String> documentPaths;

  /// Assert known formats even under the standard 2020-12 dialect.
  final bool assertFormats;

  /// `auto` retains typed v1 models where possible; `validated` uses exact
  /// source-schema value wrappers for every model.
  final AckJsonSchemaModelMode modelMode;
}

/// A generated Dart library and the document it was checked against.
final class AckJsonSchemaLibrary {
  const AckJsonSchemaLibrary._({
    required this.source,
    required this.effectiveDocument,
    required this.widenedPointers,
  });

  /// The formatted Dart source.
  final String source;

  /// The input document with the option widenings applied.
  ///
  /// Validated value models use `Ack.fromJsonSchema` directly. Typed models
  /// retain the documented integer-range and string-length edge cases.
  final Map<String, Object?> effectiveDocument;

  /// Pointers of objects whose unknown-property rule an option widened.
  final List<String> widenedPointers;
}

/// Generates typed Ack models or validated value models from a draft 2020-12
/// [document].
///
/// [documentUri] identifies the document in diagnostics and resolves its
/// references. [documents] supplies offline external resources. [partStem]
/// names typed model parts (`<stem>.g.dart`); value-model fallback needs no
/// parts. Set [includeParts] to `false` for a plain typed schema library.
///
/// Throws an [AckJsonSchemaGenerationException] for invalid or unresolvable
/// schema resources, with source pointers where available.
AckJsonSchemaLibrary generateAckSchemaLibrary({
  required Object? document,
  required Uri documentUri,
  required String partStem,
  AckJsonSchemaLibraryOptions options = const AckJsonSchemaLibraryOptions(),
  Map<Uri, Object> documents = const {},
  bool includeParts = true,
  Version? languageVersion,
}) {
  if (options.modelMode == AckJsonSchemaModelMode.auto) {
    final translator = _Translator(documentUri, options, documents);
    final effective = translator.prepare(document);
    if (effective != null) translator.translate(effective);
    if (translator.diagnostics.isEmpty) {
      final unformatted = _emit(
        translator,
        documentUri: documentUri,
        partStem: partStem,
        includeParts: includeParts,
      );
      return AckJsonSchemaLibrary._(
        source: DartFormatter(
          languageVersion:
              languageVersion ?? DartFormatter.latestLanguageVersion,
        ).format(unformatted),
        effectiveDocument: effective!,
        widenedPointers: List.unmodifiable(translator.widened),
      );
    }
  }

  // The typed translator is intentionally conservative. A valid document it
  // cannot lower still generates a value model with the source validator as
  // its parse/encode boundary, so no 2020-12 assertion is silently dropped.
  final fallbackDocuments = <Uri, Object>{
    for (final entry in documents.entries) entry.key: _deepCopy(entry.value)!,
  };
  final fallback = _Translator(documentUri, options, fallbackDocuments);
  final fallbackDocument = fallback.prepareFallback(document);
  if (fallback.diagnostics.isNotEmpty) {
    throw AckJsonSchemaGenerationException(documentUri, fallback.diagnostics);
  }
  return AckJsonSchemaLibrary._(
    source:
        DartFormatter(
          languageVersion:
              languageVersion ?? DartFormatter.latestLanguageVersion,
        ).format(
          _emitFallback(
            fallbackDocument!,
            documentUri: documentUri,
            documents: fallbackDocuments,
            assertFormats: options.assertFormats,
            widened: fallback.widened,
          ),
        ),
    effectiveDocument: fallbackDocument,
    widenedPointers: List.unmodifiable(fallback.widened),
  );
}

const _annotations = {
  'title',
  'description',
  'default',
  'examples',
  r'$comment',
  'deprecated',
  'readOnly',
  'writeOnly',
};

const _typeKeywords = {
  'string': {'type', 'minLength', 'maxLength', 'pattern'},
  'integer': {
    'type',
    'minimum',
    'maximum',
    'exclusiveMinimum',
    'exclusiveMaximum',
  },
  'number': {
    'type',
    'minimum',
    'maximum',
    'exclusiveMinimum',
    'exclusiveMaximum',
  },
  'boolean': {'type'},
  'array': {'type', 'items', 'minItems', 'maxItems', 'uniqueItems'},
  'object': {
    'type',
    'properties',
    'required',
    'additionalProperties',
    'propertyNames',
  },
};

// Dart names that a generated library already uses unprefixed.
const _reservedModelNames = {
  'Object',
  'String',
  'List',
  'Map',
  'MapEntry',
  'Set',
  'Iterable',
  'Iterator',
  'Future',
  'Comparable',
  'Null',
  'Never',
  'Function',
  'Type',
  'Record',
  'Enum',
  'Symbol',
  'Duration',
  'DateTime',
  'Uri',
  'RegExp',
};

final class _Declaration {
  _Declaration(this.name, this.code);

  final String name;
  final String code;
}

final class _Expr {
  const _Expr(this.code, {this.nullable = false, this.reference});

  final String code;
  final bool nullable;

  /// The model this expression names, when it is a model reference.
  final String? reference;
}

final class _Translator {
  _Translator(this.documentUri, this.options, this.documents);

  final Uri documentUri;
  final AckJsonSchemaLibraryOptions options;
  final Map<Uri, Object> documents;
  final diagnostics = <AckJsonSchemaDiagnostic>[];
  final declarations = <_Declaration>[];
  final widened = <String>[];

  final _modelNames = <String>{};
  final _edges = <String, Set<String>>{};
  final _edgePointers = <(String, String), String>{};
  late Map<String, Object?> _defs;

  void _fail(String pointer, String message) =>
      diagnostics.add(AckJsonSchemaDiagnostic(pointer, message));

  /// Validates the document shape and names, applies widenings, and gates the
  /// result through `Ack.fromJsonSchema`. Returns `null` on failure.
  Map<String, Object?>? prepare(Object? document) {
    if (document is! Map<String, Object?>) {
      _fail('#', 'Expected a JSON object with a "\$defs" map.');
      return null;
    }
    const rootKeys = {
      r'$schema',
      r'$defs',
      r'$comment',
      'title',
      'description',
    };
    for (final key in document.keys) {
      if (!rootKeys.contains(key)) {
        _fail(
          '#/${_token(key)}',
          'Root keyword "$key" is not supported. Put each model under '
              '"\$defs".',
        );
      }
    }
    final defs = document[r'$defs'];
    if (defs is! Map<String, Object?> || defs.isEmpty) {
      _fail('#/\$defs', 'Expected a non-empty "\$defs" map of models.');
      return null;
    }
    for (final name in defs.keys) {
      final pointer = '#/\$defs/${_token(name)}';
      if (!RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(name)) {
        _fail(
          pointer,
          'Model name "$name" must be UpperCamelCase letters and digits.',
        );
      } else if (_reservedModelNames.contains(name)) {
        _fail(pointer, 'Model name "$name" shadows a dart:core type.');
      }
    }
    if (diagnostics.isNotEmpty) return null;

    final effective = _deepCopy(document)! as Map<String, Object?>;
    if (options.unknownProperties == AckUnknownPropertiesMode.preserve) {
      _widen(effective, '#');
    }
    _gate(effective, defs.keys);
    return diagnostics.isEmpty ? effective : null;
  }

  /// Prepares a 2020-12 schema and its supplied resources for value models.
  Map<String, Object?>? prepareFallback(Object? document) {
    if (document is! Map<String, Object?> && document is! bool) {
      _fail('#', 'Expected a JSON Schema object or boolean.');
      return null;
    }
    final effective = document is bool
        ? <String, Object?>{
            'allOf': [document],
          }
        : _deepCopy(document)! as Map<String, Object?>;
    final defs = effective[r'$defs'];
    if (defs != null && defs is! Map<String, Object?>) {
      _fail(r'#/$defs', 'Expected a map of schemas.');
      return null;
    }
    if (options.unknownProperties == AckUnknownPropertiesMode.preserve) {
      _widen(effective, '#');
      for (final entry in documents.entries) {
        _widen(entry.value, '${entry.key}#');
      }
    }
    try {
      Ack.fromJsonSchema(
        effective,
        baseUri: documentUri,
        documents: documents,
        assertFormats: options.assertFormats,
      );
    } on JsonSchemaImportException catch (error) {
      for (final diagnostic in error.diagnostics) {
        _fail(diagnostic.pointer, '${diagnostic.message} (${diagnostic.code})');
      }
    }
    if (defs case final Map<String, Object?> schemas when schemas.isNotEmpty) {
      _gate(effective, schemas.keys);
    }
    return diagnostics.isEmpty ? effective : null;
  }

  /// Sets `additionalProperties: false` to `true` on every schema, walking
  /// only keywords whose values are schemas.
  void _widen(Object? node, String pointer) {
    if (node is! Map<String, Object?>) return;
    if (node['additionalProperties'] == false) {
      node['additionalProperties'] = true;
      widened.add(pointer);
    }
    for (final keyword in const [
      r'$defs',
      'definitions',
      'properties',
      'patternProperties',
      'dependentSchemas',
    ]) {
      if (node[keyword] case final Map<String, Object?> schemas) {
        for (final MapEntry(:key, :value) in schemas.entries) {
          _widen(value, '$pointer/$keyword/${_token(key)}');
        }
      }
    }
    for (final keyword in const [
      'items',
      'additionalProperties',
      'propertyNames',
      'contains',
      'not',
      'if',
      'then',
      'else',
      'unevaluatedProperties',
      'unevaluatedItems',
    ]) {
      _widen(node[keyword], '$pointer/$keyword');
    }
    for (final keyword in const ['anyOf', 'allOf', 'oneOf', 'prefixItems']) {
      if (node[keyword] case final List<Object?> schemas) {
        for (var i = 0; i < schemas.length; i++) {
          _widen(schemas[i], '$pointer/$keyword/$i');
        }
      }
    }
  }

  void _gate(Map<String, Object?> effective, Iterable<String> names) {
    try {
      Ack.fromJsonSchema(
        {
          'allOf': [
            for (final name in names)
              {
                r'$ref': documentUri
                    .replace(fragment: '/\$defs/${_token(name)}')
                    .toString(),
              },
          ],
        },
        baseUri: documentUri.resolve('__ack_json_schema_gate__.json'),
        documents: {...documents, documentUri: effective},
        assertFormats: options.assertFormats,
      );
    } on JsonSchemaImportException catch (error) {
      for (final diagnostic in error.diagnostics) {
        _fail(diagnostic.pointer, '${diagnostic.message} (${diagnostic.code})');
      }
    }
  }

  void translate(Map<String, Object?> effective) {
    _defs = effective[r'$defs']! as Map<String, Object?>;
    _modelNames.addAll(_defs.keys);
    for (final MapEntry(key: name, value: node) in _defs.entries) {
      final pointer = '#/\$defs/$name';
      final expr = _expr(
        node,
        pointer,
        owner: name,
        hoistName: name,
        root: true,
      );
      if (expr == null) continue;
      if (expr.nullable) {
        _fail(
          pointer,
          'A "\$defs" model cannot be nullable. Make the properties that '
          'reference it nullable instead.',
        );
      } else if (expr.reference != null) {
        _fail(
          pointer,
          'A model that only references another model is not '
          'supported. Reference "${expr.reference}" directly.',
        );
      } else {
        declarations.add(_Declaration(name, expr.code));
      }
    }
    _rejectCycles();
  }

  _Expr? _expr(
    Object? node,
    String pointer, {
    required String owner,
    required String hoistName,
    bool root = false,
  }) {
    if (node == true) return const _Expr('ack.Ack.any()', nullable: true);
    if (node == false) {
      _fail(pointer, 'The "false" schema accepts no value.');
      return null;
    }
    if (node is! Map<String, Object?>) {
      _fail(pointer, 'Expected a schema object.');
      return null;
    }
    final keywords = node.keys.where((key) => !_annotations.contains(key));
    final keys = keywords.toSet();
    final description = node['description'];
    String describe(String code) => description is String
        ? '$code.describe(${_literal(description)})'
        : code;

    if (keys.isEmpty) {
      return _Expr(describe('ack.Ack.any()'), nullable: true);
    }
    if (keys.contains(r'$ref')) {
      if (keys.length > 1) {
        _fail(pointer, 'Keywords next to "\$ref" are not supported.');
        return null;
      }
      return _ref(node[r'$ref'], '$pointer/\$ref', owner);
    }
    for (final keyword in ['allOf', 'oneOf', 'not', 'if', 'then', 'else']) {
      if (keys.contains(keyword)) {
        _fail('$pointer/$keyword', 'Keyword "$keyword" is not supported.');
        return null;
      }
    }
    if (keys.contains('anyOf')) {
      if (keys.length > 1) {
        _fail(pointer, 'Keywords next to "anyOf" are not supported.');
        return null;
      }
      return _anyOf(
        node['anyOf'],
        pointer,
        owner,
        hoistName,
        describe,
        root: root,
      );
    }
    if (keys.contains('enum')) return _enum(node, pointer, keys, describe);
    if (keys.contains('const')) return _const(node, pointer, keys, describe);

    final type = node['type'];
    if (type == null) {
      _fail(pointer, 'Add a "type"; untyped schemas are not supported.');
      return null;
    }
    final types = type is List<Object?> ? type : [type];
    final nullable = types.contains('null');
    final nonNull = [
      for (final t in types)
        if (t != 'null') t,
    ];
    if (nonNull.isEmpty) {
      _fail(
        '$pointer/type',
        'A schema that only accepts null is not '
            'supported.',
      );
      return null;
    }
    if (nonNull.length > 1) {
      if (keys.length > 1) {
        _fail(pointer, 'A multi-type schema cannot also have constraints.');
        return null;
      }
      final union = _scalarUnion(nonNull, '$pointer/type');
      return union == null ? null : _Expr(describe(union), nullable: nullable);
    }
    final single = nonNull.single! as String;
    final allowed = _typeKeywords[single];
    if (allowed == null) {
      _fail('$pointer/type', 'Type "$single" is not supported.');
      return null;
    }
    for (final keyword in keys.difference(allowed)) {
      _fail(
        '$pointer/${_token(keyword)}',
        'Keyword "$keyword" cannot be represented in a generated model.',
      );
    }
    if (!allowed.containsAll(keys)) return null;

    if (single == 'object') {
      final object = _object(node, pointer, owner, hoistName, root: root);
      if (object == null) return null;
      return object.reference == null
          ? _Expr(describe(object.code), nullable: nullable)
          : _Expr(object.code, nullable: nullable, reference: object.reference);
    }
    final code = switch (single) {
      'string' => _string(node, pointer),
      'integer' => _integer(node),
      'number' => _number(node),
      'boolean' => 'ack.Ack.boolean()',
      _ => _array(node, pointer, owner, hoistName),
    };
    if (code == null) return null;
    return _Expr(describe(code), nullable: nullable);
  }

  _Expr? _ref(Object? ref, String pointer, String owner) {
    final match = ref is String
        ? RegExp(r'^#/\$defs/([A-Za-z0-9]+)$').firstMatch(ref)
        : null;
    final name = match?.group(1);
    if (name == null || !_defs.containsKey(name)) {
      _fail(
        pointer,
        'Only "#/\$defs/<Name>" references to a model in this '
        'document are supported.',
      );
      return null;
    }
    _edge(owner, name, pointer);
    return _Expr(_variable(name), reference: name);
  }

  _Expr? _anyOf(
    Object? branches,
    String pointer,
    String owner,
    String hoistName,
    String Function(String) describe, {
    required bool root,
  }) {
    final flat = <(Object?, String)>[];
    void flatten(Object? list, String at) {
      if (list is! List<Object?>) return;
      for (var i = 0; i < list.length; i++) {
        final branch = list[i];
        final branchPointer = '$at/anyOf/$i';
        if (branch is Map<String, Object?> &&
            branch.keys.every(
              (k) => k == 'anyOf' || _annotations.contains(k),
            ) &&
            branch.containsKey('anyOf')) {
          flatten(branch['anyOf'], branchPointer);
        } else {
          flat.add((branch, branchPointer));
        }
      }
    }

    flatten(branches, pointer);
    bool isNull(Object? branch) =>
        branch is Map<String, Object?> &&
        branch.keys.every((k) => k == 'type' || _annotations.contains(k)) &&
        (branch['type'] == 'null' ||
            (branch['type'] is List && _listEquals(branch['type'], ['null'])));
    final nullable = flat.any((b) => isNull(b.$1));
    final rest = [
      for (final branch in flat)
        if (!isNull(branch.$1)) branch,
    ];
    if (rest.isEmpty) {
      _fail(pointer, 'An "anyOf" that only accepts null is not supported.');
      return null;
    }
    if (rest.length == 1) {
      final (branch, branchPointer) = rest.single;
      final inner = _expr(
        branch,
        branchPointer,
        owner: owner,
        hoistName: hoistName,
        root: root,
      );
      if (inner == null) return null;
      return _Expr(
        inner.reference == null ? describe(inner.code) : inner.code,
        nullable: nullable || inner.nullable,
        reference: inner.reference,
      );
    }
    final types = <Object?>[];
    for (final (branch, branchPointer) in rest) {
      final bare =
          branch is Map<String, Object?> &&
          branch.keys.every((k) => k == 'type' || _annotations.contains(k)) &&
          branch['type'] is String;
      if (!bare) {
        _fail(
          branchPointer,
          'Only unions of bare string, number, and boolean '
          'types are supported.',
        );
        return null;
      }
      types.add(branch['type']);
    }
    final union = _scalarUnion(types, pointer);
    return union == null ? null : _Expr(describe(union), nullable: nullable);
  }

  String? _scalarUnion(List<Object?> types, String pointer) {
    const checks = {'string': 'String', 'number': 'num', 'boolean': 'bool'};
    final dartTypes = <String>[];
    for (final type in types) {
      final check = checks[type];
      if (check == null) {
        _fail(
          pointer,
          'Type "$type" cannot be part of a union; only string, '
          'number, and boolean can.',
        );
        return null;
      }
      if (!dartTypes.contains(check)) dartTypes.add(check);
    }
    final test = dartTypes.map((t) => 'value is $t').join(' || ');
    final names = [
      for (final type in types.toSet())
        if (type == 'number') 'a number' else 'a $type',
    ];
    return 'ack.Ack.any().refine((value) => $test, '
        'message: ${_literal('Expected ${names.join(' or ')}.')})';
  }

  _Expr? _enum(
    Map<String, Object?> node,
    String pointer,
    Set<String> keys,
    String Function(String) describe,
  ) {
    if (!{'enum', 'type'}.containsAll(keys)) {
      _fail(
        pointer,
        'Keywords next to "enum" other than "type" are not '
        'supported.',
      );
      return null;
    }
    final type = node['type'];
    final types = type == null ? null : (type is List ? type : [type]);
    if (types != null &&
        (types.any((t) => t != 'string' && t != 'null') ||
            !types.contains('string'))) {
      _fail('$pointer/type', 'A string enum needs a string-compatible type.');
      return null;
    }
    final values = node['enum'];
    if (values is! List<Object?>) return null;
    final allowsNull = types == null || types.contains('null');
    final strings = <String>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) continue;
      if (value is! String) {
        _fail('$pointer/enum/$i', 'Only string enum values are supported.');
        return null;
      }
      if (!strings.contains(value)) strings.add(value);
    }
    if (strings.isEmpty) {
      _fail('$pointer/enum', 'An enum needs at least one string value.');
      return null;
    }
    return _Expr(
      describe('ack.Ack.enumString([${strings.map(_literal).join(', ')}])'),
      nullable: allowsNull && values.contains(null),
    );
  }

  _Expr? _const(
    Map<String, Object?> node,
    String pointer,
    Set<String> keys,
    String Function(String) describe,
  ) {
    final value = node['const'];
    final type = node['type'];
    final types = type == null ? null : (type is List ? type : [type]);
    if (value is! String ||
        !{'const', 'type'}.containsAll(keys) ||
        (types != null &&
            (types.any((t) => t != 'string' && t != 'null') ||
                !types.contains('string')))) {
      _fail(
        '$pointer/const',
        'Only a string "const" with an optional string-compatible "type" '
            'is supported.',
      );
      return null;
    }
    return _Expr(describe('ack.Ack.literal(${_literal(value)})'));
  }

  String? _string(Map<String, Object?> node, String pointer) {
    final buffer = StringBuffer('ack.Ack.string()');
    if (node['minLength'] case final int n) buffer.write('.minLength($n)');
    if (node['maxLength'] case final int n) buffer.write('.maxLength($n)');
    if (node['pattern'] case final String pattern) {
      if (RegExp(r'\\[pPu]\{').hasMatch(pattern)) {
        _fail(
          '$pointer/pattern',
          r'Unicode-mode patterns (\p{…}, \P{…}, '
              r'\u{…}) are not supported.',
        );
        return null;
      }
      buffer.write('.matches(${_literal(pattern)})');
    }
    return buffer.toString();
  }

  String _integer(Map<String, Object?> node) {
    final buffer = StringBuffer('ack.Ack.integer()');
    int? integral(Object? value) =>
        value is num && value == value.truncate() ? value.toInt() : null;
    if (node['minimum'] case final num n) {
      buffer.write('.min(${integral(n) ?? n.ceil()})');
    }
    if (node['exclusiveMinimum'] case final num n) {
      final exact = integral(n);
      buffer.write(
        exact == null ? '.min(${n.ceil()})' : '.greaterThan($exact)',
      );
    }
    if (node['maximum'] case final num n) {
      buffer.write('.max(${integral(n) ?? n.floor()})');
    }
    if (node['exclusiveMaximum'] case final num n) {
      final exact = integral(n);
      buffer.write(exact == null ? '.max(${n.floor()})' : '.lessThan($exact)');
    }
    return buffer.toString();
  }

  String _number(Map<String, Object?> node) {
    final buffer = StringBuffer('ack.Ack.number()');
    for (final (keyword, method) in [
      ('minimum', 'min'),
      ('exclusiveMinimum', 'greaterThan'),
      ('maximum', 'max'),
      ('exclusiveMaximum', 'lessThan'),
    ]) {
      if (node[keyword] case final num n) buffer.write('.$method(${_num(n)})');
    }
    return buffer.toString();
  }

  String? _array(
    Map<String, Object?> node,
    String pointer,
    String owner,
    String hoistName,
  ) {
    if (!node.containsKey('items')) {
      _fail(pointer, 'Arrays need an "items" schema.');
      return null;
    }
    final item = _expr(
      node['items'],
      '$pointer/items',
      owner: owner,
      hoistName: '${hoistName}Item',
    );
    if (item == null) return null;
    if (item.nullable) {
      _fail(
        '$pointer/items',
        'Nullable array items are not supported; Ack '
            'lists cannot contain null.',
      );
      return null;
    }
    final buffer = StringBuffer('ack.Ack.list(${item.code})');
    if (node['minItems'] case final int n) buffer.write('.minItems($n)');
    if (node['maxItems'] case final int n) buffer.write('.maxItems($n)');
    if (node['uniqueItems'] == true) buffer.write('.unique()');
    return buffer.toString();
  }

  _Expr? _object(
    Map<String, Object?> node,
    String pointer,
    String owner,
    String hoistName, {
    required bool root,
  }) {
    final properties = node['properties'];
    final additional = node['additionalProperties'];
    final propertyNames = node['propertyNames'];
    final open =
        additional == null ||
        additional == true ||
        (additional is Map && additional.isEmpty);
    final hasProperties =
        properties is Map<String, Object?> && properties.isNotEmpty;

    final required = <String>{
      for (final key in node['required'] as List<Object?>? ?? const [])
        if (key is String) key,
    };
    final declared = properties is Map<String, Object?>
        ? properties.keys.toSet()
        : <String>{};
    final missingRequired = required.difference(declared);
    for (final missing in missingRequired) {
      _fail(
        '$pointer/required',
        'Required property "$missing" is not declared in "properties".',
      );
    }
    if (missingRequired.isNotEmpty) return null;

    if (propertyNames != null &&
        (hasProperties || !_jsonEquals(propertyNames, {'type': 'string'}))) {
      _fail(
        '$pointer/propertyNames',
        'Only "propertyNames": {"type": '
            '"string"} on a map-shaped object is supported.',
      );
      return null;
    }
    if (!hasProperties && root && additional is Map && additional.isNotEmpty) {
      _fail(
        pointer,
        'A "\$defs" model must be an object with "properties"; '
        'map-shaped models are not supported.',
      );
      return null;
    }
    if (!hasProperties && !root && (open || additional is Map)) {
      // A map-shaped object: string keys to one value schema.
      if (open) return const _Expr('ack.Ack.map(ack.Ack.any().nullable())');
      final value = _expr(
        additional,
        '$pointer/additionalProperties',
        owner: owner,
        hoistName: '${hoistName}Value',
      );
      if (value == null) return null;
      return _Expr(
        'ack.Ack.map(${value.code}${value.nullable ? '.nullable()' : ''})',
      );
    }
    if (additional is Map && additional.isNotEmpty) {
      _fail(
        '$pointer/additionalProperties',
        'An "additionalProperties" '
            'schema next to "properties" is not supported.',
      );
      return null;
    }

    final entries = <String>[];
    if (properties is Map<String, Object?>) {
      for (final MapEntry(key: key, value: value) in properties.entries) {
        final fieldPointer = '$pointer/properties/${_token(key)}';
        if (key == hoistName) {
          _fail(
            fieldPointer,
            'Property "$key" would have the same name as its generated '
            'model class.',
          );
          continue;
        }
        final problem = ackSchemaFirstFieldNameProblem(
          key,
          capturesExtras: open,
        );
        if (problem != null) {
          _fail(fieldPointer, 'Property "$key" $problem');
          continue;
        }
        final field = _expr(
          value,
          fieldPointer,
          owner: owner,
          hoistName: '$hoistName${key[0].toUpperCase()}${key.substring(1)}',
        );
        if (field == null) continue;
        entries.add(
          '${_literal(key)}: ${field.code}'
          '${field.nullable ? '.nullable()' : ''}'
          '${required.contains(key) ? '' : '.optional()'}',
        );
      }
    }
    final extras = open ? ', additionalProperties: true' : '';
    final code = 'ack.Ack.object({${entries.join(', ')}}$extras)';
    if (root) return _Expr(code);

    if (_modelNames.contains(hoistName)) {
      _fail(
        pointer,
        'The generated model name "$hoistName" for this inline '
        'object is already used. Move it to "\$defs" under a unique name.',
      );
      return null;
    }
    _modelNames.add(hoistName);
    final description = node['description'];
    declarations.add(
      _Declaration(
        hoistName,
        description is String
            ? '$code.describe(${_literal(description)})'
            : code,
      ),
    );
    _edge(owner, hoistName, pointer);
    return _Expr(_variable(hoistName), reference: hoistName);
  }

  void _edge(String from, String to, String pointer) {
    (_edges[from] ??= {}).add(to);
    _edgePointers[(from, to)] ??= pointer;
  }

  void _rejectCycles() {
    final state = <String, int>{};
    void visit(String node) {
      state[node] = 1;
      for (final next in _edges[node] ?? const <String>{}) {
        if (state[next] == 1) {
          _fail(
            _edgePointers[(node, next)]!,
            'Recursive references are not '
            'supported yet ("$node" → "$next").',
          );
        } else if (state[next] == null) {
          visit(next);
        }
      }
      state[node] = 2;
    }

    for (final name in _defs.keys) {
      if (state[name] == null) visit(name);
    }
  }
}

String _emit(
  _Translator translator, {
  required Uri documentUri,
  required String partStem,
  required bool includeParts,
}) {
  final source = documentUri.pathSegments.isEmpty
      ? '$documentUri'
      : documentUri.pathSegments.last;
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// dart format width=80')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln('// coverage:ignore-file')
    ..writeln('//')
    ..writeln('// Generated from $source by ack_generator:ack_json_schema.');
  if (translator.widened.isNotEmpty) {
    buffer.writeln('// unknown_properties: preserve widened these objects:');
    for (final pointer in translator.widened) {
      buffer.writeln('// - ${_commentText(pointer)}');
    }
  }
  buffer
    ..writeln()
    ..writeln("import 'package:ack/ack.dart' as ack;")
    ..writeln();
  if (includeParts) {
    buffer
      ..writeln("part '$partStem.g.dart';")
      ..writeln();
  }
  for (final declaration in translator.declarations) {
    buffer
      ..writeln('@ack.Schemable(name: ${_literal(declaration.name)})')
      ..writeln('final ${_variable(declaration.name)} = ${declaration.code};')
      ..writeln();
  }
  return buffer.toString();
}

String _emitFallback(
  Map<String, Object?> document, {
  required Uri documentUri,
  required Map<Uri, Object> documents,
  required bool assertFormats,
  required List<String> widened,
}) {
  final defs = document[r'$defs'] as Map<String, Object?>? ?? const {};
  const rootAnnotations = {
    r'$schema',
    r'$defs',
    r'$comment',
    'title',
    'description',
  };
  final hasRootModel =
      defs.isEmpty ||
      document.keys.any((key) => !rootAnnotations.contains(key));
  final names = <String>{};
  String uniqueName(String key) {
    final words = key
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    var base = words.isEmpty
        ? 'Definition'
        : words
              .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
              .join();
    if (RegExp(r'^[0-9]').hasMatch(base)) base = 'Definition$base';
    if (_reservedModelNames.contains(base)) base = '${base}Model';
    var name = base;
    var suffix = 2;
    while (!names.add(name)) {
      name = '$base${suffix++}';
    }
    return name;
  }

  final definitions = <(String, String)>[
    for (final key in defs.keys) (uniqueName(key), key),
  ];
  final rootName = hasRootModel
      ? uniqueName(names.contains('Root') ? 'DocumentRoot' : 'Root')
      : null;
  final models = <(String, String?)>[
    if (rootName != null) (rootName, null),
    ...definitions,
  ];
  final uri = _literal(documentUri.toString());
  final lookupUri = _literal(
    documentUri.resolve('__ack_json_schema_generated__.json').toString(),
  );
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// dart format width=80')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln('// coverage:ignore-file')
    ..writeln('//')
    ..writeln('// Draft 2020-12 value models retain source-schema validation.')
    ..writeln(
      '// Complex shapes use Object? values, not inferred typed fields.',
    );
  if (widened.isNotEmpty) {
    buffer.writeln('// unknown_properties: preserve widened these objects:');
    for (final pointer in widened) {
      buffer.writeln('// - ${_commentText(pointer)}');
    }
  }
  buffer
    ..writeln()
    ..writeln("import 'dart:convert';")
    ..writeln("import 'package:ack/ack.dart' as ack;")
    ..writeln()
    ..writeln('final Object _jsonSchemaDocument =')
    ..writeln('    jsonDecode(${_literal(jsonEncode(document))}) as Object;')
    ..writeln('final Map<Uri, Object> _jsonSchemaDocuments = {')
    ..writeln('  Uri.parse($uri): _jsonSchemaDocument,');
  for (final entry in documents.entries) {
    buffer.writeln(
      '  Uri.parse(${_literal(entry.key.toString())}): '
      'jsonDecode(${_literal(jsonEncode(entry.value))}) as Object,',
    );
  }
  buffer
    ..writeln('};')
    ..writeln();
  for (final (name, definition) in models) {
    final variable = _variable(name);
    final formatOption = assertFormats ? ', assertFormats: true' : '';
    final schemaExpression = definition == null
        ? 'ack.Ack.fromJsonSchema(_jsonSchemaDocument, '
              'baseUri: Uri.parse($uri), documents: {'
              'for (final entry in _jsonSchemaDocuments.entries) '
              'if (entry.key != Uri.parse($uri)) entry.key: entry.value}'
              '$formatOption)'
        : 'ack.Ack.fromJsonSchema('
              "{r'\$ref': ${_literal(documentUri.replace(fragment: '/\$defs/${_token(definition)}').toString())}}, "
              'baseUri: Uri.parse($lookupUri), '
              'documents: _jsonSchemaDocuments$formatOption)';
    buffer
      ..writeln('final $variable = $schemaExpression;')
      ..writeln()
      ..writeln('/// A validated Draft 2020-12 value model.')
      ..writeln('final class $name {')
      ..writeln('  const $name._(this.value);')
      ..writeln()
      ..writeln('  /// The parsed, immutable JSON value.')
      ..writeln('  final Object? value;')
      ..writeln()
      ..writeln('  /// The exact source-schema validator for this model.')
      ..writeln(
        '  static ack.AckSchema<Object, Object> get schema => $variable;',
      )
      ..writeln()
      ..writeln('  static $name parse(Object? value) =>')
      ..writeln('      safeParse(value).getOrThrow()!;')
      ..writeln()
      ..writeln('  static ack.SchemaResult<$name> safeParse(Object? value) =>')
      ..writeln(
        '      schema.safeParse(value).map((parsed) => $name._(parsed));',
      )
      ..writeln()
      ..writeln('  static Object? encode($name model) =>')
      ..writeln('      safeEncode(model).getOrThrow();')
      ..writeln()
      ..writeln('  static ack.SchemaResult<Object> safeEncode($name model) =>')
      ..writeln('      schema.safeEncode(model.value);')
      ..writeln()
      ..writeln('  Object? toJson() => encode(this);')
      ..writeln()
      ..writeln('  static Map<String, Object?> toJsonSchema() =>')
      ..writeln('      schema.toJsonSchema();')
      ..writeln('}')
      ..writeln();
  }
  return buffer.toString();
}

String _variable(String modelName) =>
    '${modelName[0].toLowerCase()}${modelName.substring(1)}Schema';

String _commentText(String value) => value
    .replaceAll('\\', r'\\')
    .replaceAll('\r', r'\r')
    .replaceAll('\n', r'\n')
    .replaceAll('\t', r'\t')
    .replaceAll('\u2028', r'\u2028')
    .replaceAll('\u2029', r'\u2029');

/// A single-quoted Dart string literal with every special character escaped,
/// so descriptions, patterns, and keys stay one simple literal.
String _literal(String value) {
  final buffer = StringBuffer("'");
  for (final rune in value.runes) {
    buffer.write(switch (rune) {
      0x5C => r'\\',
      0x27 => r"\'",
      0x24 => r'\$',
      0x0A => r'\n',
      0x0D => r'\r',
      0x09 => r'\t',
      < 0x20 => '\\u{${rune.toRadixString(16)}}',
      _ => String.fromCharCode(rune),
    });
  }
  buffer.write("'");
  return buffer.toString();
}

String _num(num value) =>
    value is int || value != value.truncate() ? '$value' : '${value.toInt()}';

String _token(String key) => key.replaceAll('~', '~0').replaceAll('/', '~1');

Object? _deepCopy(Object? value) => switch (value) {
  final Map<String, Object?> map => {
    for (final MapEntry(:key, :value) in map.entries) key: _deepCopy(value),
  },
  final List<Object?> list => [for (final item in list) _deepCopy(item)],
  _ => value,
};

bool _jsonEquals(Object? a, Object? b) => jsonEncode(a) == jsonEncode(b);

bool _listEquals(Object? a, List<Object?> b) =>
    a is List<Object?> && _jsonEquals(a, b);
