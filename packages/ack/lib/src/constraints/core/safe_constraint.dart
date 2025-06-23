import '../constraint.dart';

/// The maximum safe integer in JavaScript.
const maxSafeInteger = 9007199254740991;

/// Constraint to validate if an integer is a "safe" integer.
/// A safe integer is an integer that can be exactly represented as an
/// IEEE-754 double precision number.
class IsSafeIntegerConstraint extends Constraint<int> with Validator<int> {
  IsSafeIntegerConstraint()
      : super(
          constraintKey: 'integer.isSafe',
          description: 'Value must be a safe integer.',
        );

  @override
  bool isValid(int value) => value.abs() <= maxSafeInteger;

  @override
  String buildMessage(int value) =>
      'Value must be between -$maxSafeInteger and $maxSafeInteger, but was $value.';
}
