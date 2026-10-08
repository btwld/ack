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
  }) {
    final compiler = _JsonSchemaCompiler();
    final base = baseUri ?? Uri.parse('ack-import:///root.json');
    final root = compiler.addDocument(document, base);
    for (final entry in documents.entries) {
      compiler.addDocument(entry.value, base.resolveUri(entry.key));
    }
    compiler.compile(root);
    if (compiler.diagnostics.isNotEmpty) {
      throw JsonSchemaImportException._(compiler.diagnostics);
    }
    return ImportedJsonSchema._(root);
  }

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

  /// Builds root-scoped definitions for the shared schema-model renderer.
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
        entry.value: entry.key.render((node) => names[node]!),
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

_ImportViolation? _checkImportedNode(_ImportedNode node, Object? value) {
  _ImportViolation fail(String keyword) => _ImportViolation(node, keyword);
  if (node.source == false) return fail('');
  final keywords = node.keywords;
  if (keywords['type'] case final type?) {
    final matches = type is List
        ? type.any((t) => _isImportType(t, value))
        : _isImportType(type, value);
    if (!matches) return fail('type');
  }
  if (keywords.containsKey('const') && !deepEquals(value, keywords['const'])) {
    return fail('const');
  }
  if (keywords['enum'] case final List values) {
    if (!values.any((v) => deepEquals(v, value))) return fail('enum');
  }
  if (node.reference case final target?) {
    final error = _checkImportedNode(target, value);
    if (error != null) return error.via(const [r'$ref']);
  }
  for (final (i, target) in (node.lists['allOf'] ?? const []).indexed) {
    final error = _checkImportedNode(target, value);
    if (error != null) return error.via(['allOf', '$i']);
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
  if (node.children['if'] case final condition?) {
    final key = _checkImportedNode(condition, value) == null ? 'then' : 'else';
    if (node.children[key] case final branch?) {
      final error = _checkImportedNode(branch, value);
      if (error != null) return error.via([key]);
    }
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
    if (keywords['multipleOf'] case final num divisor) {
      if (!_isJsonMultipleOf(value, divisor)) return fail('multipleOf');
    }
    if (keywords['format'] case final String format) {
      if (!_isValidImportedNumericFormat(format, value)) {
        return fail('format');
      }
    }
  }
  final (length, minKey, maxKey) = switch (value) {
    String() => (value.runes.length, 'minLength', 'maxLength'),
    List() => (value.length, 'minItems', 'maxItems'),
    Map() => (value.length, 'minProperties', 'maxProperties'),
    _ => (null, '', ''),
  };
  if (length != null) {
    if (keywords[minKey] case final num minimum) {
      if (length < minimum) return fail(minKey);
    }
    if (keywords[maxKey] case final num maximum) {
      if (length > maximum) return fail(maxKey);
    }
  }
  if (value is String) {
    if (keywords['format'] case final String format) {
      if (!_isValidImportedStringFormat(format, value)) {
        return fail('format');
      }
    }
    if (node.pattern case final pattern?) {
      if (!pattern.hasMatch(value)) return fail('pattern');
    }
  }
  if (value is Map) {
    for (final key in keywords['required'] as List? ?? const []) {
      if (!value.containsKey(key)) return fail('required').at(key as String);
    }
    final properties = node.maps['properties'] ?? const {};
    for (final entry in value.entries) {
      final key = entry.key as String;
      final declared = properties[key];
      final target = declared ?? node.children['additionalProperties'];
      if (target == null) continue;
      final error = _checkImportedNode(target, entry.value);
      if (error != null) {
        return error.at(
          key,
          declared == null
              ? const ['additionalProperties']
              : ['properties', key],
        );
      }
    }
    if (node.children['propertyNames'] case final target?) {
      for (final key in value.keys) {
        final error = _checkImportedNode(target, key);
        if (error != null) {
          return error.atPropertyName(key as String, const ['propertyNames']);
        }
      }
    }
  }
  if (value is List) {
    if (keywords['uniqueItems'] == true) {
      for (var i = 0; i < value.length; i++) {
        for (var j = 0; j < i; j++) {
          if (deepEquals(value[i], value[j])) {
            return fail('uniqueItems');
          }
        }
      }
    }
    if (node.children['contains'] case final target?) {
      if (!value.any((item) => _checkImportedNode(target, item) == null)) {
        return fail('contains');
      }
    }
    if (node.children['items'] case final target?) {
      for (var i = 0; i < value.length; i++) {
        final error = _checkImportedNode(target, value[i]);
        if (error != null) return error.at('$i', const ['items']);
      }
    }
  }
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

bool _isValidImportedNumericFormat(String format, num value) =>
    switch (format) {
      'int32' =>
        value.isFinite &&
            value % 1 == 0 &&
            value >= -2147483648 &&
            value <= 2147483647,
      'int64' => value.isFinite && value % 1 == 0,
      'uint32' =>
        value.isFinite && value % 1 == 0 && value >= 0 && value <= 4294967295,
      'uint64' => value.isFinite && value % 1 == 0 && value >= 0,
      'float' || 'double' => value.isFinite,
      _ => true,
    };

bool _isValidImportedStringFormat(String format, String value) =>
    switch (format) {
      'date-time' => isValidRfc3339DateTime(value),
      'date' => _isFullDate(value),
      'email' => _isEmail(value),
      'uuid' => _uuidFormatPattern.hasMatch(value),
      'uri' => _isUri(value),
      'ipv4' => _isIpv4(value),
      'ipv6' => _isIpv6(value),
      _ => true,
    };

final _fullDatePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

final _uuidFormatPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

final _ipv4PartPattern = RegExp(r'^(0|[1-9][0-9]{0,2})$');

bool _isFullDate(String value) {
  final match = _fullDatePattern.firstMatch(value);
  if (match == null) return false;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

bool _isIpv4(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return false;
  for (final part in parts) {
    if (!_ipv4PartPattern.hasMatch(part)) return false;
    if (int.parse(part) > 255) return false;
  }
  return true;
}

bool _isIpv6(String value) {
  if (value.isEmpty || RegExp(r'[^0-9A-Fa-f:.]').hasMatch(value)) {
    return false;
  }
  var address = value;
  var embeddedGroups = 0;
  if (value.contains('.')) {
    final separator = value.lastIndexOf(':');
    if (separator < 0) return false;
    final tail = value.substring(separator + 1);
    if (!_isIpv4(tail)) return false;
    address = value.substring(0, separator);
    if (address.endsWith(':')) address += ':';
    if (address.contains('.')) return false;
    embeddedGroups = 2;
  }
  final compressed = address.contains('::');
  if (compressed) {
    if (address.contains(':::') ||
        address.indexOf('::', address.indexOf('::') + 2) >= 0 ||
        (address.startsWith(':') && !address.startsWith('::')) ||
        (address.endsWith(':') && !address.endsWith('::'))) {
      return false;
    }
  } else if (address.startsWith(':') || address.endsWith(':')) {
    return false;
  }
  final groups = address.split(':').where((group) => group.isNotEmpty).toList();
  if (groups.any((group) => group.length > 4)) return false;
  final expectedGroups = 8 - embeddedGroups;
  return compressed
      ? groups.length < expectedGroups
      : groups.length == expectedGroups;
}

bool _isAsciiHostname(String value) {
  if (value.isEmpty || value.length > 253) return false;
  for (final label in value.split('.')) {
    if (label.isEmpty ||
        label.length > 63 ||
        label.startsWith('-') ||
        label.endsWith('-') ||
        !RegExp(r'^[A-Za-z0-9-]+$').hasMatch(label)) {
      return false;
    }
  }
  return true;
}

bool _isEmail(String value) {
  final match = RegExp(
    r'^("(?:[^"\\]|\\[\s\S])*"|[^@]+)@(.+)$',
  ).firstMatch(value);
  if (match == null) return false;
  final local = match[1]!;
  final domain = match[2]!;
  if (!local.runes.every((rune) => rune < 128)) return false;
  if (local.startsWith('"')) {
    if (!local.endsWith('"')) return false;
    if (RegExp(r'[\u0000-\u001f\u007f]').hasMatch(local)) return false;
  } else {
    final atom = RegExp(r"^[A-Za-z0-9!#\$%&'*+/=?^_`{|}~.-]+$");
    if (!atom.hasMatch(local) ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return false;
    }
  }
  if (domain.startsWith('[') && domain.endsWith(']')) {
    final literal = domain.substring(1, domain.length - 1);
    if (literal.toLowerCase().startsWith('ipv6:')) {
      return _isIpv6(literal.substring(5));
    }
    return _isIpv4(literal);
  }
  return _isAsciiHostname(domain);
}

bool _hasValidPercents(String value) {
  for (var i = 0; i < value.length; i++) {
    if (value[i] != '%') continue;
    if (i + 2 >= value.length ||
        !RegExp(r'^[0-9a-fA-F]{2}$').hasMatch(value.substring(i + 1, i + 3))) {
      return false;
    }
    i += 2;
  }
  return true;
}

bool _isUri(String value) {
  if (!_hasValidPercents(value)) return false;
  if (RegExp(r'[\u0000-\u0020\u007f<>"{}|\\^`]').hasMatch(value)) {
    return false;
  }
  if (value.runes.any((rune) => rune > 127)) return false;
  if (!RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:').hasMatch(value)) {
    return false;
  }
  try {
    final firstBracket = value.indexOf('[');
    final lastBracket = value.lastIndexOf(']');
    if (firstBracket >= 0 || lastBracket >= 0) {
      final authorityMarker = value.indexOf('//');
      if (authorityMarker < 0) return false;
      final authorityStart = authorityMarker + 2;
      var authorityEnd = value.length;
      for (final delimiter in ['/', '?', '#']) {
        final next = value.indexOf(delimiter, authorityStart);
        if (next >= 0 && next < authorityEnd) authorityEnd = next;
      }
      if (firstBracket < authorityStart ||
          firstBracket >= authorityEnd ||
          lastBracket < firstBracket ||
          lastBracket >= authorityEnd) {
        return false;
      }
      final literal = value.substring(firstBracket + 1, lastBracket);
      if (!_isIpv6(literal) &&
          !RegExp(
            r"^[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!$&'()*+,;=:-]+$",
          ).hasMatch(literal)) {
        return false;
      }
    }
    final uri = Uri.parse(value);
    if (!uri.hasScheme) return false;
    if (uri.path.contains('[') || uri.path.contains(']')) return false;
    if (uri.hasAuthority &&
        uri.host.contains(':') &&
        !value.contains('[${uri.host}]')) {
      return false;
    }
    return true;
  } on FormatException {
    return false;
  }
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
