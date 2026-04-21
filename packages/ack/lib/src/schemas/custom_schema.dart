part of 'schema.dart';

/// Schema that validates an arbitrary runtime object of type [T].
///
/// Unlike the primitive schemas, [CustomSchema] does not attempt any
/// type coercion or JSON-style parsing — it simply checks that the input is
/// of type [T] and optionally delegates to a caller-provided predicate.
///
/// This is the recommended output-side schema for [CodecSchema] when the
/// runtime value is a richer user-defined type (e.g. a `Color` class).
///
/// ```dart
/// final colorSchema = Ack.custom<Color>(
///   (color) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color.hex),
///   message: 'Invalid Color value',
/// );
/// ```
@immutable
final class CustomSchema<T extends Object> extends AckSchema<T>
    with FluentSchema<T, CustomSchema<T>> {
  final bool Function(T value)? validator;
  final String message;

  const CustomSchema({
    this.validator,
    this.message = 'Invalid value',
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
  SchemaResult<T> parseAndValidate(Object? inputValue, SchemaContext context) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    final nonNull = inputValue!;
    if (nonNull is! T) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Expected instance of $T, got ${nonNull.runtimeType}',
          context: context,
        ),
      );
    }

    if (validator != null && !validator!(nonNull)) {
      return SchemaResult.fail(
        SchemaValidationError(message: message, context: context),
      );
    }

    return applyConstraintsAndRefinements(nonNull, context);
  }

  @override
  CustomSchema<T> copyWith({
    bool Function(T value)? validator,
    String? message,
    bool? isNullable,
    bool? isOptional,
    String? description,
    T? defaultValue,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return CustomSchema<T>(
      validator: validator ?? this.validator,
      message: message ?? this.message,
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
    typeSchema: const {'x-ack-custom': true},
    serializedDefault: defaultValue,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomSchema<T>) return false;
    return baseFieldsEqual(other) &&
        identical(validator, other.validator) &&
        message == other.message;
  }

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, validator, message);
}
