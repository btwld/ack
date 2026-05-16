part of 'schema.dart';

/// Wraps another schema and supplies a runtime default when the input is
/// null on parse. Encoding does not inject defaults.
@immutable
final class DefaultSchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime>
    implements ConfigurableSchema<Boundary, Runtime> {
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

  // DefaultSchema is treated as optional/nullable based on inner so callers
  // can use it as a property without further annotation.
  @override
  bool get isNullable => super.isNullable || inner.isNullable;

  @override
  bool get isOptional => super.isOptional || inner.isOptional;

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(
    Object? value,
    SchemaContext context,
  ) {
    if (value == null) {
      final cloned = cloneDefault(defaultValue);
      final effective = (cloned is Runtime) ? cloned : defaultValue;
      // Validate the runtime default through the inner schema's runtime
      // path — defaults are runtime values, not boundary values.
      return inner.validateRuntimeWithContext(effective, context);
    }
    return inner.parseWithContext(value, context);
  }

  @override
  @protected
  SchemaResult<Runtime> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    return inner.validateRuntimeWithContext(value, context);
  }

  @override
  @protected
  SchemaResult<Boundary> encodeWithContext(
    Runtime value,
    SchemaContext context,
  ) {
    return inner.encodeWithContext(value, context);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final base = Map<String, Object?>.from(inner.toJsonSchema());
    // Best-effort: emit default only if it round-trips cleanly to boundary
    // AND the boundary value is JSON-safe. Schemas like `Ack.instance<T>()`
    // happily round-trip non-JSON Dart objects through their identity
    // encode path; emitting those would leak runtime-only types into the
    // schema output.
    final encoded = inner.safeEncode(defaultValue);
    if (encoded.isOk) {
      final value = encoded.getOrNull();
      if (value != null) {
        final safe = jsonSafeOrNull(value);
        if (safe != null) {
          base['default'] = safe;
        }
      }
    }
    return base;
  }

  /// Returns a copy of this default-wrapped schema with the given fields
  /// replaced.
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

  @override
  AckSchema<Boundary, Runtime> withRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    // Constraints/refinements are forwarded onto the inner schema if it is
    // configurable; the default wrapper itself only owns description,
    // isNullable and isOptional.
    if ((constraints != null || refinements != null) &&
        inner is ConfigurableSchema<Boundary, Runtime>) {
      final updated =
          (inner as ConfigurableSchema<Boundary, Runtime>).withRuntimeConfig(
        constraints: constraints,
        refinements: refinements,
      );
      return DefaultSchema<Boundary, Runtime>(
        inner: updated,
        defaultValue: defaultValue,
        isNullable: isNullable ?? super.isNullable,
        isOptional: isOptional ?? super.isOptional,
        description: description ?? this.description,
      );
    }
    return copyWith(
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
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
