part of 'schema.dart';

/// Schema that bidirectionally converts between a boundary type [I] and a
/// runtime type [O] using paired decoder and encoder functions.
@immutable
final class CodecSchema<I extends Object, O extends Object> extends AckSchema<O>
    with FluentSchema<O, CodecSchema<I, O>> {
  static const String jsonSchemaMarker = 'x-transformed';

  static const String _oneWayEncodeMessage =
      'This schema is one-way (.transform(...)) and has no encode '
      'function. Use Ack.codec(input, output, decode: ..., encode: ...) '
      'for a bidirectional codec.';

  final AckSchema<I> inputSchema;
  final AckSchema<O> outputSchema;
  final O Function(I value) decoder;
  final I Function(O value)? encoder;

  const CodecSchema({
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
  SchemaResult<O> validate(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    final outputCheck = outputSchema.validate(value, context);
    if (outputCheck.isFail) return outputCheck.castFail();

    final outputValue = outputCheck.getOrThrow()!;
    return applyConstraintsAndRefinements(outputValue, context);
  }

  @override
  @protected
  SchemaResult<O> decodeBoundary(Object? input, SchemaContext context) {
    if (input == null && isNullable) {
      return SchemaResult.ok(null);
    }

    final inputResult = inputSchema.decodeBoundary(input, context);
    if (inputResult.isFail) {
      return inputResult.castFail();
    }

    final validatedInput = inputResult.getOrNull();
    if (validatedInput == null) {
      if (!isNullable) return failNonNullable(context);
      return SchemaResult.ok(null);
    }

    final O decoded;
    try {
      decoded = decoder(validatedInput);
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

    final outputResult = outputSchema.validate(decoded, context);
    if (outputResult.isFail) return outputResult.castFail();
    final outputValue = outputResult.getOrThrow()!;
    return applyConstraintsAndRefinements(outputValue, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeBoundary(O value, SchemaContext context) {
    final encode = encoder;
    if (encode == null) {
      return SchemaResult.fail(
        SchemaEncodeError(message: _oneWayEncodeMessage, context: context),
      );
    }

    final I encoded;
    try {
      encoded = encode(value);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaEncodeError(
          message: 'Encode failed: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    // Re-validate the encoded boundary value against inputSchema to catch
    // encoders that produce values violating the input schema's constraints.
    // Use validate (not decodeBoundary) so a codec-of-codec inputSchema does
    // not re-run its decoder on the already-runtime-typed encoded value.
    final inputCheck = inputSchema.validate(encoded, context);
    if (inputCheck.isFail) return inputCheck.castFail();
    return SchemaResult.ok(encoded);
  }

  @override
  CodecSchema<I, O> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<O>>? constraints,
    List<Refinement<O>>? refinements,
  }) {
    return CodecSchema<I, O>(
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
  Map<String, Object?> toJsonSchema() {
    final base = inputSchema.toJsonSchema();
    base[jsonSchemaMarker] = true;
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
        outputSchema == other.outputSchema;
  }

  @override
  int get hashCode =>
      Object.hash(baseFieldsHashCode, inputSchema, outputSchema);
}
