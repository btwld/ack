part of 'schema.dart';

/// Schema that transforms validated data from one type to another.
///
/// Created using the [transform] extension method on any schema. First validates
/// the input against the base schema, then applies the transformation function.
///
/// ```dart
/// // Parse ISO date strings into DateTime objects
/// final dateSchema = Ack.string()
///   .datetime()
///   .transform<DateTime>((s) => DateTime.parse(s!));
/// ```
///
/// ## Default Values
///
/// Default values for TransformedSchema are of type `OutputType` (post-transformation),
/// not `InputType`. When providing collection defaults with parameterized types
/// (e.g., `List<MyClass>`), be aware that cloning may not preserve the exact type:
///
/// ```dart
/// // This works - primitive defaults are safely cloned
/// final schema = Ack.string()
///     .transform((v) => v ?? 'fallback')
///     .copyWith(defaultValue: 'hello');
///
/// // Limitation: List<String> defaults may not be cloned (mutation risk)
/// // The implementation falls back to using the original default if cloning
/// // produces an incompatible type. For immutable defaults, this is safe.
/// ```
///
/// For complex collection defaults, consider using immutable collections or
/// accepting that the default may be shared across parse calls.
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

  // NOTE: TransformedSchema intentionally does NOT use the centralized
  // handleNullInput pattern. This is because:
  // 1. defaultValue is of type OutputType (post-transformation), not InputType
  // 2. Using handleNullInput would route the default through parseAndValidate,
  //    which would try to validate OutputType through the InputType inner schema
  // 3. Instead, we handle null/default inline and clone the default manually
  @override
  @protected
  SchemaResult<OutputType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Handle defaults before delegation, since wrapped schemas may reject null.
    // If cloning loses generic type information, fall back to the original value.
    if (inputValue == null && defaultValue != null) {
      final cloned = cloneDefault(defaultValue!);
      final safeDefault = (cloned is OutputType) ? cloned : defaultValue!;
      return applyConstraintsAndRefinements(safeDefault, context);
    }

    // Delegate validation/parsing to the wrapped schema for all other cases.
    final originalResult = schema.parseAndValidate(inputValue, context);
    if (originalResult.isFail) {
      return SchemaResult.fail(originalResult.getError());
    }

    final validatedValue = originalResult.getOrNull();
    try {
      final transformedValue = transformer(validatedValue);

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

    // Merge constraints from the TransformedSchema (e.g., DateTimeConstraint)
    return mergeConstraintSchemas(originalJsonSchema);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransformedSchema<InputType, OutputType>) return false;
    return baseFieldsEqual(other) &&
        schema == other.schema &&
        identical(transformer, other.transformer);
  }

  @override
  int get hashCode =>
      Object.hash(baseFieldsHashCode, schema, transformer.hashCode);
}
