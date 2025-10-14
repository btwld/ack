import 'constraint.dart';

/// Validates that an input string is exactly equal to an `expectedValue`.
///
/// Useful for discriminator fields or fixed value properties.
/// It will always pass if the input value is `null`.
class StringLiteralConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  final String expectedValue;

  const StringLiteralConstraint(this.expectedValue)
    : super(
        constraintKey: 'string_literal_equals',
        description: 'String must be exactly "$expectedValue".',
      );

  @override
  bool isValid(String value) {
    return value == expectedValue;
  }

  @override
  String buildMessage(String value) =>
      'Must be exactly "$expectedValue", but got "$value".';

  @override
  Map<String, Object?> toJsonSchema() => {
    // 'const' is the most direct JSON Schema keyword for this.
    'const': expectedValue,
  };
}
