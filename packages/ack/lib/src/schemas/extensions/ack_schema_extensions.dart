import '../../constraints/constraint.dart';
import '../../schemas/schema.dart';

/// Core extensions for all AckSchema types.
extension AckSchemaExtensions<Boundary extends Object, Runtime extends Object>
    on AckSchema<Boundary, Runtime> {
  /// Adds a custom validation check that runs after all other validations have
  /// passed for this schema.
  AckSchema<Boundary, Runtime> refine(
    bool Function(Runtime value) validate, {
    String message = 'The value did not pass the custom validation.',
  }) {
    final newRefinement = (validate: validate, message: message);
    final self = this;
    if (self is FluentSchema) {
      return (self as dynamic).copyWithBase(
        refinements: [...refinements, newRefinement],
      ) as AckSchema<Boundary, Runtime>;
    }
    if (self is CodecSchemaImpl<Boundary, dynamic, Runtime>) {
      return self.copyWith(
        refinements: [...refinements, newRefinement],
      );
    }
    throw StateError(
      'refine() is not supported on ${self.runtimeType}. '
      'Use a schema produced by Ack or a CodecSchema.',
    );
  }

  /// Marks the schema as optional - the field can be omitted from an object.
  ///
  /// See FluentSchema.optional for details.
  AckSchema<Boundary, Runtime> optional({bool value = true}) {
    if (isOptional == value) return this;
    final self = this;
    if (self is FluentSchema) {
      return (self as dynamic).optional(value: value)
          as AckSchema<Boundary, Runtime>;
    }
    if (self is CodecSchemaImpl<Boundary, dynamic, Runtime>) {
      return self.optional(value: value);
    }
    if (self is DefaultSchema<Boundary, Runtime>) {
      return self.optional(value: value);
    }
    if (self is TransformedSchema<Boundary, dynamic, Runtime>) {
      return self.optional(value: value);
    }
    throw StateError(
      'optional() is not supported on ${self.runtimeType}.',
    );
  }

  /// Marks the schema as nullable.
  AckSchema<Boundary, Runtime> nullable({bool value = true}) {
    if (isNullable == value) return this;
    final self = this;
    if (self is FluentSchema) {
      return (self as dynamic).nullable(value: value)
          as AckSchema<Boundary, Runtime>;
    }
    if (self is CodecSchemaImpl<Boundary, dynamic, Runtime>) {
      return self.nullable(value: value);
    }
    if (self is DefaultSchema<Boundary, Runtime>) {
      return self.nullable(value: value);
    }
    if (self is TransformedSchema<Boundary, dynamic, Runtime>) {
      return self.nullable(value: value);
    }
    throw StateError(
      'nullable() is not supported on ${self.runtimeType}.',
    );
  }

  /// Adds a raw [constraint] to the schema.
  AckSchema<Boundary, Runtime> constrain(
    Constraint<Runtime> constraint, {
    String? message,
  }) {
    if (constraint is! Validator<Runtime>) {
      throw ArgumentError(
        'Constraint ${constraint.runtimeType} must implement Validator<Runtime>.',
      );
    }

    final effectiveConstraint = message == null
        ? constraint
        : _ConstraintMessageOverride<Runtime>(constraint, message);

    final self = this;
    if (self is FluentSchema) {
      return (self as dynamic).copyWithBase(
        constraints: [...constraints, effectiveConstraint],
      ) as AckSchema<Boundary, Runtime>;
    }
    if (self is CodecSchemaImpl<Boundary, dynamic, Runtime>) {
      return self.copyWith(
        constraints: [...constraints, effectiveConstraint],
      );
    }
    throw StateError(
      'constrain() is not supported on ${self.runtimeType}.',
    );
  }

  /// Maps the validated runtime value to a new runtime type [R] in a
  /// parse-only direction. Encoding will fail with
  /// `SchemaEncodeFailureKind.oneWayTransform`.
  TransformedSchema<Boundary, Runtime, R> transform<R extends Object>(
    R Function(Runtime value) transformer,
  ) {
    return TransformedSchema<Boundary, Runtime, R>(
      this,
      transformer,
      isOptional: isOptional,
      isNullable: isNullable,
    );
  }

  /// Builds a bidirectional codec on top of this schema. Encoding is
  /// supported when both [decode] and [encode] are provided.
  CodecSchema<Boundary, R> codec<R extends Object>({
    required R Function(Runtime value) decode,
    required Runtime Function(R value) encode,
    AckSchema<dynamic, R>? output,
  }) {
    return CodecSchemaImpl<Boundary, Runtime, R>(
      inputSchema: this,
      outputSchema: output ?? InstanceSchema<R>(),
      decoder: decode,
      encoder: encode,
    );
  }
}

class _ConstraintMessageOverride<T extends Object> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  _ConstraintMessageOverride(this.inner, this.customMessage)
    : super(constraintKey: inner.constraintKey, description: inner.description);

  final Constraint<T> inner;
  final String customMessage;

  Validator<T> get _validator => inner as Validator<T>;

  @override
  bool isValid(T value) => _validator.isValid(value);

  @override
  String buildMessage(T value) => customMessage;

  @override
  Map<String, Object?> buildContext(T value) {
    return _validator.buildContext(value);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    if (inner is JsonSchemaSpec<T>) {
      return (inner as JsonSchemaSpec<T>).toJsonSchema();
    }
    return const {};
  }
}
