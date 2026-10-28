part of 'json_schema_library.dart';

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

  /// Sets `additionalProperties: false` and `unevaluatedProperties: false` to
  /// `true` on every schema, walking only keywords whose values are schemas.
  void _widen(Object? node, String pointer) {
    if (node is! Map<String, Object?>) return;
    var didWiden = false;
    if (node['additionalProperties'] == false) {
      node['additionalProperties'] = true;
      didWiden = true;
    }
    if (node['unevaluatedProperties'] == false) {
      node['unevaluatedProperties'] = true;
      didWiden = true;
    }
    if (didWiden) widened.add(pointer);
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
        ? '$code.describe(${dartStringLiteral(description)})'
        : code;

    if (keys.isEmpty) {
      return _Expr(describe('ack.Ack.any()'), nullable: true);
    }
    if (keys.contains(r'$ref')) {
      if (keys.length > 1) {
        _fail(pointer, 'Keywords next to "\$ref" are not supported.');
        return null;
      }
      return _ref(node[r'$ref'], '$pointer/\$ref', owner, describe);
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
      final union = _scalarUnion(nonNull, '$pointer/type', root: root);
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
      'integer' => _integer(node, pointer),
      'number' => _number(node),
      'boolean' => 'ack.Ack.boolean()',
      _ => _array(node, pointer, owner, hoistName),
    };
    if (code == null) return null;
    return _Expr(describe(code), nullable: nullable);
  }

  _Expr? _ref(
    Object? ref,
    String pointer,
    String owner,
    String Function(String) describe,
  ) {
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
    return _Expr(describe(_variable(name)), reference: name);
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
        describe(inner.code),
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
    final union = _scalarUnion(types, pointer, root: root);
    return union == null ? null : _Expr(describe(union), nullable: nullable);
  }

  String? _scalarUnion(
    List<Object?> types,
    String pointer, {
    required bool root,
  }) {
    if (root) {
      _fail(pointer, 'Named scalar unions require a validated value model.');
      return null;
    }
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
        'message: ${dartStringLiteral('Expected ${names.join(' or ')}.')})';
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
      describe(
        'ack.Ack.enumString([${strings.map(dartStringLiteral).join(', ')}])',
      ),
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
    return _Expr(describe('ack.Ack.literal(${dartStringLiteral(value)})'));
  }

  static bool _fitsInInt64(num value) =>
      value is int ||
      (value.isFinite &&
          value >= -9223372036854775808.0 &&
          value < 9223372036854775808.0);

  int? _sizeBound(Map<String, Object?> node, String keyword, String pointer) {
    final value = node[keyword];
    if (value == null) return null;
    // The importer gate has already checked that the bound is integral.
    // Guard conversion as toInt() clamps values outside the integer range.
    if (value is num && _fitsInInt64(value) && value.toInt() == value) {
      return value.toInt();
    }
    _fail(
      '$pointer/$keyword',
      'Bound cannot be represented as a Dart integer.',
    );
    return null;
  }

  String? _string(Map<String, Object?> node, String pointer) {
    final buffer = StringBuffer('ack.Ack.string()');
    if (_sizeBound(node, 'minLength', pointer) case final int n) {
      buffer.write('.minLength($n)');
    }
    if (_sizeBound(node, 'maxLength', pointer) case final int n) {
      buffer.write('.maxLength($n)');
    }
    if (node.containsKey('pattern')) {
      // matches() uses non-Unicode RegExp semantics, unlike the importer.
      // Even patterns without Unicode escapes (for example ^.$) can differ.
      _fail('$pointer/pattern', 'Patterns require Unicode-mode validation.');
      return null;
    }
    return buffer.toString();
  }

  String? _integer(Map<String, Object?> node, String pointer) {
    final buffer = StringBuffer('ack.Ack.integer()');
    int? integral(Object? value) =>
        value is num && _fitsInInt64(value) && value == value.truncate()
        ? value.toInt()
        : null;
    if (node['minimum'] case final num n) {
      if (!_fitsInInt64(n)) {
        _fail(
          '$pointer/minimum',
          'Bound cannot be represented as a Dart integer.',
        );
        return null;
      }
      buffer.write('.min(${integral(n) ?? n.ceil()})');
    }
    if (node['exclusiveMinimum'] case final num n) {
      if (!_fitsInInt64(n)) {
        _fail(
          '$pointer/exclusiveMinimum',
          'Bound cannot be represented as a Dart integer.',
        );
        return null;
      }
      final exact = integral(n);
      buffer.write(
        exact == null ? '.min(${n.ceil()})' : '.greaterThan($exact)',
      );
    }
    if (node['maximum'] case final num n) {
      if (!_fitsInInt64(n)) {
        _fail(
          '$pointer/maximum',
          'Bound cannot be represented as a Dart integer.',
        );
        return null;
      }
      buffer.write('.max(${integral(n) ?? n.floor()})');
    }
    if (node['exclusiveMaximum'] case final num n) {
      if (!_fitsInInt64(n)) {
        _fail(
          '$pointer/exclusiveMaximum',
          'Bound cannot be represented as a Dart integer.',
        );
        return null;
      }
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
    if (_sizeBound(node, 'minItems', pointer) case final n?) {
      buffer.write('.minItems($n)');
    }
    if (_sizeBound(node, 'maxItems', pointer) case final n?) {
      buffer.write('.maxItems($n)');
    }
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
          '${dartStringLiteral(key)}: ${field.code}'
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
            ? '$code.describe(${dartStringLiteral(description)})'
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

String _num(num value) {
  if (value is int) {
    return value.abs() <= 9007199254740992 ? '$value' : '${value.toDouble()}';
  }
  if (value.isFinite &&
      value.abs() <= 9007199254740992.0 &&
      value == value.truncate()) {
    return '${value.toInt()}';
  }
  return '$value';
}

String _token(String key) => key.replaceAll('~', '~0').replaceAll('/', '~1');

Object? _deepCopy(Object? value) => switch (value) {
  final Map<String, Object?> map => {
    for (final MapEntry(:key, :value) in map.entries) key: _deepCopy(value),
  },
  final List<Object?> list => [for (final item in list) _deepCopy(item)],
  _ => value,
};

bool _jsonEquals(Object? a, Object? b) => deepEquals(a, b);

bool _listEquals(Object? a, List<Object?> b) =>
    a is List<Object?> && deepEquals(a, b);
