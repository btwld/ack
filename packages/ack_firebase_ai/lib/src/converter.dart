import 'package:ack/ack.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;

/// Converts ACK schemas to Firebase AI (Gemini) Schema format.
///
/// Firebase AI uses a schema format compatible with OpenAPI 3.0 for structured
/// output generation with Gemini models.
///
/// This is a utility class with only static methods and cannot be instantiated.
class FirebaseAiSchemaConverter {
  // Private constructor prevents instantiation
  const FirebaseAiSchemaConverter._();

  /// Converts an ACK schema to Firebase AI format.
  ///
  /// Returns a [Schema] representing the Firebase AI Schema structure.
  static firebase_ai.Schema convert(AckSchema schema) {
    return _convertSchema(schema);
  }

  static firebase_ai.Schema _convertSchema(AckSchema schema) {
    // Check for unsupported types BEFORE calling toJsonSchema()
    if (schema is TransformedSchema) {
      throw UnsupportedError(
        'TransformedSchema cannot be converted to Firebase AI format. '
        'Convert the underlying schema instead.',
      );
    }

    // Get JSON Schema representation first (ACK already implements this)
    final jsonSchema = schema.toJsonSchema();

    return switch (schema) {
      StringSchema() => _convertString(schema, jsonSchema),
      IntegerSchema() => _convertInteger(schema, jsonSchema),
      DoubleSchema() => _convertDouble(schema, jsonSchema),
      BooleanSchema() => _convertBoolean(schema, jsonSchema),
      ObjectSchema() => _convertObject(schema, jsonSchema),
      ListSchema() => _convertArray(schema, jsonSchema),
      EnumSchema() => _convertEnum(schema, jsonSchema),
      AnyOfSchema() => _convertAnyOf(schema),
      AnySchema() => _convertAny(schema, jsonSchema),
      DiscriminatedObjectSchema() => _convertDiscriminated(schema),
      _ => throw UnsupportedError(
          'Schema type ${schema.runtimeType} is not supported for Firebase AI conversion.',
        ),
    };
  }

  static firebase_ai.Schema _convertString(
    StringSchema schema,
    Map<String, Object?> json,
  ) {
    final enumValues = _readEnumValues(json);

    if (enumValues != null) {
      return firebase_ai.Schema.enumString(
        enumValues: enumValues,
        description: schema.description,
        title: json['title'] as String?,
        nullable: schema.isNullable ? true : null,
      );
    }

    final format = json['format'] as String?;

    final result = firebase_ai.Schema.string(
      description: schema.description,
      title: json['title'] as String?,
      nullable: schema.isNullable ? true : null,
      format: format,
    );

    return result;
  }

  static firebase_ai.Schema _convertInteger(
    IntegerSchema schema,
    Map<String, Object?> json,
  ) {
    return firebase_ai.Schema.integer(
      description: schema.description,
      title: json['title'] as String?,
      nullable: schema.isNullable ? true : null,
      minimum: _asInt(json['minimum']),
      maximum: _asInt(json['maximum']),
      format: json['format'] as String?,
    );
  }

  static firebase_ai.Schema _convertDouble(
    DoubleSchema schema,
    Map<String, Object?> json,
  ) {
    return firebase_ai.Schema.number(
      description: schema.description,
      title: json['title'] as String?,
      nullable: schema.isNullable ? true : null,
      minimum: _asDouble(json['minimum']),
      maximum: _asDouble(json['maximum']),
      format: json['format'] as String?,
    );
  }

  static firebase_ai.Schema _convertBoolean(
    BooleanSchema schema,
    Map<String, Object?> json,
  ) {
    return firebase_ai.Schema.boolean(
      description: schema.description,
      title: json['title'] as String?,
      nullable: schema.isNullable ? true : null,
    );
  }

  static firebase_ai.Schema _convertObject(
    ObjectSchema schema,
    Map<String, Object?> jsonSchema,
  ) {
    final properties = <String, firebase_ai.Schema>{};
    final optionalProperties = <String>[];
    final propertyOrdering = <String>[];

    for (final entry in schema.properties.entries) {
      final key = entry.key;
      final propSchema = entry.value;

      // Wrap conversion in try-catch to provide property path context
      try {
        properties[key] = _convertSchema(propSchema);
      } catch (e) {
        // Re-throw with property path context for better error messages
        if (e is UnsupportedError) {
          throw UnsupportedError(
            'Error converting property "$key": ${e.message}',
          );
        } else if (e is ArgumentError) {
          throw ArgumentError(
            'Error converting property "$key": ${e.message}',
          );
        } else if (e is StateError) {
          throw StateError(
            'Error converting property "$key": ${e.message}',
          );
        } else {
          // Wrap unknown errors
          rethrow;
        }
      }

      propertyOrdering.add(key);

      // In Firebase AI, fields are required unless marked optional
      if (!propSchema.isOptional) {
        continue;
      }
      optionalProperties.add(key);
    }

    return firebase_ai.Schema.object(
      properties: properties,
      optionalProperties: optionalProperties.isEmpty ? null : optionalProperties,
      propertyOrdering: propertyOrdering.isEmpty ? null : propertyOrdering,
      description: schema.description,
      title: jsonSchema['title'] as String?,
      nullable: schema.isNullable ? true : null,
    );
  }

