part of 'schema.dart';

/// Schema that bidirectionally converts between a boundary type [I] and a
/// runtime type [O] using paired `decoder` and `encoder` functions.
///
/// `parse` validates `I` via [inputSchema], runs [decoder], then validates
/// the result against [outputSchema] before applying codec-level
/// constraints and refinements.
///
/// `encode` is the inverse: it validates `O` via [outputSchema], applies
/// codec-level constraints and refinements, runs [encoder], then validates
/// the resulting `I` via [inputSchema].
///
/// When [encoder] is `null` the codec is one-way: any call to `encode` (or
/// `safeEncode`) fails with a [SchemaEncodeError] that points at
/// `Ack.codec(...)`. The fluent `.transform(fn)` extension produces such a
/// one-way codec.
///
/// Defaults are forward-only. [defaultValue] is `O`-typed and is applied
/// only during parse (via the same defensive cloning used by the previous
/// `TransformedSchema`); encode never synthesizes boundary data from a
/// default.
@immutable
final class CodecSchema<I extends Object, O extends Object> extends AckSchema<O>
    with FluentSchema<O, CodecSchema<I, O>> {
  /// JSON Schema extension key marking a codec/transform output.
  static const String jsonSchemaMarker = 'x-transformed';

  /// Error message produced when `encode` is called on a one-way schema
  /// (a `.transform(...)` with no inverse).
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
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => inputSchema.schemaType;

  @override
  bool get strictPrimitiveParsing => inputSchema.strictPrimitiveParsing;

  @override
  @protected
  SchemaResult<O> parseAndValidate(Object? inputValue, SchemaContext context) {
    if (inputValue == null && defaultValue != null) {
      final cloned = cloneDefault(defaultValue!);
      final safeDefault = (cloned is O) ? cloned : defaultValue!;
      return _validateDecoded(safeDefault, context);
    }

    final inputResult = inputSchema.parseAndValidate(inputValue, context);
    if (inputResult.isFail) {
      return inputResult.castFail();
    }

    final validatedInput = inputResult.getOrNull();

    if (validatedInput == null) {
      if (!isNullable) {
        return failNonNullable(context);
      }
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

    return _validateDecoded(decoded, context);
  }

  SchemaResult<O> _validateDecoded(O value, SchemaContext context) {
    final result = outputSchema.parseAndValidate(value, context);
    if (result.isFail) return result.castFail();
    return applyConstraintsAndRefinements(result.getOrThrow()!, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeValue(
    Object? runtimeValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullForEncode(runtimeValue, context);
    if (nullResult != null) return nullResult;

    final encode = encoder;
    if (encode == null) {
      return SchemaResult.fail(
        SchemaEncodeError(message: _oneWayEncodeMessage, context: context),
      );
    }

    if (runtimeValue is! O) {
      return SchemaResult.fail(
        SchemaEncodeError.typeMismatch(
          expected: O,
          actual: runtimeValue,
          context: context,
        ),
      );
    }

    // Validate runtime shape against outputSchema. We call encodeValue for its
    // validation side-effect only; the boundary-form result is irrelevant here
    // because the codec's own `encoder` produces the boundary form below.
    final outputCheck = outputSchema.encodeValue(runtimeValue, context);
    if (outputCheck.isFail) return outputCheck.castFail();

    final constraintResult = applyConstraintsAndRefinements(
      runtimeValue,
      context,
    );
    if (constraintResult.isFail) {
      return constraintResult.castFail();
    }

    final I encoded;
    try {
      encoded = encode(runtimeValue);
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

    return inputSchema.encodeValue(encoded, context);
  }

  @override
  CodecSchema<I, O> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    O? defaultValue,
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
      defaultValue: defaultValue ?? this.defaultValue,
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
    if (defaultValue != null) {
      final encodedDefault = safeEncode(defaultValue);
      if (encodedDefault.isOk) {
        base['default'] = encodedDefault.getOrNull();
      }
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
