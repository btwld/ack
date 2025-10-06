import '../constraint.dart';

/// Constraint to validate if a double is finite.
class IsFiniteConstraint extends Constraint<double> with Validator<double> {
  const IsFiniteConstraint()
    : super(
        constraintKey: 'double.isFinite',
        description: 'Value must be a finite number.',
      );

  @override
  bool isValid(double value) => value.isFinite;

  @override
  String buildMessage(double value) => 'Value must be finite, but was not.';
}