  static firebase_ai.Schema _convertArray(
    ListSchema schema,
    Map<String, Object?> jsonSchema,
  ) {
    return firebase_ai.Schema.array(
      items: _convertSchema(schema.itemSchema),
      description: schema.description,
      title: jsonSchema['title'] as String?,
      nullable: schema.isNullable ? true : null,
      minItems: _asInt(jsonSchema['minItems']),
      maxItems: _asInt(jsonSchema['maxItems']),
    );
  }

  static firebase_ai.Schema _convertEnum(
    EnumSchema schema,
    Map<String, Object?> json,
  ) {
    final enumNames = schema.values.map((e) => e.name).toList(growable: false);

    return firebase_ai.Schema.enumString(
      enumValues: enumNames,
      description: schema.description,
      title: json['title'] as String?,
      nullable: schema.isNullable ? true : null,
    );
  }

  static firebase_ai.Schema _convertAnyOf(AnyOfSchema schema) {
    if (schema.schemas.isEmpty) {
      return firebase_ai.Schema(
        firebase_ai.SchemaType.anyOf,
        description: schema.description,
        nullable: schema.isNullable ? true : null,
        anyOf: const [],
      );
    }

    final converted = schema.schemas.map(_convertSchema).toList(growable: false);
    return firebase_ai.Schema(
      firebase_ai.SchemaType.anyOf,
      description: schema.description,
      nullable: schema.isNullable ? true : null,
      anyOf: converted,
    );
  }

  static firebase_ai.Schema _convertAny(
    AnySchema schema,
    Map<String, Object?> jsonSchema,
  ) {
    return firebase_ai.Schema.object(
      properties: const {},
      description: jsonSchema['description'] as String?,
      nullable: schema.isNullable ? true : null,
    );
  }

  static firebase_ai.Schema _convertDiscriminated(
    DiscriminatedObjectSchema schema,
  ) {
    if (schema.schemas.isEmpty) {
      return firebase_ai.Schema.object(
        properties: const {},
        description: schema.description,
        nullable: schema.isNullable ? true : null,
      );
    }

    final convertedBranches = schema.schemas.entries.map((entry) {
      final discriminatorValue = entry.key;
      final branchSchema = entry.value;

      if (branchSchema is! ObjectSchema) {
        return _convertSchema(branchSchema);
      }

      final branchProperties = <String, AckSchema>{
        schema.discriminatorKey: Ack.string().enumString([discriminatorValue]),
        ...branchSchema.properties,
      };

      final normalizedObject = branchSchema.copyWith(properties: branchProperties);

      return _convertObject(
        normalizedObject,
        normalizedObject.toJsonSchema(),
      );
    }).toList(growable: false);

    return firebase_ai.Schema(
      firebase_ai.SchemaType.anyOf,
      description: schema.description,
      nullable: schema.isNullable ? true : null,
      anyOf: convertedBranches,
    );
  }

  /// Reads enum values from JSON schema, ensuring all values are strings.
  ///
  /// Returns null if no 'enum' key exists.
  /// Throws [ArgumentError] if enum format is invalid or contains non-string values.
  static List<String>? _readEnumValues(Map<String, Object?> json) {
    final values = json['enum'];
    if (values == null) {
      return null;
    }

    if (values is! List) {
      throw ArgumentError(
        'Invalid enum format in JSON schema: expected List, got ${values.runtimeType}. '
        'Value: $values',
      );
    }

    final stringValues = <String>[];
    final nonStringValues = <Object?>[];

    for (final value in values) {
      if (value is String) {
        stringValues.add(value);
      } else {
        nonStringValues.add(value);
      }
    }

    // Fail if ANY non-string values found
    if (nonStringValues.isNotEmpty) {
      throw ArgumentError(
        'Firebase AI enum values must be strings. Found non-string values: $nonStringValues. '
        'ACK schemas with numeric or other enum types cannot be converted to Firebase AI format.',
      );
    }

    if (stringValues.isEmpty) {
      throw ArgumentError(
        'Enum list is empty. This indicates an invalid ACK schema definition.',
      );
    }

    return stringValues;
  }

  /// Converts a value to int, with strict validation.
  ///
  /// Throws [ArgumentError] if the value cannot be safely converted.
  /// This prevents silent data loss from truncation or type mismatches.
  static int? _asInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      // Check for special values that can't be converted
      if (value.isNaN) {
        throw ArgumentError(
          'Cannot convert NaN to int for schema constraint',
        );
      }
      if (value.isInfinite) {
        throw ArgumentError(
          'Cannot convert Infinity to int for schema constraint',
        );
      }
      // Check for precision loss from fractional parts
      if (value != value.truncateToDouble()) {
        throw ArgumentError(
          'Cannot safely convert $value to int: would lose fractional part '
          '${value - value.truncateToDouble()}',
        );
      }
      return value.toInt();
    }

    // This should never happen if ACK's toJsonSchema() is working correctly
    throw StateError(
      'Unexpected type ${value.runtimeType} for integer constraint value. '
      'Expected int or double, got: $value. '
      'This indicates a bug in ACK\'s toJsonSchema() implementation.',
    );
  }

  /// Converts a value to double, with strict validation.
  ///
  /// Throws [StateError] if the value is not a number.
  /// Allows NaN and Infinity through, as they are valid double values.
  static double? _asDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }

    // This should never happen if ACK's toJsonSchema() is working correctly
    throw StateError(
      'Unexpected type ${value.runtimeType} for numeric constraint value. '
      'Expected num (int or double), got: $value. '
      'This indicates a bug in ACK\'s toJsonSchema() implementation.',
    );
  }
}
