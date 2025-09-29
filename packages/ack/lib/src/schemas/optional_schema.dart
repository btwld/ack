part of 'schema.dart';

/// A schema wrapper that makes any schema optional (field may be omitted).
/// Optional ≠ Nullable: use `.nullable()` explicitly to allow present nulls.
@immutable
final class OptionalSchema<DartType extends Object> extends AckSchema<DartType>
    with FluentSchema<DartType, OptionalSchema<DartType>> {
  final AckSchema<DartType> wrappedSchema;

  OptionalSchema({
    required this.wrappedSchema,
    bool isNullable = false,
    super.description,
    super.defaultValue,
    super.constraints = const [],
    super.refinements = const [],
  }) : super(
          schemaType: wrappedSchema.schemaType,
          // Do not force nullable; nullability must be explicit.
          isNullable: isNullable,
        );

  @override
  @protected
  SchemaResult<DartType> _onConvert(
    Object? inputValue,
    SchemaContext context,
  ) {
    // This should not be called since we override parseAndValidate
    return wrappedSchema._onConvert(inputValue, context);
  }

  @override
  @protected
  OptionalSchema<DartType> copyWithInternal({
    bool? isNullable,
    String? description,
    DartType? defaultValue,
    List<Constraint<DartType>>? constraints,
    List<Refinement<DartType>>? refinements,
  }) {
    return OptionalSchema(
      wrappedSchema: wrappedSchema,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  // No custom parse: optionality is handled at the object level. For present
  // values (including null), delegate to the base pipeline.

  @override
  Map<String, Object?> toJsonSchema() {
    // Return the wrapped schema's JSON schema
    // The "required" property is handled at the object level in JSON Schema
    return wrappedSchema.toJsonSchema();
  }

  @override
  bool get isOptional => true;
}
