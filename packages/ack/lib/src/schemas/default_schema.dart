part of 'schema.dart';

/// Wraps another schema and supplies a runtime default when the input is
/// null on parse. Encoding does not inject defaults.
@immutable
final class DefaultSchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime> {
  final AckSchema<Boundary, Runtime> inner;
  final Runtime defaultValue;

  DefaultSchema({
    required this.inner,
    required this.defaultValue,
    super.isNullable,
    super.isOptional,
    super.description,
  }) : super(constraints: const [], refinements: const []);

  @override
  SchemaType get schemaType => inner.schemaType;

  @override
  bool get isNullable => super.isNullable || inner.isNullable;

  @override
  bool get isOptional => super.isOptional || inner.isOptional;

  @override
  @protected
  SchemaResult<Runtime> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue == null) {
      final cloned = cloneDefault(defaultValue);
      final effective = (cloned is Runtime) ? cloned : defaultValue;
      // Validate the default through the inner schema (in case it has
      // constraints/refinements that should apply).
      return inner.parseAndValidate(effective, context);
    }
    return inner.parseAndValidate(inputValue, context);
  }

  @override
  @protected
  SchemaResult<Boundary> encodeRuntime(
    Runtime value,
    SchemaContext context,
  ) {
    return inner.safeEncode(value);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final base = Map<String, Object?>.from(inner.toJsonSchema());
    // Best-effort: attempt to encode the default to boundary for export.
    final encoded = inner.safeEncode(defaultValue);
    if (encoded.isOk) {
      base['default'] = encoded.getOrNull();
    } else {
      base['default'] = defaultValue;
    }
    return base;
  }

  /// Returns a copy of this default-wrapped schema with the given fields
  /// replaced. Provided so chained fluent calls (e.g.
  /// `.withDefault(x).describe(...)`) keep working.
  DefaultSchema<Boundary, Runtime> copyWith({
    AckSchema<Boundary, Runtime>? inner,
    Runtime? defaultValue,
    bool? isNullable,
    bool? isOptional,
    String? description,
  }) {
    return DefaultSchema<Boundary, Runtime>(
      inner: inner ?? this.inner,
      defaultValue: defaultValue ?? this.defaultValue,
      isNullable: isNullable ?? super.isNullable,
      isOptional: isOptional ?? super.isOptional,
      description: description ?? this.description,
    );
  }

  DefaultSchema<Boundary, Runtime> nullable({bool value = true}) =>
      copyWith(isNullable: value);

  DefaultSchema<Boundary, Runtime> optional({bool value = true}) =>
      copyWith(isOptional: value);

  DefaultSchema<Boundary, Runtime> describe(String description) =>
      copyWith(description: description);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DefaultSchema<Boundary, Runtime>) return false;
    return inner == other.inner &&
        defaultValue == other.defaultValue &&
        super.isNullable == other.isNullable &&
        super.isOptional == other.isOptional &&
        description == other.description;
  }

  @override
  int get hashCode => Object.hash(
    inner,
    defaultValue,
    super.isNullable,
    super.isOptional,
    description,
  );
}
