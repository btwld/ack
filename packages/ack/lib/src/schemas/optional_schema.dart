part of 'schema.dart';

/// A schema wrapper that makes any schema optional (field may be omitted).
/// Optional fields are always nullable - they can be missing OR explicitly null.
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
          // Optional always implies nullable
          isNullable: true,
        );

  @override
  @protected
  SchemaResult<DartType> _performTypeConversion(
    Object inputValue,
    SchemaContext context,
  ) {
    // Delegate to the wrapped schema's _performTypeConversion
    // Since we're in _performTypeConversion, inputValue is guaranteed to be non-null
    // However, wrappedSchema._performTypeConversion also expects non-null now
    return wrappedSchema._performTypeConversion(inputValue, context);
  }

  @override
  @protected
  SchemaResult<DartType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // For non-null input, delegate directly to wrapped schema
    if (inputValue != null) {
      return wrappedSchema.parseAndValidate(inputValue, context);
    }

    // For null input with a default, validate the default against wrapped schema
    if (defaultValue != null) {
      return wrappedSchema.parseAndValidate(defaultValue, context);
    }

    // For null input without default, accept it (optional is always nullable)
    return SchemaResult.ok(null);
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
