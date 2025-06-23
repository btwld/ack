import '../constraint.dart';

/// Constraint to enforce a minimum length on a string.
class MinLengthConstraint extends Constraint<String> with Validator<String> {
  final int min;
  MinLengthConstraint(this.min)
      : super(
          constraintKey: 'string.minLength',
          description: 'Value must be at least $min characters long.',
        );

  @override
  bool isValid(String value) => value.length >= min;

  @override
  String buildMessage(String value) =>
      'Value must be at least $min characters long, but was ${value.length}.';
}

/// Constraint to enforce a maximum length on a string.
class MaxLengthConstraint extends Constraint<String> with Validator<String> {
  final int max;
  MaxLengthConstraint(this.max)
      : super(
          constraintKey: 'string.maxLength',
          description: 'Value must be no more than $max characters long.',
        );

  @override
  bool isValid(String value) => value.length <= max;

  @override
  String buildMessage(String value) =>
      'Value must be no more than $max characters long, but was ${value.length}.';
}

/// Constraint to enforce an exact length on a string.
class ExactLengthConstraint extends Constraint<String> with Validator<String> {
  final int length;
  ExactLengthConstraint(this.length)
      : super(
          constraintKey: 'string.exactLength',
          description: 'Value must be exactly $length characters long.',
        );

  @override
  bool isValid(String value) => value.length == length;

  @override
  String buildMessage(String value) =>
      'Value must be exactly $length characters long, but was ${value.length}.';
}
