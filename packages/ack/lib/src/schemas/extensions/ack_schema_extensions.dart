import '../../constraints/constraint.dart';
import '../../schemas/schema.dart';

/// Core extensions for all AckSchema types.
/// Provides common functionality like refinement, transformation, and optional marking.
extension AckSchemaExtensions<T extends Object> on AckSchema<T> {
  /// Adds a custom validation check that runs after all other validations for this schema have passed.
  ///
  /// [validate] is a function that receives the parsed value of type [T] and must return `true` if the validation passes, and `false` otherwise.
  ///
  /// [message] is the custom error message to be used if the validation fails.
  AckSchema<T> refine(
    bool Function(T value) validate, {
    String message = 'The value did not pass the custom validation.',
  }) {
    final newRefinement = (validate: validate, message: message);

    // Create a new schema instance with the new refinement added to the list.
    return copyWith(refinements: [...refinements, newRefinement]);
  }

  /// Makes the schema optional - the field can be omitted from an object.
  ///
  /// This is different from `nullable()`:
  /// - `optional()`: Field can be absent from object, but if present, must not be null
  /// - `nullable()`: Field must be present in object, but can be null
  /// - Both: Field can be absent OR present as null
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'required': Ack.string(),           // Must be present and non-null
  ///   'optional': Ack.string().optional(), // Can be absent, but if present must be non-null
  ///   'nullable': Ack.string().nullable(), // Must be present, can be null
  ///   'both': Ack.string().optional().nullable(), // Can be absent or null
  /// });
  /// ```
  ///
  /// This method is idempotent - calling it multiple times returns the same schema if already optional.
  AckSchema<T> optional({bool value = true}) {
    if (isOptional == value) return this;
    return copyWith(isOptional: value);
  }

  /// Adds a raw [constraint] to the schema. This is useful for composing
  /// declarative constraints in addition to the built-in helpers.
  AckSchema<T> constrain(Constraint<T> constraint, {String? message}) {
    if (constraint is! Validator<T>) {
      throw ArgumentError(
        'Constraint ${constraint.runtimeType} must implement Validator<T>.',
      );
    }

    final effectiveConstraint = message == null
        ? constraint
        : _ConstraintMessageOverride<T>(constraint, message);

    return copyWith(constraints: [...constraints, effectiveConstraint]);
  }

  /// Transforms the validated value using the provided transformer function.
  ///
  /// The transformer is applied after all validations pass.
  /// This is useful for converting data types or applying business logic transformations.
  TransformedSchema<T, R> transform<R extends Object>(
    R Function(T? value) transformer,
  ) {
    return TransformedSchema(
      this,
      transformer,
      isOptional: isOptional,
      isNullable: isNullable,
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
