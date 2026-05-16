part of 'schema.dart';

/// Public interface for codec schemas exposing two type parameters.
abstract interface class CodecSchema<
  Boundary extends Object,
  Runtime extends Object
> implements AckSchema<Boundary, Runtime> {
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
  SchemaResult<Runtime> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    final inputResult = inputSchema.parseAndValidate(inputValue, context);
    if (inputResult.isFail) {
      return SchemaResult.fail(inputResult.getError());
    }

    final decodedInput = inputResult.getOrNull();
    if (decodedInput == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    final Runtime runtime;
    try {
      runtime = decoder(decodedInput);
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

    // Run the runtime value through the output schema so refinements/
    // constraints attached to the typed runtime apply.
    final outputResult = outputSchema.parseAndValidate(runtime, context);
    if (outputResult.isFail) {
      return SchemaResult.fail(outputResult.getError());
    }

    final validatedRuntime = outputResult.getOrNull();
    if (validatedRuntime == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    return applyConstraintsAndRefinements(validatedRuntime, context);
  }

  @override
  @protected
  SchemaResult<Boundary> encodeRuntime(
    Runtime value,
    SchemaContext context,
  ) {
    // Validate runtime through the output schema first.
    final outputCheck = outputSchema.safeEncode(value);
    if (outputCheck.isFail) {
      return SchemaResult.fail(outputCheck.getError());
    }

    final InputRuntime intermediate;
    try {
      intermediate = encoder(value);
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

    return inputSchema.safeEncode(intermediate);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final base = inputSchema.toJsonSchema();
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

  CodecSchemaImpl<Boundary, InputRuntime, Runtime> nullable({
    bool value = true,
  }) {
    return copyWith(isNullable: value);
  }

  CodecSchemaImpl<Boundary, InputRuntime, Runtime> optional({
    bool value = true,
  }) {
    return copyWith(isOptional: value);
  }

  DefaultSchema<Boundary, Runtime> withDefault(Runtime defaultValue) {
    return DefaultSchema<Boundary, Runtime>(
      inner: this,
      defaultValue: defaultValue,
    );
  }

  CodecSchemaImpl<Boundary, InputRuntime, Runtime> describe(
    String description,
  ) {
    return copyWith(description: description);
  }

  CodecSchemaImpl<Boundary, InputRuntime, Runtime> refine(
    bool Function(Runtime value) validate, {
    String message = 'The value did not pass the custom validation.',
  }) {
    return copyWith(
      refinements: [...refinements, (validate: validate, message: message)],
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
