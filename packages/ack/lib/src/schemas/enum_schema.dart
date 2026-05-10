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

  /// Decodes a non-null boundary value into an enum [T]. Accepts the enum
  /// itself, the enum's `.name`, or its index. Constraints/refinements are
  /// applied by [_parse].
  @override
  @protected
  SchemaResult<T> decodeBoundary(Object? input, SchemaContext context) {
    final inputValue = input!;

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

    return SchemaResult.ok(parsed);
  }

  /// Validates that the runtime value is the enum type [T] AND a member of
  /// this schema's allowed [values] subset.
  ///
  /// Per the A4 decision (codec-open-questions.md:84), the encode side is
  /// strict: only enum values are accepted. Strings and integer indices are
  /// rejected even though [decodeBoundary] still accepts them on parse.
  /// Membership outside the allowed subset surfaces as a
  /// [SchemaConstraintsError] over [_EnumValuesConstraint], not as a type
  /// mismatch.
  @override
  @protected
  SchemaResult<T> _validateRuntime(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return SchemaResult.fail(_failNullForRuntime(context));
    }
    if (value is! T) {
      return SchemaResult.fail(_failTypeMismatchForRuntime(value, context));
    }
    if (!values.contains(value)) {
      final allowed = values.map((e) => e.name).toList(growable: false);
      final error = ConstraintError(
        constraint: _EnumValuesConstraint(allowed),
        message:
            'Enum value "${value.name}" is not in the allowed subset: '
            '${allowed.map((s) => '"$s"').join(', ')}.',
        context: {
          'received': value.name,
          'allowedValues': allowed,
        },
      );
      return SchemaResult.fail(
        SchemaConstraintsError(constraints: [error], context: context),
      );
    }
    return applyConstraintsAndRefinements(value, context);
  }

  /// Encodes an enum runtime value to its `.name` string — the canonical
  /// boundary form. Membership and type are already enforced by
  /// [_validateRuntime] before this is called.
  @override
  @protected
  SchemaResult<Object> encodeBoundary(T value, SchemaContext context) {
    return SchemaResult.ok(value.name);
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
      typeSchema: {'type': 'string', 'enum': enumNames},
      // Serialize enum default to its name
      serializedDefault: defaultValue?.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EnumSchema<T>) return false;
    final listEq = ListEquality<T>();
    return baseFieldsEqual(other) && listEq.equals(values, other.values);
  }

  @override
  int get hashCode {
    final listEq = ListEquality<T>();
    return Object.hash(baseFieldsHashCode, listEq.hash(values));
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _EnumValuesConstraint) return false;
    if (runtimeType != other.runtimeType) return false;
    const listEq = ListEquality<String>();
    return constraintKey == other.constraintKey &&
        description == other.description &&
        listEq.equals(allowed, other.allowed);
  }

  @override
  int get hashCode {
    const listEq = ListEquality<String>();
    return Object.hash(
      runtimeType,
      constraintKey,
      description,
      listEq.hash(allowed),
    );
  }
}
