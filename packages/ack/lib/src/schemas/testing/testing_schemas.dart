part of 'package:ack/src/schemas/schema.dart';

/// Testing-only schema used to simulate unsupported conversions in
/// integration packages.
@visibleForTesting
final class TestUnsupportedAckSchema extends AckSchema<Object, Object>
    with FluentSchema<Object, Object, TestUnsupportedAckSchema> {
  const TestUnsupportedAckSchema({
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
  SchemaResult<Object> parseWithContext(Object? value, SchemaContext context) =>
      validateRuntimeWithContext(value, context);

  @override
  @protected
  SchemaResult<Object> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    return applyConstraintsAndRefinements(value!, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeWithContext(Object value, SchemaContext context) =>
      encodeAsBoundary(value, context);

  @override
  TestUnsupportedAckSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) {
    return TestUnsupportedAckSchema(
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
    if (other is! TestUnsupportedAckSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
