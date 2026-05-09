part of 'schema.dart';

/// Schema for bidirectional value conversion between an [inputSchema] (boundary
/// form, type [I]) and an [outputSchema] (runtime form, type [O]).
///
/// `decode(I) → O` runs during [parseAndValidate]; `encode(O) → I`, when
/// supplied, runs during [encodeBoundary]. When `encode` is `null`, the codec
/// is one-way and any [safeEncode] call fails with
/// [SchemaEncodeError.oneWayTransform].
///
/// ```dart
/// final intFromString = CodecSchema<String, int>(
///   inputSchema: Ack.string().matches(r'^-?\d+$'),
///   outputSchema: Ack.integer(),
///   decode: int.parse,
///   encode: (i) => i.toString(),
/// );
/// intFromString.parse('42');  // → 42
/// intFromString.encode(42);   // → '42'
/// ```
@immutable
class CodecSchema<I extends Object, O extends Object> extends AckSchema<O>
    with FluentSchema<O, CodecSchema<I, O>> {
  /// Schema describing the boundary form (e.g. JSON-friendly types).
  final AckSchema<I> inputSchema;

  /// Schema describing the runtime form. Used to validate decoded values on
  /// parse and runtime values on encode.
  final AckSchema<O> outputSchema;

  /// Boundary → runtime converter.
  final O Function(I) decoder;

  /// Runtime → boundary converter. `null` for one-way codecs (e.g. legacy
  /// `.transform(...)` chains that did not specify an inverse).
  final I Function(O)? encoder;

  const CodecSchema({
    required this.inputSchema,
    required this.outputSchema,
    required this.decoder,
    this.encoder,
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
  SchemaResult<O> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Defaults are of type O (runtime). Apply them before delegating, so the
    // wrapped inputSchema doesn't try to validate an O value.
    if (inputValue == null && defaultValue != null) {
      final cloned = cloneDefault(defaultValue!);
      final safeDefault = (cloned is O) ? cloned : defaultValue!;
      return applyConstraintsAndRefinements(safeDefault, context);
    }

    final inputResult = inputSchema.parseAndValidate(inputValue, context);
    if (inputResult case Fail(error: final e)) {
      return SchemaResult.fail<O>(e);
    }

    final validatedInput = inputResult.getOrNull();

    // Outer nullability still applies even if the wrapped input schema can
    // accept null.
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
          message: 'Decode failed: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    // Validate the decoded runtime value (e.g. range checks declared on the
    // output schema).
    final outputResult = outputSchema._validateRuntime(decoded, context);
    if (outputResult case Fail(error: final e)) {
      return SchemaResult.fail<O>(e);
    }

    return applyConstraintsAndRefinements(decoded, context);
  }

  @override
  @protected
  SchemaResult<O> _validateRuntime(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return SchemaResult.fail(
        SchemaEncodeError.nonNullable(context: context),
      );
    }

    final outputResult = outputSchema._validateRuntime(value, context);
    if (outputResult case Fail(error: final e)) {
      return SchemaResult.fail<O>(e);
    }

    final validatedValue = outputResult.getOrNull();
    if (validatedValue == null) {
      // Should not happen: outputSchema accepted null for a non-null value.
      return SchemaResult.fail(
        SchemaEncodeError.nonNullable(context: context),
      );
    }

    return applyConstraintsAndRefinements(validatedValue, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeBoundary(O value, SchemaContext context) {
    final fn = encoder;
    if (fn == null) {
      return SchemaResult.fail(
        SchemaEncodeError.oneWayTransform(context: context),
      );
    }

    final I encoded;
    try {
      encoded = fn(value);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaEncodeError.encoderThrew(
          cause: e,
          stackTrace: st,
          context: context,
        ),
      );
    }

    // Run the encoded value through the inputSchema's encode pipeline so
    // nested codecs compose correctly. We use the protected hooks directly
    // (rather than safeEncode) so the existing context / path are preserved.
    final innerValidation = inputSchema._validateRuntime(encoded, context);
    if (innerValidation case Fail(error: final e)) {
      return SchemaResult.fail<Object>(e);
    }
    final innerValue = innerValidation.getOrNull();
    if (innerValue == null) {
      return SchemaResult.ok<Object>(null);
    }
    return inputSchema.encodeBoundary(innerValue, context);
  }

  @override
  CodecSchema<I, O> copyWith({
    AckSchema<I>? inputSchema,
    AckSchema<O>? outputSchema,
    O Function(I)? decoder,
    I Function(O)? encoder,
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
    final base = inputSchema.toJsonSchema();
    base['x-ack-codec'] = true;
    // Legacy marker, retained for one beta cycle so existing consumers keep
    // working. Will be removed once downstream packages migrate to
    // `x-ack-codec`.
    base['x-transformed'] = true;
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
        identityHashCode(decoder),
        identityHashCode(encoder),
      );
}
