import 'constraint.dart';

/// Constraint to validate if a double is finite.
class NumberFiniteConstraint extends Constraint<double> with Validator<double> {
  const NumberFiniteConstraint()
    : super(
        constraintKey: 'double.isFinite',
        description: 'Value must be a finite number.',
      );

  @override
  bool isValid(double value) => value.isFinite;

  @override
  String buildMessage(double value) => 'Value must be finite, but was not.';

  // No additional fields - base class equality is sufficient.
}
