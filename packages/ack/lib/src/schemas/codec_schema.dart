part of 'schema.dart';

/// Schema that describes a bidirectional transformation between a boundary
/// representation of type [I] and a runtime representation of type [O].
///
/// Unlike a unidirectional `.transform(...)`, a codec supplies both directions:
/// `decode` converts the validated input into the runtime output, while
/// `encode` converts the runtime output back into the input representation.
///
/// Forward traversal (`parse` / `decode`):
///   1. validate the incoming value against [inputSchema];
///   2. run `decode` on the validated input;
///   3. validate the decoded result against [outputSchema];
///   4. apply codec-level constraints and refinements.
///
/// Backward traversal (`encode`):
///   1. validate the incoming value against [outputSchema];
///   2. apply codec-level constraints and refinements;
///   3. run `encode` on the validated value;
///   4. validate the encoded value against [inputSchema].
///
/// ## Error model
///
/// During codec traversal, errors propagate verbatim from the inner
/// schemas — they are NOT wrapped in [SchemaTransformError] or
/// [SchemaEncodeError]. The error CLASS indicates the kind of failure
/// (constraint violation, type mismatch, refinement failure, transform
/// throw, encode throw, structural mismatch). The `path` and `context`
/// indicate WHERE in the graph it failed. Direction (parse vs encode) is
/// implied by the method that was called — `parse` / `safeParse` /
/// `decode` / `safeDecode` for forward, `encode` / `safeEncode` for
/// backward.
///
/// To handle any failure generically, catch the base [SchemaError].
/// To pin "the codec's own decode/encode closure threw", catch
/// [SchemaTransformError] (forward) or [SchemaEncodeError] (backward).
///
/// Defaults are not synthesized during backward traversal — encoding
/// serializes an existing runtime value rather than recovering from missing
/// input.
@immutable
final class CodecSchema<I extends Object, O extends Object> extends AckSchema<O>
    with FluentSchema<O, CodecSchema<I, O>> {
  final AckSchema<I> inputSchema;
  final AckSchema<O> outputSchema;
  final O Function(I value) _decode;
  final I Function(O value) _encode;

  const CodecSchema({
    required this.inputSchema,
    required this.outputSchema,
    required O Function(I value) decode,
    required I Function(O value) encode,
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : _decode = decode,
       _encode = encode;

  @override
  SchemaType get schemaType => outputSchema.schemaType;

  @override
  @protected
  SchemaResult<O> parseAndValidate(Object? inputValue, SchemaContext context) {
    // Null/default handling is inlined (rather than delegated to
    // handleNullInput) because defaultValue is typed O, not I — it must not
    // be routed through inputSchema.
    if (inputValue == null) {
      if (defaultValue != null) {
        final cloned = cloneDefault(defaultValue!);
        final safeDefault = (cloned is O) ? cloned : defaultValue!;
        return applyConstraintsAndRefinements(safeDefault, context);
      }
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    final inputResult = inputSchema.parseAndValidate(inputValue, context);
    if (inputResult case Fail(:final error)) return SchemaResult.fail(error);
    // inputValue is non-null (guarded above); inputSchema cannot produce Ok(null)
    // from a non-null input, so this is an invariant assertion.
    final validatedInput = inputResult.getOrNull()!;

    final O decoded;
    try {
      decoded = _decode(validatedInput);
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

    final outputResult = outputSchema.parseAndValidate(decoded, context);
    if (outputResult case Fail(:final error)) return SchemaResult.fail(error);
    final validatedOutput = outputResult.getOrNull()!;

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

    if (runtimeValue is! O) {
      return SchemaResult.fail(
        SchemaEncodeError(
          message:
              'Expected runtime type $O during encode, got ${runtimeValue.runtimeType}',
          context: context,
        ),
      );
    }

    final outputResult = outputSchema.parseAndValidate(runtimeValue, context);
    if (outputResult case Fail(:final error)) return SchemaResult.fail(error);
    // runtimeValue is non-null O (guarded above); outputSchema cannot produce
    // Ok(null) for a non-null O, so this is an invariant assertion. The same
    // applies to the subsequent applyConstraintsAndRefinements and encoder
    // boundary validation.
    final validatedOutput = outputResult.getOrNull()!;

    final refined = applyConstraintsAndRefinements(validatedOutput, context);
    if (refined case Fail(:final error)) return SchemaResult.fail(error);
    final refinedValue = refined.getOrNull()!;

    final I encoded;
    try {
      encoded = _encode(refinedValue);
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

    final encodedResult = inputSchema.parseAndValidate(encoded, context);
    if (encodedResult case Fail(:final error)) return SchemaResult.fail(error);
    return SchemaResult.ok(encodedResult.getOrNull()!);
  }

  /// Decodes a boundary value into the runtime type.
  ///
  /// Strongly-typed entry point: parameter is [I?]. For loose-typed input,
  /// use the inherited [parse] / [safeParse], which accept `Object?`.
  O? decode(I? value, {String? debugName}) {
    final result = safeDecode(value, debugName: debugName);
    return result.getOrThrow();
  }

  /// Decodes a boundary value into the runtime type without throwing.
  SchemaResult<O> safeDecode(I? value, {String? debugName}) =>
      safeParse(value, debugName: debugName);

  /// Encodes a runtime value back into its boundary representation.
  ///
  /// Returns `null` when the schema is nullable/optional and [value] is null.
  /// Throws [AckException] on failure.
  @override
  I? encode(Object? value, {String? debugName}) {
    final result = safeEncode(value, debugName: debugName);
    return result.getOrThrow();
  }

  /// Encodes a runtime value back into its boundary representation, returning
  /// a typed [SchemaResult]. Never throws.
  @override
  SchemaResult<I> safeEncode(Object? value, {String? debugName}) {
    final context = _createRootContext(value, debugName: debugName);
    // encodeValue produces an Object? in the SchemaResult — but for a codec
    // the underlying value is always either null (nullable/optional pass-
    // through) or a validated I from inputSchema.parseAndValidate, so the
    // cast on the way out is safe.
    return encodeValue(
      value,
      context,
    ).match(onOk: (v) => SchemaResult.ok(v as I?), onFail: SchemaResult.fail);
  }

  /// Returns the codec with input/output and decode/encode swapped.
  ///
  /// Equivalent to Zod's `z.invertCodec(...)`. The inverse drops codec-level
  /// constraints, refinements, and default value because those are typed
  /// against the original [O] direction.
  ///
  /// `isNullable`, `isOptional`, and `description` are preserved (they are
  /// type-agnostic).
  CodecSchema<O, I> inverse() => CodecSchema<O, I>(
    inputSchema: outputSchema,
    outputSchema: inputSchema,
    decode: _encode,
    encode: _decode,
    isNullable: isNullable,
    isOptional: isOptional,
    description: description,
  );

  @override
  CodecSchema<I, O> copyWith({
    AckSchema<I>? inputSchema,
    AckSchema<O>? outputSchema,
    O Function(I value)? decode,
    I Function(O value)? encode,
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
      decode: decode ?? _decode,
      encode: encode ?? _encode,
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
    // Defaults on a codec are runtime-typed (`O`); the JSON Schema's
    // `default` describes the boundary form, so encode through the codec
    // before serializing. If encoding fails, omit the default rather than
    // poison the schema.
    if (defaultValue != null) {
      try {
        base['default'] = _encode(defaultValue!);
      } catch (_) {
        // Intentionally silent: default omitted on encode failure.
      }
    }
    // Codec-level constraints/refinements are typed `Constraint<O>` and
    // describe the runtime side. Merging them into the input's JSON schema
    // tree would produce nonsense, so they are skipped here. They still
    // execute at parse/encode time.
    return base;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CodecSchema<I, O>) return false;
    return baseFieldsEqual(other) &&
        inputSchema == other.inputSchema &&
        outputSchema == other.outputSchema &&
        identical(_decode, other._decode) &&
        identical(_encode, other._encode);
  }

  @override
  int get hashCode => Object.hash(
    baseFieldsHashCode,
    inputSchema,
    outputSchema,
    _decode,
    _encode,
  );
}
