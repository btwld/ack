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
    with
        FluentSchema<Boundary, Runtime, CodecSchema<Boundary, Runtime>>,
        WrapperSchema<Boundary, Runtime, CodecSchema<Boundary, Runtime>> {
  /// The boundary input schema. Internal codec plumbing; not part of the
  /// public API surface.
  @internal
  final AckSchema<Boundary, Object> inputSchema;

  /// The output schema applied to the runtime value after decoding and before
  /// encoding. Internal codec plumbing; not part of the public API surface.
  @internal
  final AckSchema<dynamic, Runtime> outputSchema;

  /// Whether this codec's runtime constraints describe its boundary values,
  /// and may therefore be projected onto the exported wire schema.
  ///
  /// A constraint is declared in runtime terms, so the projection is only
  /// valid when the codec's mapping preserves the keyword's meaning — e.g.
  /// [Ack.duration], whose boundary is the milliseconds a
  /// `DurationConstraint` already renders. Internal codec plumbing; not part
  /// of the public API surface.
  @internal
  final bool projectsConstraintsToBoundary;

  final Runtime Function(Object value) _decoder;
  final Object Function(Runtime value)? _encoder;
  final Object _decoderIdentity;

  CodecSchema._({
    required this.inputSchema,
    required this.outputSchema,
    required Runtime Function(Object value) decoder,
    required Object Function(Runtime value)? encoder,
    required Object decoderIdentity,
    this.projectsConstraintsToBoundary = false,
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
    return createCodecSchemaInternal(
      inputSchema: inputSchema,
      outputSchema: outputSchema,
      decoder: decoder,
      encoder: encoder,
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(Object? value, SchemaContext context) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final inputResult = inputSchema.parseWithContext(value, context);
    if (inputResult.isFail) {
      return SchemaResult.fail(inputResult.getError());
    }

    final intermediate = inputResult.getOrNull()!;

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

    final validated = outputResult.getOrNull()!;

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
    final runtime = validated.getOrNull()!;

    final Object intermediate;
    try {
      intermediate = encode(runtime);
    } catch (e, st) {
      if (e is Error) {
        Error.throwWithStackTrace(e, st);
      }
      return SchemaResult.fail(
        SchemaEncodeError.encoderThrew(
          message: 'Codec encode failed: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    return inputSchema.encodeWithContext(intermediate, context);
  }

  @override
  CodecSchema<Boundary, Runtime> copyWithInner(AnyAckSchema newInner) {
    return CodecSchema._(
      inputSchema: newInner as AckSchema<Boundary, Object>,
      outputSchema: outputSchema,
      decoder: _decoder,
      encoder: _encoder,
      decoderIdentity: _decoderIdentity,
      projectsConstraintsToBoundary: projectsConstraintsToBoundary,
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  CodecSchema<Boundary, Runtime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return CodecSchema._(
      inputSchema: inputSchema,
      outputSchema: outputSchema,
      decoder: _decoder,
      encoder: _encoder,
      decoderIdentity: _decoderIdentity,
      projectsConstraintsToBoundary: projectsConstraintsToBoundary,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CodecSchema<Boundary, Runtime>) return false;

    return baseFieldsEqual(other) &&
        inputSchema == other.inputSchema &&
        outputSchema == other.outputSchema &&
        projectsConstraintsToBoundary == other.projectsConstraintsToBoundary &&
        _decoderIdentity == other._decoderIdentity &&
        _encoder == other._encoder;
  }

  @override
  AnyAckSchema get inner => inputSchema as AnyAckSchema;

  @override
  SchemaType get schemaType => inputSchema.schemaType;

  @override
  int get hashCode => Object.hash(
    baseFieldsHashCode,
    inputSchema,
    outputSchema,
    projectsConstraintsToBoundary,
    _decoderIdentity,
    _encoder,
  );
}

/// Internal codec construction used by ACK factories and fluent extensions.
///
/// This keeps nullability inference and wire-constraint projection out of the
/// public [CodecSchema.create] contract.
@internal
CodecSchema<Boundary, Runtime> createCodecSchemaInternal<
  Boundary extends Object,
  InputRuntime extends Object,
  Runtime extends Object
>({
  required AckSchema<Boundary, InputRuntime> inputSchema,
  required AckSchema<dynamic, Runtime> outputSchema,
  required Runtime Function(InputRuntime value) decoder,
  required InputRuntime Function(Runtime value)? encoder,
  bool projectsConstraintsToBoundary = false,
  bool? isNullable,
  bool isOptional = false,
  String? description,
  List<Constraint<Runtime>> constraints = const [],
  List<Refinement<Runtime>> refinements = const [],
}) {
  return CodecSchema._(
    inputSchema: inputSchema,
    outputSchema: outputSchema,
    decoder: (value) => decoder(value as InputRuntime),
    encoder: encoder,
    decoderIdentity: decoder,
    projectsConstraintsToBoundary: projectsConstraintsToBoundary,
    isNullable: isNullable ?? inputSchema.acceptsNull,
    isOptional: isOptional,
    description: description,
    constraints: constraints,
    refinements: refinements,
  );
}
