import 'constraint.dart';

/// Constraint to validate if a string is a valid IP address.
class StringIpConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  final int? version; // 4, 6 or null for any

  static final _ipv4Regex = RegExp(
    r'^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$',
  );

  const StringIpConstraint({this.version})
    : super(
        constraintKey: 'string.ip',
        description:
            'Value must be a valid IP${version != null ? 'v$version' : ''} address.',
      );

  @override
  bool isValid(String value) {
    if (version == 4) return isIpv4(value);
    if (version == 6) return isIpv6(value);

    return isIpv4(value) || isIpv6(value);
  }

  static bool isIpv4(String value) => _ipv4Regex.hasMatch(value);

  static bool isIpv6(String value) {
    try {
      Uri.parseIPv6Address(value);
      return true;
    } on FormatException {
      return false;
    }
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
      ],
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StringIpConstraint) return false;
    if (runtimeType != other.runtimeType) return false;

    return constraintKey == other.constraintKey &&
        description == other.description &&
        version == other.version;
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, constraintKey, description, version);
}
