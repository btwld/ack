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
  SchemaResult<OutputType> _onConvert(
    Object? inputValue,
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
    // 1. Run the conversion, which includes the original schema's full
    //    validation pipeline. This will correctly handle the input's nullability.
    final convertedResult = _onConvert(inputValue, context);
    if (convertedResult.isFail) {
      return convertedResult;
    }

    final convertedValue = convertedResult.getOrNull();

    // 2. The transformer produced a null. Check if this is allowed for the output.
    if (convertedValue == null) {
      if (isNullable) {
        // A null output is allowed, so we succeed.
        return SchemaResult.ok(null);
      } // A null output is not allowed.
      final constraintError = NonNullableConstraint().validate(null);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ),
      );
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
