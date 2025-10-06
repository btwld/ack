part of 'schema.dart';

@immutable
class TransformedSchema<InputType extends Object, OutputType extends Object>
    extends AckSchema<OutputType> {
  final AckSchema<InputType> schema;
  final OutputType Function(InputType?) transformer;

  TransformedSchema(
    this.schema,
    this.transformer, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  @protected
  SchemaResult<OutputType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Handle TransformedSchema's own defaultValue for null input
    // This must happen BEFORE delegating to wrapped schema, because the wrapped
    // schema might not accept null (e.g., non-nullable StringSchema)
    if (inputValue == null) {
      if (defaultValue case final dv?) {
        // Use centralized constraints and refinements check
        return applyConstraintsAndRefinements(dv, context);
      }
    }

    // For non-null input OR null input without default:
    // 1. Validate through underlying schema (handles type conversion, constraints, refinements)
    final originalResult = schema.parseAndValidate(inputValue, context);
    if (originalResult.isFail) {
      return SchemaResult.fail(originalResult.getError());
    }

    // 2. Transform the validated value (may be null if underlying schema is nullable)
    final validatedValue = originalResult.getOrNull();
    try {
      final transformedValue = transformer(validatedValue);

      // 3. Use centralized constraints and refinements check
      return applyConstraintsAndRefinements(transformedValue, context);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaTransformError(
          message: 'Transformation failed: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  SchemaType get schemaType => schema.schemaType;

  @override
  bool get strictPrimitiveParsing => schema.strictPrimitiveParsing;

  @override
  TransformedSchema<InputType, OutputType> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    OutputType? defaultValue,
    List<Constraint<OutputType>>? constraints,
    List<Refinement<OutputType>>? refinements,
  }) {
    return TransformedSchema(
      schema,
      transformer,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // A transformed schema doesn't have a direct, standard JSON Schema representation.
    // It might be possible to represent it as the original schema with a custom
    // property indicating a transformation, but for now, we'll return the original.
    // Another option is to add an "x-transformed" property, a common practice for
    // custom annotations in JSON Schema.
    final originalJsonSchema = schema.toJsonSchema();
    originalJsonSchema['x-transformed'] = true;
    if (description != null) {
      originalJsonSchema['description'] = description;
    }

    return originalJsonSchema;
  }
}
