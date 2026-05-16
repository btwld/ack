part of 'package:ack/src/schemas/schema.dart';

/// Testing-only schema used to simulate unsupported conversions in integration packages.
@visibleForTesting
final class TestUnsupportedAckSchema extends AckSchema<Object, Object> {
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
  SchemaResult<Object> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;
    return applyConstraintsAndRefinements(inputValue!, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeRuntime(Object value, SchemaContext context) {
    return SchemaResult.ok(value);
  }

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
  Map<String, Object?> toJsonSchema() => const {'type': 'string'};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TestUnsupportedAckSchema) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => baseFieldsHashCode;
}
