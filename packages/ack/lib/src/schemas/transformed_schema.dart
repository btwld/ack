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
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : super(schemaType: schema.schemaType);

  @override
  @protected
  SchemaResult<OutputType> _performTypeConversion(
    Object inputValue,
    SchemaContext context,
  ) {
    // We need to run the validation of the original schema. We can't just call
    // `validate` because it creates a new context. To reuse the context and
    // avoid nested errors that point to the same location, we call `parseAndValidate`.
    final originalResult = schema.parseAndValidate(inputValue, context);

    return originalResult.match(
      onOk: (validatedValue) {
        try {
          final transformedValue = transformer(validatedValue);

          return SchemaResult.ok(transformedValue);
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
      },
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  @override
  @protected
  SchemaResult<OutputType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Handle default value for null input
    if (inputValue == null && defaultValue != null) {
      return SchemaResult.ok(defaultValue);
    }

    // For null input without a default, we need to:
    // 1. Let the wrapped schema validate it (it might be nullable)
    // 2. Transform the result
    // 3. Check if the output is allowed to be null

    // If input is null and we have no default, we still need to process it
    // through the wrapped schema and transformer
    if (inputValue == null) {
      // Let the wrapped schema handle the null
      final originalResult = schema.parseAndValidate(null, context);
      if (originalResult.isFail) {
        return SchemaResult.fail(originalResult.getError());
      }

      // Transform the validated null value
      try {
        final transformedValue = transformer(originalResult.getOrNull());

        // Check if the transformed value is allowed
        if (transformedValue == null && !isNullable) {
          return failNonNullable(context);
        }

        return SchemaResult.ok(transformedValue);
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

    // 1. Run the conversion for non-null input
    final convertedResult = _performTypeConversion(inputValue, context);
    if (convertedResult.isFail) {
      return convertedResult;
    }

    final convertedValue = convertedResult.getOrNull();

    // 2. The transformer produced a null. Check if this is allowed for the output.
    if (convertedValue == null) {
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullable(context);
    }

    // 3. The output is not null, so run this schema's constraints on it.
    final constraintViolations = _checkConstraints(convertedValue, context);
    if (constraintViolations.isNotEmpty) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintViolations,
        context: context,
      ));
    }

    return _runRefinements(convertedValue, context);
  }

  @override
  TransformedSchema<InputType, OutputType> copyWith({
    bool? isNullable,
    String? description,
    OutputType? defaultValue,
    List<Constraint<OutputType>>? constraints,
    List<Refinement<OutputType>>? refinements,
  }) {
    return TransformedSchema(
      schema,
      transformer,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  AckSchema<OutputType> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required OutputType? defaultValue,
    required List<Constraint<OutputType>>? constraints,
    required List<Refinement<OutputType>>? refinements,
  }) {
    return copyWith(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
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
