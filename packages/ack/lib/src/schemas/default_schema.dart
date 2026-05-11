part of 'schema.dart';

/// Returns a JSON-safe form of [value], or `null` if it cannot be encoded.
///
/// Used by [DefaultSchema.toJsonSchema] so runtime objects that an identity
/// encoder may pass through (e.g. a `DateTime` returned by
/// `Ack.instance<DateTime>().encodeBoundary`) never appear as JSON Schema
/// defaults.
Object? _jsonSerializableOrNull(Object? value) {
  try {
    return jsonDecode(jsonEncode(value));
  } catch (_) {
    return null;
  }
}

/// Adds a JSON Schema null branch when wrapper nullability requires it.
///
/// Wraps [schema] in an `anyOf [..., {type: null}]` form when [isNullable] is
/// true and the schema does not already include a null branch. Hoists any
/// existing `default` to the top so the null wrapper does not bury it.
Map<String, Object?> _applyNullableWrapper(
  Map<String, Object?> schema,
  bool isNullable,
) {
  if (!isNullable) return schema;
  final anyOf = schema['anyOf'];
  if (anyOf is List &&
      anyOf.any((entry) => entry is Map && entry['type'] == 'null')) {
    return schema;
  }
  final defaultValue = schema['default'];
  return {
    if (defaultValue != null) 'default': defaultValue,
    'anyOf': [
      {
        for (final entry in schema.entries)
          if (entry.key != 'default') entry.key: entry.value,
      },
      {'type': 'null'},
    ],
  };
}

