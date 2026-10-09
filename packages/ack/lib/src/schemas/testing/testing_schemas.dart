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
  SchemaType get schemaType => SchemaType.any;

  @override
  int get hashCode => baseFieldsHashCode;
}

/// Testing-only schema that records parse, validate, and encode operations.
@visibleForTesting
final class TestOperationRecordingAckSchema extends AckSchema<String, String>
    with FluentSchema<String, String, TestOperationRecordingAckSchema> {
  const TestOperationRecordingAckSchema({
    required this.parseOperations,
    required this.validateOperations,
    required this.encodeOperations,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  final List<SchemaOperation> parseOperations;
  final List<SchemaOperation> validateOperations;
  final List<SchemaOperation> encodeOperations;

  @override
  SchemaType get schemaType => SchemaType.string;

  @override
  SchemaResult<String> parseWithContext(Object? value, SchemaContext context) {
    parseOperations.add(context.operation);
    return validateRuntimeWithContext(value, context);
  }

  @override
  SchemaResult<String> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    validateOperations.add(context.operation);
    return SchemaResult.ok(value as String);
  }

  @override
  SchemaResult<String> encodeWithContext(String value, SchemaContext context) {
    encodeOperations.add(context.operation);
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    return SchemaResult.ok(value);
  }

  @override
  TestOperationRecordingAckSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
  }) {
    return TestOperationRecordingAckSchema(
      parseOperations: parseOperations,
      validateOperations: validateOperations,
      encodeOperations: encodeOperations,
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
  bool operator ==(Object other) =>
      other is TestOperationRecordingAckSchema &&
      identical(parseOperations, other.parseOperations) &&
      identical(validateOperations, other.validateOperations) &&
      identical(encodeOperations, other.encodeOperations) &&
      baseFieldsEqual(other);

  @override
  int get hashCode => Object.hash(
    baseFieldsHashCode,
    identityHashCode(parseOperations),
    identityHashCode(validateOperations),
    identityHashCode(encodeOperations),
  );
}

/// Testing-only non-codec schema whose encode throws an ordinary [Exception].
@visibleForTesting
final class TestThrowingLeafAckSchema extends AckSchema<String, String>
    with FluentSchema<String, String, TestThrowingLeafAckSchema> {
  const TestThrowingLeafAckSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.string;

  @override
  SchemaResult<String> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) => SchemaResult.ok(value as String);

  @override
  SchemaResult<String> encodeWithContext(String value, SchemaContext context) {
    throw const FormatException('leaf encode refused');
  }

  @override
  TestThrowingLeafAckSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
  }) {
    return TestThrowingLeafAckSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TestThrowingLeafAckSchema && baseFieldsEqual(other);

  @override
  int get hashCode => baseFieldsHashCode;
}
