/// Instances that probe whether two validators agree on a JSON Schema model.
///
/// Starts from one valid instance and applies one mutation at a time: remove a
/// property, set it to `null`, replace it with a value of each JSON type, step
/// over a bound, and add unknown keys, including inside nested objects.
final class InstanceCorpus {
  /// Creates a corpus over the `$defs` of an effective document.
  InstanceCorpus(Map<String, Object?> document)
    : _defs = document[r'$defs']! as Map<String, Object?>;

  final Map<String, Object?> _defs;

  static const _probes = <Object?>[
    's',
    0,
    1,
    1.0,
    1.5,
    true,
    <Object?>[],
    <String, Object?>{},
  ];

  /// Every probe instance for the model named [name].
  List<Object?> instancesFor(String name) {
    final schema = _defs[name];
    final full = valid(schema)! as Map<String, Object?>;
    return [
      full,
      _requiredOnly(schema, full),
      <String, Object?>{},
      null,
      'not an object',
      ..._objectMutations(schema, full, depth: 0),
    ];
  }

  /// A canonical valid value for [schema].
  Object? valid(Object? schema) {
    final node = _resolve(schema);
    if (node is! Map<String, Object?>) return 'any';
    if (node['anyOf'] case final List<Object?> branches) {
      return valid(branches.firstWhere((b) => !_isNull(b)));
    }
    if (node['enum'] case final List<Object?> values) {
      return values.firstWhere((v) => v != null);
    }
    if (node.containsKey('const')) return node['const'];
    return switch (_type(node)) {
      'string' => _validString(node),
      'integer' => _validInteger(node),
      'number' => _validNumber(node),
      'boolean' => true,
      'array' => _validArray(node),
      'object' => _validObject(node),
      _ => 'any',
    };
  }

  Iterable<Object?> _objectMutations(
    Object? schema,
    Map<String, Object?> instance, {
    required int depth,
  }) sync* {
    final node = _resolve(schema);
    if (node is! Map<String, Object?>) return;
    final properties = node['properties'];
    if (properties is Map<String, Object?>) {
      for (final MapEntry(key: key, value: property) in properties.entries) {
        final without = {...instance}..remove(key);
        yield without;
        for (final value in [null, ..._probes, ..._boundaryValues(property)]) {
          yield {...instance, key: value};
        }
        final nested = _resolve(_nonNull(property));
        final nestedValue = instance[key];
        if (depth == 0 &&
            nested is Map<String, Object?> &&
            _type(nested) == 'object' &&
            nestedValue is Map<String, Object?>) {
          for (final mutation in _objectMutations(
            nested,
            nestedValue,
            depth: depth + 1,
          )) {
            yield {...instance, key: mutation};
          }
        }
      }
    }
    yield {...instance, '__x': 1};
    yield {...instance, '__x': null};
  }

  List<Object?> _boundaryValues(Object? schema) {
    final node = _resolve(_nonNull(schema));
    if (node is! Map<String, Object?>) return const [];
    return [
      if (node['minLength'] case final int n when n > 0) 'a' * (n - 1),
      if (node['maxLength'] case final int n) 'a' * (n + 1),
      if (node['minLength'] case final int n) 'a' * n,
      if (node['maxLength'] case final int n) 'a' * n,
      for (final keyword in const [
        'minimum',
        'maximum',
        'exclusiveMinimum',
        'exclusiveMaximum',
      ])
        if (node[keyword] case final num n) ...[
          n,
          n - 1,
          n + 1,
          n - 0.5,
          n + 0.5,
        ],
      if (node['enum'] != null || node['const'] != null) 'not-a-member',
      // Every member, plus near misses, so a dropped or case-folded member
      // shows up as a disagreement.
      for (final member in [
        ...?(node['enum'] as List<Object?>?),
        if (node['const'] case final String value) value,
      ])
        if (member is String) ...[member, '${member}x', member.toLowerCase()],
      if (_type(node) == 'array') ...[
        <Object?>[null],
        [valid(node['items']), valid(node['items'])],
        [for (var i = 0; i < ((node['maxItems'] as int?) ?? 3) + 1; i++) 'x$i'],
        for (final probe in _probes) [probe],
      ],
      if (_type(node) == 'object' && node['properties'] == null) ...[
        {'k': 's'},
        {'k': 1},
        {'k': null},
      ],
    ];
  }

  Map<String, Object?> _requiredOnly(
    Object? schema,
    Map<String, Object?> full,
  ) {
    final node = _resolve(schema)! as Map<String, Object?>;
    final required = {...?(node['required'] as List<Object?>?)};
    return {
      for (final MapEntry(:key, :value) in full.entries)
        if (required.contains(key)) key: value,
    };
  }

  String _validString(Map<String, Object?> node) {
    if (node['examples'] case [final String example, ...]) return example;
    final minimum = (node['minLength'] as int?) ?? 1;
    return 'a' * (minimum < 1 ? 1 : minimum);
  }

  int _validInteger(Map<String, Object?> node) {
    final exclusive = node['exclusiveMinimum'] as num?;
    final minimum = node['minimum'] as num?;
    return switch ((minimum, exclusive)) {
      (final num m, _) => m.ceil(),
      (_, final num e) => e.floor() + 1,
      _ => 1,
    };
  }

  num _validNumber(Map<String, Object?> node) {
    final minimum = node['minimum'] as num?;
    final exclusive = node['exclusiveMinimum'] as num?;
    return minimum ?? (exclusive == null ? 1.5 : exclusive + 0.5);
  }

  List<Object?> _validArray(Map<String, Object?> node) {
    final count = (node['minItems'] as int?) ?? 1;
    final item = valid(node['items']);
    return [
      for (var i = 0; i < count; i++)
        node['uniqueItems'] == true && item is String ? '$item$i' : item,
    ];
  }

  Map<String, Object?> _validObject(Map<String, Object?> node) {
    final properties = node['properties'];
    if (properties is Map<String, Object?>) {
      return {
        for (final MapEntry(:key, :value) in properties.entries)
          key: valid(value),
      };
    }
    final additional = node['additionalProperties'];
    return {
      'k': additional is Map && additional.isNotEmpty ? valid(additional) : 'v',
    };
  }

  Object? _resolve(Object? schema) {
    if (schema is Map<String, Object?> && schema[r'$ref'] is String) {
      final ref = schema[r'$ref']! as String;
      return _defs[ref.substring(r'#/$defs/'.length)];
    }
    return schema;
  }

  Object? _nonNull(Object? schema) {
    if (schema is Map<String, Object?> && schema['anyOf'] is List) {
      final branches = (schema['anyOf']! as List).where((b) => !_isNull(b));
      return branches.length == 1 ? _nonNull(branches.single) : schema;
    }
    return schema;
  }

  static bool _isNull(Object? schema) =>
      schema is Map && (schema['type'] == 'null');

  static String? _type(Map<String, Object?> node) => switch (node['type']) {
    final String type => type,
    final List<Object?> types =>
      types.firstWhere((t) => t != 'null') as String?,
    _ => null,
  };
}
