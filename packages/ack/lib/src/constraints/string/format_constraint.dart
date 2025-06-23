import '../constraint.dart';

/// Constraint to validate if a string is a valid email address.
class EmailConstraint extends Constraint<String> with Validator<String> {
  // A common email regex pattern.
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  EmailConstraint()
      : super(
          constraintKey: 'string.email',
          description: 'Value must be a valid email address.',
        );

  @override
  bool isValid(String value) => _emailRegex.hasMatch(value);

  @override
  String buildMessage(String value) => '"$value" is not a valid email address.';
}

/// Constraint to validate if a string is a valid URL.
class UrlConstraint extends Constraint<String> with Validator<String> {
  // A common URL regex pattern.
  static final _urlRegex = RegExp(
    r'^(https_?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
  );

  UrlConstraint()
      : super(
          constraintKey: 'string.url',
          description: 'Value must be a valid URL.',
        );

  @override
  bool isValid(String value) => _urlRegex.hasMatch(value);

  @override
  String buildMessage(String value) => '"$value" is not a valid URL.';
}

/// Constraint to validate if a string is a valid UUID.
class UuidConstraint extends Constraint<String> with Validator<String> {
  // A common UUID regex pattern.
  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  UuidConstraint()
      : super(
          constraintKey: 'string.uuid',
          description: 'Value must be a valid UUID.',
        );

  @override
  bool isValid(String value) => _uuidRegex.hasMatch(value);

  @override
  String buildMessage(String value) => '"$value" is not a valid UUID.';
}
