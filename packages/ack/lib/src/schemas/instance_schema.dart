part of 'schema.dart';

/// Schema that accepts a specific runtime [T] instance, with [T] as both
/// boundary and runtime type.
///
/// Used primarily as the `output` schema of a [CodecSchema] to attach typed
/// refinements (e.g. requiring a `DateTime` to be UTC).
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
  SchemaResult<T> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    if (inputValue is! T) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Expected instance of $T, got ${inputValue.runtimeType}',
          context: context,
        ),
      );
    }
    return applyConstraintsAndRefinements(inputValue, context);
  }

  @override
  @protected
  SchemaResult<T> encodeRuntime(T value, SchemaContext context) {
    return SchemaResult.ok(value);
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
