part of 'schema.dart';

/// Eagerly checks that [value] survives a JSON round-trip and returns the
/// (possibly normalized) JSON-safe form, or `null` if it cannot be encoded.
///
/// Used by [DefaultSchema.toJsonSchema] to ensure runtime objects that the
/// inner encoder leaks through (e.g. a `DateTime` from
/// `Ack.instance<DateTime>().encodeBoundary`) never appear as JSON Schema
/// defaults.
Object? _jsonSerializableOrNull(Object? value) {
  try {
    return jsonDecode(jsonEncode(value));
  } catch (_) {
    return null;
  }
}

/// Wraps [schema] in an `anyOf [..., {type: null}]` form when [isNullable]
/// is true and the schema does not already include a null branch. Hoists
/// any existing `default` to the top so the null wrapper does not bury it.
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

/// Schema wrapper that supplies a parse-time default value.
///
/// `DefaultSchema<T>` wraps an inner [AckSchema<T>] and synthesizes
/// [defaultValue] when the parse-side input is `null`. Per requirements
/// §5.5 / decision A7 (codec-open-questions.md:140), defaults are
/// **parse-only** — the encode pipeline never injects the default and
/// always defers null-handling to the inner schema's nullability.
///
/// ```dart
/// // Boundary `null` → runtime 'guest'
/// final schema = Ack.string().withDefault('guest');
/// schema.parse(null);  // → 'guest'
///
/// // Encode does NOT inject the default; nullable inner controls null:
/// schema.safeEncode(null);                       // Fail (non-nullable inner)
/// Ack.string().nullable().withDefault('x').safeEncode(null);  // → null
/// ```
///
/// `DefaultSchema` is created by [FluentSchema.withDefault]. The inner
/// [defaultValue] is a runtime value (`T`), not a boundary value — for
/// codecs this means the default is the decoded form (e.g. `DateTime`,
/// not the ISO-8601 string). The default is validated through the inner
/// schema's runtime path (`_validateRuntime`), so any runtime-side
/// constraints declared on the inner apply to the default.
@immutable
final class DefaultSchema<T extends Object> extends AckSchema<T>
    with FluentSchema<T, DefaultSchema<T>> {
  /// The wrapped inner schema. The default value is treated as a runtime `T`
  /// validated through `inner._validateRuntime`. On encode this wrapper
  /// delegates straight to `inner.encodeBoundary`, never synthesizing the
  /// default.
  final AckSchema<T> inner;

  DefaultSchema({
    required this.inner,
    required T super.defaultValue,
    bool? isNullable,
    bool? isOptional,
    String? description,
    super.constraints,
    super.refinements,
  }) : super(
          // Wrapper's nullability/optional/description default to the inner's
          // — so that `Ack.string().nullable().withDefault('x').encode(null)`
          // behaves per A7 (returns null via inner nullability, default is
          // ignored on encode).
          isNullable: isNullable ?? inner.isNullable,
          isOptional: isOptional ?? inner.isOptional,
          description: description ?? inner.description,
        );

  @override
  SchemaType get schemaType => inner.schemaType;

  @override
  bool get strictPrimitiveParsing => inner.strictPrimitiveParsing;

  /// Synthesizes [defaultValue] when the parse input is `null`, then
  /// validates it through the inner runtime path (NOT the inner boundary
  /// path — for codecs the default is a runtime `T`, not a boundary value).
  /// `handleParseNull` short-circuits the dispatcher, so wrapper
  /// constraints/refinements are applied here.
  @override
  @protected
  SchemaResult<T>? handleParseNull(Object? input, SchemaContext context) {
    if (input != null) return null;

    // Cast-safety fallback for cloneDefault returning a non-T value (mirrors
    // the legacy InstanceSchema/DiscriminatedObjectSchema patterns).
    final cloned = cloneDefault(defaultValue!);
    final safeDefault = cloned is T ? cloned : defaultValue!;

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

  /// Runtime validation: delegate to the inner schema, then apply wrapper
  /// constraints/refinements once. Encode-side null handling is determined
  /// by the wrapper's `isNullable` (which by default mirrors `inner.isNullable`
  /// — preserving A7 for `nullableInner.withDefault(x).encode(null) == null`).
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

  /// Encode delegates to the inner schema. Defaults are never synthesized
  /// on encode (§5.5).
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
      defaultValue: defaultValue ?? this.defaultValue!,
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

    // Run the default through the inner's full encode pipeline:
    //   1. Validate as runtime T via inner._validateRuntime — defaults that
    //      would fail parse-time validation are NOT emitted as JSON Schema
    //      metadata. This is stricter than Zod (which emits unconditionally).
    //   2. Translate to boundary form via inner.encodeBoundary — handles
    //      codec encoders (e.g. DateTime → ISO-8601 string). One-way
    //      transforms surface SchemaEncodeError; the default is omitted.
    //   3. Round-trip through jsonEncode/jsonDecode to ensure the value is
    //      JSON-safe — catches runtime objects that an identity encode
    //      (e.g. InstanceSchema<DateTime>.encodeBoundary) would otherwise
    //      leak through.
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
    return baseFieldsEqual(other) && inner == other.inner;
  }

  @override
  int get hashCode => Object.hash(DefaultSchema<T>, baseFieldsHashCode, inner);
}
