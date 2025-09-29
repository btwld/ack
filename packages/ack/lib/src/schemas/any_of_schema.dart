part of 'schema.dart';

/// Schema for validating against a list of schemas.
/// The input is valid if it is valid against any of the schemas in the list.
@immutable
final class AnyOfSchema extends AckSchema<Object>
    with FluentSchema<Object, AnyOfSchema> {
  final List<AckSchema> schemas;

  const AnyOfSchema(
    this.schemas, {
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : super(schemaType: SchemaType.unknown);

  @override
  @protected
  SchemaResult<Object> _performTypeConversion(Object inputValue, SchemaContext context) {
    final validationErrors = <SchemaError>[];

    for (var i = 0; i < schemas.length; i++) {
      final schema = schemas[i];
      final result = schema.validate(
        inputValue,
        debugName: '${context.name}[anyOf:$i]',
      );
      if (result.isOk) {
        return SchemaResult.ok(result.getOrThrow());
      }
      validationErrors.add(result.getError());
    }

    return SchemaResult.fail(SchemaNestedError(
      errors: validationErrors,
      context: context,
    ));
  }

  @override
  AnyOfSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Constraint<Object>>? constraints,
    required List<Refinement<Object>>? refinements,
    List<AckSchema>? schemas,
  }) {
    return AnyOfSchema(
      schemas ?? this.schemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final anyOfClauses = schemas.map((s) => s.toJsonSchema()).toList();

    // Add null as an option if nullable
    if (isNullable) {
      anyOfClauses.insert(0, {'type': 'null'});
    }

    return {
      'anyOf': anyOfClauses,
      if (description != null) 'description': description,
    };
  }
}
