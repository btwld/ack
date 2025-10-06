import '../constraint.dart';

/// Constraint to validate if a string is a valid IP address.
class IpConstraint extends Constraint<String>
    with Validator<String>, JsonSchemaSpec<String> {
  final int? version; // 4, 6 or null for any

  static final _ipv4Regex = RegExp(
    r'^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$',
  );

  // Regex for IPv6.
  static final _ipv6Regex = RegExp(
    r'(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))',
  );

  const IpConstraint({this.version})
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
      ],
    };
  }
}
