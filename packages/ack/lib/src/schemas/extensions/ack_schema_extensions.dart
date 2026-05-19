import '../../schemas/schema.dart';

/// Core extensions for all AckSchema types.
extension AckSchemaExtensions<Boundary extends Object, Runtime extends Object>
    on AckSchema<Boundary, Runtime> {
  /// Maps the validated runtime value to a new runtime type [R] in a
  /// parse-only direction.
  ///
  /// Encoding this one-way schema fails with a [SchemaEncodeError] whose
  /// [SchemaEncodeError.kind] is [SchemaEncodeFailureKind.oneWayTransform].
  CodecSchema<Boundary, R> transform<R extends Object>(
    R Function(Runtime value) transformer,
  ) {
    return CodecSchema.create<Boundary, Runtime, R>(
      inputSchema: this,
      outputSchema: InstanceSchema<R>(),
      decoder: transformer,
      encoder: null,
      isOptional: isOptional,
      isNullable: isNullable,
    );
  }

  /// Builds a bidirectional codec on top of this schema.
  ///
  /// [output] is the runtime-side schema for [R]. It validates decoded values
  /// after [decode] and validates runtime values before [encode]. When omitted,
  /// [InstanceSchema] checks only the runtime type.
  CodecSchema<Boundary, R> codec<R extends Object>({
    required R Function(Runtime value) decode,
    required Runtime Function(R value) encode,
    AckSchema<dynamic, R>? output,
  }) {
    return CodecSchema.create<Boundary, Runtime, R>(
      inputSchema: this,
      outputSchema: output ?? InstanceSchema<R>(),
      decoder: decode,
      encoder: encode,
      isOptional: isOptional,
      isNullable: isNullable,
    );
  }
}
