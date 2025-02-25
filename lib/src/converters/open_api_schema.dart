part of '../ack.dart';

class OpenApi3SchemaConverter<S extends Schema<T>, T extends Object> {
  final S _schema;

  const OpenApi3SchemaConverter({required S schema}) : _schema = schema;

  Map<String, Object?> toSchema() {
    return _convertSchema(_schema);
  }
}

typedef JSON = Map<String, Object?>;

JSON _convertObjectSchema(ObjectSchema schema) {
  final properties = schema.getProperties();
  final required = schema.getRequiredProperties();
  final additionalProperties = schema.getAllowsAdditionalProperties();

  return {
    'properties':
        properties.map((key, value) => MapEntry(key, _convertSchema(value))),
    if (required.isNotEmpty) 'required': required,
    'additionalProperties': additionalProperties,
  };
}

JSON _convertDiscriminatedObjectSchema(DiscriminatedObjectSchema schema) => {
      'discriminator': {'propertyName': schema.getDiscriminatorKey()},
      'oneOf':
          schema.getSchemas().map((schema) => _convertSchema(schema)).toList(),
    };

JSON _convertListSchema(ListSchema schema) => {
      'items': _convertSchema(schema.getItemSchema()),
    };

JSON _convertSchema<S extends Schema<T>, T extends Object>(S schema) {
  final type = _convertSchemaType(schema.getSchemaType());
  final nullable = schema.getNullable();
  final description = schema.getDescription();
  final defaultValue = schema._defaultValue;

  JSON schemaMap = {
    if (type.isNotEmpty) 'type': type,
    // Nullable is false by default
    if (nullable) 'nullable': nullable,
    if (description.isNotEmpty) 'description': description,
    if (defaultValue != null) 'default': defaultValue,
  };

  switch (schema) {
    case ObjectSchema o:
      schemaMap = deepMerge(schemaMap, _convertObjectSchema(o));
      break;
    case DiscriminatedObjectSchema d:
      schemaMap = deepMerge(schemaMap, _convertDiscriminatedObjectSchema(d));
      break;
    case ListSchema l:
      schemaMap = deepMerge(schemaMap, _convertListSchema(l));
      break;
    default:
      break;
  }

  return deepMerge(
    schemaMap,
    _getMergedOpenApiConstraints(schema.getConstraints()),
  );
}

String _convertSchemaType(SchemaType type) {
  return switch (type) {
    SchemaType.string => 'string',
    SchemaType.double => 'number',
    SchemaType.int => 'integer',
    SchemaType.boolean => 'boolean',
    SchemaType.list => 'array',
    SchemaType.object => 'object',
    SchemaType.discriminatedObject => '',
  };
}

/// Merges the OpenAPI schemas from a list of [OpenApiConstraintValidator<T>].
///
/// This function converts each validator to its schema representation using
/// [toSchema()] and combines them into a single schema map using [deepMerge].
/// If a call to [toSchema()] fails, the error is logged and the schema is skipped.
///
/// [constraints] - The list of OpenAPI constraint validators to merge.
/// Returns a merged schema map, or an empty map if no valid schemas are provided.
JSON _getMergedOpenApiConstraints<T extends Object>(
  List<ConstraintValidator<T>> constraints,
) {
  final openApiConstraints =
      constraints.whereType<OpenApiConstraintValidator<T>>();

  return openApiConstraints.fold<JSON>({}, (previousValue, element) {
    try {
      final schema = element.toSchema();

      return deepMerge(previousValue, schema);
    } catch (e) {
      // Log the error and skip this schema
      log('Error generating schema for $element: $e');

      return previousValue;
    }
  });
}
