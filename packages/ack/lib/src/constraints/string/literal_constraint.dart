import 'package:ack/src/constraints/constraint.dart';

/// {@template string_literal_constraint}
/// Validates that the input string equals the expected value exactly
///
/// This is particularly useful for discriminator fields in discriminated schemas.
/// {@endtemplate}
class StringLiteralConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  /// The expected string value
  final String expectedValue;

  /// {@macro string_literal_constraint}
  const StringLiteralConstraint(this.expectedValue)
      : super(
          constraintKey: 'string_literal',
          description: 'Must be exactly: "$expectedValue"',
        );

  @override
  bool isValid(String value) => value == expectedValue;

  @override
  String buildMessage(String value) =>
      'Must be exactly: "$expectedValue" but got "$value"';

  @override
  Map<String, Object?> toJsonSchema() => {
        'enum': [expectedValue],
      };
}