/// A schema wrapper that supplies a parse-time default value.
///
/// Wraps an inner [AckSchema] of type [T] and returns [defaultValue] when the
/// parse input is `null`. The default is a runtime `T`, so codec defaults use
/// the decoded form (e.g. a `DateTime`, not its ISO-8601 string). The default
/// is validated against the inner schema, so runtime-side constraints
/// declared on the inner still apply.
///
/// Encoding never synthesizes [defaultValue]; null handling on the encode
/// path is controlled by this wrapper's nullability, which by default mirrors
/// the inner schema's.
///
/// ```dart
/// // Boundary `null` → runtime 'guest'.
/// final schema = Ack.string().withDefault('guest');
/// schema.parse(null);  // → 'guest'
///
/// // Encode does NOT inject the default; nullability of the inner controls null:
/// schema.safeEncode(null);                                    // Fail
/// Ack.string().nullable().withDefault('x').safeEncode(null);  // → null
/// ```
///
/// Instances are created by [FluentSchema.withDefault].
@immutable
final class DefaultSchema<T extends Object> extends AckSchema<T>
    with FluentSchema<T, DefaultSchema<T>> {
  /// The wrapped inner schema. Treated as the canonical owner of runtime
  /// validation: [defaultValue] is validated against this schema, and
  /// encoding delegates straight to it.
  final AckSchema<T> inner;

  /// Parse-time default. Synthesized only when parse input is `null`; never
  /// injected on encode.
  ///
  /// Cloned on every parse via [cloneDefault] so shared mutable defaults
  /// (Maps / Lists) cannot drift across calls.
  final T defaultValue;

  DefaultSchema({
    required this.inner,
    required this.defaultValue,
    bool? isNullable,
    bool? isOptional,
    String? description,
    super.constraints,
    super.refinements,
  }) : super(
         // Wrapper nullability/optional/description default to the inner's,
         // so `nullableInner.withDefault(x).encode(null)` returns `null` via
         // the inner's nullability — the default is never injected on encode.
         isNullable: isNullable ?? inner.isNullable,
         isOptional: isOptional ?? inner.isOptional,
         description: description ?? inner.description,
       );

  @override
  SchemaType get schemaType => inner.schemaType;

  /// Synthesizes [defaultValue] when the parse input is `null`, then validates
  /// it through the inner runtime path — not the inner boundary path, since
  /// the default is a runtime [T], not a boundary value. Short-circuits the
  /// dispatcher, so wrapper-level constraints and refinements are applied
  /// here.
  @override
  @protected
  SchemaResult<T>? handleParseNull(Object? input, SchemaContext context) {
    if (input != null) return null;

    // Cast-safety fallback for cloneDefault returning a non-T value (e.g.
    // cloneDefault produces Map<String, Object?> for a Map-shaped default
    // typed as a more specific subtype). Prefer the original.
    final cloned = cloneDefault(defaultValue);
    final safeDefault = cloned is T ? cloned : defaultValue;

    final innerResult = inner._validateRuntime(safeDefault, context);
    if (innerResult.isFail) return innerResult;
    final value = innerResult.getOrThrow();
    if (value == null) return SchemaResult.ok(null);
    return applyConstraintsAndRefinements(value, context);
  }

  /// Non-null parse: delegate to the inner schema's full parse pipeline.
  /// The dispatcher applies wrapper-level constraints once after this
  /// returns.
  @override
  @protected
  SchemaResult<T> decodeBoundary(Object? input, SchemaContext context) {
    return inner._parse(input, context);
  }

  /// Runtime validation: delegates to the inner schema, then applies wrapper
  /// constraints and refinements once. Encode-side null handling is determined
  /// by this wrapper's [isNullable], which by default mirrors [inner]'s.
  @override
  @protected
  SchemaResult<T> _validateRuntime(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return SchemaResult.fail(_failNullForRuntime(context));
    }
    final innerResult = inner._validateRuntime(value, context);
    if (innerResult.isFail) return innerResult;
    final validated = innerResult.getOrThrow();
    if (validated == null) return SchemaResult.ok(null);
    return applyConstraintsAndRefinements(validated, context);
  }

  /// Encode delegates to the inner schema. [defaultValue] is never injected
  /// on encode.
  @override
  @protected
  SchemaResult<Object> encodeBoundary(T value, SchemaContext context) {
    return inner.encodeBoundary(value, context);
  }

  @override
  DefaultSchema<T> copyWith({
    AckSchema<T>? inner,
    bool? isNullable,
    bool? isOptional,
    String? description,
    T? defaultValue,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return DefaultSchema<T>(
      inner: inner ?? this.inner,
      defaultValue: defaultValue ?? this.defaultValue,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // Start from the inner schema's JSON form (preserves nullable / anyOf
    // wrapping, type, format, additionalProperties, etc.). Defensive copy
    // so we don't mutate any shared map the inner returned.
    var base = Map<String, Object?>.of(inner.toJsonSchema());

    // Run the default through the inner schema's encode pipeline so the
    // JSON Schema `default` is the boundary form:
    //   1. Defaults that fail runtime validation are not emitted.
    //   2. Codec encoders run (e.g. DateTime → ISO-8601). One-way transforms
    //      surface [SchemaEncodeError]; the default is omitted in that case.
    //   3. The value is round-tripped through jsonEncode/jsonDecode so
    //      non-JSON runtime objects (e.g. an [InstanceSchema] value passed
    //      through identity encode) never appear as JSON Schema defaults.
    final encoded = inner.safeEncode(defaultValue);
    if (encoded.isOk) {
      final jsonSafe = _jsonSerializableOrNull(encoded.getOrNull());
      if (jsonSafe != null) {
        base['default'] = jsonSafe;
      }
    }

    // Wrapper-level nullability: if the wrapper was made nullable
    // (e.g. `.nullable()` after `.withDefault(...)`), surface a null branch
    // in JSON Schema even when the inner is non-nullable.
    base = _applyNullableWrapper(base, isNullable);

    // Wrapper-level description overrides inner's only if explicitly set
    // on this wrapper (constructor inherits inner.description by default).
    if (description != null && description != inner.description) {
      base['description'] = description;
    }

    return mergeConstraintSchemas(base);
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
  int get hashCode =>
      Object.hash(DefaultSchema<T>, baseFieldsHashCode, inner, defaultValue);
}
