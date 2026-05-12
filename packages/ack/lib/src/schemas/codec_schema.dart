part of 'schema.dart';

bool _isNullJsonSchemaBranch(Object? value) {
  return value is Map && value['type'] == 'null';
}

Map<String, Object?> _stripNullableJsonSchema(Map<String, Object?> schema) {
  final anyOf = schema['anyOf'];
  if (anyOf is List && anyOf.any(_isNullJsonSchemaBranch)) {
    final nonNullBranches = [
      for (final branch in anyOf)
        if (!_isNullJsonSchemaBranch(branch)) branch,
    ];

    if (nonNullBranches.length == 1 && nonNullBranches.single is Map) {
      final branch = Map<String, Object?>.from(nonNullBranches.single as Map);
      for (final entry in schema.entries) {
        if (entry.key == 'anyOf' || entry.key == 'nullable') continue;
        branch.putIfAbsent(entry.key, () => entry.value);
      }
      return branch;
    }

    return {
      for (final entry in schema.entries)
        if (entry.key != 'nullable')
          entry.key: entry.key == 'anyOf' ? nonNullBranches : entry.value,
    };
  }

  final type = schema['type'];
  if (type is List && type.contains('null')) {
    final nonNullTypes = [
      for (final entry in type)
        if (entry != 'null') entry,
    ];
    return {
      for (final entry in schema.entries)
        if (entry.key != 'nullable' && entry.key != 'type')
          entry.key: entry.value,
      if (nonNullTypes.length == 1) 'type': nonNullTypes.single,
      if (nonNullTypes.length > 1) 'type': nonNullTypes,
    };
  }

  if (schema['nullable'] == true) {
    return {
      for (final entry in schema.entries)
        if (entry.key != 'nullable') entry.key: entry.value,
    };
  }

  return schema;
}

Map<String, Object?> _applyCodecNullability(
  Map<String, Object?> schema,
  bool isNullable,
) {
  if (isNullable) return _applyNullableWrapper(schema, true);
  return _stripNullableJsonSchema(schema);
}

/// A schema that converts between boundary values of type [I] and runtime
/// values of type [O].
///
/// Parsing validates the input with [inputSchema], runs [decoder], and
/// validates the decoded value with [outputSchema]. Encoding validates the
/// runtime value with [outputSchema], runs [encoder], and feeds the result
/// back through [inputSchema] so nested codecs compose.
///
/// When [encoder] is `null`, the codec is one-way and [safeEncode] fails with
/// [SchemaEncodeError.oneWayTransform]. Prefer the [Ack.codec] factory for
/// public construction — it requires both [decoder] and [encoder].
///
/// Field naming follows `dart:convert`: methods are verbs (`encode` /
/// `decode`), the function-typed fields holding them are nouns ([encoder] /
/// [decoder]).
///
/// ```dart
/// final intFromString = Ack.codec<String, int>(
///   input: Ack.string().matches(r'^-?\d+$'),
///   output: Ack.integer(),
///   decoder: int.parse,
///   encoder: (value) => value.toString(),
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

  /// Runtime → boundary converter. `null` for one-way codecs produced by
  /// `schema.transform(...)`; [safeEncode] then fails with
  /// [SchemaEncodeError.oneWayTransform].
  final I Function(O)? encoder;

  const CodecSchema({
    required this.inputSchema,
    required this.outputSchema,
    required this.decoder,
    this.encoder,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => inputSchema.schemaType;

  /// Decodes a non-null boundary value through [inputSchema], runs [decoder],
  /// then validates the decoded value through [outputSchema]. Constraints and
  /// refinements declared on this codec itself are applied by the dispatcher
  /// after decode succeeds.
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

    // Validate the decoded runtime value through [outputSchema] and pass the
    // validated value forward, so refinements observe the canonical form
    // produced by [outputSchema] rather than the raw decoder output.
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

    // Run the encoded value through [inputSchema]'s encode pipeline so nested
    // codecs compose. Calls the protected hooks directly to preserve the
    // existing context and JSON-pointer path.
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
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final base = Map<String, Object?>.of(inputSchema.toJsonSchema());
    final body = _applyCodecNullability(base, isNullable);
    body['x-ack-codec'] = true;
    final codecDescription = description;
    if (codecDescription != null) {
      body['description'] = codecDescription;
    }
    return mergeConstraintSchemas(body);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CodecSchema<I, O>) return false;
    // Closure identity is intentionally ignored: equality is structural over
    // schemas. The presence or absence of an encoder is observably different
    // (one-way vs bidirectional) and remains part of equality.
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
