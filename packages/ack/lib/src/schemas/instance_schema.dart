part of 'schema.dart';

/// Schema that validates a runtime value is an instance of [T].
///
/// Unlike structural schemas (object, list, anyOf), [InstanceSchema] only
/// checks the Dart type at runtime via `value is T` and applies any attached
/// refinements. Use it when the runtime side of a codec is a domain object
/// or value type that ACK does not structurally know how to validate.
///
/// ```dart
/// final dateCodec = Ack.codec<String, DateTime>(
///   Ack.string().datetime(),
///   Ack.instance<DateTime>(),
///   decode: DateTime.parse,
///   encode: (d) => d.toIso8601String(),
/// );
/// ```
///
/// Use `.refine(...)` for any business rules beyond the type check.
@immutable
final class InstanceSchema<T extends Object> extends AckSchema<T>
    with FluentSchema<T, InstanceSchema<T>> {
  const InstanceSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
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
  InstanceSchema<T> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    T? defaultValue,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return InstanceSchema<T>(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() => buildJsonSchemaWithNullable(
    typeSchema: {},
    serializedDefault: defaultValue,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InstanceSchema<T>) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
