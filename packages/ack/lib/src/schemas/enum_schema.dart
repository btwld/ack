part of 'schema.dart';

/// Schema for validating enum values.
@immutable
final class EnumSchema<T extends Enum> extends AckSchema<T>
    with FluentSchema<T, EnumSchema<T>> {
  final List<T> values;

  const EnumSchema({
    required this.values,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : super(schemaType: SchemaType.enumType);

  @override
  @protected
  SchemaResult<T> _onConvert(Object? inputValue, SchemaContext context) {
    if (inputValue is T && values.contains(inputValue)) {
      return SchemaResult.ok(inputValue);
    }

    // Try to match by name if input is a string
    if (inputValue is String) {
      try {
        final enumValue = values.firstWhere((e) => e.name == inputValue);

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
  EnumSchema<T> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required T? defaultValue,
    required List<Validator<T>>? constraints,
    required List<Refinement<T>>? refinements,
    List<T>? values,
  }) {
    return EnumSchema(
      values: values ?? this.values,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  EnumSchema<T> copyWith({
    bool? isNullable,
    String? description,
    T? defaultValue,
    List<Validator<T>>? constraints,
    List<Refinement<T>>? refinements,
    List<T>? values,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
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
