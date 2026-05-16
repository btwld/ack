part of 'schema.dart';

/// Schema for validating enum values where the boundary is the enum's `.name`
/// (a `String`) and the runtime is the typed enum value.
@immutable
final class EnumSchema<T extends Enum> extends AckSchema<String, T>
    with FluentSchema<String, T, EnumSchema<T>> {
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
  SchemaResult<T> parseWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    if (value is! String) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: SchemaType.string,
          actualType: AckSchema.getSchemaType(value),
          context: context,
        ),
      );
    }

    T? parsed;
    try {
      parsed = values.firstWhere((e) => e.name == value);
    } on StateError {
      parsed = null;
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Unexpected error matching enum value: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    if (parsed == null) {
      final allowed = values.map((e) => e.name).toList(growable: false);
      final closest = findClosestStringMatch(value, allowed);
      final suggestion = closest != null && closest != value
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

    return applyConstraintsAndRefinements(parsed, context);
  }

  @override
  @protected
  SchemaResult<T> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;
    if (value is! T) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Expected instance of $T, got ${value.runtimeType}',
          context: context,
        ),
      );
    }
    if (!values.contains(value)) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Enum value $value is not part of the schema values.',
          context: context,
        ),
      );
    }
    return applyConstraintsAndRefinements(value, context);
  }

  @override
  @protected
  SchemaResult<String> encodeWithContext(T value, SchemaContext context) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    return SchemaResult.ok(value.name);
  }

  @override
  EnumSchema<T> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<T>>? constraints,
    List<Refinement<T>>? refinements,
  }) {
    return EnumSchema<T>(
      values: values,
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
