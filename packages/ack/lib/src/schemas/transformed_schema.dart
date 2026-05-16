part of 'schema.dart';

/// One-way transform schema. Parse maps the inner schema's runtime to a new
/// runtime via [transformer]; encode is not supported and returns
/// [SchemaEncodeFailureKind.oneWayTransform].
///
/// For bidirectional mapping use [CodecSchema] instead.
@immutable
class TransformedSchema<
  Boundary extends Object,
  InputRuntime extends Object,
  Runtime extends Object
> extends AckSchema<Boundary, Runtime>
    implements ConfigurableSchema<Boundary, Runtime> {
  final AckSchema<Boundary, InputRuntime> schema;
  final Runtime Function(InputRuntime) transformer;

  TransformedSchema(
    this.schema,
    this.transformer, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final innerResult = schema.parseWithContext(value, context);
    if (innerResult.isFail) {
      return SchemaResult.fail(innerResult.getError());
    }

    final inner = innerResult.getOrNull();
    if (inner == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    final Runtime transformed;
    try {
      transformed = transformer(inner);
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

    return validateRuntimeWithContext(transformed, context);
  }

  @override
  @protected
  SchemaResult<Runtime> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    if (value is! Runtime) {
      return SchemaResult.fail(
        SchemaValidationError(
          message:
              'Transformed runtime is ${value.runtimeType}, expected $Runtime.',
          context: context,
        ),
      );
    }
    return applyConstraintsAndRefinements(value, context);
  }

  @override
  @protected
  SchemaResult<Boundary> encodeWithContext(
    Runtime value,
    SchemaContext context,
  ) {
    return SchemaResult.fail(
      SchemaEncodeError.oneWayTransform(context: context),
    );
  }

  @override
  SchemaType get schemaType => schema.schemaType;

  TransformedSchema<Boundary, InputRuntime, Runtime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return TransformedSchema<Boundary, InputRuntime, Runtime>(
      schema,
      transformer,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  TransformedSchema<Boundary, InputRuntime, Runtime> withRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return copyWith(
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  TransformedSchema<Boundary, InputRuntime, Runtime> nullable({
    bool value = true,
  }) {
    return copyWith(isNullable: value);
  }

  TransformedSchema<Boundary, InputRuntime, Runtime> optional({
    bool value = true,
  }) {
    return copyWith(isOptional: value);
  }

  TransformedSchema<Boundary, InputRuntime, Runtime> describe(
    String description,
  ) {
    return copyWith(description: description);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final originalJsonSchema = schema.toJsonSchema();
    originalJsonSchema['x-transformed'] = true;
    if (description != null) {
      originalJsonSchema['description'] = description;
    }
    return mergeConstraintSchemas(originalJsonSchema);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransformedSchema<Boundary, InputRuntime, Runtime>) {
      return false;
    }
    return baseFieldsEqual(other) &&
        schema == other.schema &&
        identical(transformer, other.transformer);
  }

  @override
  int get hashCode =>
      Object.hash(baseFieldsHashCode, schema, transformer.hashCode);
}
