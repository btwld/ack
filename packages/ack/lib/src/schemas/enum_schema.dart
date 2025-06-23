part of 'schema.dart';

/// Schema for validating enum values.
@immutable
final class EnumSchema<T extends Enum> extends AckSchema<T> {
  final List<T> values;

  const EnumSchema({
    required this.values,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
  }) : super(schemaType: SchemaType.enumType);

  @override
  SchemaResult<T> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is T && values.contains(inputValue)) {
      return SchemaResult.ok(inputValue);
    }

    // Try to match by name if input is a string
    if (inputValue is String) {
      try {
        final enumValue = values.firstWhere(
          (e) => e.name == inputValue,
        );
        return SchemaResult.ok(enumValue);
      } catch (_) {
        // Continue to error handling
      }
    }

    // Try to match by index if input is an int
    if (inputValue is int && inputValue >= 0 && inputValue < values.length) {
      return SchemaResult.ok(values[inputValue]);
    }

    final constraintError = InvalidTypeConstraint(
      expectedType: T,
      inputValue: inputValue,
    ).validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<T> validateConvertedValue(
    T convertedValue,
    SchemaContext context,
  ) {
    return SchemaResult.ok(convertedValue);
  }

  @override
  EnumSchema<T> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<T>>? constraints,
    List<T>? values,
  }) {
    return EnumSchema<T>(
      values: values ?? this.values,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as T?,
      constraints: constraints ?? this.constraints,
    );
  }

  @override
  EnumSchema<T> copyWith({
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<T>>? constraints,
    List<T>? values,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      values: values,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final enumNames = values.map((e) => e.name).toList();
    
    return {
      'type': isNullable ? ['string', 'null'] : 'string',
      'enum': enumNames,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': (defaultValue as T).name,
    };
  }
}