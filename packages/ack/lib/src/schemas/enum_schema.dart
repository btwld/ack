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
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.enum_;

  @override
  @protected
  SchemaResult<T> validate(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    if (value is! T || !values.contains(value)) {
      final allowed = values.map((e) => e.name).toList(growable: false);
      final inputStr = value.toString();
      final closest = findClosestStringMatch(inputStr, allowed);
      final suggestion = closest != null && closest != inputStr
          ? ' Did you mean "$closest"?'
          : '';
      final error = ConstraintError(
        constraint: _EnumValuesConstraint(allowed),
        message:
            'Invalid enum value. Allowed: ${allowed.map((s) => '"$s"').join(', ')}.$suggestion',
        context: {
          'received': value,
          'allowedValues': allowed,
          if (closest != null) 'closestMatchSuggestion': closest,
        },
      );

      return SchemaResult.fail(
        SchemaConstraintsError(constraints: [error], context: context),
      );
    }

    return applyConstraintsAndRefinements(value, context);
  }

  @override
  @protected
  SchemaResult<T> decodeBoundary(Object? input, SchemaContext context) {
    if (input == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    if (input is T && values.contains(input)) {
      return applyConstraintsAndRefinements(input, context);
    }

    if (input is String) {
      for (final value in values) {
        if (value.name == input) {
          return applyConstraintsAndRefinements(value, context);
        }
      }
    } else if (input is int && input >= 0 && input < values.length) {
      return applyConstraintsAndRefinements(values[input], context);
    }

    return _failEnumValue(input, context);
  }

  @override
  @protected
  SchemaResult<Object> encodeBoundary(T value, SchemaContext context) {
    return SchemaResult.ok(value.name);
  }

  SchemaResult<T> _failEnumValue(Object value, SchemaContext context) {
    final allowed = values.map((e) => e.name).toList(growable: false);
    final inputStr = value.toString();
    final closest = findClosestStringMatch(inputStr, allowed);
    final suggestion = closest != null && closest != inputStr
        ? ' Did you mean "$closest"?'
        : '';
    final error = ConstraintError(
      constraint: _EnumValuesConstraint(allowed),
      message:
          'Invalid enum value. Allowed: ${allowed.map((s) => '"$s"').join(', ')}.$suggestion',
      context: {
        'received': value,
        'allowedValues': allowed,
        if (closest != null) 'closestMatchSuggestion': closest,
      },
    );

    return SchemaResult.fail(
      SchemaConstraintsError(constraints: [error], context: context),
    );
  }

  @override
  EnumSchema<T> copyWith({
    List<T>? values,
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return EnumSchema(
      values: values ?? this.values,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final enumNames = values.map((e) => e.name).toList();

    return buildJsonSchemaWithNullable(
      typeSchema: {'type': 'string', 'enum': enumNames},
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
