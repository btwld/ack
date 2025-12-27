part of 'schema.dart';

/// Schema for validating enum values.
@immutable
final class EnumSchema<T extends Enum> extends AckSchema<T>
    with FluentSchema<T, EnumSchema<T>> {
  final List<T> values;

  const EnumSchema({
    required this.values,
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.enum_;

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
      } on StateError {
        // Expected when no match found - continue to integer check
      } catch (e, st) {
        // Unexpected error indicates a serious problem
        return SchemaResult.fail(
          SchemaValidationError(
            message: 'Unexpected error matching enum value: ${e.toString()}',
            context: context,
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }
    // Try to match by index if input is an int
    else if (inputValue is int &&
        inputValue >= 0 &&
        inputValue < values.length) {
      parsed = values[inputValue];
    }

    if (parsed == null) {
      // Build helpful error message with allowed values and suggestions
      final allowed = values.map((e) => e.name).toList(growable: false);
      final inputStr = inputValue.toString();
      final closest = findClosestStringMatch(inputStr, allowed);
      final suggestion = closest != null && closest != inputStr
          ? ' Did you mean "$closest"?'
          : '';

      final error = ConstraintError(
        constraint: _EnumValuesConstraint(allowed),
        message:
            'Invalid enum value. Allowed: ${allowed.map((s) => '"$s"').join(', ')}.$suggestion',
        context: {
          'received': inputValue,
          'allowedValues': allowed,
          if (closest != null) 'closestMatchSuggestion': closest,
        },
      );

      return SchemaResult.fail(
        SchemaConstraintsError(constraints: [error], context: context),
      );
    }

    // Use centralized constraints and refinements check
    return applyConstraintsAndRefinements(parsed, context);
  }

  @override
  EnumSchema<T> copyWith({
    List<T>? values,
    bool? isNullable,
    bool? isOptional,
    String? description,
    T? defaultValue,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return EnumSchema(
      values: values ?? this.values,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final enumNames = values.map((e) => e.name).toList();

    return buildJsonSchemaWithNullable(
      typeSchema: {
        'type': 'string',
        'enum': enumNames,
      },
      // Serialize enum default to its name
      serializedDefault: defaultValue?.name,
    );
  }
}

/// Internal constraint used for better error reporting in EnumSchema.
class _EnumValuesConstraint extends Constraint<Object?> {
  final List<String> allowed;

  _EnumValuesConstraint(this.allowed)
    : super(
        constraintKey: 'enum_value',
        description: 'Value must be one of: ${allowed.join(", ")}',
      );
}
