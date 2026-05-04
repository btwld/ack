part of 'schema.dart';

/// Schema that bidirectionally converts between a boundary type [I] and a
/// runtime type [O] using paired `decode` and `encode` functions.
///
/// `parse` validates `I` via [inputSchema], runs [decodeFn], then validates
/// the result against [outputSchema] before applying codec-level
/// constraints and refinements.
///
/// `encode` is the inverse: it validates `O` via [outputSchema], applies
/// codec-level constraints and refinements, runs [encodeFn], then validates
/// the resulting `I` via [inputSchema].
///
/// When [encodeFn] is `null` the codec is one-way: any call to `encode` (or
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
  static const String oneWayEncodeMessage =
      'This schema is one-way (.transform(...)) and has no encode '
      'function. Use Ack.codec(input, output, decode: ..., encode: ...) '
      'for a bidirectional codec.';

  final AckSchema<I> inputSchema;
  final AckSchema<O> outputSchema;
  final O Function(I value) decodeFn;
  final I Function(O value)? encodeFn;

  const CodecSchema({
    required this.inputSchema,
    required this.outputSchema,
    required this.decodeFn,
    required this.encodeFn,
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
    // Default handling: codec defaults are O-typed, so short-circuit before
    // delegating to the input schema (which expects I).
    if (inputValue == null && defaultValue != null) {
      final cloned = cloneDefault(defaultValue!);
      final safeDefault = (cloned is O) ? cloned : defaultValue!;
      return applyConstraintsAndRefinements(safeDefault, context);
    }

    final inputResult = inputSchema.parseAndValidate(inputValue, context);
    if (inputResult.isFail) {
      return SchemaResult.fail(inputResult.getError());
    }

    final validatedInput = inputResult.getOrNull();

    // Outer null handling: even if the inner schema accepted null, this
    // codec only allows null through when itself nullable.
    if (validatedInput == null) {
      if (!isNullable) {
        return failNonNullable(context);
      }
      return SchemaResult.ok(null);
    }

    final O decoded;
    try {
      decoded = decodeFn(validatedInput);
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

    // Validate the decoded runtime value through the output schema.
    final outputResult = outputSchema.parseAndValidate(decoded, context);
    if (outputResult.isFail) {
      return SchemaResult.fail(outputResult.getError());
    }

    final validatedOutput = outputResult.getOrNull();
    if (validatedOutput == null) {
      return failNonNullable(context);
    }

    return applyConstraintsAndRefinements(validatedOutput, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeValue(
    Object? runtimeValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullForEncode(runtimeValue, context);
    if (nullResult != null) return nullResult;

    final encode = encodeFn;
    if (encode == null) {
      return SchemaResult.fail(
        SchemaEncodeError(message: oneWayEncodeMessage, context: context),
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

    final outputResult = outputSchema.encodeValue(runtimeValue, context);
    if (outputResult.isFail) {
      return SchemaResult.fail(outputResult.getError());
    }

    final constraintResult = applyConstraintsAndRefinements(
      runtimeValue,
      context,
    );
    if (constraintResult.isFail) {
      return SchemaResult.fail(constraintResult.getError());
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
      decodeFn: decodeFn,
      encodeFn: encodeFn,
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
        outputSchema == other.outputSchema &&
        identical(decodeFn, other.decodeFn) &&
        identical(encodeFn, other.encodeFn);
  }

  @override
  int get hashCode => Object.hash(
    baseFieldsHashCode,
    inputSchema,
    outputSchema,
    decodeFn.hashCode,
    encodeFn?.hashCode,
  );
}
