part of 'schema.dart';

/// Public interface for codec schemas exposing two type parameters.
abstract interface class CodecSchema<
  Boundary extends Object,
  Runtime extends Object
> implements
        AckSchema<Boundary, Runtime>,
        ConfigurableSchema<Boundary, Runtime> {
  /// The input/boundary schema that this codec wraps.
  AckSchema<Boundary, dynamic> get inputSchema;

  /// The output schema applied to the runtime value after decoding (and
  /// before encoding).
  AckSchema<dynamic, Runtime> get outputSchema;
}

/// Internal implementation of [CodecSchema] with a hidden intermediate input
/// runtime type [InputRuntime].
@immutable
final class CodecSchemaImpl<
  Boundary extends Object,
  InputRuntime extends Object,
  Runtime extends Object
>
    extends AckSchema<Boundary, Runtime>
    implements CodecSchema<Boundary, Runtime> {
  @override
  final AckSchema<Boundary, InputRuntime> inputSchema;

  @override
  final AckSchema<dynamic, Runtime> outputSchema;

  final Runtime Function(InputRuntime value) decoder;
  final InputRuntime Function(Runtime value) encoder;

  CodecSchemaImpl({
    required this.inputSchema,
    required this.outputSchema,
    required this.decoder,
    required this.encoder,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => inputSchema.schemaType;

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final inputResult = inputSchema.parseWithContext(value, context);
    if (inputResult.isFail) {
      return SchemaResult.fail(inputResult.getError());
    }

    final intermediate = inputResult.getOrNull();
    if (intermediate == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    final Runtime runtime;
    try {
      runtime = decoder(intermediate);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaTransformError(
          message: 'Codec decode failed: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    return validateRuntimeWithContext(runtime, context);
  }

  @override
  @protected
  SchemaResult<Runtime> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final outputResult =
        outputSchema.validateRuntimeWithContext(value, context);
    if (outputResult.isFail) {
      return SchemaResult.fail(outputResult.getError());
    }

    final validated = outputResult.getOrNull();
    if (validated == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    return applyConstraintsAndRefinements(validated, context);
  }

  @override
  @protected
  SchemaResult<Boundary> encodeWithContext(
    Runtime value,
    SchemaContext context,
  ) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    final runtime = validated.getOrNull();
    if (runtime == null) return failNonNullableEncode(context);

    final InputRuntime intermediate;
    try {
      intermediate = encoder(runtime);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaEncodeError.encoderThrew(
          message: 'Codec encode failed: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    // Ensure the intermediate matches the input schema's runtime shape
    // before encoding to boundary. The intermediate context inherits the
    // path so nested errors stay grouped under the codec's location.
    final inputValidation =
        inputSchema.validateRuntimeWithContext(intermediate, context);
    if (inputValidation.isFail) {
      return SchemaResult.fail(inputValidation.getError());
    }

    return inputSchema.encodeWithContext(intermediate, context);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final base = Map<String, Object?>.from(inputSchema.toJsonSchema());
    if (description != null) {
      base['description'] = description;
    }
    return mergeConstraintSchemas(base);
  }

  /// Returns a copy of this codec with the supplied fields replaced.
  CodecSchemaImpl<Boundary, InputRuntime, Runtime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return CodecSchemaImpl<Boundary, InputRuntime, Runtime>(
      inputSchema: inputSchema,
      outputSchema: outputSchema,
      decoder: decoder,
      encoder: encoder,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  CodecSchemaImpl<Boundary, InputRuntime, Runtime> withRuntimeConfig({
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

  /// Wraps this codec in a [DefaultSchema] that supplies [defaultValue]
  /// when the input is null on parse.
  DefaultSchema<Boundary, Runtime> withDefault(Runtime defaultValue) {
    return DefaultSchema<Boundary, Runtime>(
      inner: this,
      defaultValue: defaultValue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CodecSchemaImpl<Boundary, InputRuntime, Runtime>) {
      return false;
    }
    return baseFieldsEqual(other) &&
        inputSchema == other.inputSchema &&
        outputSchema == other.outputSchema &&
        identical(decoder, other.decoder) &&
        identical(encoder, other.encoder);
  }

  @override
  int get hashCode => Object.hash(
    baseFieldsHashCode,
    inputSchema,
    outputSchema,
    decoder.hashCode,
    encoder.hashCode,
  );
}
