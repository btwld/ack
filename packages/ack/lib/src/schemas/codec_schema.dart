part of 'schema.dart';

/// Codec schema for translating between a boundary value and a runtime value.
///
/// [Boundary] is the encoded shape and [Runtime] is the Dart application value.
/// The intermediate runtime type produced by [inputSchema] is preserved by
/// [create] and erased inside this concrete wrapper so callers do not have to
/// carry a third public type argument.
@immutable
final class CodecSchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime>
    with WrapperSchema<Boundary, Runtime, CodecSchema<Boundary, Runtime>> {
  final AckSchema<Boundary, dynamic> inputSchema;

  /// The output schema applied to the runtime value after decoding and before
  /// encoding.
  final AckSchema<dynamic, Runtime> outputSchema;

  final Runtime Function(Object value) _decoder;
  final Object Function(Runtime value)? _encoder;
  final Object _decoderIdentity;

  CodecSchema._({
    required this.inputSchema,
    required this.outputSchema,
    required Runtime Function(Object value) decoder,
    required Object Function(Runtime value)? encoder,
    required Object decoderIdentity,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  }) : _decoder = decoder,
       _encoder = encoder,
       _decoderIdentity = decoderIdentity;

  /// Creates a codec while preserving the input schema's runtime type.
  static CodecSchema<Boundary, Runtime> create<
    Boundary extends Object,
    InputRuntime extends Object,
    Runtime extends Object
  >({
    required AckSchema<Boundary, InputRuntime> inputSchema,
    required AckSchema<dynamic, Runtime> outputSchema,
    required Runtime Function(InputRuntime value) decoder,
    required InputRuntime Function(Runtime value)? encoder,
    bool isNullable = false,
    bool isOptional = false,
    String? description,
    List<Constraint<Runtime>> constraints = const [],
    List<Refinement<Runtime>> refinements = const [],
  }) {
    return CodecSchema<Boundary, Runtime>._(
      inputSchema: inputSchema,
      outputSchema: outputSchema,
      decoder: (value) => decoder(value as InputRuntime),
      encoder: encoder,
      decoderIdentity: decoder,
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  AnyAckSchema get inner => inputSchema as AnyAckSchema;

  @override
  SchemaType get schemaType => inputSchema.schemaType;

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(Object? value, SchemaContext context) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final inputResult = inputSchema.parseWithContext(value, context);
    if (inputResult.isFail) {
      return SchemaResult.fail(inputResult.getError());
    }

    final intermediate = inputResult.getOrNull();
    if (intermediate == null) {
      // Defensive: a well-behaved inputSchema does not return Ok(null) for a
      // non-null input. Surface the nullability error as a contract violation.
      if (isNullable) return SchemaResult.ok(null);
      return failNonNullable(context);
    }

    final Runtime runtime;
    try {
      runtime = _decoder(intermediate);
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

    final outputResult = outputSchema.validateRuntimeWithContext(
      value,
      context,
    );
    if (outputResult.isFail) {
      return SchemaResult.fail(outputResult.getError());
    }

    final validated = outputResult.getOrNull();
    if (validated == null) {
      // Defensive: a well-behaved outputSchema does not return Ok(null) for a
      // non-null input. Surface the nullability error as a contract violation.
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
    final encode = _encoder;
    if (encode == null) {
      return SchemaResult.fail(
        SchemaEncodeError.oneWayTransform(context: context),
      );
    }

    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    final runtime = validated.getOrNull();
    if (runtime == null) return failNonNullableEncode(context);

    final Object intermediate;
    try {
      intermediate = encode(runtime);
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

    // Ensure the intermediate matches the input schema's runtime shape before
    // encoding to boundary.
    final inputValidation = inputSchema.validateRuntimeWithContext(
      intermediate,
      context,
    );
    if (inputValidation.isFail) {
      return SchemaResult.fail(inputValidation.getError());
    }

    final validatedInput = inputValidation.getOrNull();
    if (validatedInput == null) return failNonNullableEncode(context);
    return inputSchema.encodeWithContext(validatedInput, context);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    return applyWrapperJsonSchemaMetadata(
      Map<String, Object?>.from(inputSchema.toJsonSchema()),
      metadata: {if (_encoder == null) 'x-transformed': true},
    );
  }

  /// Returns a copy of this codec with the supplied runtime config replaced.
  CodecSchema<Boundary, Runtime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return CodecSchema<Boundary, Runtime>._(
      inputSchema: inputSchema,
      outputSchema: outputSchema,
      decoder: _decoder,
      encoder: _encoder,
      decoderIdentity: _decoderIdentity,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  @protected
  CodecSchema<Boundary, Runtime> copyWithRuntimeConfig({
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CodecSchema<Boundary, Runtime>) return false;
    return baseFieldsEqual(other) &&
        inputSchema == other.inputSchema &&
        outputSchema == other.outputSchema &&
        identical(_decoderIdentity, other._decoderIdentity) &&
        identical(_encoder, other._encoder);
  }

  @override
  int get hashCode => Object.hash(
    baseFieldsHashCode,
    inputSchema,
    outputSchema,
    _decoderIdentity.hashCode,
    _encoder.hashCode,
  );
}
