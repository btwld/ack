part of 'schema.dart';

/// Schema for validating a discriminated union of objects.
///
/// Based on a `discriminatorKey` (e.g., 'type'), it uses one of the provided
/// `schemas` to validate the object.
@immutable
final class DiscriminatedObjectSchema extends AckSchema<MapValue>
    with FluentSchema<MapValue, DiscriminatedObjectSchema> {
  final String discriminatorKey;
  final Map<String, AckSchema> schemas;

  const DiscriminatedObjectSchema({
    required this.discriminatorKey,
    required this.schemas,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : super(schemaType: SchemaType.discriminatedObject);

  @override
  @protected
  SchemaResult<MapValue> _performTypeConversion(
    Object inputValue,
    SchemaContext context,
  ) {
    if (inputValue is! MapValue) {
      final constraintError =
          InvalidTypeConstraint(expectedType: MapValue).validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    final Object? discValueRaw = inputValue[discriminatorKey];

    if (discValueRaw == null) {
      final constraintError = ObjectRequiredPropertiesConstraint(
        missingPropertyKey: discriminatorKey,
      ).validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    if (discValueRaw is! String) {
      final constraintError =
          InvalidTypeConstraint(expectedType: String).validate(discValueRaw);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    final AckSchema? selectedSubSchema = schemas[discValueRaw];

    if (selectedSubSchema == null) {
      final allowed = schemas.keys.toList(growable: false);
      final enumError = StringEnumConstraint(allowed).validate(discValueRaw);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: enumError != null ? [enumError] : [],
        context: context.createChild(
          name: discriminatorKey,
          schema: const StringSchema(),
          value: discValueRaw,
          pathSegment: discriminatorKey,
        ),
      ));
    }

    final subSchemaContext = SchemaContext(
      name: '${context.name}(when $discriminatorKey="$discValueRaw")',
      schema: selectedSubSchema,
      value: inputValue,
    );

    final result = selectedSubSchema.parseAndValidate(
      inputValue,
      subSchemaContext,
    );

    // Convert the result to MapValue type for compatibility
    return result.match(
      onOk: (value) => SchemaResult.ok(value as MapValue),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  @override
  DiscriminatedObjectSchema copyWith({
    String? discriminatorKey,
    Map<String, AckSchema>? schemas,
    bool? isNullable,
    String? description,
    MapValue? defaultValue,
    List<Constraint<MapValue>>? constraints,
    List<Refinement<MapValue>>? refinements,
  }) {
    return copyWithInternal(
      discriminatorKey: discriminatorKey,
      schemas: schemas,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  DiscriminatedObjectSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required MapValue? defaultValue,
    required List<Constraint<MapValue>>? constraints,
    required List<Refinement<MapValue>>? refinements,
    // DiscriminatedObjectSchema specific
    String? discriminatorKey,
    Map<String, AckSchema>? schemas,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      schemas: schemas ?? this.schemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final oneOfClauses = <Map<String, Object?>>[];
    schemas.forEach((discriminatorValue, objectSchema) {
      final subSchemaJson = objectSchema.toJsonSchema();
      // Ensure the discriminator property is correctly constrained in the sub-schema JSON
      subSchemaJson['properties'] = {
        ...?(subSchemaJson['properties'] as Map?),
        discriminatorKey: {'const': discriminatorValue},
      };
      subSchemaJson['required'] = {
        ...?(subSchemaJson['required'] as List?)?.cast<String>(),
        discriminatorKey,
      }.toList();
      oneOfClauses.add(subSchemaJson);
    });

    // Add null as an option if nullable
    if (isNullable) {
      oneOfClauses.insert(0, {'type': 'null'});
    }

    return {
      'oneOf': oneOfClauses,
      if (description != null) 'description': description,
    };
  }
}
