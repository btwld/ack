part of 'schema.dart';

/// Schema that validates a runtime value is an instance of [T].
@immutable
final class InstanceSchema<T extends Object> extends AckSchema<T>
    with FluentSchema<T, InstanceSchema<T>> {
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
  SchemaResult<T> _validateRuntime(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    if (value is! T) {
      return SchemaResult.fail(
        context.operation == SchemaOperation.encode
            ? SchemaEncodeError.typeMismatch(
                expected: T,
                actual: value,
                context: context,
              )
            : SchemaValidationError(
                message: 'Expected instance of $T, got ${value.runtimeType}',
                context: context,
              ),
      );
    }

    return applyConstraintsAndRefinements(value, context);
  }

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
