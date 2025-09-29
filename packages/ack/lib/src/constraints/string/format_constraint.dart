import '../constraint.dart';

/// Constraint to validate if a string is a valid email address.
class EmailConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  // Email regex pattern that requires at least one dot after @ and no consecutive dots
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$",
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

  @override
  Map<String, Object?> toJsonSchema() => {'format': 'email'};
}

/// Constraint to validate if a string is a valid URL.
class UrlConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  UrlConstraint()
      : super(
          constraintKey: 'string.url',
          description: 'Value must be a valid URL.',
        );

  @override
  bool isValid(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  String buildMessage(String value) => '"$value" is not a valid URL.';

  @override
  Map<String, Object?> toJsonSchema() => {'format': 'uri'};
}

/// Constraint to validate if a string is a valid UUID.
class UuidConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
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

  @override
  Map<String, Object?> toJsonSchema() => {'format': 'uuid'};
}

/// Constraint to validate if a string matches a given regex pattern.
class MatchesConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
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

  @override
  Map<String, Object?> toJsonSchema() => {'pattern': pattern};
}

/// Constraint to validate if a string is a valid ISO 8601 date-time.
class DateTimeConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
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

  @override
  Map<String, Object?> toJsonSchema() => {'format': 'date-time'};
}

/// Constraint to validate if a string starts with a given value.
class StartsWithConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
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

  @override
  Map<String, Object?> toJsonSchema() =>
      {'pattern': '^${RegExp.escape(prefix)}'};
}

/// Constraint to validate if a string ends with a given value.
class EndsWithConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
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

  @override
  Map<String, Object?> toJsonSchema() =>
      {'pattern': '${RegExp.escape(suffix)}\$'};
}

/// Constraint to validate if a string is a valid IP address.
class IpConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  final int? version; // 4, 6 or null for any

  static final _ipv4Regex =
      RegExp(r'^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$');

  // Regex for IPv6.
  static final _ipv6Regex = RegExp(
    r'(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))',
  );

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

  @override
  Map<String, Object?> toJsonSchema() {
    if (version == 4) return {'format': 'ipv4'};
    if (version == 6) return {'format': 'ipv6'};

    return {
      'oneOf': [
        {'format': 'ipv4'},
        {'format': 'ipv6'},
      ]
    };
  }
}
