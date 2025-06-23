part of 'schema.dart';

/// Schema for validating discriminated unions (also known as tagged unions).
///
/// A `DiscriminatedObjectSchema` uses a specific `discriminatorKey` field in
/// the input object to determine which of the provided `subSchemas` should be
/// used to validate the rest of the object.
@immutable
final class DiscriminatedObjectSchema extends AckSchema<MapValue> {
  final String discriminatorKey;
  final Map<String, ObjectSchema>
      subSchemas; // Key is the discriminator value, Value is the schema

  DiscriminatedObjectSchema({
    required this.discriminatorKey,
    required this.subSchemas,
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints, // Object-level constraints applied AFTER successful discrimination
  }) : super(schemaType: SchemaType.discriminatedObject) {
    subSchemas.forEach((discriminatorValue, schema) {
      if (!schema.properties.containsKey(discriminatorKey)) {
        throw ArgumentError(
          'Sub-schema for discriminator value "$discriminatorValue" must define the discriminator property "$discriminatorKey".',
        );
      }
      final discriminatorPropSchema = schema.properties[discriminatorKey]!;
      if (discriminatorPropSchema is! StringSchema) {
        throw ArgumentError(
          'Discriminator property "$discriminatorKey" in sub-schema for "$discriminatorValue" must be a StringSchema.',
        );
      }
    });
  }

  @override
  SchemaResult<MapValue> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is Map) {
      try {
        final mapValue = Map<String, Object?>.from(inputValue);

        return SchemaResult.ok(mapValue);
      } catch (e) {
        return SchemaResult.fail(SchemaConstraintsError(
          constraints: [
            InvalidTypeConstraint(expectedType: MapValue).validate(inputValue)!,
          ],
          context: context,
        ));
      }
    }

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: [
        InvalidTypeConstraint(expectedType: MapValue).validate(inputValue)!,
      ],
      context: context,
    ));
  }

  @override
  SchemaResult<MapValue> validateConvertedValue(
    MapValue? convertedMap,
    SchemaContext context,
  ) {
    if (convertedMap == null) {
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: [NonNullableConstraint().validate(convertedMap)!],
          context: context,
        ),
      );
    }

    final Object? discValueRaw = convertedMap[discriminatorKey];

    if (discValueRaw == null) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          ObjectRequiredPropertiesConstraint(
            missingPropertyKey: discriminatorKey,
          ).validate(convertedMap)!,
        ],
        context: context,
      ));
    }

    if (discValueRaw is! String) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          InvalidTypeConstraint(expectedType: String).validate(discValueRaw)!,
        ],
        context: context,
      ));
    }

    final String discValue = discValueRaw;
    final ObjectSchema? selectedSubSchema = subSchemas[discValue];

    if (selectedSubSchema == null) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [
          // Simple constraint error for unknown discriminator value
          InvalidTypeConstraint(expectedType: String).validate(discValue)!,
        ],
        context: context,
      ));
    }

    final subSchemaContext = SchemaContext(
      name: '${context.name}(when $discriminatorKey="$discValue")',
      schema: selectedSubSchema,
      value: convertedMap,
    );

    return selectedSubSchema.parseAndValidate(convertedMap, subSchemaContext);
  }

  
  @protected
  DiscriminatedObjectSchema copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<MapValue>>? constraints,
    // DiscriminatedObjectSchema specific
    String? discriminatorKey,
    Map<String, ObjectSchema>? subSchemas,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      subSchemas: subSchemas ?? this.subSchemas,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as MapValue?,
      constraints: constraints ?? this.constraints,
    );
  }

  @override
  DiscriminatedObjectSchema copyWith({
    bool? isNullable,
    String? description,
    Object? defaultValue = ackRawDefaultValue,
    List<Validator<MapValue>>? constraints,
    String? discriminatorKey,
    Map<String, ObjectSchema>? subSchemas,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      discriminatorKey: discriminatorKey,
      subSchemas: subSchemas,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final List<Map<String, Object?>> oneOfClauses = [];
    subSchemas.forEach((discriminatorValue, objectSchema) {
      oneOfClauses.add(objectSchema.toJsonSchema());
    });

    Map<String, Object?> schema = {
      'oneOf': oneOfClauses,
      if (description != null) 'description': description,
    };

    if (isNullable) {
      return {
        'oneOf': [
          {'type': 'null'},
          schema,
        ],
        if (description != null) 'description': description,
      };
    }

    return schema;
  }

  @override
  DiscriminatedObjectSchema withDefault(Object? val) {
    return copyWith(defaultValue: val);
  }

  @override
  DiscriminatedObjectSchema addConstraint(Validator<MapValue> constraint) {
    return copyWith(constraints: [...constraints, constraint]);
  }

  @override
  DiscriminatedObjectSchema addConstraints(
    List<Validator<MapValue>> newConstraints,
  ) {
    return copyWith(constraints: [...constraints, ...newConstraints]);
  }

  @override
  DiscriminatedObjectSchema nullable({bool value = true}) {
    return copyWith(isNullable: value);
  }

  @override
  DiscriminatedObjectSchema withDescription(String? newDescription) {
    return copyWith(description: newDescription);
  }
}
