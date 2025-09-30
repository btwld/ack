part of 'schema.dart';

/// A schema wrapper that makes any schema optional (field may be omitted).
/// Optional means the field can be missing. It does NOT imply nullable.
/// Use .nullable() explicitly if you want to accept null values.
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
    super.isNullable = false,
  }) : super(
          schemaType: wrappedSchema.schemaType,
        );

  @override
  JsonType get acceptedType => wrappedSchema.acceptedType;

  @override
  bool get strictPrimitiveParsing => wrappedSchema.strictPrimitiveParsing;

  /// OptionalSchema delegates to wrapped schema for parsing.
  @override
  @protected
  SchemaResult<DartType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Use centralized null handling
    if (inputValue == null) return handleNullInput(context);

    // Delegate full validation to wrapped schema, which includes wrapped schema's
    // constraints and refinements. After this, we'll apply OptionalSchema's own constraints/refinements.
    final result = wrappedSchema.parseAndValidate(inputValue, context);
    if (result.isFail) return result;

    final validatedValue = result.getOrThrow()!;

    // Use centralized constraints and refinements check for OptionalSchema's own constraints
    return applyConstraintsAndRefinements(validatedValue, context);
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
      isNullable: isNullable ?? this.isNullable,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // Get the wrapped schema's JSON Schema representation
    final base = Map<String, Object?>.from(wrappedSchema.toJsonSchema());

    // If this OptionalSchema is also marked nullable, add null to the type
    if (isNullable) {
      final existingType = base['type'];
      if (existingType is String && existingType != 'null') {
        base['type'] = [existingType, 'null'];
      } else if (existingType is List && !existingType.contains('null')) {
        base['type'] = [...existingType, 'null'];
      }
    }

    // Override with OptionalSchema's own properties
    if (description != null) base['description'] = description;
    if (defaultValue != null) base['default'] = defaultValue;

    // Merge OptionalSchema's constraints into the JSON Schema
    return mergeConstraintSchemas(base);
  }
}
