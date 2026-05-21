part of 'schema.dart';

/// Wraps another schema and supplies a runtime default when the input is
/// null on parse. Object encode injects encoded defaults for missing
/// default-wrapped fields.
@immutable
final class DefaultSchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime>
    with WrapperSchema<Boundary, Runtime, DefaultSchema<Boundary, Runtime>> {
  @override
  final AckSchema<Boundary, Runtime> inner;
  final Runtime defaultValue;

  DefaultSchema({
    required this.inner,
    required this.defaultValue,
    super.isNullable,
    super.isOptional,
    super.description,
  });

  @override
  SchemaType get schemaType => inner.schemaType;

  // DefaultSchema is treated as optional/nullable based on inner so callers
  // can use it as a property without further annotation.
  @override
  bool get isNullable => super.isNullable || inner.isNullable;

  @override
  bool get isOptional => super.isOptional || inner.isOptional;

  // Constraints and refinements live on the wrapped schema.
  @override
  List<Constraint<Runtime>> get constraints => inner.constraints;

  @override
  List<Refinement<Runtime>> get refinements => inner.refinements;

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(Object? value, SchemaContext context) {
    if (value == null) {
      return _validateDefaultWithContext(context);
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
  DefaultSchema<Boundary, Runtime> copyWithInner(AnyAckSchema newInner) {
    return DefaultSchema<Boundary, Runtime>(
      inner: newInner as AckSchema<Boundary, Runtime>,
      defaultValue: defaultValue,
      isNullable: super.isNullable,
      isOptional: super.isOptional,
      description: description,
    );
  }

  @override
  @protected
  DefaultSchema<Boundary, Runtime> copyWithRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    final updatedInner = constraints == null && refinements == null
        ? inner
        : inner.withRuntimeConfig(
            constraints: constraints,
            refinements: refinements,
          );

    return DefaultSchema<Boundary, Runtime>(
      inner: updatedInner,
      defaultValue: defaultValue,
      isNullable: isNullable ?? super.isNullable,
      isOptional: isOptional ?? super.isOptional,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DefaultSchema<Boundary, Runtime>) return false;
    return inner == other.inner &&
        defaultValue == other.defaultValue &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description;
  }

  @override
  int get hashCode =>
      Object.hash(inner, defaultValue, isNullable, isOptional, description);

  SchemaResult<Runtime> _validateDefaultWithContext(SchemaContext context) {
    // Defaults are runtime values, not boundary values, so validate via the
    // runtime path. `cloneDefault` returns unmodifiable collection copies when
    // it can; mutable collection defaults are rejected if the inner schema
    // would otherwise return the original reference.
    final cloned = cloneDefault(defaultValue);
    final clonedSafely = cloned is Runtime && !identical(cloned, defaultValue);
    final effective = (cloned is Runtime) ? cloned : defaultValue;
    final result = inner.validateRuntimeWithContext(effective, context);
    if (result.isOk &&
        !clonedSafely &&
        _isCollectionDefault(defaultValue) &&
        identical(result.getOrNull(), defaultValue)) {
      return SchemaResult.fail(
        SchemaValidationError(
          message:
              'Default collection value for $runtimeType could not be '
              'cloned safely as $Runtime.',
          context: context,
        ),
      );
    }
    return result;
  }
}

bool _isCollectionDefault(Object value) =>
    value is List || value is Map || value is Set;
