import 'package:meta/meta.dart';

abstract class Constraint<T extends Object> {
  final String constraintKey;

  final String description;

  const Constraint({required this.constraintKey, required this.description});

  Map<String, Object?> toMap() {
    return {'constraintKey': constraintKey, 'description': description};
  }

  @override
  String toString() => '$runtimeType: $constraintKey: $description';
}

class ConstraintError {
  final Constraint constraint;

  final String message;

  final Map<String, Object?>? context;

  const ConstraintError({
    required this.message,
    required this.constraint,
    this.context,
  });

  Type get type => constraint.runtimeType;

  String get constraintKey => constraint.constraintKey;

  Object? getContextValue(String key) => context?[key];

  Map<String, Object?> toMap() {
    return {
      'message': message,
      'constraint': constraint.toMap(),
      'context': context,
    };
  }

  @override
  String toString() => '$runtimeType: $constraintKey: $message';
}

/// Mixin for constraints that can be converted to JSON Schema representation.
///
/// This mixin provides the contract for converting constraint validation rules
/// into JSON Schema draft-7 compliant format.
mixin JsonSchemaSpec<T extends Object> on Constraint<T> {
  /// Converts this constraint to its JSON Schema representation.
  ///
  /// Returns a map containing JSON Schema keywords that represent
  /// this constraint according to JSON Schema draft-7 specification.
  Map<String, Object?> toJsonSchema();
}

/// Deprecated alias for JsonSchemaSpec mixin.
///
/// Use [JsonSchemaSpec] instead for JSON Schema draft-7 compliance.
@Deprecated(
  'Use JsonSchemaSpec instead. Will be removed in next major version.',
)
mixin OpenApiSpec<T extends Object> on Constraint<T> {
  @Deprecated(
    'This method will be removed in future versions. Use toJsonSchema() instead.',
  )
  Map<String, Object?> toOpenApiSpec() {
    return toJsonSchema();
  }

  Map<String, Object?> toJsonSchema();
}

mixin Validator<T extends Object> on Constraint<T> {
  @protected
  String buildMessage(T value);

  @protected
  Map<String, Object?> buildContext(T value) => {'value': value};
  @protected
  bool isValid(T value);

  ConstraintError? validate(T value) => isValid(value)
      ? null
      : ConstraintError(
          message: buildMessage(value),
          constraint: this,
          context: buildContext(value),
        );
}

mixin WithConstraintError<T> on Constraint {
  @protected
  String buildMessage(T value);

  ConstraintError buildError(T value) {
    return ConstraintError(message: buildMessage(value), constraint: this);
  }
}
