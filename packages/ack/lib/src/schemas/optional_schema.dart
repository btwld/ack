part of 'schema.dart';

/// A schema wrapper that makes any schema optional.
/// Optional means the field can be omitted from an object.
/// This is different from nullable - a nullable field must still be present but can have a null value.
@immutable
final class OptionalSchema<DartType extends Object> extends AckSchema<DartType>
    with FluentSchema<DartType, OptionalSchema<DartType>> {
  final AckSchema<DartType> wrappedSchema;

  OptionalSchema({
    required this.wrappedSchema,
    super.description,
    super.defaultValue,
    super.constraints = const [],
    super.refinements = const [],
  }) : super(
          schemaType: wrappedSchema.schemaType,
          // Optional schemas are inherently nullable since missing values are treated as null
          isNullable: true,
        );

  @override
  @protected
  SchemaResult<DartType> _onConvert(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Delegate to the wrapped schema
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
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // Return the wrapped schema's JSON schema
    // The "required" property is handled at the object level in JSON Schema
    return wrappedSchema.toJsonSchema();
  }

  @override
  bool get isOptional => true;
}
