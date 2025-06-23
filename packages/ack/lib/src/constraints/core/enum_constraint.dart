import '../constraint.dart';

/// Validates that a value is one of the allowed enum values.
class EnumConstraint<T extends Enum> extends Constraint<T?>
    with Validator<T?>, JsonSchemaSpec<T?> {
  final List<T> allowedValues;

  EnumConstraint(this.allowedValues)
      : super(
          constraintKey: 'enum_value',
          description:
              'Value must be one of: ${allowedValues.map((e) => e.name).join(', ')}',
        );

  @override
  bool isValid(T? value) {
    if (value == null) return true;
    return allowedValues.contains(value);
  }

  @override
  String buildMessage(T? value) {
    final allowedNames = allowedValues.map((e) => e.name).join(', ');
    return 'Must be one of: $allowedNames, but got ${value?.name ?? 'null'}';
  }

  @override
  Map<String, Object?> toJsonSchema() => {
        'enum': allowedValues.map((e) => e.name).toList(),
      };
}