part of 'package:ack/src/schemas/schema.dart';

/// Testing-only schema used to simulate unsupported conversions in integration packages.
///
/// This lives alongside the core schema types so it can extend [AckSchema], which is
/// sealed and therefore only extensible within this library. Marked as
/// `@visibleForTesting` to discourage production use.
@visibleForTesting
final class TestUnsupportedAckSchema extends AckSchema<Object> {
  const TestUnsupportedAckSchema({
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
  TestUnsupportedAckSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    Object? defaultValue,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) {
    return TestUnsupportedAckSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() => const {'type': 'string'};
}
