part of 'schema.dart';

Object? _serializeDefaultForJsonSchema<T extends Object>(
  AckSchema<T> inner,
  T defaultValue,
) {
  if (inner is EnumSchema && defaultValue is Enum) {
    return defaultValue.name;
  }

  if (inner is CodecSchema) {
    final encoded = inner.safeEncode(defaultValue);
    if (encoded.isOk) return encoded.getOrNull();
    return null;
  }

  try {
    return jsonDecode(jsonEncode(defaultValue));
  } catch (_) {
    return null;
  }
}

Map<String, Object?> _applySchemaNullability(
  Map<String, Object?> schema,
  bool isNullable,
) {
  final anyOf = schema['anyOf'];
  if (anyOf is! List) {
    if (!isNullable) return schema;
    return {
      if (schema['default'] != null) 'default': schema['default'],
      'anyOf': [
        {
          for (final entry in schema.entries)
            if (entry.key != 'default') entry.key: entry.value,
        },
        {'type': 'null'},
      ],
    };
  }

  final hasNullBranch = anyOf.any((entry) {
    return entry is Map && entry['type'] == 'null';
  });
  if (isNullable == hasNullBranch) return schema;

  if (isNullable) {
    return {
      ...schema,
      'anyOf': [
        ...anyOf,
        {'type': 'null'},
      ],
    };
  }

  final nonNullBranches = [
    for (final entry in anyOf)
      if (entry is! Map || entry['type'] != 'null') entry,
  ];
  if (nonNullBranches.length == 1 && nonNullBranches.single is Map) {
    return {
      ...(nonNullBranches.single as Map).cast<String, Object?>(),
      if (schema['default'] != null) 'default': schema['default'],
      if (schema['description'] != null) 'description': schema['description'],
    };
  }

  return {...schema, 'anyOf': nonNullBranches};
}

/// Schema wrapper that supplies a cloned default on the parse path.
@immutable
final class DefaultSchema<T extends Object> extends AckSchema<T>
    with FluentSchema<T, DefaultSchema<T>> {
  final AckSchema<T> inner;
  final T defaultValue;

  DefaultSchema(
    this.inner,
    this.defaultValue, {
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<T>> constraints = const [],
    List<Refinement<T>> refinements = const [],
  }) : super(
         isNullable: isNullable ?? inner.isNullable,
         isOptional: isOptional ?? inner.isOptional,
         description: description ?? inner.description,
         constraints: constraints,
         refinements: refinements,
       );

  @override
  SchemaType get schemaType => inner.schemaType;

  SchemaResult<T> _validateDefault(SchemaContext context) {
    final cloned = cloneDefault(defaultValue);
    final safeDefault = cloned is T ? cloned : defaultValue;
    final result = inner._validateRuntime(safeDefault, context);
    if (result.isFail) return result.castFail();
    final value = result.getOrThrow()!;
    return applyConstraintsAndRefinements(value, context);
  }

  @override
  @protected
  SchemaResult<T> _validateRuntime(Object? value, SchemaContext context) {
    // Defaults only fire on the parse direction. Encode must reject null for
    // non-nullable inner schemas rather than silently substituting the default.
    if (value == null && context.operation == SchemaOperation.parse) {
      return _validateDefault(context);
    }

    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    final result = inner._validateRuntime(value, context);
    if (result.isFail) return result.castFail();
    final validated = result.getOrNull();
    if (validated == null) return SchemaResult.ok(null);
    return applyConstraintsAndRefinements(validated, context);
  }

  @override
  @protected
  SchemaResult<T> decodeBoundary(Object? input, SchemaContext context) {
    if (input == null && context.operation == SchemaOperation.parse) {
      return _validateDefault(context);
    }

    if (input == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    final result = inner.decodeBoundary(input, context);
    if (result.isFail) return result.castFail();
    final decoded = result.getOrNull();
    if (decoded == null) return SchemaResult.ok(null);
    return applyConstraintsAndRefinements(decoded, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeBoundary(T value, SchemaContext context) {
    return inner.encodeBoundary(value, context);
  }

  @override
  DefaultSchema<T> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    T? defaultValue,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return DefaultSchema<T>(
      inner,
      defaultValue ?? this.defaultValue,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final schema = _applySchemaNullability(
      Map<String, Object?>.of(inner.toJsonSchema()),
      isNullable,
    );
    final serializedDefault = _serializeDefaultForJsonSchema(
      inner,
      defaultValue,
    );
    if (serializedDefault != null) {
      schema['default'] = serializedDefault;
    }
    if (description != inner.description && description != null) {
      schema['description'] = description;
    }
    return mergeConstraintSchemas(schema);
  }

  @override
  Map<String, Object?> toMap() {
    return {...inner.toMap(), 'defaultValue': defaultValue};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DefaultSchema<T>) return false;
    return baseFieldsEqual(other) &&
        inner == other.inner &&
        defaultValue == other.defaultValue;
  }

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, inner, defaultValue);
}
