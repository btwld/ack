import 'constraint.dart';

/// Constraint to validate if a number is finite.
class NumberFiniteConstraint<N extends num> extends Constraint<N>
    with Validator<N> {
  const NumberFiniteConstraint()
    : super(
        constraintKey: 'number.isFinite',
        description: 'Value must be a finite number.',
      );

  @override
  bool isValid(N value) => value.isFinite;

  @override
  String buildMessage(N value) => 'Value must be finite, but was not.';

  // No additional fields - base class equality is sufficient.
}
