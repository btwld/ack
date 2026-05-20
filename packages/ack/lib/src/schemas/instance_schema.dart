part of 'schema.dart';

/// Schema that accepts a specific runtime [T] instance, with [T] as both
/// boundary and runtime type. Used as the default `output` schema of a
/// [CodecSchema] so codec authors can attach typed refinements (e.g.
/// requiring a `DateTime` to be UTC) on the runtime side.
@immutable
final class InstanceSchema<T extends Object> extends AckSchema<T, T>
    with FluentSchema<T, T, InstanceSchema<T>> {
  const InstanceSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.any;

  @override
  @protected
  SchemaResult<T> parseWithContext(Object? value, SchemaContext context) =>
      validateRuntimeWithContext(value, context);

  @override
  @protected
  SchemaResult<T> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    if (value is! T) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Expected instance of $T, got ${value.runtimeType}',
          context: context,
        ),
      );
    }
    return applyConstraintsAndRefinements(value, context);
  }

  @override
  @protected
  SchemaResult<T> encodeWithContext(T value, SchemaContext context) =>
      encodeAsBoundary(value, context);

  @override
  InstanceSchema<T> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return InstanceSchema<T>(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() =>
      buildJsonSchemaWithNullable(typeSchema: const {});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InstanceSchema<T>) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
