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
  });

  @override
  JsonType get acceptedType => JsonType.string;

  /// EnumSchema uses custom parsing logic that doesn't fit the standard
  /// primitive type conversion patterns, so it overrides parseAndValidate directly.
  @override
  @protected
  SchemaResult<T> parseAndValidate(Object? inputValue, SchemaContext context) {
    // Inline null handling for scalar schema
    if (inputValue == null) {
      if (defaultValue != null) {
        return applyConstraintsAndRefinements(defaultValue!, context);
      }
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullable(context);
    }

    // Custom enum parsing logic
    T? parsed;

    // Try exact enum match first
    if (inputValue is T && values.contains(inputValue)) {
      parsed = inputValue;
    }
    // Try to match by name if input is a string
    else if (inputValue is String) {
      try {
        parsed = values.firstWhere((e) => e.name == inputValue);
      } catch (_) {
        // Continue to integer check
      }
    }
    // Try to match by index if input is an int
    else if (inputValue is int && inputValue >= 0 && inputValue < values.length) {
      parsed = values[inputValue];
    }

    if (parsed == null) {
      final constraintError = InvalidTypeConstraint(
        expectedType: T,
        inputValue: inputValue,
      ).validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    // Use centralized constraints and refinements check
    return applyConstraintsAndRefinements(parsed, context);
  }

  @override
  EnumSchema<T> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required T? defaultValue,
    required List<Constraint<T>>? constraints,
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
    List<T>? values,
    bool? isNullable,
    String? description,
    T? defaultValue,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
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

    final schema = {
      'type': isNullable ? ['string', 'null'] : 'string',
      'enum': enumNames,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': (defaultValue as T).name,
    };

    return mergeConstraintSchemas(schema);
  }
}
