part of 'schema.dart';

/// Schema for bidirectional value conversion between an [inputSchema] (boundary
/// form, type [I]) and an [outputSchema] (runtime form, type [O]).
///
/// [decoder] (`I → O`) runs during the parse path; [encoder] (`O → I`),
/// when supplied, runs during [encodeBoundary]. When [encoder] is `null`, the
/// codec is one-way and any [safeEncode] call fails with
/// [SchemaEncodeError.oneWayTransform].
///
/// Field naming follows `dart:convert`: methods are verbs (`encode`/`decode`),
/// the function-typed fields holding them are nouns (`encoder`/`decoder`).
///
/// ```dart
/// final intFromString = CodecSchema<String, int>(
///   inputSchema: Ack.string().matches(r'^-?\d+$'),
///   outputSchema: Ack.integer(),
///   decoder: int.parse,
///   encoder: (i) => i.toString(),
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

  /// Custom null/default handling: defaults are of type `O` (runtime form),
  /// so they must not route through `inputSchema` (which validates `I`).
  @override
  @protected
  SchemaResult<O>? handleParseNull(Object? input, SchemaContext context) {
    if (input != null) return null;
    if (defaultValue != null) {
      final cloned = cloneDefault(defaultValue!);
      final safeDefault = (cloned is O) ? cloned : defaultValue!;
      return applyConstraintsAndRefinements(safeDefault, context);
    }
    if (isNullable) return SchemaResult.ok(null);
    return failNonNullable(context);
  }

  /// Decodes a non-null boundary value through `inputSchema`, runs the
  /// `decoder`, then validates the decoded value through `outputSchema`.
  /// Constraints/refinements on this codec are applied by [_parse].
  @override
  @protected
  SchemaResult<O> decodeBoundary(Object? input, SchemaContext context) {
    final inputResult = inputSchema._parse(input, context);
    if (inputResult case Fail(error: final e)) {
      return SchemaResult.fail<O>(e);
    }

    final validatedInput = inputResult.getOrNull();

    // Defensive: outer nullability still applies even if the wrapped input
    // schema permits null.
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
    // output schema). Pass the *validated* value forward — once output
    // schemas canonicalize (e.g. unmodifiable maps for ObjectSchema in M6),
    // refinements observe the canonical form, not the raw decoder output.
    final outputResult = outputSchema._validateRuntime(decoded, context);
    if (outputResult case Fail(error: final e)) {
      return SchemaResult.fail<O>(e);
    }
    final validated = outputResult.getOrThrow();
    if (validated == null) {
      // outputSchema is nullable and decoder produced null. Dispatcher will
      // short-circuit constraint application.
      return SchemaResult.ok(null);
    }

    return SchemaResult.ok(validated);
  }

  @override
  @protected
  SchemaResult<O> _validateRuntime(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return SchemaResult.fail(_failNullForRuntime(context));
    }

    final outputResult = outputSchema._validateRuntime(value, context);
    if (outputResult case Fail(error: final e)) {
      return SchemaResult.fail<O>(e);
    }

    final validatedValue = outputResult.getOrNull();
    if (validatedValue == null) {
      // Should not happen: outputSchema accepted null for a non-null value.
      return SchemaResult.fail(_failNullForRuntime(context));
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
    if (description != null) {
      base['description'] = description;
    }
    return mergeConstraintSchemas(base);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CodecSchema<I, O>) return false;
    // Closure identity is intentionally ignored (codec-open-questions §B3,
    // decision (a)): equality is structural over schemas. The presence vs.
    // absence of an encoder is observably different (one-way vs two-way), so
    // it remains part of equality even though the closure value itself is not.
    return baseFieldsEqual(other) &&
        inputSchema == other.inputSchema &&
        outputSchema == other.outputSchema &&
        (encoder == null) == (other.encoder == null);
  }

  @override
  int get hashCode => Object.hash(
        baseFieldsHashCode,
        inputSchema,
        outputSchema,
        encoder == null,
      );
}
