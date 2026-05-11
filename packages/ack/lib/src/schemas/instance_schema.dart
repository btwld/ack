part of 'schema.dart';

/// A runtime type guard for values of type [T].
///
/// Most often supplied as the `output` schema of a [CodecSchema] when the
/// runtime form is a non-JSON Dart class (e.g. `DateTime`, `Uri`, `Duration`,
/// or a user class) and the boundary form is described by another schema.
///
/// Used standalone, accepts any value of type [T] on parse and on encode
/// without performing conversion. It has no boundary representation;
/// codec wrappers are responsible for emitting JSON Schema for the
/// boundary form.
///
/// ```dart
/// final dt = Ack.instance<DateTime>();
/// dt.parse(DateTime.now());      // Ok
/// dt.parse('2025-01-01T00:00Z'); // Fail (not a DateTime)
/// ```
@immutable
final class InstanceSchema<T extends Object> extends AckSchema<T>
    with FluentSchema<T, InstanceSchema<T>> {
  const InstanceSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.any;

  /// The boundary form is the runtime form — no separate decode step.
  /// Validates the runtime type only; constraints and refinements are applied
  /// by the dispatcher.
  @override
  @protected
  SchemaResult<T> decodeBoundary(Object? input, SchemaContext context) {
    final value = input!;
    if (value is! T) {
      return SchemaResult.fail(_failTypeMismatchForRuntime(value, context));
    }
    return SchemaResult.ok(value);
  }

  @override
  InstanceSchema<T> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return InstanceSchema<T>(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    return {
      if (description != null) 'description': description,
      'x-ack-instance': T.toString(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InstanceSchema<T>) return false;
    return baseFieldsEqual(other);
  }

  @override
  int get hashCode => Object.hash(InstanceSchema<T>, baseFieldsHashCode);
}
