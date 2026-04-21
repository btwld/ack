part of 'schema.dart';

/// Schema that describes a bidirectional transformation between a boundary
/// representation of type [I] and a runtime representation of type [O].
///
/// Unlike a unidirectional `.transform(...)`, a codec supplies both directions:
/// [decoder] converts the validated input into the runtime output, while
/// [encoder] converts the runtime output back into the input representation.
///
/// Forward traversal (`parse` / `decode`):
///   1. validate the incoming value against [inputSchema];
///   2. run [decoder] on the validated input;
///   3. validate the decoded result against [outputSchema];
///   4. apply codec-level constraints and refinements.
///
/// Backward traversal (`encode`):
///   1. validate the incoming value against [outputSchema];
///   2. apply codec-level constraints and refinements;
///   3. run [encoder] on the validated value;
///   4. validate the encoded value against [inputSchema].
///
/// Defaults are not synthesized during backward traversal — encoding
/// serializes an existing runtime value rather than recovering from missing
/// input.
@immutable
final class CodecSchema<I extends Object, O extends Object> extends AckSchema<O>
    with FluentSchema<O, CodecSchema<I, O>> {
  final AckSchema<I> inputSchema;
  final AckSchema<O> outputSchema;
  final O Function(I value) decoder;
  final I Function(O value) encoder;

  const CodecSchema({
    required this.inputSchema,
    required this.outputSchema,
    required this.decoder,
    required this.encoder,
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => outputSchema.schemaType;

  @override
  @protected
  SchemaResult<O> parseAndValidate(Object? inputValue, SchemaContext context) {
    // Handle null up-front without routing through inputSchema, since input
    // schemas are typically non-nullable strings that would reject null even
    // when the codec itself is nullable.
    if (inputValue == null) {
      if (defaultValue != null) {
        final cloned = cloneDefault(defaultValue!);
        final safeDefault = (cloned is O) ? cloned : defaultValue!;
        return applyConstraintsAndRefinements(safeDefault, context);
      }
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullable(context);
    }

    // 1. Validate boundary input.
    final inputResult = inputSchema.parseAndValidate(inputValue, context);
    if (inputResult.isFail) {
      return SchemaResult.fail(inputResult.getError());
    }

    final validatedInput = inputResult.getOrNull();
    if (validatedInput == null) {
      // An internally-nullable input schema produced null. Codec decoders are
      // typed non-nullable, so this only makes sense when this codec is also
      // nullable; otherwise fail cleanly.
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    // 2. Run the decoder.
    final O decoded;
    try {
      decoded = decoder(validatedInput);
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

    // 3. Validate the decoded output using the output schema.
    final outputResult = outputSchema.parseAndValidate(decoded, context);
    if (outputResult.isFail) {
      return SchemaResult.fail(outputResult.getError());
    }

    final validatedOutput = outputResult.getOrNull();
    if (validatedOutput == null) {
      // Output schema accepted null, but codecs produce non-nullable values.
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Codec decoder returned null.',
          context: context,
        ),
      );
    }

    // 4. Apply codec-level constraints and refinements.
    return applyConstraintsAndRefinements(validatedOutput, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeValue(
    Object? runtimeValue,
    SchemaContext context,
  ) {
    // Nullability mirrors the forward direction; do NOT synthesize defaults.
    if (runtimeValue == null) {
      if (isNullable || isOptional) {
        return SchemaResult.ok(null);
      }
      return SchemaResult.fail(
        SchemaEncodeError(
          message: 'Value is required and cannot be null during encode.',
          context: context,
        ),
      );
    }

    if (runtimeValue is! O) {
      return SchemaResult.fail(
        SchemaEncodeError(
          message:
              'Expected runtime type $O during encode, got ${runtimeValue.runtimeType}',
          context: context,
        ),
      );
    }

    // 1. Validate the runtime value against the output schema.
    final outputResult = outputSchema.parseAndValidate(runtimeValue, context);
    if (outputResult.isFail) {
      return SchemaResult.fail(outputResult.getError());
    }
    final validatedOutput = outputResult.getOrNull();
    if (validatedOutput == null) {
      return SchemaResult.fail(
        SchemaEncodeError(
          message: 'Output schema produced null during encode.',
          context: context,
        ),
      );
    }

    // 2. Apply codec-level constraints/refinements on the runtime value.
    final refined = applyConstraintsAndRefinements(validatedOutput, context);
    if (refined.isFail) {
      return SchemaResult.fail(refined.getError());
    }
    final refinedValue = refined.getOrNull();
    if (refinedValue == null) {
      return SchemaResult.fail(
        SchemaEncodeError(
          message: 'Codec refinements produced null during encode.',
          context: context,
        ),
      );
    }

    // 3. Run the encoder.
    final I encoded;
    try {
      encoded = encoder(refinedValue);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaEncodeError(
          message: 'Codec encode failed: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    // 4. Validate the encoded boundary value against the input schema.
    final encodedResult = inputSchema.parseAndValidate(encoded, context);
    if (encodedResult.isFail) {
      return SchemaResult.fail(encodedResult.getError());
    }
    final validatedInput = encodedResult.getOrNull();
    if (validatedInput == null) {
      return SchemaResult.fail(
        SchemaEncodeError(
          message: 'Encoded boundary value did not validate.',
          context: context,
        ),
      );
    }
    return SchemaResult.ok(validatedInput);
  }

  /// Decodes a boundary value into the runtime type.
  ///
  /// Equivalent to [parse] for codecs, but semantically clearer.
  O? decode(Object? value, {String? debugName}) {
    final result = safeDecode(value, debugName: debugName);
    return result.getOrThrow();
  }

  /// Decodes a boundary value into the runtime type without throwing.
  SchemaResult<O> safeDecode(Object? value, {String? debugName}) =>
      safeParse(value, debugName: debugName);

  @override
  CodecSchema<I, O> copyWith({
    AckSchema<I>? inputSchema,
    AckSchema<O>? outputSchema,
    O Function(I value)? decoder,
    I Function(O value)? encoder,
    bool? isNullable,
    bool? isOptional,
    String? description,
    O? defaultValue,
    List<Constraint<O>>? constraints,
    List<Refinement<O>>? refinements,
  }) {
    return CodecSchema<I, O>(
      inputSchema: inputSchema ?? this.inputSchema,
      outputSchema: outputSchema ?? this.outputSchema,
      decoder: decoder ?? this.decoder,
      encoder: encoder ?? this.encoder,
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
    final base = Map<String, Object?>.from(inputSchema.toJsonSchema());
    base['x-ack-codec'] = true;
    if (description != null) {
      base['description'] = description;
    }
    return mergeConstraintSchemas(base);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CodecSchema<I, O>) return false;
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
    decoder,
    encoder,
  );
}
