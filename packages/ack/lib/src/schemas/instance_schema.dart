part of 'schema.dart';

/// Runtime-side schema that validates a Dart value is an instance of [T].
///
/// Primarily intended as the `output` schema for a [CodecSchema]: it gates
/// decoded runtime values by type and is where codec authors attach runtime
/// invariants via [refine] (e.g. requiring a `DateTime` to be UTC).
///
/// This is **not** a JSON-boundary schema for [T]. When exported directly, the
/// schema model only approximates it across JSON-compatible branches and
/// surfaces the `ack_instance_json_boundary` warning. For wire-format
/// validation, pair it with a codec (`schema.codec(...)`) or use a boundary
/// schema such as `Ack.string()` / `Ack.object(...)` instead.
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InstanceSchema<T>) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
