import '../constraint.dart';

/// Validates that a string value is one of the allowed enum values.
///
/// This constraint is useful for string fields that must match one of a
/// predefined set of values, similar to an enum but for strings.
class StringEnumConstraint extends Constraint<String?>
    with Validator<String?>, JsonSchemaSpec<String?> {
  final List<String> allowedValues;

  StringEnumConstraint(this.allowedValues)
      : super(
          constraintKey: 'string_enum',
          description:
              'Value must be one of: ${allowedValues.join(', ')}',
        );

  @override
  bool isValid(String? value) {
    if (value == null) return true;
    return allowedValues.contains(value);
  }

  @override
  String buildMessage(String? value) {
    final quoted = allowedValues.map((v) => '"$v"').join(', ');
    return 'Must be one of: $quoted, but got "${value ?? 'null'}"';
  }

  @override
  Map<String, Object?> toJsonSchema() => {
        'enum': allowedValues,
      };
}