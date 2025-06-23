import '../constraint.dart';

/// Constraint to validate if a string is a valid email address.
class EmailConstraint extends Constraint<String> with Validator<String> {
  // A common email regex pattern.
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$",
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

/// Constraint to validate if a string matches a given regex pattern.
class MatchesConstraint extends Constraint<String> with Validator<String> {
  final String pattern;
  final String? example;
  late final RegExp _regex;

  MatchesConstraint(this.pattern, {this.example})
      : super(
          constraintKey: 'string.matches',
          description: 'Value must match the pattern "$pattern".',
        ) {
    _regex = RegExp(pattern);
  }

  @override
  bool isValid(String value) => _regex.hasMatch(value);

  @override
  String buildMessage(String value) =>
      '"$value" does not match the required pattern'
      '${example != null ? ' (e.g., "$example")' : ''}.';
}

/// Constraint to validate if a string is a valid ISO 8601 date-time.
class DateTimeConstraint extends Constraint<String> with Validator<String> {
  DateTimeConstraint()
      : super(
          constraintKey: 'string.datetime',
          description: 'Value must be a valid ISO 8601 date-time string.',
        );

  @override
  bool isValid(String value) {
    return DateTime.tryParse(value) != null;
  }

  @override
  String buildMessage(String value) =>
      '"$value" is not a valid date-time string.';
}

/// Constraint to validate if a string starts with a given value.
class StartsWithConstraint extends Constraint<String> with Validator<String> {
  final String prefix;

  StartsWithConstraint(this.prefix)
      : super(
          constraintKey: 'string.startsWith',
          description: 'Value must start with "$prefix".',
        );

  @override
  bool isValid(String value) => value.startsWith(prefix);

  @override
  String buildMessage(String value) =>
      '"$value" does not start with "$prefix".';
}

/// Constraint to validate if a string ends with a given value.
class EndsWithConstraint extends Constraint<String> with Validator<String> {
  final String suffix;

  EndsWithConstraint(this.suffix)
      : super(
          constraintKey: 'string.endsWith',
          description: 'Value must end with "$suffix".',
        );

  @override
  bool isValid(String value) => value.endsWith(suffix);

  @override
  String buildMessage(String value) => '"$value" does not end with "$suffix".';
}

/// Constraint to validate if a string is a valid IP address.
class IpConstraint extends Constraint<String> with Validator<String> {
  final int? version; // 4, 6 or null for any

  // Regex for IPv4
  static final _ipv4Regex =
      RegExp(r'^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$');

  // Regex for IPv6.
  static final _ipv6Regex = RegExp(
      r'(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))');

  IpConstraint({this.version})
      : super(
          constraintKey: 'string.ip',
          description:
              'Value must be a valid IP${version != null ? 'v$version' : ''} address.',
        );

  @override
  bool isValid(String value) {
    if (version == 4) return _ipv4Regex.hasMatch(value);
    if (version == 6) return _ipv6Regex.hasMatch(value);

    return _ipv4Regex.hasMatch(value) || _ipv6Regex.hasMatch(value);
  }

  @override
  String buildMessage(String value) =>
      '"$value" is not a valid IP${version != null ? 'v$version' : ''} address.';
}
