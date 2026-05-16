part of 'schema.dart';

/// Schema for validating against a list of schemas (union).
///
/// `AnyOfSchema` keeps broad typing in the first redesign (`Object`/`Object`)
/// because Dart does not have first-class union types.
@immutable
final class AnyOfSchema extends AckSchema<Object, Object>
    with FluentSchema<Object, Object, AnyOfSchema> {
  final List<AckSchema> schemas;

  const AnyOfSchema(
    this.schemas, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.anyOf;

  @override
  @protected
  SchemaResult<Object> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final errors = <SchemaError>[];

    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: inputValue,
        pathSegment: '',
      );

      final result = schema.parseAndValidate(inputValue, childContext);

      if (result.isOk) {
        final validatedValue = result.getOrNull();

        if (validatedValue == null) {
          return SchemaResult.ok(null);
        }

        return applyConstraintsAndRefinements(validatedValue, context);
      }

      errors.add(result.getError());
    }

    if (inputValue == null && isNullable) {
      return SchemaResult.ok(null);
    }

    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  @protected
  SchemaResult<Object> encodeRuntime(Object value, SchemaContext context) {
    final errors = <SchemaError>[];
    for (final (index, schema) in schemas.indexed) {
      final childContext = context.createChild(
        name: 'anyOf:$index',
        schema: schema,
        value: value,
        pathSegment: '',
        operation: SchemaOperation.encode,
      );
      try {
        final encoded = schema.safeEncode(value);
        if (encoded.isOk) {
          final boundary = encoded.getOrNull();
          if (boundary != null) {
            return SchemaResult.ok(boundary);
          }
        } else {
          errors.add(encoded.getError());
        }
      } catch (e, st) {
        errors.add(
          SchemaEncodeError.encoderThrew(
            message: 'AnyOf branch $index threw: $e',
            context: childContext,
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }
    return SchemaResult.fail(
      SchemaNestedError(errors: errors, context: context),
    );
  }

  @override
  AnyOfSchema copyWithBase({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Object>>? constraints,
    List<Refinement<Object>>? refinements,
  }) {
    return AnyOfSchema(
      schemas,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final anyOfClauses = schemas.map((s) => s.toJsonSchema()).toList();

    final baseSchema = {
      'anyOf': anyOfClauses,
      if (!isNullable && description != null) 'description': description,
    };

    if (isNullable) {
      return {
        if (description != null) 'description': description,
        'anyOf': [
          mergeConstraintSchemas(baseSchema),
          {'type': 'null'},
        ],
      };
    }

    return mergeConstraintSchemas(baseSchema);
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'constraints': constraints.map((c) => c.toMap()).toList(),
      'schemas': schemas.length,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnyOfSchema) return false;
    const listEq = ListEquality<AckSchema>();
    return baseFieldsEqual(other) && listEq.equals(schemas, other.schemas);
  }

  @override
  int get hashCode {
    const listEq = ListEquality<AckSchema>();
    return Object.hash(baseFieldsHashCode, listEq.hash(schemas));
  }
}
